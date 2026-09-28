 
 /*------------------------------------------------------------------------
    File        : BusinessEntity
    Purpose     : Abstract class for business logic for a table - exposed as resource   
    Author(s)   : hdaniels
    Notes       : This is a stripped down demo version. 
                - Application implement concrete subclasses for each entity/table
                  that is exposed by application. The table is implemented as a 
                  temp-table witha corresponding dataset. The table is typically 
                  mapped to a database table, but can be a virtual temp-table filled
                  from any type of source exposed by IDataAcess 
                  The dataset should default to have this table as the only top 
                  table. The dataset defaults to have the same serialize-name as 
                  the top table.   
                - There is support to have more than one dataset and every dataset 
                  can have more than one table, but customization will be needed 
                  to manage these. For more complex datasrt suypport there would 
                  likely be more constructors    
                - This can be the basis for a better version of a full framwork 
                  but if would be further stripped down firs and then important 
                  features from the full framwork culd be addded
                  - public methods in the form of Actions or Functions 
                    This is an odata concept. It is a basic underlying requirement 
                    that is poorly handled in the shipped business entity, but    
                    that is addressed in CCS.  
                     - INamedQuery can be used to implement functions
                     - IUpdataDataRequest:CustomRequest can be used to implement 
                       a function 
                    Warning: 
                      The two CCS concepts have more similiraties than the 
                      is iplemented and these concepts would likely be deprecated
                      even if some of the behavior makes sense.
                      - The INamedParameter that is used by NamedQuery is  
                        useful, but is should also be also for actions.     
  ----------------------------------------------------------------------*/

 
block-level on error undo, throw.

using Ccs.BusinessLogic.CommitScopeEnum from propath.
using Ccs.Common.Application from propath.
using OpenEdge.Core.Assert from propath.
using OpenEdge.Core.String from propath.
using Pmfo.Core.BusinessLogic.GetDataRequest from propath.
using Pmfo.Core.BusinessLogic.GetDataResponse from propath.
using Pmfo.Core.BusinessLogic.GetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.GetDataTableResponse from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableResponse from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataResponse from propath.
using Pmfo.Core.BusinessLogic.UpdateDataRequest from propath.
using Pmfo.Core.Common.DataService from propath.
using Pmfo.Core.Common.IWarningMessageTableHolder from propath.
using Pmfo.Core.Common.IWarningMessages from propath.
using Pmfo.Core.DataLayer.IDataAccess from propath.
using Pmfo.Core.Error.ApplicationError from propath.
using Pmfo.Core.Error.BadRequestError from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.
using Pmfo.Core.Error.IllegalOperationError from propath.
using Pmfo.Core.Error.IllegalStateError from propath.
using Pmfo.Core.Error.NotImplementedError from propath.
using Pmfo.Core.Error.UnsupportedOperationError from propath.
using Pmfo.Core.Error.ValidationError from propath.
using Pmfo.Core.Manager.IServiceManager from propath.
using Pmfo.Core.Manager.ISessionManager from propath.
using Pmfo.Core.Service.IClientRequest from propath.
using Pmfo.Core.Service.JsonDatasetErrorProcessor from propath.
using Pmfo.Util.BufferUtil from propath.
using Pmfo.Util.DatasetUtil from propath.
using Pmfo.Util.ErrorStringUtil from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Progress.Lang.Error from propath.
using Progress.Lang.Object from propath.

class Pmfo.Core.BusinessLogic.BusinessEntity abstract inherits DataService implements IBusinessEntity : 
    define public property Resource as character no-undo get. protected set.
    
    define public property Datasets as handle extent no-undo get. protected set.
    
    define protected property SessionManager as ISessionManager no-undo 
       get():
            return cast(Application:SessionManager,ISessionManager).
       end.
  
   define protected property ServiceManager as IServiceManager no-undo 
       get():
            return cast(Application:ServiceManager,IServiceManager).
       end.
  
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
    
    define public property WarningMessages as IWarningMessages no-undo 
        get. 
        set(pWarningMessages as IWarningMessages):
           if valid-object(WarningMessages) and WarningMessages:HasData then 
               undo, throw new IllegalOperationError("Cannot set WarningMessages when the existing WarningMessages has data").
           WarningMessages = pWarningMessages.         
        end. 
    
    define protected property WarningMessageTableHandle as handle no-undo 
        get().
            if not valid-handle(WarningMessageTableHandle) then 
               if type-of(WarningMessages,IWarningMessageTableHolder) then 
                    WarningMessageTableHandle = cast(WarningMessages,IWarningMessageTableHolder):tableHandle.
            return WarningMessageTableHandle.  
        end. 
        set.
    
    
    define protected property Initialized as logical no-undo get. set. 
    
    // avoid memory leak by keeping only one requested dynamic dataset (set in GetRequestDataset or GetUpdateRequestDataset) 
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
    
    method protected void ValidateData(poUpdateDataRequest as IUpdateDataRequest, input dataset-handle phDataset):
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
    
    method public IGetDataResponse GetData( output dataset-handle phDataset ):
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
        if not valid-handle(phDataset) then
        do:
            phdataset = DefaultDataset.
        end.    
        
        if ClientOnly = true then 
            oGetResponse = CreateDataResponse(pRequest). 
        else  
            oGetResponse = FetchData(pRequest, input-output dataset-handle phdataset by-reference).
      
        ReceiveData(pRequest, oGetResponse, phDataset).
        if valid-object(oGetResponse) then 
            oGetResponse:SetRequestProperties(pRequest).   
        
        return oGetResponse.
         
    end method.
    
    // for requests for just the table - does not support by-reference
    method public logical GetData( input pQueryEntry as IQueryEntry, output table-handle phTable): 
        define variable oTableRequest as Pmfo.Core.BusinessLogic.IGetDataTableRequest no-undo.
        define variable oRequest as Pmfo.Core.BusinessLogic.IGetDataRequest  no-undo.
        oTableRequest = new GetDataTableRequest(Datasets[1]:get-buffer-handle(1):table-handle:name).
        oTableRequest:AddQueryEntry(pQueryEntry).
        oRequest = new GetDataRequest(oTableRequest).
        return GetData(oTableRequest, output table-handle phTable by-reference).
        
    end method.
    
    
    // for requests for just the table - does not support by-reference
    method public logical GetData( input pTableRequest as IGetDataTableRequest, output table-handle phTable):
        define variable oRequest as IGetDataRequest  no-undo.
        if valid-handle(phTable) then 
            // The BE is dataset oriented - Use one of the GetData with Dataset output  if by-reference is needed  
            undo, throw new UnsupportedOperationError("GetData with IGetTableRequest parameter and valid handle in output table by-reference parameter. Use one of the GetData methods with Dataset output if by-reference is needed.").  
        if pTableRequest:TableName <> Datasets[1]:get-buffer-handle(1):table-handle:name then 
            undo, throw new IllegalArgumentError(subst("TableRequest for table '&1' passed to Business Entity for table '&2'",pTableRequest:TableName,Datasets[1]:get-buffer-handle(1):table-handle:name)).
        oRequest = new GetDataRequest(pTableRequest).
        
        this-object:Clear(). // clear for request for table 
        GetData(oRequest). 
        phTable = Datasets[1]:get-buffer-handle(1):table-handle.
        return phTable:has-records.     
    end method.
    
    
    method public logical GetData( input poRequest as IGetDataRequest):
        define variable hDataset as handle no-undo.
        hdataset = DefaultDataset.
        GetData(poRequest,output dataset-handle hdataset by-reference).
      
        return hDataset:get-buffer-handle(poRequest:TableRequests[1]:tablename):table-handle:has-records.
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
       // AssertInitialized().    
        undo, throw new NotImplementedError().
    end method.    
    
    method public Object UpdateData( input-output dataset-handle phDataset):
        return UpdateData(input-output dataset-handle phDataset by-reference,CreateUpdateDataRequest(phDataset)).
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
                ValidateData( poUpdateDataRequest, input dataset-handle phDataset by-reference).
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
    
    method protected Object SubmitData(input poUpdateDataRequest as IUpdateDataRequest, input-output dataset-handle phDataset):
        define variable hWarning  as handle no-undo.
        define variable oResponse as Object no-undo. 
        // Use of BufferError outside managed hooks may end here if not managed  
        // (this is considered part of the framework, as it allows BufferError to be used also outside of 
        // the validate hooks
        if phDataset:error then
            ThrowDatasetError(phDataset).
        
        oResponse = DataAccess:SubmitData(poUpdateDataRequest, input-output dataset-handle phDataset, output table-handle WarningMessageTableHandle append).        
        
        return oResponse. 
    end method.
    
    method protected IGetDataResponse FetchData(input pRequest as IGetDataRequest, input-output dataset-handle phDataset):        
        return DataAccess:FetchData(pRequest, input-output dataset-handle phdataset).
    end method.
    
    method public void Clear().
        define variable i as integer no-undo.
        do i = 1 to extent(Datasets):
            Datasets[i]:empty-dataset ().
        end.   
    end method.    
    
    method public override void Initialize():
        Initialized = true. 
    end method.    
   
    method public override void Dispose(). // IService
        Destroy().
    end method.    
    
    method public override void Destroy().  
    end method.    
    
    // final to make sure we set RequestDatasetHandle - needed if a dynamic dataset is used
    method public final handle GetRequestDataset(pClientRequest as IClientRequest):
        RequestDatasetHandle = PrepareRequestDataset(pClientRequest).
        return RequestDatasetHandle.
    end method.
    
    // separated from GetRequestDataset to allow override of dataset for the request  
    method protected handle PrepareRequestDataset(pClientRequest as IClientRequest):
        return Datasets[1].
    end method.
    
    // final to make sure we set RequestDatasetHandle 
    method public final handle GetUpdateRequestDataset(pClientRequest as IClientRequest,output plBeforeImageRequired as logical, output pUpdateRequest as IUpdateDataRequest).
        RequestDatasetHandle = PrepareUpdateRequestDataset(pClientRequest, output plBeforeImageRequired, output pUpdateRequest).
        return RequestDatasetHandle.
    end method.    
    
    // separated from GetUpdateRequestdataset to allow override of dataset for the request  
    method protected handle PrepareUpdateRequestDataset(pClientRequest as IClientRequest,output plBeforeImageRequired as logical, output pUpdateRequest as IUpdateDataRequest).
        define variable hDataset     as handle no-undo.
        define variable hMainBuffer  as handle no-undo.
       
        plBeforeImageRequired = (pClientRequest:Method = "PUT").
        
        hDataset = PrepareRequestDataset(pClientRequest). 
        
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
   
   method public character GetTextField():
       define variable hFld as handle no-undo.
       hFld = GetTextFieldHandle().
       if valid-handle(hFld) then  
            return hFld:name.
       return "".          
  
   end method.
  
   method public character GetPublicTextField():
       define variable hFld as handle no-undo.
       hFld = GetTextFieldHandle().
       if valid-handle(hFld) then  
            return hFld:serialize-name.
       return "".          
    end.     
     
    method protected handle GetTextFieldHandle():
        define variable hBuffer as handle no-undo.
        define variable hFld    as handle no-undo.
        define variable i       as integer no-undo.
        define variable cname as character no-undo.
        if extent(Datasets) <> ? and DatasetUtil:GetNumTopBuffers(Datasets[1]) = 1 then 
        do:
            hBuffer = Datasets[1]:get-buffer-handle(1).      
            hFld = hBuffer:buffer-field("name") no-error.
            
            if valid-handle(hFld) then
                return hFld.
            
            hFld = hBuffer:buffer-field("description") no-error.
            if valid-handle(hFld) then
                return hFld.
            
            hFld = hBuffer:buffer-field("descr") no-error.
            if valid-handle(hFld) then
                return hFld.
            
            cName = substitute("&1&2",hBuffer:name,"name").
            
            hFld = hBuffer:buffer-field(cName) no-error.
            if valid-handle(hFld) then
                return hFld.
            
            cName = substitute("&1&2",substr(hBuffer:name,3),"name").
            if valid-handle(hFld) then
                return hFld.
            
                
            do i = 1 to hBuffer:num-fields:
                hFld = hBuffer:buffer-field(i).
                if hFld:serialize-name = "description" or hFld:serialize-name = "name" then
                    return hFld. 
            end.
        end.       
           
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
        return CreateGetRequest(phDataset).
    end method.    
    
    method protected IGetDataRequest CreateGetRequest(phDataset as handle):
        define variable i as integer no-undo.
        define variable oGetTableRequests as IGetDataTableRequest no-undo extent.
        extent(oGetTableRequests) = phDataset:num-buffers. 
        do i = 1 to phDataset:num-buffers:
            oGetTableRequests[i] = new GetDataTableRequest(phDataset:get-buffer-handle(i):table-handle:name).
        end.    
        return new GetDataRequest(oGetTableRequests).
    end method.    
    
    method public character GetJoinPairs(pParentBE as IBusinessEntity).
        define variable i as integer no-undo.
        define variable cParentFields as character no-undo.
        define variable cChildFields as character no-undo.
        define variable cJoinPairs    as character no-undo.
        
        cParentFields = pParentBE:GetKeys().
        cChildFields = GetJoinFields(pParentBE).
        
        do i = 1 to num-entries(cParentFields):
            cJoinPairs = left-trim(substitute ("&1,&2,&3",cJoinPairs,entry(i,cParentFields),entry(i,cChildFields)),",").
        end.     
        return cJoinPairs.   
    end method.    
    
    method protected character GetJoinFields(pParentBE as IBusinessEntity).
        //default to same named join
        define variable cKeys          as character no-undo.
        define variable i              as integer  no-undo.
        define variable hTrueTopBuffer as handle   no-undo.
        define variable hField         as handle   no-undo.
        cKeys = pParentBE:GetKeys().
        // ignores dactivated child buffers (that are moved to top)
        if DatasetUtil:GetNumTopBuffers(DefaultDataset) = 1 then 
        do:
             hTrueTopBuffer = DatasetUtil:GetTopBuffer(DefaultDataset, 1). 
             do i = 1 to num-entries(cKeys):
                 hField = hTruetopBuffer:buffer-field(entry(i,cKeys)) no-error. 
                 if not valid-handle(hField) then 
                     undo, throw new UnsupportedOperationError(
                         substitute("Join from &1 to &2 using field &3. Add a GetJoinFields override to &4 if the relation should use a different field name.",
                                    pParentBe:Resource,Resource,entry(i,cKeys),this-object:GetCLass():TypeName
                         )
                     ). 
             end.     
        end.
        return cKeys.
    end method.    
    
    
    method protected void AssertInitialized():
        if not Initialized then 
            undo, throw new IllegalStateError(substitute("Resource '&1' Class &2 is not initialized. Cannot execute data operation. Make sure Initialize override calls super",Resource,this-object:GetClass():TypeName)). 
    end method.  
    
     method protected void BufferError(phBuffer as handle,pcMsg as character):
        // the ErrorStringUtil only works  with changed records that has error attributes
        // TODO - add error object and collection that can provide the same capabilities 
        // - cellect many errors and return table, key and field info   
        if phBuffer:row-state = 0 then 
            undo, throw new BadRequestError(pcMsg).
        if not valid-handle(phBuffer:dataset) then 
            undo, throw new BadRequestError(pcMsg).
               
        ErrorStringUtil:AddError(phBuffer, pcMsg).
    end method.    
    
    method protected void BufferError(phBuffer as handle,pcMsg as character, pcField as character):
        // the ErrorStringUtil only works  with changed records that has error attributes 
        if phBuffer:row-state = 0 then 
            undo, throw new BadRequestError(pcMsg).
        if not valid-handle(phBuffer:dataset) then 
            undo, throw new BadRequestError(pcMsg).
        ErrorStringUtil:AddError(phBuffer, pcMsg, pcField).
    end method.    
    
    method protected void ThrowBufferError(phBuffer as handle,pcMsg as character):
        // the ErrorStringUtil only works  with changed records that has error attributes 
        if phBuffer:row-state = 0 then 
            undo, throw new BadRequestError(pcMsg).
        if not valid-handle(phBuffer:dataset) then 
            undo, throw new BadRequestError(pcMsg).
        ErrorStringUtil:AddError(phBuffer, pcMsg).
        undo, throw new ValidationError().
    end method. 
    
    method protected void ThrowBufferError(phBuffer as handle,pcMsg as character, pcField as character):
        // the ErrorStringUtil only works  with changed records that has error attributes 
        if phBuffer:row-state = 0 then 
            undo, throw new BadRequestError(pcMsg).
        if not valid-handle(phBuffer:dataset) then 
            undo, throw new BadRequestError(pcMsg).
        ErrorStringUtil:AddError(phBuffer, pcMsg, pcField).
        undo, throw new ValidationError().
    end method.   
end class.