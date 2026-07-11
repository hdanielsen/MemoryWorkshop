
/*------------------------------------------------------------------------
    File        : IGetDataRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
     Notes       : 
  ----------------------------------------------------------------------*/
 
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Ccs.BusinessLogic.INamedQuery from propath.

interface Pmfo.Core.BusinessLogic.IGetDataRequest:  
    define public property MainRequestedBuffer as character no-undo get. set. 
    // tracks timout for request - the default is assumed to be in SessuinManager
    // so do not add a init value here as the query timeout message may use 
    // the presence of a value here to also sugggest increasing timeout 
    // in addition to the change filter and use paging advice 
    
    define public property Timeout             as integer no-undo get. set.
    define public property NoError             as logical  no-undo get. set.
    
    define public property TableRequests       as  IGetDataTableRequest extent no-undo
        get.
    
    define public property NamedQuery as INamedQuery no-undo get. set.
     
    method public IGetDataTableRequest GetTableRequest(pName   as character).
    method public IGetDataTableRequest GetTableRequest(pHandle as handle).
    
    method public logical AddTableRequest(pTableRequest as IGetDataTableRequest).
    
 end interface.