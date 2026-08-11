 
 /*------------------------------------------------------------------------
    File        : BusinessEntityOperationHandler
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Thu Mar 21 09:10:09 EDT 2019
    Notes       : 
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using Ccs.Common.Application from propath.
using OpenEdge.Core.Collections.ICollection from propath.
using OpenEdge.Core.Collections.IIterator from propath.
using OpenEdge.Core.Collections.IStringStringMap from propath.
using OpenEdge.Core.String from propath.
using OpenEdge.Logging.ISupportLogging from propath.
using OpenEdge.Net.HTTP.HttpHeader from propath.
using OpenEdge.Net.HTTP.HttpHeaderBuilder from propath.
using OpenEdge.Net.HTTP.IHttpResponse from propath.
using OpenEdge.Net.HTTP.StatusCodeEnum from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IEntity from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableResponse from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.BusinessLogic.Parser.TableFieldValueParser from propath.
using Pmfo.Core.BusinessLogic.RequestBuilder.QueryRequestBuilder from propath.
using Pmfo.Core.BusinessLogic.RowStateEnum from propath.
using Pmfo.Core.Error.BadRequestError from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.
using Pmfo.Core.Error.IllegalStateError from propath.
using Pmfo.Core.Error.MethodNotAllowedError from propath.
using Pmfo.Core.Error.NotFoundError from propath.
using Pmfo.Core.Error.TableNotFoundError from propath.
using Pmfo.Core.Error.UnprocessableEntityError from propath.
using Pmfo.Core.Error.UnsupportedOperationError from propath.
using Pmfo.Core.Manager.IServiceManager from propath.
using Pmfo.Core.Service.ClientGetRequest from propath.
using Pmfo.Core.Service.ClientUpdateRequest from propath.
using Pmfo.Core.Service.IBusinessEntityOperationHandler from propath.
using Pmfo.Core.Service.IClientGetRequest from propath.
using Pmfo.Core.Service.IClientRequest from propath.
using Pmfo.Core.Service.IClientUpdateRequest from propath.
using Pmfo.Core.Service.OperationHandler from propath.
using Pmfo.Util.BufferUtil from propath.
using Pmfo.Util.DatasetUtil from propath.
using Pmfo.Util.ErrorStringUtil from propath.
using Pmfo.Util.JsonUtil from propath.
using Progress.Json.ObjectModel.JsonArray from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Progress.Lang.Error from propath.
using Progress.Lang.Object from propath.
 
 
class Pmfo.Core.Service.BusinessEntityOperationHandler inherits OperationHandler implements IBusinessEntityOperationHandler,ISupportLogging: 
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    define public property NextPageLinkTemplate   as character init "&1@nextPageLink" no-undo get. 
    define public property NextBatchLinkTemplate  as character init "&1@nextBatchLink" no-undo get. 
    define public property TotalCountTemplate     as character init "&1@count" no-undo get.
    define public property SuccessEntityName      as character init "@success" no-undo get.
  
     
    define protected property ServiceManager as IServiceManager no-undo 
        get():
           return cast(Application:ServiceManager,IServiceManager).
        end.
         
    constructor public BusinessEntityOperationHandler (  ):
        super ().        
    end constructor.
  
   /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    method protected JsonObject ExtractRequestedTable(pJsonObject as JsonObject,pcSerializeName as characte):
        define variable oJsonObject       as JsonObject no-undo.
        define variable oJsonArray        as JsonArray  no-undo.
        define variable oJsonSingleObject as JsonObject no-undo.
        
        oJsonObject = new JsonObject().
         
        oJsonArray = JsonUtil:GetArrayFromSingleParents(pJsonObject,pcSerializeName).
        
        if not valid-object(oJsonArray) then
        do:
            oJsonSingleObject = JsonUtil:GetObjectFromSingleParents(pJsonObject,pcSerializeName).
            if valid-object(oJsonSingleObject) then
            do:
                oJsonObject:Add(pcSerializeName,oJsonSingleObject). 
                return oJsonObject.
            end.
            else
                undo, throw new NotFoundError(subst("Collection '&1'",pcSerializeName)).
        end.    
         
        oJsonObject:Add(pcSerializeName,oJsonArray). 
        return oJsonObject.
        catch e1 as NotFoundError :
            undo, throw e1.    
        end catch.
        catch e2 as Progress.Lang.Error :
            undo, throw new NotFoundError(subst("Collection '&1'",pcSerializeName),e2).
        end catch. 
    end method.
    
    method protected JsonObject ExtractRequestedRow(pJsonObject as JsonObject,phBuffer as handle, plUpdate as logical, pTableRequests as IGetDataTableRequest extent, plNoError as logical):
        define variable oJsonObject    as JsonObject  no-undo.
        define variable oJsonRow       as JsonObject  no-undo.
        define variable iExtent        as integer     no-undo.
        
        phBuffer:find-unique().
        
        oJsonObject = new JsonObject().
        oJsonRow = JsonUtil:GetObjectFromSingleParents(pJsonObject,phBuffer:serialize-name).
        oJsonObject:Add(phBuffer:serialize-name,cast(oJsonRow:Clone(),JsonObject)).
        return oJsonObject.
        catch e as Progress.Lang.Error :
            if e:GetMessageNum(1) = 138 then
            do:
                if plNoError then
                do:
                    oJsonObject = new JsonObject().
                    oJsonObject:AddNull(phBuffer:serialize-name).
                    return oJsonObject.
                end.
                do iExtent = 1 to extent(pTableRequests):
                     
                    if pTableRequests[iExtent]:TableName = phBuffer:table-handle:name then
                    do:    
                        undo, throw new TableNotFoundError(phBuffer, pTableRequests[iExtent], e).
                    end.
                end.
            end.
            // don't throw 404 for update
            if plUpdate = false  then
                undo, throw new NotFoundError(subst("Requested row for &1",phBuffer:serialize-name),e).
            else // this is not an expected error after update , but may happen for example if the dataset buffer serialize-names
                 // are lost/wrong      
                undo, throw e.
        end catch. 
    end method.
        
    // subclass hook 
    method protected void AddBusinessEntityProperties(pJson as JsonObject, pBusinessEntity as IBusinessEntity, pClientRequest  as ICLientRequest ):
    end.   
     
    method protected RowStateEnum GetMethodRowStateEnum (pcMethod as char, plAction as logical):
        if plAction then
        do:
            // allow PUT since we mistakenly used that on somne requests
            // but it will be made into create ny JsonReader 
            if pcMethod = "POST" or pcMethod = "PUT" then
                return RowStateEnum:Action.
            undo, throw new IllegalArgumentError(subst("Method '&1' and Action true",pcMethod)).    
        end.
        case pcMethod:
            when "GET"    then return RowStateEnum:None.
            when "PUT"    then return RowStateEnum:Modified.
            when "POST"   then return RowStateEnum:Created.
            when "DELETE" then return RowStateEnum:Deleted.
            otherwise 
                undo, throw new IllegalArgumentError(subst("Method '&1'",pcMethod)).
        end.
    end method.
    
    method public override JsonObject ExecuteUpdate
                                  (pcMethod as character,
                                   pMessageBody as Object,
                                   pcBaseAppTransportServiceURI as character,
                                   pcServiceURI as character,
                                   pURIQuery as IStringStringMap,
                                   pEntity as IEntity):
        
        define variable oClientUpdateRequest  as IClientUpdateRequest no-undo.
        define variable jsonRequest           as JsonObject no-undo.
        define variable jsonDatasetRequest    as JsonObject no-undo.
 
        define variable hDataset              as handle no-undo.
        define variable oUpdateDataRequest    as IUpdateDataRequest no-undo. 
        define variable jsonResponse          as JsonObject no-undo.
        define variable jsonWrapperResponse   as JsonObject no-undo.
        
        define variable oGetDataRequest       as IGetDataRequest no-undo. 
        define variable hRequestedBuffer      as handle no-undo.
        define variable lBeforeImage          as logical no-undo.
        define variable lBeforeImageRequired  as logical no-undo.
 
      //  define variable cActionFields         as character no-undo.
        define variable oBusinessEntity        as IbusinessEntity no-undo.
        define variable oResponse              as Object  no-undo.
        define variable lReturnDataAfterDelete as logical no-undo.
      
        if type-of(pEntity,IBusinessEntity) then 
             oBusinessEntity = cast(pEntity,IBusinessEntity).
        else     
            undo, throw new UnsupportedOperationError(subst("Entity of Type &1",pEntity:GetClass():TypeName)).
            
        if oBusinessEntity:ReadOnly then
            undo, throw new MethodNotAllowedError(pcMethod).
        
        if valid-object(pMessageBody) and type-of(pMessageBody,JsonObject) = false then
            undo, throw new UnsupportedOperationError(subst("Body of Type &1",pMessageBody:GetClass():TypeName)).
        
              
        case pcMethod:
            when "PUT" then do:
                if oBusinessEntity:ReadOnly then
                    undo, throw new MethodNotAllowedError(pcMethod).
            end.
            when "POST" then do:
                // test after building the requests
            end.    
            when "DELETE" then do:
                //  
                // if not oBusinessEntity:CanDelete then
                
                  //  undo, throw new MethodNotAllowedError(pcMethod).
                //    
            end.
            otherwise 
                undo, throw new IllegalArgumentError(subst("Method parameter '&1'",pcMethod)).
        end case.
        
        jsonRequest  = cast(pMessageBody,JsonObject).
        lBeforeImage = JsonUtil:HasBeforeImage(jsonRequest).
               
        oClientUpdateRequest = CreateClientUpdateRequest(oBusinessEntity,pcMethod,pcServiceURI,pURIQuery,cast(pMessageBody,JsonObject)).
        hDataset             = oBusinessEntity:GetUpdateRequestDataset(oClientUpdateRequest,output lBeforeImageRequired, output  oUpdateDataRequest ).
 
        if oUpdateDataRequest:MainRequestedBuffer = "" or oUpdateDataRequest:MainRequestedBuffer = ?  then 
            undo, throw new IllegalStateError("Main Requested Buffer not defined in update request").
        
         
        hRequestedBuffer = hdataset:get-buffer-handle (oUpdateDataRequest:MainRequestedBuffer).
                                                                                                   
            // this is an internal error not a notfounderror
        if not valid-handle(hRequestedBuffer) then
           undo, throw new IllegalStateError(subst("Requested buffer '&1' not found in dataset",oUpdateDataRequest:MainRequestedBuffer)).   
        
       
        // do this after we have the oUpdateDataRequest
        case pcMethod:
            when "POST" then do:
                
                if oBusinessEntity:CanCreate = false  then
                    undo, throw new MethodNotAllowedError(pcMethod).
            end.
            when "DELETE" then do:
                // this is only for top level 
                if extent(oClientUpdateRequest:Collections) = 1 then
                do: 
                    
                    if not oBusinessEntity:CanDelete then
                        undo, throw new MethodNotAllowedError(pcMethod).
                end.  
            end.
        end case.
        
        jsonDatasetRequest = JsonUtil:WrapRequestForDataset(jsonRequest, hDataset, hRequestedBuffer:name).
                   
        if lBeforeImage = false then 
        do: 
            if lBeforeImageRequired then 
                undo, throw new UnprocessableEntityError(subst("The entity body must have before image data to execute a '&1' request for '&2'",
                                                               pcMethod,
                                                               oBusinessEntity:Resource
                                                               )
                                                         ).      
         
         
            case pcMethod:
                when "POST" then
                    DatasetUtil:SetTrackingChanges(hDataset,true).
                when "PUT" then 
                    undo, throw new UnsupportedOperationError(substitute ("&1 &2 without before-image",
                                                                         pcMethod,
                                                                         hRequestedBuffer:serialize-name
                                                                         )
                                                              ).
            end case.
        end.
        
        do on error undo, throw:
            hDataset:read-json ("JsonObject",jsonDatasetRequest,"append"). // empty, but if there is data replace is correct
            catch e as Progress.Lang.Error :
                HandleLoadError(e, pcMethod, hDataset, jsonDatasetRequest).
            end.    
         end.  
        
        if lBeforeImage = false then 
        do: 
            case pcMethod:
                when "POST" then
                    DatasetUtil:SetTrackingChanges(hDataset,false).
                when "DELETE" then 
                    DeleteDataAndTrack(hdataset).
            end case.
        end.
 
        oResponse = oBusinessEntity:UpdateData(input-output dataset-handle hDataset by-reference,oUpdateDataRequest).
        
        // anticipate set of main requested buffer for multi table reqest that may have changed the relations to one top 
        if valid-handle(hRequestedBuffer) = false and oUpdateDataRequest:MainRequestedBuffer > "" then  
             hRequestedBuffer = hdataset:get-buffer-handle (oUpdateDataRequest:MainRequestedBuffer).
             
        jsonResponse = new JsonObject().
        hDataset:write-json ("JsonObject",jsonResponse,no,?,no,yes).
        if pcMethod = "DELETE" then 
        do:
            // support respone with refreshed data after delete - added for recursive cases where 
            // the delete may be posted for a record further down the tree and parents may be updated an not deleted 
             
            if hDataset:get-buffer-handle(1):table-handle:has-records then
            do: 
                // TODO - clean up
                // The else stuff below is aquick fix to keep behavior for recursive 
                // but avoid for delete of requested child where the parent is not returned in the json 
                if valid-handle(hRequestedbuffer) = false then 
                    lReturnDataAfterDelete = true.
                else if hDataset:get-buffer-handle(1) = hRequestedbuffer then  
                    lReturnDataAfterDelete = true.
                else if valid-handle(DatasetUtil:GetRecursiveRelation(hRequestedBuffer)) then
                    lReturnDataAfterDelete = true.
                    
            end.   
        end.
        
        // create response unless this is a delete or delete returns data 
        // (delete returns data  = for example delete from recursive tree may return refreshed tree)    
        if pcMethod = "DELETE" and lReturnDataAfterDelete = false then
            return ?.  // flag to caller to return http 204 no content  
        
        
        jsonWrapperResponse = new JsonObject().   
        jsonWrapperResponse:Add(ResponseNodeName, jsonResponse).
        return jsonWrapperResponse.
       
    end method.
    
    
    method protected void HandleLoadError(pError as Error, pcMethod as char, phDataset as handle, pJson as JsonObject):
        if pError:GetMessageNum(1) = 132 then 
        do:
            undo, throw new BadRequestError(BufferUtil:GetAlreadyExistsMessage(phDataset, pError),pError).
        end.
        else    
            undo, throw pError.
    end method.    
   
    /*------------------------------------------------------------------------------
     Purpose: Mark all records as deleted. 
     Notes: mark-row-state does not remove after-buffer. (last tested 11.7)
    ------------------------------------------------------------------------------*/

    method public void DeleteDataAndTrack( phdataset as handle ):
        define variable i       as integer no-undo.
        define variable hQuery  as handle no-undo.
        define variable hBuffer as handle no-undo.
        define variable hBufferDel as handle no-undo.
        define variable hTable  as handle no-undo.
        define variable rRowid as rowid no-undo.
                  phdataset:write-json ("file","/MemoryWorkshop-test/Temp/befdelete.json",yes,?,no,yes,yes).    
        
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
            phdataset:write-json ("file","/MemoryWorkshop-test/Temp/delete.json",yes,?,no,yes,yes).    
        end.            
     
    end method.
 
    /* public for unit test - not in interface
        handle  GET or HEAD request 
       The head request returns after url and query has been processed and validated                               
    */                                          
    method public override JsonObject ExecuteRead
                                          (pcMethod as character,
                                           pcBaseAppTransportServiceURI as character,
                                           pcServiceURI as character,
                                           pURIQuery as IStringStringMap,
                                           pEntity as IEntity):
        define variable jsonResponse                   as JsonObject                no-undo.
        define variable oClientGetRequest              as IClientGetRequest         no-undo.
        define variable oGetDataTableResponse          as IGetDataTableResponse     no-undo.
        define variable hDataset                       as handle                    no-undo.
        define variable oQueryRequestBuilder           as QueryRequestBuilder       no-undo.
        define variable oGetDataResponse               as IGetDataResponse          no-undo.
        define variable oGetDataRequest                as IGetDataRequest           no-undo.
        define variable hRequestedBuffer               as handle                    no-undo.
        define variable oBusinessEntity                as IBusinessEntity           no-undo.
        define variable cInternalServiceURI            as character                 no-undo.
        define variable oJson                          as JsonObject                no-undo.     
        
        if type-of(pEntity,IBusinessEntity) then 
             oBusinessEntity = cast(pEntity,IBusinessEntity).
        else     
            undo, throw new IllegalArgumentError(subst("Entity of Type &1",pEntity:GetClass():TypeName)).
        
        oClientGetRequest = CreateClientGetRequest(pcMethod,pcServiceURI,pURIQuery).
        hDataset = oBusinessEntity:GetRequestDataset(oClientGetRequest).  
        oGetDataRequest  = CreateQueryRequestBuilder():BuildGetDataRequest(oClientGetRequest,hDataset).
        
        case pcMethod:
            // bad urls and query properties will have thrown errors so just return if HEAD 
            when "HEAD" then
                return ?.
            when "GET" then 
            do:
              // if oBusinessEntity:CanRead = false then
            end.
            otherwise    
                undo, throw new IllegalArgumentError(subst("Method '&1'",pcMethod)).
        end case.

        oGetDataResponse = oBusinessEntity:GetData(oGetDataRequest,output dataset-handle hDataset by-reference).
        jsonResponse = new JsonObject().
        hDataset:write-json("JsonObject",jsonResponse,yes,?,no,yes).  
        // reset frim response - requeste may change this 
        hRequestedBuffer = ?. 
        
        // wrap in respose node
        if valid-object(oGetDataResponse) then 
        do:      
            oJson = jsonResponse.
            jsonResponse = new JsonObject().   
            jsonResponse:Add(ResponseNodeName, oJson).
        end.
         
        return jsonResponse.
             
    end method.    
   
    method protected void ProcessBeforeImageErrors(pjson as JsonObject, phDataset as handle) :
        define variable oJson          as JsonObject        no-undo.
        define variable oJsonErrors    as JsonArray         no-undo.
        define variable cNames         as character  extent no-undo.
        define variable iEntity        as integer           no-undo.
        define variable iError         as integer           no-undo.
        define variable cMessages      as character  extent no-undo.
        define variable cErrorString   as character         no-undo.
        define variable oJsonObject    as JsonObject        no-undo.
        define variable cTypes         as character  extent no-undo.
        define variable iIds           as integer    extent no-undo.
        define variable cFields        as character  extent no-undo.
        define variable oErrorMessages as JsonArray no-undo.
        define variable iMsg           as integer no-undo.
        if pJson:has("prods:errors") then
        do:
            JsonUtil:MergeDuplicateErrorNodes(pJson, phdataset).
            oJson =  pJson:GetJsonObject("prods:errors").
            
            extent(cnames) = ?.
            cNames = ojson:GetNames().
            do iEntity = 1 to extent(cNames): 
                oJsonErrors = oJson:GetJsonArray(cNames[iEntity]).
                do iError = 1 to oJsonErrors:length:
                    oJsonObject    = oJsonErrors:GetJsonObject(iError).
                    cErrorString   = oJsonObject:GetCharacter("prods:error").
                    extent(cMessages) = ?.
                    extent(cTypes) = ?.
                    extent(iIds) = ?.
                    extent(cFields) = ?.
                    cMessages      = ErrorStringUtil:GetErrors(cErrorString, output cTypes, output iIds,  output cFields).
                    oErrorMessages = new JsonArray().
                    oJsonObject:Remove("prods:error").
                    oJsonObject:Add("errors",oErrorMessages).
                    do iMsg = 1 to extent(cMessages):
                        ojson = new JsonObject().
                        oJson:Add("errorType",cTypes[iMsg]).
                        oJson:Add("errorMsg",cMessages[iMsg]).
                        oErrorMessages:Add(oJson).
                    end.
                end.    
            end.  
           
        end.   
    end method.    
    
    /* Turn off foreign key hidden and use the hide later option to avoid
       problems in jsonGetResponseProcessor when building id and linkid 
       for public child with hidden foreignkeys. (there may be cleaner ways to 
       do this, but they all seem to requiring find of buffers to get values )
       @return  - extent of relations with unhidden foreign keys. 
                  The extent size is num-buffers and may have ? entries, 
    */
    method protected handle extent UnhideForeignKeys (phDataset as handle, pRequestedbuffer as character , input-output pcHideLater as character):
        define variable i          as integer no-undo.
        define variable hRelations as handle  extent no-undo.        
        define variable hBuffer    as handle  no-undo.
        define variable iField     as integer no-undo.
        define variable cField     as character no-undo.
        define variable hField     as handle    no-undo.
      
        extent(hRelations) = phDataset:num-buffers.
        do i = 1 to phDataset:num-buffers:
            hBuffer = phDataset:get-buffer-handle(i).
            if valid-handle(hBuffer:parent-relation) and hBuffer:parent-relation:active and hBuffer:parent-relation:foreign-key-hidden then
            do: 
                hRelations[i] = hBuffer:parent-relation.
                // if the parent and child has the same name then skip this 
                // (it is assumed to be an XREf relation so it would be wrong and 
                // it also cuases error in  JsonGetResponseProcessor 
                if hRelations[i]:parent-buffer:serialize-name <>  hRelations[i]:child-buffer:serialize-name then
                do:
                    do iField = 2 to num-entries(hRelations[i]:relation-fields) by 2:
                        cField = entry(iField,hRelations[i]:relation-fields).
                        hField = hBuffer:buffer-field(cField).
                        if not hField:serialize-hidden then
                        do:
                            cField = hField:serialize-name.
                            if hBuffer:name <> pRequestedBuffer then
                                cField = hBuffer:serialize-name + "." + cField.
                            if lookup(cField,pcHideLater) = 0 then
                            do: 
                                pcHideLater = pcHideLater
                                            + (if pcHideLater = "" then "" else ",")
                                            + cField.
                            end.
                        end.
                    end.    
                    hRelations[i]:foreign-key-hidden = false.
                end.
                else do:
                    // if there is an xref relation get rid of the fields added to the parent in a previous iteration 
                    do iField = 1 to num-entries(pcHideLater):
                        if entry(iField,pcHideLater) begins subst("&1.",hRelations[i]:parent-buffer:serialize-name) then
                        do:
                            entry(iField,pcHideLater) = "".
                            pcHideLater = trim(replace(pcHideLater,",,",","),",").
                        end.         
                    end.     
                end.    
            end.
        end.    
        return hRelations.
    end method.
    
    method protected void HideForeignKeysAgain(phRelations as handle extent):
        define variable i as integer no-undo.    
        do i = 1 to extent(phRelations):
            if valid-handle(phRelations[i]) then 
               phRelations[i]:foreign-key-hidden = true.
        end.    
    end method.

    // allow subclass override
    method protected QueryRequestBuilder CreateQueryRequestBuilder():
        return new QueryRequestBuilder().
    end method.
       
    method protected void CreateRowForKeyExpression(phRequestedBuffer as handle, pcFieldExpression as character):
        define variable oTableFieldValueParser as TableFieldValueParser no-undo.
        oTableFieldValueParser = new TableFieldValueParser(). 
        oTableFieldValueParser:CreateRow(phRequestedBuffer, pcFieldExpression).
    end.
     
    // allow subclass override
    method protected IClientGetRequest CreateClientGetRequest(pcMethod as character, pcServiceUri as character, pUriQuery as IStringStringMap):
        return new ClientGetRequest(pcMethod, pcServiceUri,pUriQuery).
    end.    
     
    // allow subclass override
    method protected IClientUpdateRequest CreateClientUpdateRequest(pBusinessEntity as IBusinessEntity, pcMethod as character, pcServiceUri as character, pUriQuery as IStringStringMap, pJsonRequest as JsonObject):
        return new ClientUpdateRequest(pcMethod, pcServiceUri,pUriQuery, false).
    end.
    
    method protected override character MethodsAllowedList(pObject as Object):
        define variable cAllowed as character no-undo.
        define variable cDlm     as character no-undo.
        define variable oEntity  as IEntity no-undo.
        cAllowed = "OPTIONS".
        cDlm = ", ".
        cAllowed = cAllowed + cDlm + "HEAD".
        cAllowed = cAllowed + cDlm + "GET".
        if type-of(pObject,IEntity) then
        do:
            oEntity = cast(pObject,IEntity).
            if not oEntity:ReadOnly then
            do:
                cAllowed  = cAllowed + cDlm + "PUT".
                if oEntity:CanCreate then
                    cAllowed  = cAllowed + cDlm + "POST".
                if oEntity:CanDelete then
                    cAllowed  = cAllowed + cDlm + "DELETE".     
            end.   
        end.
        return cAllowed.  
    end method.
    
    method protected character BuildUrlQuery (pQueryMap as IStringStringMap,pProps as char extent):
        define variable cQueryString as character no-undo.
        define variable cDelimiter   as character no-undo.
        define variable i            as integer no-undo.
        define variable cValue       as character no-undo.
        if pQueryMap:Size gt 0 then
        do:
            cDelimiter = ?.
            do i = 1 to extent(pProps):
                cValue = pQueryMap:Get(pProps[i]).
                if cValue <> ? then 
                do:
                    cQueryString = cQueryString + substitute('&1&2=&3':u, cDelimiter,pProps[i],cValue).
                    cDelimiter   = '&'
                    .
                end.    
            end.
            
        end.
        return cQueryString.
    end.      
    
    method protected character BuildUrlQuery (pQueryMap as IStringStringMap):
        define variable cList        as character no-undo.
        define variable oKeyValues   as ICollection no-undo.
        define variable oIterator    as IIterator no-undo.
        define variable cKey         as character no-undo.
        define variable cValue       as character no-undo.
        define variable cDelimiter   as character no-undo.
        define variable cQueryString as character no-undo.
        
        oKeyValues = pQueryMap:KeySet.
        oIterator  = oKeyValues:Iterator().
        
        do while oIterator:HasNext():
            cKey =  cast(oIterator:Next(), String):Value.
            cValue = pQueryMap:Get(cKey).
            if cValue <> ? then 
            do:
                cQueryString = cQueryString + substitute('&1&2=&3', cDelimiter,cKey,cValue).
                cDelimiter   = '&'
               .
            end. 
        end.
        return cQueryString.
    end.
          
         
    method protected override integer WriteAllowedHeader(pObject as Object, poResponse as IHttpResponse, pStatusCodeEnum as StatusCodeEnum):
        define variable oHeader as HttpHeader no-undo.
        oHeader = HttpHeaderBuilder:Build('Allow':u):Value(MethodsAllowedList(pObject)):Header.
        poResponse:SetHeader(oHeader).
        return ReturnStatusNoBody(poResponse,pStatusCodeEnum).
    end method. 
  
end class.