 
 /*------------------------------------------------------------------------
    File        : BusinessEntity
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
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
using Pmfo.Core.Error.IllegalStateError from propath.
using Pmfo.Core.DataLayer.IDataAccess from propath.
using Ccs.Common.Application from propath.
using Pmfo.Core.Manager.IServiceManager from propath.
using OpenEdge.Core.Assert from propath.
using Pmfo.Core.Error.IllegalOperationError from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableResponse from propath.
using Pmfo.Core.BusinessLogic.IReceiveDataEventArgs from propath.
using Pmfo.Util.BufferUtil from propath.

class Pmfo.Core.BusinessLogic.BusinessEntity abstract inherits DataService implements IBusinessEntity : 
    define public property Public         as logical   no-undo get. protected set.
    define public property Resource       as character no-undo get. protected set.
    
    define public property ReadOnly       as logical       no-undo get.  
    define public property CanCreate      as logical       no-undo get.
    define public property CanDelete      as logical       no-undo get.
    define public property Datasets       as handle extent no-undo get. protected set.
    
    define public property ClientOnly     as logical        no-undo get. protected set.
    
    
    define protected property Initialized as logical no-undo get. set. 
    
    define protected property DefaultDataset as handle no-undo 
        get():
            if extent(Datasets) <> ? then
                return Datasets[1].
            return ?.    
        end. 
        protected set.
    
    // avoid memory leak by keeping only one requested dynamic dataset (set in GetRequestDataset) 
    // and deleting previous and providing a handle for the destructor to delete when done   
    define protected property RequestDatasetHandle as handle get. 
        set(ph as handle):
            if valid-handle(RequestDatasetHandle) and RequestDatasetHandle:dynamic and RequestDatasetHandle <> ph then
                delete object RequestDatasetHandle no-error.
            RequestDatasetHandle = ph.
        end.     
    
    define protected property DataAccess as IDataAccess no-undo 
        get():
            if not valid-object(DataAccess) then 
                DataAccess = CreateDataAccess().
            return DataAccess.     
        end.     
        set.
    
    
     /*--------------------------------------------------------------------------
     Purpose: Constructor for entities with one dataset with one top buffer
              Pass the buffer, temp-table or dataset as handle 
     Notes:  A single top buffer defines the resource name 
             if more than one top buffer the dataset serialize-name is used 
    --------------------------------------------------------------------------*/
    
    constructor public BusinessEntity ( phHandle as handle ):
        define variable iNumTop  as integer no-undo.
        define variable lAsserted as logical no-undo.
        define variable cMsg      as character no-undo 
            init "Handle passed to BusinessEntity Constructor".
        
        super ().
        Assert:NotNull(phHandle,cMsg).
        extent(Datasets) = 1.
        case phHandle:type:
            when "buffer" then 
            do:
                create dataset DataSets[1].
                DataSets[1]:name = "ds" + substr(phHandle:table-handle:name,2).
                /* for single top -table we keep the public names the same */
                DataSets[1]:serialize-name = phHandle:serialize-name.
                DataSets[1]:add-buffer(phHandle).
            end. // buffer
            when "temp-table" then 
            do:
                create dataset DataSets[1].
                DataSets[1]:name = "ds" + substr(phHandle:name,2).
                /* for single top-table we keep the public names the same */
                DataSets[1]:serialize-name = phHandle:serialize-name.
                DataSets[1]:add-buffer(phHandle:default-buffer-handle).
            end. // temp-table   
            when "dataset" then 
            do:  
                iNumTop = DatasetUtil:GetNumTopBuffers(phHandle).          
                if iNumTop > 1  then
                do:
                    if phHandle:serialize-name <> phHandle:name then 
                    do:
                        AssertDatasetName(phHandle).
                        lAsserted = true.
                    end.    
                    else 
                        undo, throw new IllegalArgumentError(subst("Constructor without only dataset parameter used with dataset with more than one top buffer and no serialize-name in '&1",this-object:GetClass():TypeName)).
                end.    
                /* for single top-table the public names should be the same 
                   if the serialize-name is not specified just set it 
                   - the AssertDatasetName will throw error if a different serialize-name was specified 
                */
                if iNumTop = 1 and phHandle:serialize-name = phHandle:name then 
                do:
                    phHandle:serialize-name = DatasetUtil:GetTopBuffer(phHandle,1):serialize-name.
                end.    
                DataSets[1] = phHandle.
            end. //dataset
            otherwise do:
                undo, throw new IllegalArgumentError(Cmsg + " must be buffer, temp-table or dataset").
            end.     
        end case.
        Resource = DataSets[1]:serialize-name. 
        if not lAsserted then 
            AssertDatasetName(DefaultDataset).    
    end constructor.
    
     // sub classes can overide this if something must happen before the standard call to Receivebuffer or publish DataReceived
     // known use cases - all are candidates for better ways to do this -  
        // - PublicNameBe always loaddata 
        // - BE that needs to fire DataReceived in children before parent -
        //      this-object:OnDataReceived(pReceiveDataArgs, phDataset).
        // - ClientBusinessEntity - has final ReceiveBuffer and Receivebuffer does not have args
        //   - used for 2 (?) cases that needs to check the IReceiveDataEventArgs to set flag if refresh since it does not handle it
       
    method protected void BeforeReceiveData(pReceiveDataArgs as IReceiveDataEventArgs, phDataset  as handle):
    end method.
    
    method protected void ReceiveBuffer( pParent as IBusinessEntity, pRequest as IGetDataTableRequest,pResponse as IGetDataTableResponse, phBuffer as handle):
    end method.
     
    method protected void AssertDatasetName(phDataset as handle):
        define variable i as integer no-undo.
        /* The dataset:serialize-name is exposed as resource name, to be used in 
           the url to locate this business entity. 
           For cases where the dataset has more than one top level we use 
           the resource name as the table in GetDataTableRequest as a request 
           for all top level tables. This ensures that the data service never need 
           to know the exact schema to build a request. (Most ABL Data services 
           either caches the schema or requires a getDataset call to build the
           request or they delegate the request building to tht entity )    
           So to manage ambiguity between dataset and buffer in the table request 
           management with the ability to support direct requests for the top 
           single buffer serialize-name in the url (most requests)
           and also support using resouce name to retriece all top level 
           tables for rare cases with more than one top level table the following 
           rules are enforced (to everyones benefit...) 
           */  
        if DatasetUtil:GetNumTopBuffers(phDataset) = 1  then do:
            if phDataset:serialize-name <> DatasetUtil:GetTopBuffer(phDataset,1):serialize-name then
                undo, throw new IllegalOperationError(subst('The dataset and the single top table "&1" must have the same serialize-name in order to expose the top table as the entity~'s Resource',phDataset:get-top-buffer (1):name)).
        end.
        else do i = 1 to phDataset:num-top-buffers:
            if phDataset:serialize-name = phDataset:get-top-buffer (i):serialize-name then
                undo, throw new IllegalOperationError(subst("Datasets[&1] &2 must have a different serialize-name than the top table serialize-name '&3'",i,phDataset:name,phDataset:get-top-buffer (i):serialize-name)).
        end.
    end method.     
    
    
    method public void GetDataset (output dataset-handle phDataset).
    end method.    
    
    method public void GetData():    
        AssertInitialized().    
    end method.    
    
    method public IGetDataResponse GetData( output dataset-handle phDataset ).
        AssertInitialized().    
    end method.    
    
    method public IGetDataResponse GetData( input pRequest as IGetDataRequest,output dataset-handle phDataset ).
        AssertInitialized().    
    end method.    
    
    method public logical GetData(  output table-handle phTable):
        define variable hNewDataset     as handle no-undo.
           
        if DefaultDataset:num-top-buffers > 1 then 
            undo, throw new IllegalArgumentError(subst("Request to GetData(output table-handle) in Resource &1 that has more than one top buffer in the default dataset",Resource)).
         
        if valid-handle(phTable) = false 
        or phTable = DefaultDataset:get-top-buffer (1):table-handle then
        do: 
            GetData(output dataset-handle DefaultDataset by-reference).
            if not valid-handle(phTable) then 
                phTable = DefaultDataset:get-top-buffer (1):table-handle.
        end.    
        else do:    
            if phTable:serialize-name = Resource
            or phTable:name = DefaultDataset:get-top-buffer (1):table-handle:name then
            do on error undo, throw: 
                create dataset hNewDataset.
                hNewDataset:serialize-name = Resource.
                hNewDataset:add-buffer(phTable:default-buffer-handle).
                GetData(output dataset-handle hNewDataset by-reference).
                finally:
                    if valid-handle(hNewDataset) then 
                         delete object hNewDataset.    
                end finally.
            end.
            else
                undo, throw new IllegalArgumentError(subst("Request to GetData(output table-handle &1) in Resource '&2'",phTable:name, Resource)).
       
        end.
        return true. //  we throw error for all unsupported cases    
        
    end method.     
    
    method public int64 Count().
        AssertInitialized().    
    end method.    
    
    method public Object UpdateData (input-output dataset-handle phDataset,poUpdateDataRequest as IUpdateDataRequest).     
        AssertInitialized().    
    end method.    
    
    method public Object UpdateData(input-output dataset-handle phDataset).
        AssertInitialized().    
    end method.    
     
    method public void Clear().
        AssertInitialized().    
    end method.    
    
    method public override void Initialize():
        Initialized = true. 
    end method.    
   
    method public override void Dispose(). // IService
        Destroy().
    end method.    
    
    method public override void Destroy().  
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
    
    method protected IDataAccess CreateDataAccess():
        return cast(Application:ServiceManager,IServiceManager):CreateDataAccess(Resource).
    end method.
    
     /** 
    Replaces use of BufferUtil:GetKeys 
    The use of BufferUtil(buffer is a violation of OO encapsulation, but buffers are  
    managed as pseudo-objects throughout so we allowed this for practical reasons .
    
    (BufferUtil:GetKeys is/was intended as a language extension required due to the fact 
     that buffer:keys cannot be used since we have the sequence as primary index)  
    **/     
    
    method public character GetKeys():
        if extent(Datasets) <> ? and DatasetUtil:GetNumTopBuffers(Datasets[1]) = 1 then 
            return BufferUtil:GetInternalKeys(Datasets[1]:get-buffer-handle(1)).
        return ?.     
    end.     
    
   method public character GetPublicKeys():
       define variable cKeys as character no-undo.
       if extent(Datasets) <> ? and DatasetUtil:GetNumTopBuffers(Datasets[1]) = 1 then 
       do: 
           cKeys = GetKeys().
           return BufferUtil:GetPublicFieldNames(Datasets[1]:get-buffer-handle(1), cKeys).
       end.
       return ?.    
   end.     
    
    method public character GetPublicTextField():
        define variable hFld as handle no-undo.
        define variable i as integer no-undo.
        define variable cTextFieldIdx as character extent no-undo.
        define variable hbuffer as handle no-undo.
        
        if extent(Datasets) <> ? and DatasetUtil:GetNumTopBuffers(Datasets[1]) = 1 then 
        do:
            hBuffer = Datasets[1]:get-buffer-handle(1).      
            hFld = hBuffer:buffer-field("name") no-error.
            if valid-handle(hFld) then
                return hFld:serialize-name.
            hFld = hBuffer:buffer-field("description") no-error.
            if valid-handle(hFld) then
                return hFld:serialize-name.
            hFld = hBuffer:buffer-field("descr") no-error.
            if valid-handle(hFld) then
            do:
                if hFld:serialize-name = "description" or hFld:serialize-name = "name" then
                    return hFld:serialize-name.
                else do i = 1 to hBuffer:num-fields:
                    hFld = hBuffer:buffer-field(i).
                    if hFld:serialize-name = "description" then
                        return hFld:serialize-name.
                end.       
            
            end. 
        // check if there is an index defined with name textfield
        // (convention - the assumtion is that it is ok to have an index of such a field) 
            cTextFieldIdx = BufferUtil:GetFieldsInIndex(hBuffer,"TextField",false).
            if extent(cTextFieldIdx) = 1 then 
                return cTextFieldIdx[1].
        end.        
        return "".          
    end.     
    
    
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
    
    method protected void AssertInitialized():
        if not Initialized then 
            undo, throw new IllegalStateError(substitute("&1 is not initilized. Cannot execute data operation. Make sure Initialize override calls super",Resource)). 
    end method.    
end class.