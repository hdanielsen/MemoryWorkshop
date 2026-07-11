 
 /*------------------------------------------------------------------------
    File        : GetDataResponse
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableResponse from propath.
using Pmfo.Util.Array from propath.

class Pmfo.Core.BusinessLogic.GetDataResponse  implements IGetDataResponse: 
    define private variable mTables as character no-undo.
    define public property MainRequestedBuffer as character no-undo get. protected set. 
     // set to true for singlerow method call to return empty
    define public property NoError             as logical no-undo get. protected set. 
    define public property RequestComplete as logical no-undo get.  protected set.
     /* Returns the Table requests*/
    define public property TableResponses as IGetDataTableResponse extent no-undo get. set.
    
        
    constructor public GetDataResponse ():
        super ().
    end constructor. 
     
    constructor public GetDataResponse ( input pResponse as  IGetDataTableResponse ):
        this-object(cast(Array:ToArray(pResponse),IGetDataTableResponse)).
    end constructor. 
     
    constructor public GetDataResponse ( input pResponses as  IGetDataTableResponse extent ):
        define variable i as integer no-undo.
        TableResponses = pResponses.
        do i = 1 to extent(pResponses):
            mTables = mTables 
                    + (if i = 1 then "" else ",")
                    + pResponses[i]:TableName.
        end.    
    end constructor.
    
    method public IGetDataTableResponse GetTableResponse(pName as character):
        define variable iExtent as integer no-undo.
        iExtent = lookup(pName,mTables).
        if iExtent > 0 then
            return  TableResponses[iExtent] .
        return ?.        
    end.
    
    method public final void SetRequestProperties(poRequest as IGetDataRequest):
        assign
            MainRequestedBuffer = poRequest:MainRequestedBuffer
            NoError = poRequest:NoError
            RequestComplete = true // see BusinessEntity  GetData
            .
          
    end method.
    
end class.