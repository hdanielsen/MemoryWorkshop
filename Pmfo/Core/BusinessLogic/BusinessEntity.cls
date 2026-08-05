 
 /*------------------------------------------------------------------------
    File        : BusinessEntity
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/

 
block-level on error undo, throw.

using Ccs.BusinessLogic.CommitScopeEnum from propath.
using Ccs.Common.Application from propath.
using OpenEdge.Core.Assert from propath.
using Pmfo.Core.BusinessLogic.GetDataRequest from propath.
using Pmfo.Core.BusinessLogic.GetDataResponse from propath.
using Pmfo.Core.BusinessLogic.GetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.GetDataTableResponse from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableResponse from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.BusinessLogic.UpdateDataRequest from propath.
using Pmfo.Core.Common.DataService from propath.
using Pmfo.Core.DataLayer.IDataAccess from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.
using Pmfo.Core.Error.IllegalOperationError from propath.
using Pmfo.Core.Error.IllegalStateError from propath.
using Pmfo.Core.Error.NotImplementedError from propath.
using Pmfo.Core.Manager.IServiceManager from propath.
using Pmfo.Core.Service.IClientRequest from propath.
using Pmfo.Util.BufferUtil from propath.
using Pmfo.Util.DatasetUtil from propath.
using Progress.Lang.Object from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataResponse from propath.
using Progress.Lang.Error from propath.
using Pmfo.Core.Error.ValidationError from propath.
using OpenEdge.Core.String from propath.
using Pmfo.Core.BusinessLogic.IClientEntity from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Pmfo.Core.Service.JsonDatasetErrorProcessor from propath.
using Pmfo.Core.Error.ApplicationError from propath.

class Pmfo.Core.BusinessLogic.BusinessEntity abstract inherits DataService implements IBusinessEntity : 
 //   define public property Public         as logical   no-undo get. protected set.
    define public property Resource       as character no-undo get. protected set.
    
 //   define public property ReadOnly       as logical       no-undo get.  
 //   define public property CanCreate      as logical       no-undo get.
 //   define public property CanDelete      as logical       no-undo get.
    define public property Datasets       as handle extent no-undo get. protected set.
    
    define protected property DefaultDataset as handle no-undo 
        get():
            if extent(Datasets) <> ? then
                return Datasets[1].
            return ?.    
        end. 
        protected set.
    
    define public property Public   as logical init true no-undo 
        get. 
        protected set(plPublic as logical):
            AssertConstructorProperty().
            Public = plPublic.
        end.
        
    define public property ReadOnly  as logical   no-undo init ?   
        get().  
            if ReadOnly = ? then 
            do: 
                if valid-handle(DefaultDataset)  
                and DatasetUtil:GetNumTopBuffers(DefaultDataset) = 1 then
                    ReadOnly = not valid-handle(DefaultDataset:get-top-buffer(1):table-handle:before-table).
                else     
                    ReadOnly = true.
            end.    
            return ReadOnly.
        end get.    
        protected set(plReadOnly as logical):
            AssertConstructorProperty().
            ReadOnly = plReadOnly.
        end.
    
    define public property CanDelete as logical   no-undo init ? 
        get().
            if CanDelete = ? then
                CanDelete = not ReadOnly.
            return CanDelete.    
        end get.    
        protected set(plCanDelete as logical):
            AssertConstructorProperty().
            CanDelete = plCanDelete.
        end.
    
    define public property CanCreate as logical   no-undo init ? 
        get().
            if CanCreate = ? then
                CanCreate = not ReadOnly.
            return CanCreate.    
        end get.    
        protected set(plCreate as logical):
            AssertConstructorProperty().
            CanCreate = plCreate.
        end.
        
    define public property CanUpdate as logical   no-undo init ? 
        get().
            if CanUpdate = ? then
               return not ReadOnly.
            return CanUpdate.    
        end get.    
        protected set(plCanUpdate as logical):
            AssertConstructorProperty().
            CanUpdate = plCanUpdate.
        end.    
    
    // set to false for classes that only supports public update - (quite uncommon)
    define public property CanRead as logical   no-undo init ? 
        get().
            if CanRead = ? then
               return true.
            return CanRead.    
        end get.    
        protected set(plCanRead as logical):
            AssertConstructorProperty().
            CanRead = plCanRead.
        end.    
    
    define public property ClientOnly     as logical        no-undo get. protected set.
    
    define protected property Initialized as logical no-undo get. set. 
    
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
    
    method protected void BeforeReceiveData(phDataset  as handle):
    end method.
    
    method protected final void ReceiveData(pRequest as IGetDataRequest, pResponse as IGetDataResponse, phDataset as handle):
        define variable hBuffer as handle no-undo.
        define variable cTable  as character no-undo.
        define variable Htable  as handle no-undo.
         
        // allow override for BE with no data and buffer - for example PublicNameBe
                           
        BeforeReceiveData(phDataset).
        
        if valid-handle(phdataset) then
        do:
            // the temp-table serialize-name may be an alias so use the table-handle to identify this from the resource
            hBuffer = DatasetUtil:GetBufferBySerializeName(phDataset, Resource).
            if valid-handle(hBuffer) then
            do:
                hTable = hBuffer:table-handle.
                cTable = hTable:name.
                ReceiveBuffer(pRequest:GetTableRequest(cTable),pResponse:GetTableResponse(cTable), hBuffer).
            end.
        end.
    end method.    
    
    method protected void ReceiveBuffer( pRequest as IGetDataTableRequest,pResponse as IGetDataTableResponse, phBuffer as handle):
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
       phDataset = defaultDataset. 
    end method.    
    
    method public void GetData():    
        define variable hDataset as handle no-undo.
        hdataset = DefaultDataset.
        GetData(output dataset-handle hdataset by-reference).
    end method.    
    
    method public IGetDataResponse GetData(  output dataset-handle phDataset ):
        define variable oRequest as Pmfo.Core.BusinessLogic.IGetDataRequest no-undo.
        define variable oResponse as Pmfo.Core.BusinessLogic.IGetDataResponse no-undo. 
         
        define variable oTableRequests as Pmfo.Core.BusinessLogic.IGetDataTableRequest extent no-undo.
        define variable i as integer no-undo.
        
        if not valid-handle(phDataset) then
        do:
            phdataset = DefaultDataset.
        end.    
        extent(oTableRequests) = phDataset:num-buffers.
        do i = 1 to phDataset:num-buffers:
            oTableRequests[i] = new GetDataTableRequest(phDataset:get-buffer-handle(i):table-handle:name).
        end.
            
        oRequest = new GetDataRequest(oTableRequests).
        this-object:Clear().
        oResponse = GetData(oRequest, output dataset-handle phDataset by-reference).
     
     //   if phdataset = DefaultDataset then
      //      AllDataIsFetched = true.
        return oResponse.
    end method. 
    
        
    method public IGetDataResponse GetData( input pRequest as IGetDataRequest,output dataset-handle phDataset ).
        define variable oGetResponse         as IGetDataResponse no-undo.
        AssertInitialized().    
        
        if ClientOnly = true then 
            oGetResponse = CreateDataResponse(pRequest). 
        else
            oGetResponse = DataAccess:FetchData(pRequest, input-output dataset-handle phdataset).
        
        ReceiveData(pRequest, oGetResponse, phDataset).
           
        return oGetResponse.
         
    end method.
    
    
    method public IGetDataResponse CreateDataResponse(poRequest as IGetDataRequest):
        define variable iTable as integer no-undo.
        define variable oTableResponses as IGetDataTableResponse extent no-undo.
        
        extent(oTableResponses) = extent(poRequest:TableRequests).
        do iTable = 1 to extent(poRequest:TableRequests):
            oTableResponses[iTable] = new GetDataTableResponse(poRequest:TableRequests[iTable]:TableName).
        end.    
        return new GetDataResponse(oTableResponses).
    end method.  
    
        
    method public final Object GetData( input poRequest as IGetDataRequest, input dataset-handle phDataset ):
        undo, throw new NotImplementedError().  
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
        define variable oResponse as Object no-undo.
        define variable oUpdateResponse as IUpdateDataResponse no-undo.
        define variable hWarning   as handle no-undo.
        
        define variable lError as logical no-undo.
        define variable oReceiveError as Error no-undo.
        define variable oError as Error no-undo.
        
        Assert:NotNull(phdataset,"Dataset passed to UpdateData").
        Assert:NotNull(poUpdateDataRequest,"UpdateDataRequest passed to UpdateData").
        
        do on error undo, throw :
            
            // standard crud call before uopdate (actions are handled in ValidateAction to ensure they are called also from other BEs
            do on error undo, throw: 
            //   BeforeUpdateDataset( poUpdateDataRequest, phDataset).
                if phDataset:error then
                    lError = true.
                catch eval as ValidationError:
                    if phDataset:error then 
                        lError = true.
                    // rethrow or rethrow as Qquestion if question       
                    else 
                        undo, throw eVal.  
.       
                end catch.                  
            end.
        
            if not phDataset:error then
            do: 
                oResponse = SubmitData(poUpdateDataRequest, input-output dataset-handle phDataset by-reference).
                // Need research on how to manage dataset error to the by-reference 
                // from the return from DataAccess input-output deep copy ) - bug?
                // This is a workaround in the DataAccess  
                if valid-object(oResponse) and type-of(oResponse,String) then
                do:
                    if cast(oResponse,String):Value = "error" then
                    do:
                        phDataset:error = true.
                        lError = true.
                    end.   
                end.
                  
            end.
            else 
                lError = true.
            catch e as Progress.Lang.Error :
                oError = e.
                lError = true.     
            end catch.
        end.       
        do on error undo, throw:
            RefreshData(poUpdateDataRequest,phDataset,lError).
            catch e2 as Progress.Lang.Error :
                oReceiveError = e2.
            end catch.
        end. 
       
        if valid-object(oError) then
            undo, throw oError.
        
        if phDataset:error then  
            ThrowDatasetError(phDataset).
         
        return oResponse.        
        
    end method.    
    
    method public Object SubmitData(input poUpdateDataRequest as IUpdateDataRequest, input-output dataset-handle phDataset):
         
        // Use of BufferError outside managed hooks may end here if not managed  
        // (this is considered part of the framework, as it allows BufferError to be used also outside of 
        // the validate hooks
       if phDataset:error then
           ThrowDatasetError(phDataset).
        
        
       return DataAccess:SubmitData(poUpdateDataRequest, input-output dataset-handle phDataset).        
        
       
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
        return RequestDatasetHandle.
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
        
            pUpdateRequest = new UpdateDataRequest(hMainBuffer:name). 
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
    
    method public void ThrowDatasetError( phDataset as handle): 
        define variable oJson as JsonObject no-undo.
        define variable oErrorProcessor as JsonDatasetErrorProcessor no-undo.
        define variable oError as Error no-undo.
        define variable iRelation as integer no-undo.
        
        oJson = new JsonObject().
        do iRelation = 1 to phDataset:num-relations:
            // ensure keys are in json so they can be added to error 
            // as of current the dataset is not returne for errors 
            // we may return datasets for 409 in futrure , but the assumption is that it causes no isses since it will always be correct 
            // TODO  use parent relation  
            phDataset:get-relation (iRelation):foreign-key-hidden = false.
        end.       
        phDataset:write-json ("JsonObject",oJson,no,?,no,yes, yes).
        oErrorProcessor = new JsonDatasetErrorProcessor().
            
        if DatasetUtil:HasBeforeState(phDataset,row-deleted) then 
            oError = oErrorProcessor:CreateDeleteError (ojson, phdataset).
        else 
            oError = oErrorProcessor:CreateError (ojson, phdataset).
        
        if valid-object(oError) then
        do:
            undo, throw oError .
        end.
        else do:
            // this should no longer happen since JsonDatasetErrorProcessor now should manage all cases that ended up here before  
            oError = new ApplicationError("Update of data failed, but no error information was returned to the client. Please Contact IT.").
            undo, throw oError. 
        end.     
        
    end method.    
    
    method protected final void RefreshData(poUpdateRequest as IUpdateDataRequest, phDataset as handle, plUpdateError as logical):
        define variable oGetRequest as Pmfo.Core.BusinessLogic.IGetDataRequest no-undo.
        oGetRequest = CreateGetRequestForRefresh(poUpdateRequest,phDataset).
        // this is called also after an error, but if an error occurs here it will only cause a warning 
        // the lError passed in is just for information to the event  
        // we use ReceiveDataEventArgs constructor that has parameter for the update 
        ReceiveData(oGetRequest, 
                    new GetDataResponse(),
                    phDataset).
    end method. 
    
    method protected IGetDataRequest CreateGetRequestForRefresh(poUpdateRequest as IUpdateDataRequest,phDataset as handle):
        define variable i as integer no-undo.
        define variable oGetTableRequests as Pmfo.Core.BusinessLogic.IGetDataTableRequest no-undo extent.
        extent(oGetTableRequests) = phDataset:num-buffers. 
        do i = 1 to phDataset:num-buffers:
            oGetTableRequests[i] = new GetDataTableRequest(phDataset:get-buffer-handle(i):table-handle:name).
        end.    
        return new GetDataRequest(oGetTableRequests).
    end method.    
    
    method protected void AssertInitialized():
        if not Initialized then 
            undo, throw new IllegalStateError(substitute("Resource '&1' Class &2 is not initialized. Cannot execute data operation. Make sure Initialize override calls super",Resource,this-object:GetClass():TypeName)). 
    end method.    
end class.