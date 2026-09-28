 
 /*------------------------------------------------------------------------
    File        : UpdateUtil
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Aug 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Pmfo.Core.Common.IKey from propath.
using Pmfo.Core.Common.IFieldValue from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.
using Pmfo.Util.BufferUtil from propath.
using Pmfo.Core.Common.FieldValue from propath.
using Pmfo.Core.Common.Key from propath.
using OpenEdge.DataAdmin.Error.IllegalOperationError from propath.
using Pmfo.Core.Common.IntegerHolder from propath.

block-level on error undo, throw.

class Pmfo.Util.UpdateUtil: 
   
   // change keys for all children for buffer with one integer key
   method public static void UpdateKey(phBuffer as handle,pFieldName as character,piNewValue as integer):
       UpdateKey(phBuffer, new Key(new FieldValue(pFieldName,new IntegerHolder(piNewValue)))).
   end method.
   
   method public static  void UpdateKey(phBuffer as handle, poNewKey as IKey ):
        define variable iInputKey     as integer no-undo.
        define variable iChild        as integer no-undo.
        
        define variable iField        as integer no-undo.
        define variable cParentField  as character no-undo.
        define variable hRelation     as handle  no-undo.
        define variable cParentFields as character no-undo.
        define variable iKeyField     as integer no-undo.
        define variable hQuery        as handle no-undo.
        define variable oChildkey     as IKey no-undo.
        define variable cJoin         as character no-undo.
        define variable oFieldValues  as IFieldValue extent no-undo.
        define variable iKey          as integer no-undo.
        define variable cChildName    as character no-undo.
        define variable cParentJoins  as character no-undo.
        define variable cChildJoins   as character no-undo.
        define variable lHaskey       as logical no-undo.
        define variable iKeyPos       as integer no-undo.
        define variable hField        as handle no-undo.
        define variable lAny          as logical no-undo.
        do iInputKey = 1 to extent(poNewKey:FieldValues): 
            hField = phBuffer:buffer-field(poNewKey:FieldValues[iInputKey]:name) no-error.
            if valid-handle(hField) then
                lany = true.
             
        end.
        if not lAny then 
            undo, throw new IllegalArgumentError(subst("UpdateKey called for buffer &1 with no fields that matches Key  &2",
                                                       phBuffer:name,
                                                       poNewKey:toString() 
                                                       )
                                                 ).
        
        do iChild = 1 to phBuffer:num-child-relations: 
            hRelation = phBuffer:get-child-relation(iChild).
            cParentFields = BufferUtil:GetParentJoinFields(hRelation).
            cJoin = BufferUtil:GetJoinExpression(hRelation).
            cParentJoins = BufferUtil:GetParentJoinFields(hRelation).
            cChildJoins  = BufferUtil:GetChildJoinFields(hRelation).
            
            extent(oFieldValues) = ?.
            extent(oFieldValues) = extent(poNewKey:FieldValues).
            lHaskey = false.
            do iKey = 1 to extent(oFieldValues): 
                iKeypos = lookup(poNewKey:FieldValues[iKey]:Name,cParentJoins). 
                if iKeyPos > 0 then 
                do:
                    oFieldValues[iKey] = new FieldValue(entry(iKeypos,cChildJoins),poNewKey:FieldValues[iKey]:Value).
                    lHaskey = true.
                end.
            end.
            if lHaskey then 
            do on error undo, throw: 
                oChildkey = new Key(ofieldValues).
                create query hQuery.
                hQuery:add-buffer(hRelation:child-buffer).
                hQuery:query-prepare(subst("preselect each &1 where &3 and row-state(&1) = &2",
                                            hRelation:child-buffer:name,
                                            row-created,
                                            cJoin)).
         
                hQuery:query-open().
                hQuery:get-first.
                do while hRelation:child-buffer:avail:
                    if hRelation:child-buffer:rejected = false and hRelation:child-buffer:error = false then
                    do: 
                        UpdateKey(hRelation:child-buffer,oChildkey).    
                    end.     
                    hQuery:get-next. 
                end. 
                finally:
                    if valid-handle(hQuery) then 
                        delete object hQuery.        
                end finally.
            end.
        end.  
        do iInputKey = 1 to extent(poNewKey:FieldValues): 
            hField = phBuffer:buffer-field(poNewKey:FieldValues[iInputKey]:name) no-error.
            if valid-handle(hField) then
            do:
                hField:buffer-value = poNewKey:FieldValues[iInputKey]:value:toString().
            end.
        end.       
    end method.
end class.