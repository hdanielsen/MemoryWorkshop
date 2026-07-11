 
 /*------------------------------------------------------------------------
    File        : BusinessEntity
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Sat Jun 27 07:19:49 EDT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

 
block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Progress.Lang.Object from propath.
using Pmfo.Core.Service.IClientRequest from propath.
using Ccs.BusinessLogic.CommitScopeEnum from propath.
using Pmfo.Util.DatasetUtil from propath.
using Pmfo.Core.Error.NotFoundError from propath.
using Pmfo.Core.BusinessLogic.UpdateDataRequest from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.
using Pmfo.Core.Common.DataService from propath.

class Pmfo.Core.BusinessLogic.BusinessEntity abstract inherits DataService implements IBusinessEntity : 
    define public property Public         as logical   no-undo get. protected set.
    define public property Resource       as character no-undo get. protected set.
    
    define public property ReadOnly       as logical       no-undo get.  
    define public property CanCreate      as logical       no-undo get.
    define public property CanDelete      as logical       no-undo get.
    define public property Datasets       as handle extent no-undo get.
    
    // avoid memory leak by keeping only one requested dynamic dataset (set in GetRequestDataset) 
    // and deleting previous and providing a handle for the destructor to delete when done   
    define protected property RequestDatasetHandle as handle get. 
        set(ph as handle):
            if valid-handle(RequestDatasetHandle) and RequestDatasetHandle:dynamic and RequestDatasetHandle <> ph then
                delete object RequestDatasetHandle no-error.
            RequestDatasetHandle = ph.
        end.
     
    
    method public void getDataset (output dataset-handle phDataset).
    end method.    
    
    method public void GetData():    
    end method.    
    
    method public IGetDataResponse GetData( output dataset-handle phDataset ).
    end method.    
    
    method public IGetDataResponse GetData( input pRequest as IGetDataRequest,output dataset-handle phDataset ).
    end method.    
    
    method public int64 Count().
    end method.    
    
    method public Object UpdateData (input-output dataset-handle phDataset,poUpdateDataRequest as IUpdateDataRequest).     
    end method.    
    
    method public Object UpdateData(input-output dataset-handle phDataset).
    end method.    
     
    method public void Clear().
    end method.    
    
    method public abstract override void Initialize().
   
    method public override void Dispose(). // IService
        Destroy().
    end method.    
    
    method public handle GetRequestDataset(pClientRequest as IClientRequest):
        RequestDatasetHandle = Datasets[1].
    end method.
    
    method public handle GetUpdateRequestDataset(pClientRequest as IClientRequest,output plBeforeImageRequired as logical, output pUpdateRequest as IUpdateDataRequest).
        define variable hDataset     as handle no-undo.
        define variable hMainBuffer  as handle no-undo.
        plBeforeImageRequired = (pClientRequest:Method = "PUT").
        
        hDataset = GetRequestDataset(pClientRequest). 
        if valid-object(hDataset) then
        do:
            // get the last buffer in the collections (extracged from rest path)
            hMainBuffer = DatasetUtil:GetRequestedBuffer(hDataset, pClientRequest:Collections).
            pUpdateRequest = CreateUpdateDataRequest(hMainBuffer). 
            pUpdateRequest:CommitScope = GetCommitScope(pClientRequest).    
        end.  
       
        return hDataset.
    
    end method.    
    
    
    // default update request for dataset 
    method protected IUpdateDataRequest CreateUpdateDataRequest(phDataset as handle):
        define variable hMainBuffer as handle no-undo.
        define variable oUpdateRequest as UpdateDataRequest no-undo.
        if DatasetUtil:GetNumTopBuffers(phDataset) > 1 then 
            undo, throw new IllegalArgumentError("Dataset with more than one top table").
        hMainBuffer =  DatasetUtil:GetTopBuffer(phDataset, 1).  
        oUpdateRequest = new UpdateDataRequest(hMainbuffer:name).
        return oUpdateRequest.
    end method.
    
    
    // defauilt to all - allow overriode based on client request
    method protected CommitScopeEnum GetCommitScope(pClientRequest as IClientRequest):
        return CommitScopeEnum:All.
    end method.
    
    
end class.