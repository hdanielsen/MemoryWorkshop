 
 /*------------------------------------------------------------------------
    File        : TransactionManager
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Wed Jul 31 08:49:13 EDT 2019
    Notes       : 
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using Ccs.BusinessLogic.CommitScopeEnum from propath.
using OpenEdge.Core.Collections.IMap from propath.
using OpenEdge.Core.WidgetHandle from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.DataLayer.IUpdateTarget from propath.
using Pmfo.Core.DataLayer.Update.ITransactionManager from propath.
using Pmfo.Core.DataLayer.ValidationHookEventType from propath.
using Pmfo.Core.Error.IllegalOperationError from propath.
using Pmfo.Core.Error.TransactionError from propath.
using Progress.Lang.ParameterList from propath.
using Progress.Reflect.Method from propath.

class Pmfo.Core.DataLayer.Update.TransactionManager implements ITransactionManager: 
    /* Event published before update starts. 
       DataSources may subscribe to this for example to change row-state  
    */
    define public event DatasetTransactionEnd signature void (input dataset-handle phDataset). 
    define public event EndTableTransaction signature void (input dataset-handle phDataset). 
    
    define public property ShallowDelete as logical no-undo get. protected set.
    define public property UpdateTargets as IMap no-undo get. set.
    define public property CommitScope   as CommitScopeEnum      no-undo get. set.  
    
    define protected property UpdateTarget       as IUpdateTarget no-undo get. set.
    define protected property NoTargetTables     as character no-undo get. set.
    define protected property UpdateRequest      as IUpdateDataRequest no-undo get. set.   
    define protected variable TransactionNum as integer no-undo.
    
    define variable hAlertDataset as handle no-undo.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
        
    constructor public TransactionManager (pUpdateTargets as IMap,pUpdateRequest as IUpdateDataRequest):
        UpdateTargets = pUpdateTargets.
        UpdateRequest = pUpdateRequest.
        CommitScope = pUpdateRequest:CommitScope.
    end constructor.
    
    // called from AbstractUpdateTargetManager
    // @TODO some of this is duplicated in NestedTransactionManager (except the subscription)
    // maybe move this to AbstractUpdateTargetManager 
    // - but this would likely require empty overrideson ActionTransactionManager and ValidationTransactionManager
    method protected void SubscribeDatasetTransactionEnd(pUpdateTarget as IUpdateTarget, phdataset as handle).
        define variable oMethod as Method no-undo.
        define variable oParamList as ParameterList  no-undo.
        define variable hHandle    as handle no-undo.
        oParamList = new ParameterList(1).
        oParamList:SetParameter(1,"dataset-handle","input",hhandle).    
        oMethod = pUpdateTarget:GetClass():GetMethod("DatasetTransactionEnd",Progress.Reflect.Flags:Public or Progress.Reflect.Flags:Instance or Progress.Reflect.Flags:DeclaredOnly,oParamList).
        if valid-object(oMethod) then 
        do:
            if CommitScopeEnum:All:Equals(CommitScope) then
                DatasetTransactionEnd:Subscribe(pUpdateTarget:DatasetTransactionEnd).
            else 
                undo, throw new IllegalOperationError(subst("Cannot use CommitScope &1 with &2 that has a 'DatasetTransactionEnd' override",
                                                            CommitScope:ToString(),
                                                            pUpdateTarget:GetClass():TypeName))
                                                            .    
        end.     
    end method.
    
    method protected logical IsBufferActive(phBuffer as handle):
        return (phbuffer:table-handle:has-records or (valid-handle(phbuffer:table-handle:before-table) and phbuffer:table-handle:before-table:has-records)) 
                and (NoTargetTables = "" or lookup(phbuffer:table-handle:name,NoTargetTables) = 0). 
    end method.    
    
    method protected void ProcessDeletedRows(phBuffer as handle, plDeep as logical):
        define variable hQuery  as handle no-undo.
        define variable hBefore as handle no-undo.
        
        if IsBufferActive(phBuffer) then
        do:
            if plDeep then
                ProcessDeletedChildren(phBuffer).        
            
            AssertAndSynchBuffer(phBuffer).
            
            hBefore = phBuffer:before-buffer.
            create query hQuery.
            hQuery:add-buffer(hBefore).        
            hQuery:query-prepare(subst("for each &1 where row-state(&1) = row-deleted",hBefore:name)).
            hQuery:query-open().
            hQuery:get-first.
            do while hBefore:avail:
                if hBefore:error = false and hBefore:rejected = false then
                do:
                    if CommitScopeEnum:Row:Equals(CommitScope) then
                    do transaction:
                        ProcessBeforeRow(hBefore).
                    end.
                    else
                        ProcessBeforeRow(hBefore).
                end.
                hQuery:get-next. 
            end.    
        end.
        finally:
            if valid-object(hQuery) then
                delete object hQuery.
        end finally. 
        
    end method.
    
    
    method protected void ProcessDeletedChildren(phBuffer as handle):
        define variable hRelation as handle no-undo.
        define variable i as integer no-undo.
        do i = 1 to phBuffer:num-child-relations:
            hRelation = phbuffer:get-child-relation(i).
            if hRelation:recursive = false then
                ProcessDeletedRows(hRelation:child-buffer, true).
        end.     
    end method.
    
    method protected void ProcessChildren(phBuffer as handle):
        define variable hRelation as handle no-undo.
        define variable i as integer no-undo.
        do i = 1 to phBuffer:num-child-relations:
            hRelation = phbuffer:get-child-relation(i).
            if hRelation:recursive = false then
               ProcessTable(hRelation:child-buffer).
        end.     
    end method.
    
    method public void ProcessDataset(phDataset as handle):
        if CommitScopeEnum:All:Equals(CommitScope) then
        do: 
            do transaction:
                TransactionNum = TransactionNum + 1.
                DoProcessDataset(phDataset).
                if phdataset:error then 
                    undo, throw new TransactionError().   
                DatasetTransactionEnd:publish(input dataset-handle phDataset by-reference).
            end.
        end.
        else do:
            DoProcessDataset(phDataset).
        end.
          
    end method. 
    
    method protected void DoProcessDataset(phDataset as handle):
        define variable iBuffer as integer no-undo.
        define variable iNumTopBuffers as integer no-undo.
        define variable hBuffer as handle no-undo.
        
      //  AssertDataset(phDataset).       
        do iBuffer = 1 to phDataset:num-top-buffers:
            hBuffer = phDataset:get-top-buffer(iBuffer).
            if ShallowDelete = false 
            and IsBufferActive(hBuffer)  then
                ProcessDeletedRows(hBuffer,true).
            ProcessTable(hBuffer).
        end.
    end method.     
    
    
    method protected void ProcessTable( input phBuffer as handle ):
        if IsBufferActive(phBuffer) then
        do:
            if CommitScopeEnum:Table:Equals(CommitScope) then
            do:
                if not phBuffer:error then
                do transaction:
                    TransactionNum = TransactionNum + 1.
                    DoProcessTable(input phBuffer).
                end.
            end.
            else 
                DoProcessTable(input phBuffer).
        end. 
    end method.
    
    method protected void DoProcessTable( input phBuffer as handle ):
        if IsBufferActive(phBuffer) then
        do:
            if ShallowDelete then
                ProcessDeletedRows(phBuffer,false).
            
            AssertAndSynchBuffer(phbuffer).
            ProcessRows(phbuffer,0). // will call ProcessUnmodifiedRow 
            ProcessRows(phbuffer,row-modified).
            ProcessRows(phbuffer,row-created).
            ProcessChildren(phBuffer).
        end.   
    end method.
    
    method protected void ProcessBeforeRow( input phBuffer as handle ):
        if CommitScopeEnum:Row:Equals(CommitScope) then
        do:
            if not phBuffer:error then
            do transaction:
                TransactionNum = TransactionNum + 1.
                DoProcessBeforeRow(input phBuffer).
            end.
            
        end.
        else 
            DoProcessBeforeRow(input phBuffer).
         
    end method.
    
    method protected void DoProcessBeforeRow(phBeforeBuffer as handle):
        define variable hAfter as handle no-undo.
        if phBeforeBuffer:row-state <> row-deleted then
        do:
            hAfter = phBeforeBuffer:after-buffer.
            hAfter:find-by-rowid (phBeforebuffer:after-rowid).
        end.            
         
        DoBeforeRow(phBeforeBuffer).
        
        if phBeforeBuffer:row-state <> row-deleted then
        do:
            // use no-error in case the receord was deleted (could happen for action)
            // an error does not help and the loop continues 
            if hAfter:avail = false or hAfter:rowid <> phBeforebuffer:after-rowid then
                hAfter:find-by-rowid (phBeforebuffer:after-rowid) no-error.
        end.            
    end method.
    
    method protected void ProcessRows(phBuffer as handle, piState as integer):
        define variable hBefore as handle no-undo.
        define variable hQuery  as handle no-undo.
        define variable lok as logical no-undo. 
        create query hQuery.
        hQuery:add-buffer(phBuffer).
        hBefore = phBuffer:before-buffer.
        // Use preselect since otherwise references to the buffer may mess up the query and cause an endless loop
        // known case - AfterRow assign of sequenceBuffer handle .. InventoryDS - PrintWeighTag > FillCurrent = probably bug  
        // Later: it is also a general precaution for cases where the primary key may change
        hQuery:query-prepare(subst("preselect each &1 where row-state(&1) = &2",phbuffer:name,piState)).
        hQuery:query-open().
        hQuery:get-first.
        do while phBuffer:avail:
            if phbuffer:error = false and phbuffer:rejected = false then
            do:
                if phBuffer:row-state <> 0 then
                do:
                    hBefore:find-by-rowid(phBuffer:before-rowid). 
                    ProcessBeforeRow(hBefore).
                end.
                else  
                    ProcessUnmodifiedRow(phBuffer).
            end.
            lok = hQuery:get-next.
        end.   
        finally:
            delete object hQuery no-error.
        end finally. 
    end method.
    
    method protected void DoBeforeRow (phBeforeBuffer as handle):
        if not phBeforeBuffer:error then
        do:
            UpdateTarget:ValidateRow(phBeforeBuffer, ValidationHookEventType:Begin). 
            if not phBeforeBuffer:error then
            do:
                UpdateTarget:SaveRow(phBeforeBuffer). 
                if not phBeforeBuffer:error then
                    UpdateTarget:ValidateRow(phBeforeBuffer, ValidationHookEventType:End). 
            end.
        end.    
    end method.
  
    // check if data is current if specfied by UpdateRequest 
    method protected void ProcessUnmodifiedRow(phBuffer as handle):
        UpdateTarget:FindSourceForUnmodifiedRow().  
    end method.

    
    method protected void AssertAndSynchBuffer (phBuffer as handle):
        
        define variable oUpdateTarget as IUpdateTarget no-undo.
        
        if valid-handle(phBuffer:after-buffer) then
            phBuffer = phBuffer:after-buffer.
        
        if not valid-object(UpdateTarget) or UpdateTarget:DataBuffer <> phBuffer then    
        do:
            UpdateTarget = cast(UpdateTargets:Get(new WidgetHandle(phBuffer)),IUpdateTarget).
            if not valid-object(UpdateTarget) then 
                  undo, throw new IllegalOperationError(subst("Buffer '&1' does not have a corresponding UpdateTarget",
                                                            phBuffer:name,
                                                            phBuffer:dataset:name
                                                            )
                                                      ).
        end.
        
    end method.
    
end class.