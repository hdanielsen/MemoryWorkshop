
/*------------------------------------------------------------------------
    File        . IBusinessEntity
    Purpose     . 
    Syntax      . 
    Description .
    Author(s)   . hdaniels
    Created     . Mon Feb 11 00.17.18 EST 2019
    Notes       . 
  ----------------------------------------------------------------------*/
 
using Ccs.Common.IService from propath.
using Pmfo.Core.BusinessLogic.IEntity from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Progress.Lang.Object from propath.
using Pmfo.Core.Service.IClientRequest from propath.
 
interface Pmfo.Core.BusinessLogic.IBusinessEntity inherits IEntity, IService.  
    define public property Datasets       as handle extent no-undo get. 
  
    method public void getDataset (output dataset-handle phDataset).
    
    method public void GetData():    
    method public IGetDataResponse GetData( output dataset-handle phDataset ).
    method public IGetDataResponse GetData( input pRequest as IGetDataRequest,output dataset-handle phDataset ).
    method public int64 Count().
    
    method public Object UpdateData (input-output dataset-handle phDataset,poUpdateDataRequest as IUpdateDataRequest).     
    method public Object UpdateData(input-output dataset-handle phDataset).
   
    method public handle GetRequestDataset(pClientRequest as IClientRequest).
    method public handle GetUpdateRequestDataset(pClientRequest as IClientRequest,output plBeforeImageRequired as logical, output pUpdateRequest as IUpdateDataRequest).
    
    method public void Clear().
    
end interface.