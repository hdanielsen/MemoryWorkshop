 
 /*------------------------------------------------------------------------
    File        : FieldValue
    Purpose     : Holds a field value detached from data buffer 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : May 2022
    Notes       :  
 ----------------------------------------------------------------------*/
  


block-level on error undo, throw.

using Ccs.Common.Support.IPrimitiveHolder from propath.
using Pmfo.Core.Common.IFieldValue from propath.
using Pmfo.Util.PrimitiveHolderUtil from propath.
 

class Pmfo.Core.Common.FieldValue implements IFieldValue: 

    define public property Name as character no-undo 
    get.
    protected set. 

    define public property Value as IPrimitiveHolder no-undo 
    get.
    protected set. 
    
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    
    constructor public FieldValue (pcName as character, poValue as IPrimitiveHolder ):
        super ().
        Name = pcName.
        this-object:Value = poValue.
    end constructor.
    
    constructor public FieldValue (pcName as character, pcValue as character ):
        this-object (pcName, PrimitiveHolderUtil:GetHolder(pcValue)).
    end constructor.
    
    constructor public FieldValue (pcName as character, plongValue as longchar):
        this-object (pcName, PrimitiveHolderUtil:GetHolder(plongValue)).
    end constructor.
       
    constructor public FieldValue (pcName as character, piValue as integer ):
        this-object (pcName, PrimitiveHolderUtil:GetHolder(piValue)).
    end constructor.
    
    constructor public FieldValue (pcName as character, piValue as int64 ):
        this-object (pcName, PrimitiveHolderUtil:GetHolder(piValue)).
    end constructor.
    
    constructor public FieldValue (pcName as character, pdValue as decimal):
        this-object (pcName, PrimitiveHolderUtil:GetHolder(pdValue)).
    end constructor.
    
    constructor public FieldValue (pcName as character, plValue as logical):
        this-object (pcName, PrimitiveHolderUtil:GetHolder(plValue)).
    end constructor.
    
    constructor public FieldValue (pcName as character, ptValue as date):
        this-object (pcName, PrimitiveHolderUtil:GetHolder(ptValue)).
    end constructor.
    
    constructor public FieldValue (pcName as character, ptValue as datetime):
        this-object (pcName, PrimitiveHolderUtil:GetHolder(ptValue)).
    end constructor.
    
    constructor public FieldValue (pcName as character, ptValue as datetime-tz):
        this-object (pcName, PrimitiveHolderUtil:GetHolder(ptValue)).
    end constructor.
    
    method override public logical Equals(input PO as Progress.Lang.Object):
        
        if super:Equals(PO) then
            return true.
        
        if type-of(PO,IFieldValue) then
        do:
            if cast(PO, IFieldValue):Name = this-object:Name then 
            do:
                if type-of(PO,IFieldValue) then 
                    return this-object:Value:Equals(cast(PO,IFieldValue):Value).
                    
            end.          
        end.
        return false.
    end method.
         
end class.