 
 /*------------------------------------------------------------------------
    File        : DataRequestBuilder
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Tue Apr 02 12:18:57 EDT 2019
    Notes       : 
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using OpenEdge.Core.Assert from propath.
using OpenEdge.Core.Collections.Collection from propath.
using OpenEdge.Core.Collections.ICollection from propath.
using OpenEdge.Core.Collections.IList from propath.
using Pmfo.Core.BusinessLogic.GetDataRequest from propath.
using Pmfo.Core.BusinessLogic.GetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.IQueryDefinition from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.
using Pmfo.Core.BusinessLogic.Parser.KeyValueParser from propath.
using Pmfo.Core.BusinessLogic.QueryDefinition from propath.
using Pmfo.Core.BusinessLogic.RequestTypeEnum from propath.
using Pmfo.Core.Error.BadRequestError from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.
using Pmfo.Core.Error.NotFoundError from propath.
using Pmfo.Core.Error.NotImplementedError from propath.
using Pmfo.Core.Error.UnsupportedOperationError from propath.
using Pmfo.Core.Service.IClientGetRequest from propath.
using Pmfo.Core.Service.IClientRequest from propath.
using Pmfo.Util.DatasetUtil from propath.
using Pmfo.Util.ServiceInfo from propath.
 
 
class Pmfo.Core.BusinessLogic.RequestBuilder.DataRequestBuilder abstract: 
    define protected property HasWarnings as logical no-undo get. set.
      
     
    define protected property MainRequestedBufferName    as character  no-undo get. set.
      
    constructor public DataRequestBuilder ( ):
        super ().
    end constructor.
    
   
    method public void AssertURIQuery(pClientRequest as IClientRequest, pRequestType  as RequestTypeEnum, input phhandle as handle):
        define variable hDataset as handle no-undo.
        if phHandle:type = "buffer" then
            hDataset = phhandle:dataset.
        else     
            hDataset = phhandle.
    end method.    
    
    method public void AssertAliases(pClientRequest as IClientRequest):
            
    end method.   
    
    method public IGetDataRequest BuildGetDataRequest(pClientRequest as IClientRequest, input phDataset as handle):
        define variable iCollection   as integer         no-undo.
        define variable oRequests     as ICollection     no-undo.
        define variable hBuffer       as handle          no-undo.
        define variable iBuffer       as integer         no-undo.
        define variable oRequestType  as RequestTypeEnum no-undo.
        define variable oRequest      as IGetDataRequest no-undo.
        define variable oTableRequest as IGetDataTableRequest no-undo.
        define variable lNoerror      as logical         no-undo.
        AssertDataset(pClientRequest, phDataset).
         
        MainRequestedBufferName = "".
     
        oRequests = new Collection().
       
        // the buffer must be in one of the top 3 collections
        collectionloop: 
        do iCollection = 1 to min(extent(pClientRequest:Collections),3):
            do iBuffer = 1 to phDataset:num-top-buffers:
                hBuffer = phDataset:get-top-buffer(iBuffer).
                if hBuffer:serialize-name = pClientRequest:Collections[iCollection] then    
                do:
                    AssertTopCollections(pClientRequest, iCollection).
                    oRequestType = ProcessTableRequests(oRequests,pClientRequest,hBuffer,iCollection).
                    leave collectionloop. 
                end.
            end.
            // reached last collection and no matches process the entire dataset 
            if iCollection = extent(pClientRequest:Collections) then
            do:
                ProcessDatasetRequest(oRequests,phDataset).
            end.
        end.
        
        if not valid-object(oRequestType) then 
        do:
            oRequestType = RequestTypeEnum:MultiTable.
            AssertURIQuery(pClientRequest, oRequestType, phDataset).  
        end.
                 
        if oRequests:Size > 0 then 
        do:
            oRequest = CreateGetDataRequest(pClientRequest,cast(oRequests:ToArray(),IGetDataTableRequest),oRequestType).
            if type-of(pClientRequest,IClientGetRequest) then
                oRequest:Timeout = cast(pClientRequest,IClientGetRequest):Timeout .
            
            if MainRequestedBufferName > "" then
            do:  
                oRequest:MainRequestedBuffer = MainRequestedBufferName.
                oTableRequest = cast(oRequest:GetTableRequest(phDataset:get-buffer-handle(MainRequestedBufferName)),IGetDataTableRequest).
            end.
            else do:
                undo, throw new NotImplementedError("Process without finnding MainRequestBuffer"). 
            end.     
            return oRequest.
        end.
        else 
            undo, throw new NotFoundError(pClientRequest:ServiceURI).       
         
    end method.
    
      // allow subclass override - pass clientrequest since that may be the reason for the override  
    method protected IGetDataRequest CreateGetDataRequest(pClientRequest as IClientRequest, pRequests as IGetDataTableRequest extent,pRequestType as RequestTypeEnum):
        return new GetDataRequest(pRequests). //,pRequestType).
    end method.
         
    // override by subclass if necessary
    method protected void ProcessDatasetRequest(input pRequests as ICollection, input phDataset as handle):
    end method. 
    
    // separated out for super class override 
    method protected logical IsRequestMainTable(pClientRequest as IClientRequest,piCollection as integer):
         return extent(pClientRequest:Collections) = 
         //  if valid-object(pClientRequest:ServiceMethod) then piCollection + 1 else
          piCollection.
    end method. 
    
    method protected RequestTypeEnum ProcessTableRequests(input pRequests as ICollection, pClientRequest as IClientRequest, input phBuffer as handle, piCollection as integer):
        define variable oTableRequest     as IGetDataTableRequest no-undo.
        define variable oRequestType      as RequestTypeEnum no-undo.
        
        oTableRequest = new GetDataTableRequest(phBuffer:table-handle:name).
        pRequests:Add(oTableRequest).
        
        // Check if the collection the main requested table
        // This is normally the last collection, but IsRequestMainTable is overridden in subclass to retuen the second to last collection for Find for update  
        if IsRequestMainTable(pClientRequest,piCollection)  then 
        do:           
            oRequestType = ProcessMainTable(pRequests,pClientRequest,phBuffer,piCollection,oTableRequest).
        end.
        else do: 
            if extent(pClientRequest:Collections) > piCollection then
            do: 
                undo, throw new UnsupportedOperationError(subst("Request with no key provided for parent resource '&1'",
                                                                pClientRequest:Collections[piCollection])).
            end.
            oRequestType = ProcessParentTable(pRequests,pClientRequest,phBuffer,piCollection,oTableRequest ).
        end. 
        return oRequestType.
    end method.
    
    method protected logical HasUniqueParentJoin( pClientRequest as IClientRequest, input phBuffer as handle): 
        return true.
    end method.       
 
    method protected RequestTypeEnum ProcessParentTable( input pRequests as ICollection, pClientRequest as IClientRequest, input phBuffer as handle, piCollection as integer, pTableRequest as IGetDataTableRequest):
        
        define variable i             as integer no-undo. 
        define variable lFound        as logical no-undo.
        define variable lError        as logical no-undo.
        define variable hRelation     as handle no-undo.
        define variable hDataset      as handle no-undo.
       
        define variable lUniquejoin   as logical no-undo.
        
        if extent(pClientRequest:Collections) = piCollection then 
            undo, throw new IllegalArgumentError("ProcessParentTable called for last collection").
         
        if pClientRequest:KeyWheres[piCollection] = "" then 
        do: 
            lUniqueJoin = HasUniqueParentJoin(pClientRequest,phBuffer).
            // we will throw the error after checking what type of child is requested below
            lError = not lUniqueJoin.
        end.  
        if not lError then
        do:
            if not lUniqueJoin then
            do:
               cast(pTableRequest,GetDataTableRequest):QueryDefinition = GetKeyDefinition(phBuffer,piCollection,pClientRequest). 
            end.
            pTableRequest:FindUnique = true. 
          
        end.
                
        do i = 1 to phBuffer:num-child-relations:
            hRelation = phBuffer:get-child-relation (i).
            if hRelation:recursive = false then
            do:
                 
                if hRelation:child-buffer:serialize-name = pClientRequest:Collections[piCollection + 1] then
                do:
                    if hRelation:reposition then 
                        undo, throw new BadRequestError(subst("Request for reposition collection '&1' from collection '&2 'is not supported",
                                                        pClientRequest:Collections[piCollection + 1],
                                                        pClientRequest:Collections[piCollection])).
                    else if lError then 
                        undo, throw new BadRequestError(subst("Missing key for collection '&1' to process child collection '&2'",
                                                        pClientRequest:Collections[piCollection],
                                                        pClientRequest:Collections[piCollection + 1])).                                                 
                   
                    lFound = true.
                    // as of current we only support method on top level so as fornow pass ? to method (may need to pass entire map to support)
                    return ProcessTableRequests(pRequests,pClientRequest,phBuffer:get-child-relation (i):child-buffer,piCollection + 1).
                   
                end.
            end.      
        end.        
        if not lFound then 
        do:
            hDataset = phBuffer:dataset.
            if valid-handle(DatasetUtil:GetBufferBySerializeName(hDataset, pClientRequest:Collections[piCollection + 1])) then
            do:
                undo, throw new BadRequestError(subst("Request for collection '&1' from collection '&2' is not valid",
                                                pClientRequest:Collections[piCollection + 1],
                                                pClientRequest:Collections[piCollection])).
               
            end.
            else 
               undo, throw new NotFoundError(subst("Collection '&1'",pClientRequest:Collections[piCollection + 1]),subst("'&1'",pClientRequest:Collections[piCollection])).
        end.
    end method.
     
    method protected RequestTypeEnum ProcessMainTable(pRequests        as ICollection, 
                                                      pClientRequest   as IClientRequest, 
                                                      phBuffer         as handle,
                                                      piCollection     as integer,
                                                      pTableRequest    as IGetDataTableRequest):
        define variable oRequestType     as RequestTypeEnum no-undo.
        define variable lSetNamedQuery as logical no-undo.
        define variable cUsedAliases as character no-undo.
        define variable lHasUniqueParent as logical no-undo.
        
        MainRequestedBufferName = phBuffer:name. 
        if pClientRequest:KeyWheres[piCollection] > "" then 
        do:
            assign
                cast(pTableRequest,GetDataTableRequest):QueryDefinition = GetKeyDefinition(phBuffer,piCollection,pClientRequest)
                pTableRequest:FindUnique      = true.
            
            // Don't assign if assigned from method:singleRow above
            if not valid-object(oRequestType) then     
                oRequestType = RequestTypeEnum:SingleRow.
        end.
        else // collection      
        do:
            // Don't assign if assigned from method:singleRow above
            if not valid-object(oRequestType) then
            do: 
                oRequestType = if lHasUniqueParent then RequestTypeEnum:SingleRow else RequestTypeEnum:SingleTopTable.
            end.     
        end.
        
        AssertURIQuery(pClientRequest, oRequestType, phBuffer).  
        
        if type-of(pClientRequest,IClientGetRequest) then 
            ProcessMainTableRequest(pRequests,cast(pClientRequest,IClientGetRequest),pTableRequest,phBuffer,piCollection,oRequestType).
        return oRequestType.
    end method.
    
    
    method protected  abstract void ProcessMainTableRequest(pRequests        as ICollection, 
                                                            pClientRequest   as IClientGetRequest,
                                                            pTableRequest as  IGetDataTableRequest, 
                                                            phBuffer         as handle,
                                                            piCollection     as integer,
                                                            poRequestType    as RequestTypeEnum).
    
    
    method protected final IQueryDefinition GetKeyDefinition(phBuffer as handle,piCollection as integer, pClientRequest as IClientRequest ):
         define variable cKeyExpression as character no-undo.
         cKeyExpression = pClientRequest:KeyWheres[piCollection].
         return new QueryDefinition(GetKeyEntry(true,phBuffer,cKeyExpression)).
    end method. 
    
    method protected final IQueryEntry GetKeyEntry(phBuffer as handle,pcKeyValue as char ).
        return GetKeyEntry(false,phBuffer,pcKeyValue ).
    end method.
    
    method private IQueryEntry GetKeyEntry(plCheckJoin as logical,phBuffer as handle,pcKeyValue as char ).
        define variable oKeyParser as KeyValueParser no-undo.
        oKeyParser = new KeyValueParser().
                                                         // true public name
        return oKeyParser:GetKeyEntry(pcKeyValue,phbuffer,true,plCheckJoin).
        
        catch e as Progress.Lang.Error :
            undo, throw new IllegalArgumentError(subst('Cannot create an expression from key value &1',pcKeyValue),e).   
        end catch.
    end method.
    
    method protected final void AssertTopCollections(pClientRequest as IClientRequest, piCollection as integer):
        define variable cErrorCollection as character no-undo.
        define variable cKeyMsgTmpl as character no-undo
                      init "Cannot specify key for &1 in request &2".
        
        if piCollection > 1 and pClientRequest:KeyWheres[1] > "" then
            cErrorCollection = subst("collection '&1'",pClientRequest:Collections[1]).        
                    
        if piCollection = 3 and pClientRequest:KeyWheres[2] > "" then
            cErrorCollection = cErrorCollection 
                             + (if cErrorCollection = "" then "" else " and ")
                             + subst("collection '&1'",pClientRequest:Collections[2]).        
        if cErrorCollection > "" then   
             undo, throw new BadRequestError(subst(cKeyMsgTmpl,cErrorCollection,pClientRequest:ServiceURI)).         
                    
    end method.
    
    method protected void AssertDataset(pClientRequest as IClientRequest, phDataset as handle):
       define variable cDatasetErrorTmpl as character no-undo
          init "Dataset with serialize-name '&1' does not match request '&2'".
      
        Assert:NotNull(phDataSet, "Dataset passed to BuildGetDataRequest").      
        if extent(pClientRequest:collections) = 1 then
        do:
            if phDataset:serialize-name <> pClientRequest:collections[1] then
               undo, throw new IllegalArgumentError(subst(cDatasetErrorTmpl,phDataset:serialize-name,pClientRequest:ServiceURI)). 
        end.
        else do:
            if  phDataset:serialize-name <> pClientRequest:collections[1] 
            and phDataset:serialize-name <> pClientRequest:collections[2] then
               undo, throw new IllegalArgumentError(subst(cDatasetErrorTmpl,phDataset:serialize-name,pClientRequest:ServiceURI)). 
        end.    
    end method.   

      
end class.