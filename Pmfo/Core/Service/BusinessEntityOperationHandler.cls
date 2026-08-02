 
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
using Ccs.Common.Support.IPrimitiveArrayHolder from propath.
using Ccs.Common.Support.IPrimitiveHolder from propath.
using OpenEdge.Core.Collections.Collection from propath.
using OpenEdge.Core.Collections.ICollection from propath.
using OpenEdge.Core.Collections.IIterator from propath.
using OpenEdge.Core.Collections.IMap from propath.
using OpenEdge.Core.Collections.ISet from propath.
using OpenEdge.Core.Collections.IStringStringMap from propath.
using OpenEdge.Core.Collections.StringStringMap from propath.
using OpenEdge.Core.String from propath.
using OpenEdge.Logging.ISupportLogging from propath.
using OpenEdge.Net.HTTP.HttpHeader from propath.
using OpenEdge.Net.HTTP.HttpHeaderBuilder from propath.
using OpenEdge.Net.HTTP.IHttpResponse from propath.
using OpenEdge.Net.HTTP.StatusCodeEnum from propath.
using OpenEdge.Net.URI from propath.
using OpenEdge.Web.DataObject.IOperationHandler from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IEntity from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.Error.ApplicationError from propath.
using Pmfo.Core.Error.BadRequestError from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.
using Pmfo.Core.Error.IllegalOperationError from propath.
using Pmfo.Core.Error.IllegalStateError from propath.
using Pmfo.Core.Error.MethodNotAllowedError from propath.
using Pmfo.Core.Error.NotFoundError from propath.
using Pmfo.Core.Error.NotImplementedError from propath.
using Pmfo.Core.Error.TableNotFoundError from propath.
using Pmfo.Core.Error.UnprocessableEntityError from propath.
using Pmfo.Core.Error.UnsupportedOperationError from propath.
using Pmfo.Core.Error.ValidationError from propath.
using Pmfo.Core.Manager.IServiceManager from propath.
using Pmfo.Core.Service.ClientGetRequest from propath.
using Pmfo.Core.Service.ClientUpdateRequest from propath.
using Pmfo.Core.Service.IClientGetRequest from propath.
using Pmfo.Core.Service.IClientRequest from propath.
using Pmfo.Core.Service.IClientUpdateRequest from propath.
using Pmfo.Core.Service.OperationHandler from propath.
using Pmfo.Util.BufferUtil from propath.
using Pmfo.Util.DatasetUtil from propath.
using Pmfo.Util.ErrorStringUtil from propath.
using Pmfo.Util.JsonUtil from propath.
using Pmfo.Util.PrimitiveHolderUtil from propath.
using Pmfo.Util.ServiceInfo from propath.
using Pmfo.Util.StringUtil from propath.
using Progress.Json.ObjectModel.JsonArray from propath.
using Progress.Json.ObjectModel.JsonConstruct from propath.
using Progress.Json.ObjectModel.JsonDataType from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Progress.Lang.Error from propath.
using Progress.Lang.Object from propath.
using Progress.Reflect.Method from propath.
using Pmfo.Util.Array from propath.
using OpenEdge.Core.Collections.IIterator from propath.
using Progress.Lang.FlagsEnum from propath.
using Progress.Lang.ParameterList from propath.
using Pmfo.Util.QueryUtil from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataResponse from propath.
using Pmfo.Core.Error.NotImplementedError from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.RowStateEnum from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableResponse from propath.
using Pmfo.Core.BusinessLogic.RequestBuilder.QueryRequestBuilder from propath.
using Pmfo.Core.BusinessLogic.Parser.TableFieldValueParser from propath.
 
 
class Pmfo.Core.Service.BusinessEntityOperationHandler inherits OperationHandler implements IOperationHandler,ISupportLogging: 
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
    
    // public for unit test - not in interface
    method public override JsonObject ExecutePostOrPutOrDelete
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
        define variable oGetDataRequest       as IGetDataRequest no-undo. 
        define variable oGetActionDataRequest as IGetDataRequest no-undo. 
        define variable hRequestedBuffer      as handle no-undo.
        define variable oError                as Error no-undo.
        define variable lBeforeImage          as logical no-undo.
        define variable lBeforeImageRequired  as logical no-undo.
 
        define variable oJsonRequest          as JsonConstruct no-undo.
        define variable oJsonParent           as JsonObject no-undo.
        define variable oJsonChildArray       as JsonArray  no-undo.
       
        define variable oUpdateBe             as IBusinessEntity no-undo.  
        define variable oEmptyTableRequests   as IGetDataTableRequest extent no-undo.
      //  define variable cActionFields         as character no-undo.
        define variable iField                as integer no-undo.
        define variable lNoData               as logical no-undo.
        define variable iJson                 as integer no-undo.
        define variable lActionWithoutBody    as logical no-undo.
        define variable lRowCreatedFromURL    as logical no-undo.
        define variable lUniqueAction         as logical no-undo.
        define variable oBusinessEntity       as IbusinessEntity no-undo.
        define variable iCollection           as integer no-undo.
        define variable lDeleteAndNoContent   as logical no-undo.
        define variable lActionHasParent            as logical no-undo.
        define variable oResponse              as Object  no-undo.
        define variable cBeforeImageNames      as character extent no-undo.
        define variable lUseJsonReaderOnPost   as logical no-undo.
        define variable lReturnDataAfterDelete as logical no-undo.
        define variable lRecursive             as logical no-undo.
      
        if type-of(pEntity,IBusinessEntity) then 
             oBusinessEntity = cast(pEntity,IBusinessEntity).
        else     
            undo, throw new IllegalArgumentError(subst("Entity of Type &1",pEntity:GetClass():TypeName)).
            
        if oBusinessEntity:ReadOnly then
            undo, throw new MethodNotAllowedError(pcMethod).
        
        if valid-object(pMessageBody) and type-of(pMessageBody,JsonObject) = false then
            pMessageBody = ?.
        
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
                 
        oClientUpdateRequest          = CreateClientUpdateRequest(oBusinessEntity,pcMethod,pcServiceURI,pURIQuery,cast(pMessageBody,JsonObject)).
        oBusinessEntity:getDataset(output dataset-handle hDataset). 
        
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
        
         
        // probably not necessary to check both conditions 
      //  if extent(oClientUpdateRequest:Collections) > 1 + (if valid-object(oUpdateDataRequest:CustomRequest) and type-of(oUpdateDataRequest:CustomRequest,IAction) then 1 else 0) 
      //  and oBusinessEntity:resource <> hRequestedBuffer:table-handle:serialize-name then
       //     oUpdateBe = ServiceManager:CreateBusinessEntity(hRequestedBuffer:table-handle:serialize-name).
      //  else
        oUpdateBe = oBusinessEntity.
        
        do: 
            // create, delete or modify with a key  provided for the requested entity
            if valid-handle(hRequestedBuffer)
            and oClientUpdateRequest:Keywheres[extent(oClientUpdateRequest:Keywheres)] > "" then
            do:
                // return true if created  (no messagebody) 
                lRowCreatedFromURL = AssignKeysFromUrl(pcMethod, oClientUpdateRequest, pMessageBody, hRequestedBuffer, false). // false = not action
            end.     
        end.
         
                 
         // NOT an action with no body 
       // else @TODO need error handling or management of metric support for actions woth no body 
        // if we have a BE for the requested table different than the requested resource use that from now on 
        
        oBusinessEntity = oUpdateBe.
        oResponse = oBusinessEntity:UpdateData(input-output dataset-handle hDataset by-reference,oUpdateDataRequest).
        
        // we have a bug  - some large dataset with more than one top buffer loses the serialize-name
/*        do i = 1 to hDataset:num-buffers:                                                                                           */
/*            hDataset:get-buffer-handle(i):buffer-release().                                                                         */
/*          //  hDataset:get-buffer-handle(i):table-handle:serialize-name = hDataset:get-buffer-handle(i):table-handle:serialize-name.*/
/*            hDataset:get-buffer-handle(i):serialize-name = hDataset:get-buffer-handle(i):serialize-name.                            */
/*        end.                                                                                                                        */
        
        
        
        // anticipate set of main requested buffer for multi table reqest that may have changed the relations to one top 
        if valid-handle(hRequestedBuffer) = false and oUpdateDataRequest:MainRequestedBuffer > "" then  
             hRequestedBuffer = hdataset:get-buffer-handle (oUpdateDataRequest:MainRequestedBuffer).
        jsonResponse = new JsonObject().
        
        if pcMethod = "DELETE" then 
        do:
            // support repsone with refreshed data after delete - added for recursive cases where 
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
        if pcMethod <> "DELETE" or lReturnDataAfterDelete then
        do:
           // check if the action should return no content or sucdess instead of data  
                 
             
        end. // not delete
        else // set flag to return ? - will be set false if sucess or warning messages are added  
            lDeleteAndNoContent = true.
           
        /***
           UpdateDataResponse:Messages, WarningMessages and successMessages have some differences that currently requires different approaches
           TODO - UpdateDataResponse:Messages is intended to unify and abstract this togeterh
           //  and also add info messages
        ***/   
                  /*
           Warningmessages Can be also be added on server and is currently returned from DA in a temp-table
                           It is also used both on GET and here    
                           The WarningMessages is thus a temp-table wrapper created at the start of a request
                           that knows the dataset of the request
                           The dataset is used to convert internal field names to serfializenames gfetting 
                           the dataset buffer form serializ-name
        */
         
        /**
           Successmessages is pure OO ands is currently (?) only managed in the BE 
           The SuccessMessage objects have constructors that requires public field keys and field names
           so there is no need to know the dataset 
           The class is thus lazyloaded and HasSuccessMessages is set when used
           It is deleted on start of update request toi make sure no statle data is present if 
           a BE UpdateData is called twice    
        */ 
       
        return jsonResponse.
    end method.
    
    method protected void HandleTableNotFoundForUniqueFunction(phRequestedbuffer as handle,plOneToOneParent as logical,pcKeyExpression as character):
        define variable hParent as handle no-undo.
        
        // if one to one parent then the keyexpression is for the parent
        if plOneToOneParent then 
        do:
             // if the parent is found then throw not found child of parent  
            hParent = phRequestedbuffer:parent-relation:parent-buffer.
            hParent:find-unique() no-error.
            if phRequestedbuffer:avail then
            do:
                undo, throw new NotFoundError(subst("The single &1 of the &2 where &3",
                                               BufferUtil:GetRowName(phRequestedBuffer,true),
                                               BufferUtil:GetRowName(hParent,true),
                                               cast(QueryUtil:GetKeyEntry(pcKeyExpression,hParent,true),IQueryEntry):ToString(hParent,true,true) 
                                               )
                                           ).       
                
            
            end.
            // otherwise throw error below about the parent
            else 
                phRequestedbuffer = hParent.     
        end.
        
        undo, throw new TableNotFoundError(
                         phRequestedBuffer,
                         QueryUtil:GetKeyEntry(
                             pcKeyExpression,
                             phRequestedBuffer, 
                             true // public names in expression
                         )        
                     ).
               
    end.
    
    method protected void HandleLoadError(pError as Error, pcMethod as char, phDataset as handle, pJson as JsonObject):
        if pError:GetMessageNum(1) = 132 then 
        do:
            undo, throw new BadRequestError(BufferUtil:GetAlreadyExistsMessage(phDataset, pError),pError).
        end.
        else    
            undo, throw pError.
    end method.    
    
     
    method protected Method GetFirstMethod(pObject as Object,pcname as char):                     
        define variable oMethods as Method extent no-undo.
        define variable i as integer no-undo.
        oMethods = pObject:GetClass():GetMethods(Progress.Reflect.Flags:Public or Progress.Reflect.Flags:Instance or Progress.Reflect.Flags:DeclaredOnly).
        do i = 1 to extent(oMethods): 
            if oMethods[i]:Name = pcname then 
                return oMethods[i].
        end.    
    end.
    
     
   
    method protected IBusinessEntity ResolveGetRequest(pClientGetRequest as IClientGetRequest,input pRequestedBe as IBusinessEntity, output pRequest as IGetDataRequest, output phDataset as handle).
        define variable cRedirect        as character no-undo.
        define variable cRedirects       as character extent no-undo.
        define variable i                as integer no-undo.
        define variable cFixedContainers as character no-undo.
        define variable cContainerRef    as character no-undo.
        define variable cRelativeRequest as character no-undo.
        define variable cParentContext   as character no-undo.
        define variable iResource        as integer no-undo.
         
        
        phDataset = pRequestedBe:GetRequestDataset(pClientGetRequest).  
        pRequest  = CreateQueryRequestBuilder():BuildGetDataRequest(pClientGetRequest,phDataset).
        return pRequestedBe.
    end method.  
    
    /* public for unit test - not in interface
        handle  GET or HEAD request 
       The head request returns after url and query has been processed and validated                               
    */                                          
    method public override JsonObject ExecuteGetOrHead
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
        define variable iTable                         as integer                   no-undo.
        define variable cNextId                        as character                 no-undo.
        define variable cQuery                         as character                 no-undo.
        define variable iTotalCount                    as int64                     no-undo.
        define variable cNextLinkName                  as character                 no-undo.
        define variable hRequestedBuffer               as handle                    no-undo.
        define variable oLinks                         as ICollection               no-undo.
        define variable lRecursive                     as logical                   no-undo.
 //       define variable oJsonWriter                    as IJsonWriter               no-undo.
        define variable oBusinessEntity                as IBusinessEntity           no-undo.
        define variable cInternalServiceURI            as character                 no-undo.
        define variable oJson                          as JsonObject                no-undo.     
        define variable cRedirect                      as character                 no-undo.
        define variable iSelect                        as integer                   no-undo.
        define variable lPrimitiveFunction             as logical                   no-undo.
        define variable IPrimitiveSingleEntityFunction as logical                   no-undo.
        define variable oPrimitiveResponse             as Object                    no-undo.
    //    define variable oParentRelation                as IRelationDefinition       no-undo.    
        define variable iCollectionWhere               as integer                   no-undo.
        define variable oFunction                      as character                 no-undo. 
        define variable lNoContentResponse             as logical                   no-undo.
   //     define variable oApplyRequestProcessor         as ApplyRequestProcessor no-undo.
        
        if type-of(pEntity,IBusinessEntity) then 
             oBusinessEntity = cast(pEntity,IBusinessEntity).
        else     
            undo, throw new IllegalArgumentError(subst("Entity of Type &1",pEntity:GetClass():TypeName)).
        
        oClientGetRequest = CreateClientGetRequest(pcMethod,pcServiceURI,pURIQuery).
 
        oBusinessEntity = ResolveGetRequest(oClientGetRequest, oBusinessEntity, output oGetDataRequest, output hDataset).
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
        
/*        if valid-object(oClientGetRequest:ServiceMethod)                                                                            */
/*        and type-of(oClientGetRequest:ServiceMethod,IFunction) then                                                                 */
/*        do:                                                                                                                         */
/*            lPrimitiveFunction = cast(oClientGetRequest:ServiceMethod,IFunction):isPrimitive.                                       */
/*            lNoContentResponse = oClientGetRequest:ServiceMethod:NoContentResponse.                                                 */
/*            if lPrimitiveFunction then                                                                                              */
/*                IPrimitiveSingleEntityFunction = cast(oClientGetRequest:ServiceMethod,IFunction):Binding = MethodBindingEnum:Entity.*/
/*            if oGetDataRequest:MainRequestedBuffer > "" then                                                                        */
/*            do:                                                                                                                     */
/*                hRequestedBuffer = hdataset:get-buffer-handle (oGetDataRequest:MainRequestedBuffer).                                */
/*                if oBusinessEntity:resource <> hRequestedBuffer:serialize-name then                                                 */
/*                do:                                                                                                                 */
/*                    if oBusinessEntity:HasLink then                                                                                 */
/*                    do:                                                                                                             */
/*                        oParentRelation = GetRelation(hRequestedBuffer:serialize-name,oBusinessEntity:Links).                       */
/*                    end.                                                                                                            */
/*                                                                                                                                    */
/*                    // if this is an child function then execute in the actual entity                                               */
/*                    oBusinessEntity = ServiceManager:CreateBusinessEntity(hRequestedBuffer:serialize-name).                         */
/*                end.                                                                                                                */
/*            end.                                                                                                                    */
/*        end.                                                                                                                        */
         
        if lPrimitiveFunction then 
        do on error undo, throw:   
          undo, throw new NotImplementedError("PrimitiveFunction").
        end.
        else do:
            oGetDataResponse = oBusinessEntity:GetData(oGetDataRequest,output dataset-handle hDataset by-reference).
            jsonResponse = new JsonObject().
            hDataset:write-json("JsonObject",jsonResponse,yes,?,no,yes).  
            // reset frim response - requeste may change this 
            hRequestedBuffer = ?. 
            
               // lNOcoenentResponse =  false
        end.  
        
        if lNoContentResponse then 
            return ?. 
        
        if lPrimitiveFunction then 
            return jsonResponse.
        
        if lNoContentResponse = false and valid-object(oGetDataResponse) then 
        do:      
            if JsonResponse:has("prods:errors") then 
            do: 
                 ProcessBeforeImageErrors(jsonResponse,hdataset).
            end.     
            
            JsonUtil:MergeDuplicateBeforeImageNodes(jsonResponse, hdataset).
             
            oJson = jsonResponse.
            jsonResponse = new JsonObject().   
            jsonResponse:Add(ResponseNodeName, oJson).
        end.
         
        return jsonResponse.
             
    end method.    
    
    // Temporary limitation - odata: 
    // The server filter for apply is supposed to be passed as an apply aggregation while the filter is supposed to 
    // reference data in the aggregatged result sop as for now we only allow filter on the groupby since that is 
    // valid both on server and in the result    
    method protected void AssertApplyAndFilter(pRequest as IGetDataRequest, pRequestedBuffer as handle, pcGroupBy as character):
        
    end method. 
    
    method protected void AddPrimitiveValueToJson(pName as character,
                                               pObject as Object,
                                               pJson as JsonObject):
                                                   
        if type-of(pObject,IPrimitiveHolder) then 
            PrimitiveHolderUtil:AddToJson(pName, cast(pObject,IPrimitiveHolder), pJson).
        else if type-of(pObject,IPrimitiveArrayHolder) then 
            PrimitiveHolderUtil:AddToJson(pName, cast(pObject,IPrimitiveArrayHolder), pJson).
        else 
           undo, throw new IllegalStateError(subst("Type &1 returned from call to a BE function defined as primitive",pObject:GetCLass():TypeName)).                                                   
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
    
    // replace request collection 1 and 2 with a direct reference  
    method protected IBusinessEntity RedirectRequest(pcRedirect as character,pClientRequest as IClientRequest):
        define variable oBe            as IBusinessEntity no-undo.
        oBe = this-object:ServiceManager:CreateBusinessEntity(pcRedirect).  
        pClientRequest:Redirect(pcRedirect). 
        return oBe.
    end method.        
    
    
    /**
    Create the json response from the dataset 
    - Extracts the requested table if the dataset has parent records that only is used to find the data
    - hides fields if selected fields specified
    - Calls the JsonGetResponseProcessor to decorate the json
    -- HATEOAS - adds links and keys
    --- metadataenum controls what to add 
    - Deals with repos tables - adds them at the top level 
    - converts array to object for one to one relation
    Parameters     
    **/
   
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
    
   // method protected FindRequestBuilder CreateFindRequestBuilder():
    //    return new FindRequestBuilder().
   // end method.
    
/*    // allow subclass override                                                   */
/*    method protected FindParentsRequestBuilder CreateFindParentsRequestBuilder():*/
/*        return new FindParentsRequestBuilder().                                  */
/*    end method.                                                                  */
/*                                                                                 */
    
    method protected logical AssignKeysFromUrl(pcMethod as character,pClientUpdateRequest as IClientUpdateRequest, pMessageBody as Object,phRequestedBuffer as handle, plAction as logical):
         define variable lRowCreatedFromURL as logical no-undo.
         if valid-object(pMessageBody) then 
              AssertJsonAndAddValues(cast(pMessageBody,JsonObject), phRequestedBuffer, pClientUpdateRequest:Keywheres[extent(pClientUpdateRequest:Keywheres) - if plAction then 1 else 0]). 
         else if pcMethod = "POST" then 
         do:
              CreateRowForKeyExpression(phRequestedBuffer, pClientUpdateRequest:Keywheres[extent(pClientUpdateRequest:Keywheres) - if plAction then 1 else 0]).
              lRowCreatedFromURL = true.
         end.    
         else // TODO consider support of DELETE with just keys (possibly by calling CreateRowForKeyExpression or a variation that sets delete\
              //  - this would probably require some option in the entity   
             undo, throw new UnsupportedOperationError(subst("&1 request with key in URL and no JSON Body",pcMethod)).
    end method.
    
    method protected void CreateRowForKeyExpression(phRequestedBuffer as handle, pcFieldExpression as character):
        define variable oTableFieldValueParser as TableFieldValueParser no-undo.
        oTableFieldValueParser = new TableFieldValueParser(). 
        oTableFieldValueParser:CreateRow(phRequestedBuffer, pcFieldExpression).
    end.
    
    method protected void AssertJsonAndAddValues(pJson as JsonObject,phRequestedBuffer as handle, pcFieldExpression as character):
        define variable oTableFieldValueParser as TableFieldValueParser no-undo.
        define variable cnames as character extent no-undo.
        define variable oRequestNode as JsonConstruct no-undo. 
        oRequestNode = JsonUtil:GetRequestNode(pjson, phRequestedBuffer, true). // true throw erro somewhat mute as it is already checked in JsonReader 
        if type-of(oRequestNode,JsonArray) then 
             undo, throw new UnprocessableEntityError(subst("Cannot submit '&1' as json array with URL '/&1(&2)' that has a key ",phRequestedBuffer:serialize-name,pcFieldExpression)).
        
        oTableFieldValueParser = new TableFieldValueParser(). 
        oTableFieldValueParser:AssertJsonAndAddValues(cast(oRequestNode,JsonObject), phRequestedBuffer, pcFieldExpression).
    end.
     
                      
 
      
    // allow subclass override
    method protected IClientGetRequest CreateClientGetRequest(pcMethod as character, pcServiceUri as character, pUriQuery as IStringStringMap):
        return new ClientGetRequest(pcMethod, pcServiceUri,pUriQuery).
    end.    
    
     
    // allow subclass override
    method protected IClientUpdateRequest CreateClientUpdateRequest(pBusinessEntity as IBusinessEntity, pcMethod as character, pcServiceUri as character, pUriQuery as IStringStringMap, pJsonRequest as JsonObject):
        return new ClientUpdateRequest(pcMethod, pcServiceUri,pUriQuery, false).
    end.
    
    /* check if the request is for a specific table in the dataset 
       returns true if a table is to be extracted from the dataset 
       throws error if any of the parents of the table that is to be extracted are not unique 
       public for test purposes. (ok since it is a utility of sorts)  
    */          
    method protected logical CheckTableRequestAndAssertUniqueParents(phDataset as handle,pClientRequest as IClientRequest,pTableRequests as IGetDataTableRequest extent, phRequestedBuffer as handle ):
        define variable iTable           as integer no-undo.
        define variable hBuffer          as handle  no-undo.
        define variable iCollection      as integer no-undo.
        define variable iCollectionTable as integer no-undo.
    
        if extent(pClientRequest:Collections) > 1 then
        do:
            do iTable = 1 to extent(pTableRequests)
            on error undo, throw.
               hBuffer = DatasetUtil:GetBufferByTableName(phDataset, pTableRequests[iTable]:TableName).
               if not valid-handle(hBuffer) then 
                   undo, throw new NotFoundError(subst("Table '&1' not found in dataset '&2'",pTableRequests[iTable]:TableName,phDataset:name)).
               
               // skip the collections that are not table references 
               if iTable = 1 then 
               do:
                  do iCollection = 1 to extent(pClientRequest:Collections):
                      if pClientRequest:Collections[iCollection] = hBuffer:serialize-name then 
                      do:
                         iCollectionTable = iCollection.
                         leave.
                      end.   
                  end.
                 
                  if iCollectionTable = 0 then
                  do:
                      return false.
                  end.    
               end.
               else 
                   iCollectionTable = iCollectionTable + 1.
               
               // we do not check uniqueness of the actual requested table - this is done later 
               if hBuffer = phRequestedBuffer then
               do: 
                   if iTable = 1 then 
                   do:
                        // if this is a specific requested table in a dataset with multiple buffers we may want to extract the table  
                       if phDataset:num-top-buffers > 1 then 
                       do:
                           // extract if there is no repos tables
                           if DatasetUtil:GetNumTopBuffers(phDataset) > 1 then 
                               return true.
                           // or the repos table is the requested table
                           else if valid-handle(hBuffer:parent-relation) then
                               return true.   
                       end.        
                       return false.     
                   end.
                   else 
                       return true.
               end.
               
               /* If there is no key for a prior(parent) table the request is likely wrong, but for this logic it works as long as it is unique
                  We could (in future allow just table in a URI if we know it is always unique in the context of its parent ()
               */    
             
               hBuffer:find-unique().
               
               catch e1 as NotFoundError :
                   undo, throw e1.
               end catch.
               catch e2 as Progress.Lang.Error :
                 
                   // may happen if static DatasetUUtil is out of synch 
                   if not valid-handle(hBuffer) then
                       undo, throw e2. 
                   // 3166 - more than one
                   // 138 - not on file 
                   if iCollectionTable > 0 and pClientRequest:KeyWheres[iCollectionTable] > "" then
                       //                                                                                    true = publicnames 
                       undo, throw new TableNotFoundError(hBuffer,pClientRequest:KeyWheres[iCollectionTable],true,e2).
                       
                   else do:
                       undo, throw new NotFoundError(subst("'&1'",hBuffer:serialize-name),e2).
                   end. 
               end catch.                                
               
            end.
        end.
        return false.
    end method.    
    
    // Assert that all requested tables are unique and return the last buffer for import of child data 
    method protected handle AssertUniqueRecords(phDataset as handle,pTableRequests as IGetDataTableRequest extent ):
        define variable iTable           as integer no-undo.
        define variable hBuffer          as handle  no-undo.
        define variable iCollection      as integer no-undo.
        define variable iCollectionTable as integer no-undo.
    
        do iTable = 1 to extent(pTableRequests)
        on error undo, throw.
            hBuffer = DatasetUtil:GetBufferByTableName(phDataset, pTableRequests[iTable]:TableName).
            if not valid-handle(hBuffer) then 
                undo, throw new NotFoundError(subst("Table '&1' not found in dataset '&2'",pTableRequests[iTable]:TableName,phDataset:name)).
               
               /* If there is no key for a prior(parent) table the request is likely wrong, but for this logic it works as long as it is unique
                  We could (in future allow just table in a URI if we know it is always unique in the context of its parent ()
               */    
            hBuffer:find-unique().
            
            catch e1 as NotFoundError :
                undo, throw e1.
            end catch.
            catch e2 as Progress.Lang.Error :
                 // may happen if static DatasetUUtil is out of synch 
                if not valid-handle(hBuffer) then
                    undo, throw e2. 
                   // 3166 - more than one
                   // 138 - not on file 
                if e2:GetMessageNum(1) = 138 or e2:GetMessageNum(1) = 3166 then
                do: 
                    undo, throw new TableNotFoundError(hBuffer, pTableRequests[iTable], e2).
                end.
                else 
                    undo, throw new NotFoundError(subst("'&1'",hBuffer:serialize-name),e2).
                   
            end catch.                                
             
        end.
        return hBuffer.
    end method.    
        
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