
/*------------------------------------------------------------------------
    File        : IGetDataResponse
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/


using Pmfo.Core.BusinessLogic.IGetDataTableResponse from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.

interface Pmfo.Core.BusinessLogic.IGetDataResponse:
      
    define public property MainRequestedBuffer   as character no-undo get.  
      
    define public property TableResponses as IGetDataTableResponse extent no-undo
    get.
    
    method public IGetDataTableResponse GetTableResponse(pName as character).
      
    method public void SetRequestProperties(pRequest as IGetDataRequest).
end interface.