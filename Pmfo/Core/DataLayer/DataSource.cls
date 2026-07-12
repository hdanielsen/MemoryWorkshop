 
 /*------------------------------------------------------------------------
    File        : DataSource
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/

using Pmfo.Core.DataLayer.IDataSource.
using Pmfo.Core.DataLayer.IUpdateTarget.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using OpenEdge.Core.Collections.ICollection from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using OpenEdge.Core.Collections.IIterator from propath.
using Pmfo.Util.StringUtil from propath.
using Pmfo.Util.BufferUtil from propath.
using Pmfo.Core.DataLayer.DbQuery from propath.
using Pmfo.Core.Error.ApplicationError from propath.
using Pmfo.Core.Error.NotImplementedError from propath.
using Pmfo.Core.Error.UnsupportedOperationError from propath.
using Pmfo.Core.Error.IllegalStateError from propath.
using Progress.Lang.Error from propath.
using Pmfo.Core.BusinessLogic.QueryBuilder.QueryBuilder from propath.

block-level on error undo, throw.

class Pmfo.Core.DataLayer.DataSource inherits DbQuery implements IDataSource, IUpdateTarget abstract: 
    
    define protected property RestartRow       as int64  no-undo get. set.
    define protected property RestartIds       as rowid  extent no-undo get. set.     
    define protected property SeqFieldHandle   as handle no-undo get. set.
    
    // Don't create andprepare the query, but call BufferHandles with requests 
    // (See also inherited NoConnnectNeeded, which is to be used when buffers are to be defined later 
    define protected property NoQueryCreate as logical   no-undo get. set. 
    
    define protected property DataSourceHandle as handle no-undo get. set.               
     
    define protected property UpdateSource   as integer  no-undo 
        get():
            define variable i as integer no-undo.
            if UpdateSource = 0 then
            do:
                AssertBufferHandles("Get UpdateSource").
                do i = 1 to extent(BufferHandles):
                    if BufferHandle = BufferHandles[i] then
                    do:
                        UpdateSource = i.
                        leave.
                    end.    
                end.    
            end.
            return UpdateSource.
        end.     
        set.
   
    define public    property DataBuffer     as handle    no-undo 
        get. 
        set(pBuffer as handle):
            // static SeqFieldName  
            SeqFieldHandle = pBuffer:buffer-field(BufferUtil:SeqFieldName) no-error.
            DataBuffer = pBuffer.
        end. 
    
    define protected property FieldMap        as character init ? no-undo
        get():
            define variable cMap as character no-undo.
            AssertBufferHandles("Get FieldMap").
            cMap = GetFieldMap().
            return cMap.
        end. 
    
    
    define public property Count as logical no-undo 
    get.
    set. 

    define public property EntityName as character no-undo 
    get.
    

    define public property FillErrors as ICollection no-undo 
    get.
    set. 

    define public property NextRowKey as character no-undo 
    get.
    set. 

    define public property NumRecords as int64 no-undo 
    get.
    set. 

    define public property OptimisticLockExceptFields as character no-undo 
    get.
    set. 

    define public property Resource as character no-undo 
    get.
    set. 

    define public property TotalCount as int64 no-undo 
    get.
    set. 

   

    constructor public DataSource ( input phDbBuffer as handle ):
        super (input phDbBuffer).
    end constructor.
    
    // careful - for datasources that get data from non-db sources  
    constructor protected DataSource ( ):
        super ().
        message this-object
        view-as alert-box.
    end constructor.
    
    
     /* override to attach after row event and/or bind the buffer to static def */ 
    method protected void PrepareBuffer ( input pBuffer as handle):
        if valid-handle(SeqFieldHandle) then
            pBuffer:set-callback("After-Row-fill","AfterRow").
    end method. 
    
    /* override to attach after row event and/or bind the buffer to static def */ 
    method protected void PrepareSaveBuffer ( input pBuffer as handle):
    end method. 
    
    method protected void ThrowFillError(pcMsg as character):
        ThrowFillError(new ApplicationError(pcMsg)).
    end method. 
    
    method protected void ThrowFillError(pError as Error):
        // add to collection so that DataAccess:Fill can find it
        FillErrors:Add(pError).
        // throw so that Fill returns false (also written to log)
        undo, throw pError.  
    end method. 
    
    method override protected void CreateQuery():
    
        super:CreateQuery().
        if valid-object(DataSourcehandle) then
            delete object DataSourcehandle. 
            
        create data-source DataSourcehandle.
       
        DataSourceHandle:query = QueryHandle.
    end method.   
    
    
    
    method public void AfterRow( input DATASET-HANDLE phDataset ):
        
        undo, throw new NotImplementedError( ).

    end method.

    method public void AfterUpdate( input DATASET-HANDLE phDataset ):
        
        undo, throw new NotImplementedError( ).

    end method.

    method public void BeforeUpdate( input DATASET-HANDLE phDataset ):
        
        undo, throw new NotImplementedError( ).

    end method.

    method public void Destroy(  ):
        
        undo, throw new NotImplementedError( ).

    end method.

    method public logical Fill(  ):
        
        undo, throw new NotImplementedError( ).

    end method.

    method public void FindAndCompareSource(  ):
        
        undo, throw new NotImplementedError( ).

    end method.

    method public void FindAndCompareSource( input phBuffer as handle ):
        
        undo, throw new NotImplementedError( ).

    end method.

    method public void FindAndCompareSource( input phbuffer as handle, input pFields as character ):
        
        undo, throw new NotImplementedError( ).

    end method.

    method public void FindSource( input plock as integer ):
        
        undo, throw new NotImplementedError( ).

    end method.

    method public void FindSource( input phBuffer as handle, input pLock as integer ):
        
        undo, throw new NotImplementedError( ).

    end method.

    method public void FindSource( input phbuffer as handle, input pDbBuffer as handle, input plock as integer ):
        
        undo, throw new NotImplementedError( ).

    end method.

    method public void FindSourceForUnmodifiedRow(  ):
        
        undo, throw new NotImplementedError( ).

    end method.

    method public void Initialize(  ):
        
        undo, throw new NotImplementedError( ).

    end method.
    
    method final public logical Prepare( phBuffer as handle,  pRequest as IGetDataTableRequest ):
        return prepare(phBuffer,pRequest,?). 
    end method.
    
    method final public logical Prepare(phBuffer as handle, pRequest as IGetDataTableRequest, pParentRequest as IGetDataTableRequest ):
        return prepare(phBuffer,pRequest,pParentRequest,false). 
    end method.    
    
    method final protected logical Prepare(phBuffer as handle, pRequest as IGetDataTableRequest, pParentRequest as IGetDataTableRequest, plSkipQueryPrepare as logical ):
        define variable oQueryBuilder as QueryBuilder no-undo.
        define variable cQuery        as character no-undo.
        define variable oRequest      as Pmfo.Core.BusinessLogic.IGetDataTableRequest no-undo.
        define variable lOk           as logical no-undo.
        define variable lUniqueFind   as logical no-undo.
        define variable iIndexedPosition as integer no-undo.
        define variable oAppError        as AppError no-undo.
        define variable cChildJoinFields as character no-undo.
        define variable iFld             as integer no-undo.
        define variable lProxyJoin       as logical no-undo.
        define variable iRel             as integer no-undo.
        
        assign 
            NextRowKey = ?
            RestartRow = 0
            extent(RestartIds) = ?
            .
        
        DataBuffer = phBuffer.
        
        // should possibly be in initialize? but trying ot avoid depending on initialize   
        PrepareBuffer(phBuffer).
        
        // set to true in empty constructor  
        if NoConnectNeeded then 
            return true.
            
        extent(BufferHandles) = ?.
        // if valid-object(oRequest) is used in subsequen logic
        if(type-of(pRequest,Pmfo.Core.BusinessLogic.IGetDataTableRequest)) then
        do:
            oRequest = cast(pRequest,Pmfo.Core.BusinessLogic.IGetDataTableRequest). 
            BufferHandles = GetBufferHandles(oRequest, cast(pParentRequest,Pmfo.Core.BusinessLogic.IGetDataTableRequest)).
        end.
        else // wasted too much time debugging cases where the Ccs version was used by accident - there is no point supporting that 
            undo, throw new UnsupportedOperationError(subst("Unsupported TableRequest Type &1",pRequest:GetCLass():TypeName)).
        
        if extent(BufferHandles) = ? then
            undo, throw new IllegalStateError(subst("&1.GetBufferHandles() does not return any handles",getClass():TypeName)).
        
        // set to true to defi8ne query later (typically in a before-Fill event)  
        if NoQueryCreate then 
            return true.
        
        CreateQuery().   
      
       // if(type-of(pRequest,Pmfo.Core.BusinessLogic.IGetDataTableRequest)) then
         //   BaseQuery = PrepareBaseQuery(BaseQuery, oRequest).
        cQuery = BaseQuery.
        
        
        DataBuffer:attach-data-source(DataSourceHandle,FieldMap).
        /** Cannot do this here since we need to build the query to support child filter in innerjoin
        if valid-object(pParentRequest) then
        do:
            QueryStringWithoutParent = cQuery. // used by prepareInnerJoins
            cQuery = AddParentJoinToQuery(cQuery).
        end.     
        **/
                
        if plSkipQueryPrepare = false and valid-object(pRequest:QueryDefinition) then
        do on error undo, throw :
             
            oQueryBuilder = new QueryBuilder(this-object,BufferNames,cQuery).
            
            cQuery = oQueryBuilder:Build(pRequest,DataBuffer).
            
            if valid-object(pParentRequest) and not lProxyJoin then
            do:
                QueryStringWithoutParent = cQuery. // used by prepareInnerJoins
                cQuery = AddParentJoinToQuery(cQuery).
            end.    
            
            catch e as Progress.Lang.Error :
              
               // default to throw but overrides may ignore - and just return false to silently set no-fill
                HandleQueryError(pRequest,e).
                return false. 
            end catch.
        end.
        else if not lProxyJoin then
        do: 
            if valid-object(pParentRequest) then
            do:
                QueryStringWithoutParent = cQuery. // used by prepareInnerJoins
                cQuery = AddParentJoinToQuery(cQuery).
            end.    
        end.
        
        if  pRequest:NumRecords = 0 
            and pRequest:PagingContext = ""
            and pRequest:Skip = 0 then
        do:
            iIndexedPosition = StringUtil:FindAnyWord(cQuery,"indexed-reposition").
            if iIndexedPosition > 0 then 
               // remove 1 extra since there is space before and after
                substring(cQuery,iIndexedPosition,length("indexed-reposition") + 1) = "".
        
            QueryHandle:forward-only = true.
        end.
        
        // only Psi request 
        if valid-object(oRequest) then 
        do:
            lUniqueFind = oRequest:FindUnique.
        end. 
           
        if lUniqueFind = false and plSkipQueryPrepare = false then
        do:
            // only Psi request supports count
            if valid-object(oRequest) and cast(pRequest,Pmfo.Core.BusinessLogic.IGetDataTableRequest):Count  then 
                cQuery = PrepareOrExecuteCount(cast(pRequest,Pmfo.Core.BusinessLogic.IGetDataTableRequest), input cQuery, valid-object(pParentRequest)).
            
            PreparePaging(pRequest, oQueryBuilder).
        end.
        if plSkipQueryPrepare = false then
        do:          
            /*            if entityname= "partners" then*/
            /*                message cQuery            */
            /*                view-as alert-box.        */
            lok = QueryHandle:query-prepare(cQuery).
            
            // workaround for recursive data source fill-where-string and query prepare-string not being in sync
            // This is only for recursive cases where there are two tables and the child (this buffer) has a recursive relation to the parent 
            // and is a problem when the fill recurses to the parent and back to this and not for the first fill from the parent 
            // NOTE: We probably NEED this behavior for self recursisve relations in order to filter on top level only 
            //       but we could possibly use fill-where-string if we ever wanted to filer on children only.       
            if valid-handle(phBuffer:parent-relation) then
            do iRel = 1 to phBuffer:num-child-relations:
                if phBuffer:get-child-relation (iRel):recursive then 
                do: 
                    if phBuffer:parent-relation:parent-buffer = phBuffer:get-child-relation (iRel):child-buffer then
                    do:   
                        DataSourceHandle:fill-where-string = substr(QueryHandle:prepare-string,index(QueryHandle:prepare-string," where ") + 1).
                        leave.
                    end.    
                end.
            end.
        end.          
        else 
            lok = true. // not sure what is best here ???    
     
        RecordCounter = 0. 
        return lok. 
        catch e as Progress.Lang.Error :
            // @TODO should ideally check if production and only show the query return if not
            //  (ideally this error should never happen in production... but it will 
            if e:GetMessageNum(1) = 7328  or e:GetMessageNum(1) = 7325 or e:GetMessageNum(1) = 247 then
            do:
                oAppError = new ApplicationError("The query does not compile.",e). 
                oAppError:AddMessage(cQuery,?).
                undo, throw oAppError.
            end.    
            undo, throw e.
        end catch.   
    end method.
    
    method protected handle extent GetBufferHandles ( input pRequest as IGetDataTableRequest, input pParentRequest as IGetDataTableRequest ):
        return GetBufferHandles().
    end method.
    
    
    method public override logical Prepare(  ):
        
      undo, throw new NotImplementedError( ).

    end method.

    method public IGetDataTableRequest PrepareCurrent( input phBuffer as handle, input pParentRequest as IGetDataTableRequest ):
        
      undo, throw new NotImplementedError( ).

    end method.

    method public logical PrepareSave( input phBuffer as handle, input pUpdateRequest as IUpdateDataRequest ):
        
        undo, throw new NotImplementedError( ).

    end method.

    method public logical RefillCurrentRow(  ):
        
        undo, throw new NotImplementedError( ).

    end method.

     

    method public logical SaveRow( input phBeforeBuffer as handle ):
        
        undo, throw new NotImplementedError( ).

    end method.
    
    method public void DatasetTransactionEnd( input dataset-handle phDataset ).
    end method.
    
    method protected character GetFieldMap(): 
        define variable oIterator   as IIterator   no-undo.
        define variable cExceptList as character no-undo.
        define variable cDlm        as character no-undo.
        define variable cKeys       as character no-undo.
        define variable i           as integer no-undo.
        define variable iThisbuffer as integer no-undo.
        define variable hFld as handle no-undo.
        define variable IKey as integer no-undo.  
        define variable cKeymap as character no-undo.
        define variable cmap as character no-undo.
        define variable j as integer no-undo.
        
        if extent(BufferHandles) = 1 then 
            return "".
                     
       // if valid-object(ProxyManager) then
       //  as of current ProxyFieldNames is managed in AddProxyField and also set directly
       //  to manage keys and specifically join to keys in sources mapped to generic tables
       // TODO use FieldProxy always (FieldMap)    
                   
        // if main buffer is not first buffer then check if key can be mapped to an earlier table
        // this may seem a bit loose and odd, but it is actually what will happen in a case where 
        // no fieldmap is provided in attach 
        // -  the GetFieldMAp used to return "" so this logic was added to preserve
        //    similar behavior after adding new logic here that ensures the fields are
        //    mapped correctly for the main table 
        // -  without  this change mapping the key to the main table when not first in query will cause   
        // error  Unable to auto-generate a FILL query predicate for <table> if field <keyfield in <ttname> is not mapped. (11883)"
         
        if Bufferhandle <> BufferHandles[1] then 
        do:
            cKeys = Bufferhandle:keys.
            
            iThisbuffer = lookup(BufferName,BufferNames).
            do i = 1 to iThisBuffer - 1 : 
                do ikey = 1 to num-entries(cKeys): 
                    hFld = BufferHandles[i]:buffer-field(entry(i,cKeys)) no-error.
                    if valid-handle(hFld) then 
                    do: 
                        ckeymap = cKeymap 
                            + (if cKeyMap = "" then "" else ",")
                            + subst("&1,&2.&1",entry(i,ckeys),BufferHandles[i]:name).  
                        cExceptList = cExceptList 
                            + (if cExceptList = "" then "" else ",")
                            + entry(i,ckeys).  
                                                            
                    end. 
                end.
                do j = 1 to num-entries(cExceptlist):
                    iKey = lookup(entry(j,cexceptList),cKeys).
                    if IKey > 0 then 
                    do:
                        StringUtil:RemoveEntryFromList(iKey,cKeys).
                    end.        
                end.        
            end.
        end. 
        cMap = BufferUtil:GetFieldMap(DataBuffer,BufferHandle,cExceptList).
        if cKeymap > "" then
            cMap = trim(subst("&1,&2",cMap,cKeymap),","). 
        return cMap.    
    end method.
    
        
end class.