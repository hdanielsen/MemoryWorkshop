 /*------------------------------------------------------------------------
    File        : GetDataRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : Override in order to add GetTableRequest
  ----------------------------------------------------------------------*/


block-level on error undo, throw.
 
using OpenEdge.Core.Assert from propath.
using Pmfo.Core.BusinessLogic.GetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Util.Array from propath.
using Progress.Lang.Object from propath.
using Ccs.BusinessLogic.INamedQuery from propath.
 

class Pmfo.Core.BusinessLogic.GetDataRequest  implements IGetDataRequest: 
    define public property HasWarnings as logical no-undo get. protected set.
      
    define public property TableRequests as IGetDataTableRequest extent no-undo get. protected set. // not public in interface   
      
    define public property MainRequestedBuffer as character no-undo get. set. 
    // tracks timout for request - the default is assumed to be in SessuinManager
    // so do not add a init value here as the query timeout message may use 
    // the presence of a value here to also sugggest increasing timeout 
    // in addition to the change filter and use paging advice 
    define public property Timeout             as integer  no-undo get. set.
    define public property NoError             as logical  no-undo get. set.
    
    define public property NamedQuery as INamedQuery no-undo  get. set.
     
    /* Default constructor */
    constructor public GetDataRequest (  ):
        super ().
    end constructor.
    
    /* Default constructor */
    constructor public GetDataRequest (pNamedQuery as INamedQuery):
        this-object().
        NamedQuery = pNamedQuery.
    end constructor.
    
    constructor public GetDataRequest(input pRequest as IGetDataTableRequest):
        this-object(cast(Array:ToArray(pRequest),IGetDataTableRequest)).
    end constructor.
    
    
    /* Constructor
       @param IGetDataTableRequest[] The table requests */
    constructor public GetDataRequest(input pRequests as IGetDataTableRequest extent):
        define variable i as integer no-undo.
        
        super().
        
        Assert:HasDeterminateExtent(pRequests, 'Table requests').
          
        assign this-object:TableRequests = pRequests.
        
    end constructor.
   
    method public logical HasTableRequest(pName as character).
        return valid-object(GetTableRequest(pName)).
    end method.
    
    method public logical HasTableRequest(pHandle as handle).
        case pHandle:type:
            when "buffer" then
                return HasTableRequest(pHandle:table-handle:name).
            when "temp-table" then
                return HasTableRequest(pHandle:name).
        end.     
    end method.
    
    method public IGetDataTableRequest GetTableRequest(pHandle as handle):
        case pHandle:type:
            when "buffer" then
                return GetTableRequest(pHandle:table-handle:name).
            when "temp-table" then
                return GetTableRequest(pHandle:name).
        end.    
    end.
    
    method public IGetDataTableRequest GetTableRequest(pName as character):
        define variable i as integer no-undo.
        do i = 1 to extent(TableRequests):
            if TableRequests[i]:TableName = pname then
                return TableRequests[i].      
        end.         
    end.
    
    method public logical ReplaceTableRequests(pTableRequest as IGetDataTableRequest extent):
        extent(TableRequests) = ?.
        TableRequests = pTableRequest.
    end method. 
    
    method public logical AddTableRequest(pTableRequest as IGetDataTableRequest):
        extent(TableRequests) = (if extent(TableRequests) = ? then 0 else extent(TableRequests)) +  1.
        TableRequests[extent(TableRequests)] = pTableRequest.
        return true.
    end method.
     
     
    method override public character ToString(  ):
        define variable i as integer no-undo.
        define variable cString as character no-undo.
        define variable cDLm as character no-undo.
        do i = 1 to extent(TableRequests):
            cString = trim(subst("&1&2 &3",
                            cString,
                            cDlm,
                            TableRequests[i]:ToString())
                            ).
            cDlm = ",". 
        end.     
        if cString > "" then
            return cString.
        else 
            return super:ToString().  
    end method.
    
     
    
    // allow subclasses to create correct type from Clone 
    method protected GetDataRequest CreateNewForClone():
        return new GetDataRequest().        
    end method. 
        
    method public override Object Clone(): 
        define variable oClientRequest as GetDataRequest no-undo.
        assign
            oClientRequest = CreateNewForClone()         
            oClientRequest:TableRequests       = this-object:TableRequests 
            oClientRequest:MainRequestedBuffer = this-object:MainRequestedBuffer
            oClientRequest:Timeout             = this-object:Timeout
            . 
        
        
        return oClientRequest. 
    end method.         
    
end class.