 
 /*------------------------------------------------------------------------
    File        : TestCustomer
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Mon Apr 15 11:46:50 EDT 2019
    Notes       : 
  ----------------------------------------------------------------------*/

 

block-level on error undo, throw.

using OpenEdge.Core.Collections.IStringStringMap from propath.
using OpenEdge.Core.Collections.StringStringMap from propath.
using Pmfo.Core.BusinessLogic.DatasetErrorProcessor from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.RequestBuilder.QueryRequestBuilder from propath.
using Pmfo.Core.Common.DataService from propath.
using Pmfo.Core.Manager.IServiceManager from propath.
using Pmfo.Core.Manager.ISessionManager from propath.
using Pmfo.Core.Service.BusinessEntityOperationHandler from propath.
using Pmfo.Core.Service.ClientGetRequest from propath.
using Pmfo.Core.Service.IBusinessEntityOperationHandler from propath.
using Pmfo.Core.Service.IClientGetRequest from propath.
using Pmfo.Tools.Test.ErrorHandler from propath.
using Progress.Json.ObjectModel.JsonArray from propath.
using Progress.Json.ObjectModel.JsonConstruct from propath.
using Progress.Json.ObjectModel.JsonDataType from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Progress.Lang.Error from propath.
using Pmfo.Util.JsonUtil from propath.
using Pmfo.Core.Error.ApplicationError from propath.
using Pmfo.Util.DatasetUtil from propath.
 

class Pmfo.Tools.Test.TestBase abstract inherits DataService:
    
     define protected property ErrorHandler as ErrorHandler  no-undo 
       get():
           if not valid-object(ErrorHandler) then 
               ErrorHandler = new ErrorHandler(). 
               
           return ErrorHandler.    
       end. 
       set.
       
    define protected property ShowErrors as logical no-undo 
        get().
           return ErrorHandler:Showerrors.
        end. 
        set(plShow as logical). 
            ErrorHandler:Showerrors = plShow.
        end.
        
    define protected property ShowErrorsInWindow as logical   no-undo 
       get().
           return ErrorHandler:ShowErrorsInWindow.
        end. 
        set(plShow as logical). 
            ErrorHandler:ShowErrorsInWindow = plShow.
        end.
            
    define protected property ErrorEntity as JsonConstruct no-undo get. set. 
                                                                                                                
    define protected property ServiceManager as  IServiceManager no-undo
        get():
            return cast(Ccs.Common.Application:ServiceManager,IServiceManager).
        end get.
        protected set.
    
    define protected property SessionManager as ISessionManager no-undo
        get():
            return cast(Ccs.Common.Application:SessionManager,ISessionManager).
        end get.
        protected set.
    
     
     define property OperationHandler as IBusinessEntityOperationHandler no-undo
        get():
            if not valid-object(OperationHandler) then
                OperationHandler = new BusinessEntityOperationHandler().
            return OperationHandler.    
        end.
        set.
    
    define property DatasetErrorHandler as DatasetErrorProcessor no-undo
        get():
            if not valid-object(DatasetErrorHandler) then
                DatasetErrorHandler = new DatasetErrorProcessor().
            return DatasetErrorHandler.    
        end.
        set.
    
    
    define protected property TempDir as character no-undo get():
            return session:temp-directory + "/temp/".
        end.
        set.
        
    method public void Setup(plant as integer):  
       // cast(Application:SessionManager,ISessionManager):Connection = "http://10.0.0.198:8080/web".
    end method.
     
    method public void Setup(  ):
        Init().
    end method.
    
    method public void Before(  ):
        Init().
    end method.
    
    method protected void Init(  ):
      //  SessionManager:IsDebug = true.
        
    end method.
     
    method override public void Destroy(  ):
         

    end method.
    
    method public IGetDataResponse GetDataset(pBusinessEntity as IBusinessEntity,pServiceUri as character,pUriQuery as IStringStringMap,output dataset-handle phDataset):
        define variable oClientGetRequest     as IClientGetRequest     no-undo.
     
        define variable oQueryRequestBuilder  as Pmfo.Core.BusinessLogic.RequestBuilder.QueryRequestBuilder   no-undo.
        define variable oGetDataRequest       as IGetDataRequest       no-undo.
      
        assign
            oClientGetRequest    = CreateClientGetRequest("GET",pServiceURI,pURIQuery) .
            phDataset             = pBusinessEntity:GetRequestDataset(oClientGetRequest).
            oQueryRequestBuilder = CreateQueryRequestBuilder().
            oGetDataRequest      = oQueryRequestBuilder:BuildGetDataRequest(oClientGetRequest,phDataset).
        // get the data 
        return pBusinessEntity:GetData(oGetDataRequest,output dataset-handle phDataset by-reference).
    end. 
    
    // convert a response to prodataset readable
    method protected JsonObject CreateJsonRenameResponse(pJson as jsonobject, pcname as character):
        define variable oJsonArray as JsonArray no-undo.
        define variable oJson  as JsonObject no-undo.
        define variable oNewJson as JsonObject  no-undo. 
        oNewjson = new JsonObject().
        if pJson:GetType("response") = JsonDataType:Array then
        do:
            oJsonArray = pJson:GetJsonArray("response").
        end.
        else
        do: 
            oJsonArray = new Jsonarray().
            oJson = pJson:GetJsonObject("response").
            
            oJsonArray:Add(oJson).
       
        end.      
        oNewJson:Add(pcname,oJsonArray).
       
        return onewJson.
        
    end method.  
    
  
    method protected void AssertDatasetUpdate(phDataset as handle):
        
        if phDataset:error then 
        do:
            DatasetErrorHandler:AssertDataset(phdataset).
        end.    
    end method.    
    
       // override to return a requestbuilder that creates Core.BusinessLogic.GetDataRequest that has Metric property
    method protected QueryRequestBuilder CreateQueryRequestBuilder():
       return new QueryRequestBuilder().
    end method.
    
    method protected IClientGetRequest CreateClientGetRequest( input pcMethod as character, input pcServiceUri as character, input pUriQuery as IStringStringMap ):
         return new ClientGetRequest(input pcMethod, input pcServiceUri, input pUriQuery).
    end method.
    
    method public IBusinessEntity GetBE(pcservice as character  ):  
        define variable oBe as IBusinessEntity no-undo.
        define variable oInnerError as Error no-undo.
    
        oBe = cast(ServiceManager:GetService(get-class(IBusinessEntity),pcService),IBusinessEntity). 
         
        return oBe.
        
    end method.
 
    method override public void Initialize(  ):

    end method.
     
    method public IStringStringMap  GetQuery(pcQueryNames as character extent,pcQueryValues as character extent):
        define variable qmap  as IStringStringMap no-undo.
        define variable i as integer no-undo.
        qmap = new StringStringMap().
        do i = 1 to extent(pcQueryNames):
            qmap:put(pcQueryNames[i],pcQueryValues[i]).
        end.
        return qmap.    
    end method.
    
    // can be added to catch to assist with debugging of errors
    method public void HandleError (pError as Error):
        ErrorEntity = ?.
        if ShowErrors then
        do:         
            ErrorHandler:Showerror(pError).  
        end.
       
        undo, throw pError.
    end method.
    
    method protected JsonObject LoadJson(pcFilename as character):
        define variable oJson as JsonObject no-undo. 
        file-info:file-name = pcfilename. 
        if file-info:full-pathname > "" then 
            oJson = JsonUtil:ReadJsonFile(file-info:full-pathname).
        if not valid-object(oJson) then 
        do: 
            undo, throw new ApplicationError(subst("Json file '&1' was not found",pcFilename)).
        end.   
        return oJson.
    end method.    
    
     method protected void DeleteDataAndTrack( phdataset as handle ):
        define variable i       as integer no-undo.
        define variable hQuery  as handle no-undo.
        define variable hBuffer as handle no-undo.
        define variable hBufferDel as handle no-undo.
        define variable hTable  as handle no-undo.
        define variable rRowid as rowid no-undo.
        
        DatasetUtil:SetTrackingChanges(phDataset,true).
        do i = 1 to phDataset:num-buffers.
            hBuffer = phDataset:get-buffer-handle(i).
            hTable = hBuffer:table-handle.
            create buffer hBufferDel for table hTable. 
            
            create query hQuery.
            hQuery:add-buffer(hBuffer).
            hQuery:query-prepare(substitute("preselect each &1",hBuffer:name)).
           
            hQuery:query-open.
            hQuery:get-first.
            do while hBuffer:avail:
                rRowid = hBuffer:rowid.
                hQuery:get-next.
                
                hBufferDel:find-by-rowid(rRowid).
                hBufferDel:buffer-delete().
            end.
            
            delete object hQuery.
            delete object hBufferDel.   
        end.
        finally:
            DatasetUtil:SetTrackingChanges(phDataset,false).
            if valid-handle(hQuery) then
                delete object hQuery.
            if valid-handle(hBufferDel) then
                delete object hBufferDel.   
        end.            
     
    end method.
 
    
    
    method protected logical IsJsonArraySortedByProperty ( input poArray as JsonArray, input pcProperty as character, input plAscending as logical ): 
        define variable i         as integer no-undo. 
        define variable cPrevious as character no-undo. 
        define variable cCurrent  as character no-undo. 
        define variable oObject   as JsonObject no-undo. 
        
        if poArray:Length <= 1 then 
            return true. 
            
        oObject = poArray:GetJsonObject(1). 
        if not valid-object(oObject) then 
            return false. 
        cPrevious = oObject:GetCharacter(pcProperty). 
        do i = 2 to poArray:Length: 
            oObject = poArray:GetJsonObject(i). 
            if not valid-object(oObject) then 
                return false. 
            cCurrent = oObject:GetCharacter(pcProperty). 
            if plAscending then do: 
                 if cCurrent < cPrevious then 
                     return false. 
            end. 
            else do: 
                if cCurrent > cPrevious then 
                    return false. 
            end. 
            cPrevious = cCurrent. 
        end. 
        return true. 
    end method. 
    
    
    method public void WriteMemory(pcfile as character  ):  
        define variable oBe as IBusinessEntity no-undo.
        define variable ojson as JsonObject no-undo.
        define variable oResponse as JsonObject no-undo. 
        define variable oMap as StringStringMap no-undo.
        oMap = new StringStringMap().
        oBe = GetBE("memoryObjects").
        oResponse = OperationHandler:ExecuteRead("GET",  "http://localhost/main/web/api", "/memoryObjects", oMap, oBe).
        oResponse:writefile(pcfile,yes).
        catch e as Progress.Lang.Error :
            handleError(e). 
        end catch.
          finally:
            delete object oBe.
        end.
    end method.
    
        
end class.