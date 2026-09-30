
/*------------------------------------------------------------------------
    File        . IBusinessEntity
    Purpose     . 
    Syntax      . 
    Description .
    Author(s)   . hdaniels
    Notes       . 
  ----------------------------------------------------------------------*/
 
using Ccs.Common.IService from propath.
using Pmfo.Core.BusinessLogic.IEntity from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Progress.Lang.Object from propath.
using Pmfo.Core.Service.IClientRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.Common.IWarningMessages from propath.
 
interface Pmfo.Core.BusinessLogic.IBusinessEntity inherits IEntity, IService.  
    define public property Datasets       as handle extent no-undo get. 
    
    define public property WarningMessages as IWarningMessages no-undo get. 
       
    method public void getDataset (output dataset-handle phDataset).
    
    // fill all data
    method public void GetData():    
    
    // fill requested data
    method public logical GetData( input poRequest as IGetDataRequest).
        
    // get all data 
    method public IGetDataResponse GetData( output dataset-handle phDataset ).
   
    // get requested dataset  
    method public IGetDataResponse GetData( input pRequest as IGetDataRequest,output dataset-handle phDataset ).
   
    // get requested main table - implementation is not expected to support by-reference. (use dataset methods for that) 
    method public logical GetData( input pTableRequest as IGetDataTableRequest, output table-handle phTable).
    
    // get requested main table - implementation is not expected to support by-reference.  (use dataset methods for that)
    method public logical GetData( input pQueryEntry as IQueryEntry, output table-handle phTable). 
   
    method public logical GetData( output table-handle phTable).
    
    method public int64 Count().
    
    method public Object UpdateData( input-output dataset-handle phDataset).
    
    method public Object UpdateData (input-output dataset-handle phDataset,poUpdateDataRequest as IUpdateDataRequest).     
   
    /* return dataset for GET request - called by service interface (OperationHandler) layer to get dataset for GetData */
    method public handle GetRequestDataset(pClientRequest as IClientRequest).
    
    /* return dataset for POST,PUT,DELETE request - called by service interface (OperationHandler) 
       layer to get dataset to load client data int and pass to UpdateData */
    method public handle GetUpdateRequestDataset(pClientRequest as IClientRequest,output plBeforeImageRequired as logical, output pUpdateRequest as IUpdateDataRequest).
    
    method public void Clear().
    
    method public character GetKeys().
    method public character GetPublicKeys().
    method public character GetTextField().
    method public character GetPublicTextField().
    method public character GetJoinPairs(parentBe as IBusinessEntity).
    
end interface.