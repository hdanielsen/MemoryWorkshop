 
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
using Progress.Lang.AppError from propath.
using Ccs.BusinessLogic.IQuerySortEntry from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.
using Pmfo.Core.BusinessLogic.IQueryPredicate from propath.
using Pmfo.Core.Error.BadRequestError from propath.
using OpenEdge.Core.StringConstant from propath.
using Pmfo.Util.QueryUtil from propath.
using Pmfo.Util.ServiceInfo from propath.
using Pmfo.Core.Error.NotFoundError from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.

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
    
    
     define protected property ParentRelation as handle no-undo 
        get():
            if not valid-handle(ParentRelation) then do:
                if valid-handle(DataBuffer) then 
                do:
                    ParentRelation = DataBuffer:parent-relation. 
                end.
            end.
            return ParentRelation.
        end. 
        
        private set.
    
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

    define protected property RecordCounter   as int64   no-undo get. set.    
    define protected property ExternalPaging  as logical no-undo get. set.
    
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
   
    // This is the heart of the datasource   
    method protected handle extent GetBufferHandles ( input pRequest as IGetDataTableRequest, input pParentRequest as IGetDataTableRequest ):
        return GetBufferHandles().
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
        define variable oRequest      as IGetDataTableRequest no-undo.
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
            //    QueryStringWithoutParent = cQuery. // used by prepareInnerJoins
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
           //     QueryStringWithoutParent = cQuery. // used by prepareInnerJoins
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
    
     method protected void PreparePaging(pRequest as IGetDataTableRequest, pQueryBuilder as QueryBuilder) :
        define variable oRequest as Pmfo.Core.BusinessLogic.IGetDataTableRequest no-undo.
        define variable iSource as integer no-undo.
        
        if pRequest:NumRecords > 0 then 
        do:
            NumRecords = pRequest:NumRecords.
                //  if UseBeforeFillWithPaging = false then
                // we need to set this also when UseBeforeFillWithPaging = false 
                // otherwise AfterRow continiues to fill data (TODO research this)
            Databuffer:batch-size = pRequest:NumRecords.
        end.
                    
        if pRequest:Skip > 0 then
        do:        
            if pRequest:PagingContext > "" then
                undo, throw new BadRequestError("Skip and Paging are conflicting request properties").
           // if UseBeforeFillWithPaging = true then
        //        RestartRow = pRequest:Skip + 1.
           // else    
                DataSourceHandle:restart-row  = pRequest:Skip + 1.
        end.
        oRequest = cast(pRequest,Pmfo.Core.BusinessLogic.IGetDataTableRequest).
            
            // only Psi request supports paging context 
        if valid-object(oRequest) then
        do:
            // external paging is an option to use serialize-name for fields in context
            ExternalPaging = true. // oRequest:ExternalPaging.
            oRequest = cast(pRequest,Pmfo.Core.BusinessLogic.IGetDataTableRequest).
            if valid-object(oRequest:PagingContextEntry) then
            do:
                // The RestartIds are defined as property to be used in BeforeFillWithPaging
                // but this is not implemented yet   
              //  if UseBeforeFillWithPaging then 
                //    undo, throw new NotImplementedError(subst("Batching on many to one query in &1",Entityname)).
            
                RestartIds = GetPagingRowids(oRequest,pQueryBuilder).
                // no need to do this if the fill is done in BeforeFillWithPaging
               // if UseBeforeFillWithPaging = false then
                do iSource = 1 to extent(RestartIds):       
                    DataSourceHandle:restart-rowid(iSource) = RestartIds[iSource].
                end.     
            end.
        end.    
        else if pRequest:PagingContext > "" then 
        do:
            undo, throw new UnsupportedOperationError(subst("Paging Context with &1",pRequest:GetClass():TypeName)).
        end.
         
    end method.    
        
    method protected character PrepareOrExecuteCount(pRequest as Pmfo.Core.BusinessLogic.IGetDataTableRequest, pcQuery as character, plHasParent as logical) :
        define variable cCountQuery as character no-undo.
        Count = pRequest:Count.
                
        // if there is a sort do the count without the sort 
        // if we have a parent the parent temp-table is referneced in the query
        // and it wontwotk here   
        if Count then 
        do: 
            //  count if manual query is not implemented yet   
        //    if UseBeforeFillWithPaging then 
           //     undo, throw new NotImplementedError(subst("Count of many to one query of '&1'",Entityname)).
                   
            if valid-object(pRequest:QueryDefinition) 
                and extent(pRequest:QueryDefinition:QuerySort) > 0 
                and plHasParent = false then
            do:
                cCountQuery = trim(pcQuery).
                entry(1,cCountQuery,StringConstant:SPACE) = "preselect".
                // remove sort - not needed for count and may improve performance 
                cCountQuery = QueryUtil:RemoveSort(cCountQuery).
                QueryHandle:query-prepare(cCountQuery).
                QueryHandle:query-open ().
                TotalCount = QueryHandle:num-results.
                
            end.
            else do: 
                // The rule for child tables is that count and paging
                // only is set when the parents are single unique find records 
                // otherwise we would need to manage count for each parent 
                pcQuery = trim(pcQuery).
                entry(1,pcQuery,StringConstant:SPACE) = "preselect".
            end.
         
        end.
        return pcQuery. 
    end method.  
    
    method protected character GetNextRowKey(phSourceBuffer as handle,pRowid as rowid): 
          
        
        define variable iField          as integer   no-undo.
        
        define variable hFld            as handle    no-undo.
        define variable iLookup         as integer   no-undo.
        define variable cTTField        as character no-undo.
        define variable cDbField        as character no-undo.
        define variable cDbFieldTable   as character no-undo.
        define variable cDbFieldName    as character no-undo.
        define variable cValue          as character no-undo.
        define variable cNextRowKey     as character no-undo.
        define variable cNextValue      as character no-undo.
        define variable lHasSpaceOrPlus as logical   no-undo.
        define variable lUseFieldname   as logical   no-undo.
        define variable cKeys           as character no-undo.
        define variable dDate           as date      no-undo.
        
        cKeys = ServiceInfo:GetKeys(DataBuffer).
        if ckeys = "" then
            undo, throw new ApplicationError(subst("Cannot generate next row key for &1 with no unique key",DataBuffer:name)).               
       
        phSourceBuffer:find-by-rowid (pRowid,no-lock).
        
        if phSourceBuffer:avail then 
        do:
            do iField = 1 to num-entries(cKeys).
                cTTField = entry(iField,cKeys).
                iLookup = lookup(subst("&1.&2",DataBuffer:name,cTTField),DataBuffer:data-source-complete-map).
                cDbField = entry(iLookup + 1,DataBuffer:data-source-complete-map).
                cDbFieldTable = entry(1,cDbField,".").
                cDbFieldName = entry(2,cDbField,".").
                
                if cDbFieldTable = phSourceBuffer:name then 
                do:
                    assign
                        hFld  = phSourceBuffer:buffer-field(cDbFieldName).
                    if hFld:data-type begins "date" then
                    do:
                        if ExternalPaging then
                        do:
                            cNextValue = quoter(iso-date(hFld:buffer-value),"'").
                        end.
                        else
                            cNextValue  = quoter(hFld:buffer-value,"'").     
                    end.
                    else if (hfld:data-type = "character" or hFld:data-type = "longchar") then
                    do:
                        assign
                            cNextValue = hFld:buffer-value
                            lHasSpaceOrPlus = index(cNextValue,StringConstant:SPACE) > 0 or index(cNextValue,"+") > 0
                            cNextValue      = quoter(cNextValue,"'")
                            .
                    end.        
                    else
                        cNextValue = hFld:buffer-value.
                   
                    /* if hasspaceorplus use field name in expression so we can safely decode bad encoders like certain REST testing tools...
                       some REST tools will encode space as +, but not if there already is a + 
                       this is indeterministic since a value with + and no space could origin from both space and +
                    */     
                    if num-entries(cKeys) = 1 and not lHasSpaceOrPlus then 
                    do:
                        cNextRowKey = cNextValue.
                    end.
                    else do:
                        cNextRowKey = cNextRowKey 
                            + (if cNextRowKey = "" then "" else " and ")
                            + subst("&1 eq &2",
                            if ExternalPaging 
                            then DataBuffer:buffer-field(cTTField):serialize-name
                            else cTtField,
                            cNextValue
                            ).
                    end.                           
                end.     
            end.
        end.
        else 
            undo, throw new ApplicationError("Data source not available for next row key").               
        
        return cNextRowKey.
        
        catch e1 as ApplicationError :
            undo, throw e1.
        end.
        catch e2 as Progress.Lang.Error :
            undo, throw new ApplicationError("Could not identify next row key",e2).               
        end catch. 
    end method.         
     
    method protected rowid extent GetPagingRowids (pRequest as Pmfo.Core.BusinessLogic.IGetDataTableRequest, pQueryBuilder as QueryBuilder):
        define variable rIds          as rowid     extent no-undo.
        define variable cQuery        as character no-undo.
        define variable i             as integer   no-undo.
        define variable cErrorDetails as character no-undo. 
        
        if not valid-object(pQueryBuilder) then
            pQueryBuilder = new QueryBuilder(this-object,BufferNames,BaseQuery).
        
        extent(rids)= extent(BufferHandles).
        
        if extent(BufferHandles) = 1 then
        do:
            cQuery = pQueryBuilder:BuildFind(pRequest:PagingContextEntry,DataBuffer).
            BufferHandles[1]:find-unique(cQuery).
          
            if BufferHandles[1]:available then
                rids[1] = BufferHandles[1]:rowid. 
            else if BufferHandles[1]:ambiguous then
                undo, throw new ApplicationError(subst("Record &1 is ambiguous",BufferHandles[1]:name)).
            else 
                undo, throw new ApplicationError(subst("Record &1 not avail",BufferHandles[1]:name)). 
        end.    
        else do:
            cQuery = pQueryBuilder:Build(pRequest:PagingContextEntry,DataBuffer).
            QueryHandle:query-prepare(cQuery).
            QueryHandle:query-open().
            QueryHandle:get-first.
            do i = 1 to extent(BufferHandles):
                if BufferHandles[i] = bufferHandle then 
                do:
                    if BufferHandle:avail then
                    do: 
                        rids[i] = BufferHandles[i]:rowid.
                        leave.
                    end.
                    else 
                        undo, throw new ApplicationError(subst("Record &1 is not avail",BufferHandles[i]:name)).
                end.    
            end. 
            
            // There must only be one 
            QueryHandle:get-next.
            if BufferHandle:avail then 
                undo, throw new ApplicationError(subst("Record &1 is ambiguous",BufferHandle:name)).
        end.       
        return rids.
        catch e as Progress.Lang.Error :
            if e:GetMessageNum(1) =  247 then 
                cErrorDetails = subst("' - &1'",cQuery).
            undo, throw new NotFoundError(subst("'&1' with paging context &2 &3",
                DataBuffer:serialize-name, // else DataBuffer:table-handle:name,
                pRequest:PagingContextEntry:ToString(),
                cErrorDetails 
                ),
                e      
                ).          
        end catch.
    end method.    
    
    
    // allow subclasses to override and do nothing 
    method protected void HandleQueryError (pRequest as IGetDataTableRequest, pError as Error):
        //  columnExpression may throw not implemented for some fields - filter on outer-join buffer 
        if type-of(pError,NotImplementedError) then
            undo, throw new ApplicationError(subst("Cannot build database query. &1. Please Contact IT.",cast(pError,ApplicationError):GetStrippedmessage()),pError).
         
        undo, throw new ApplicationError(subst("Failed to build database query from query '&1'",pRequest:QueryString),pError).  
    end method.
    
    method protected character AddParentJoinToQuery(pcQuery as character):
        define variable i            as integer no-undo.
        define variable cFillWhere   as character no-undo.
        define variable cFieldExp    as character no-undo.
        define variable cNewWhere    as character no-undo.
        define variable cChildField  as character no-undo.
        define variable cParentField as character no-undo.
        define variable cAnd         as character no-undo.
        define variable cChildBuffer as character no-undo.
        cFillWhere = left-trim(DataSourceHandle:fill-where-string).
        entry(1,cFillWhere,StringConstant:SPACE) = "".
        cFillWhere = left-trim(replace(cFillWhere," and "," ")).
        do i = 1 to num-entries(cFillWhere," ").
            cFieldExp    = entry(i,cFillWhere," ").
            cChildField  = entry(1,cFieldExp,"=").
            cChildbuffer = entry(1,cChildField,"."). 
            cParentField = entry(2,cFieldExp,"=").
            cNewWhere    = cNewWhere 
                + cAnd 
                + cChildField + " eq " + cParentField.
            cAnd         = " and ".               
        end. 
        if cChildbuffer <> BufferName and lookup(cChildbuffer,BufferNames) > 0 then
            return QueryUtil:InsertQueryExpression(cChildbuffer, pcQuery, cNewWhere).
        else 
            return QueryUtil:InsertQueryExpression(BufferName, pcQuery, cNewWhere).
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
    
    
     /* return source columns for query mapping 
    (implements IDataSOurceMap interface used by QueryBuilder map query */
    method public character ColumnSource (pcColumn as char):
        define variable iLookup     as integer     no-undo.
        define variable cTable      as character   no-undo.
        define variable hBuffer     as handle      no-undo.
        define variable hDataset    as handle      no-undo.
        define variable cDbColumn   as character   no-undo.
        define variable joinedsrc   as IDataSource no-undo.
        define variable cJoinCol    as character   no-undo.
        define variable hFld        as handle      no-undo.
        define variable i           as integer     no-undo.
        define variable oIterator   as IIterator   no-undo.
     //   define variable oFieldProxy as IFieldProxy no-undo. 
        define variable cProxyColumn as character no-undo.
        define variable cColumnName as character no-undo.
        define variable cMappedName as character no-undo.
     
        /*  inner join reference to other buffers can be passed from client,
            so we use the buffer's dataset to get those datasources' 
            fieldmap. This assume that any buffer that has been attached to a 
            datasource is referencing the same physical storage, (keep in mind that all connected 
            progress databases are the same physical storage in this context), so all dataset mapping 
            is valid for this datasource. 
            Note that this secondary inner join is passed from the client as an option to reduce the 
            number of records to fill for THIS table. 
            The actual fill of the joined table is handled by another datasource.  */
/*        if lookup(pcColumn,ProxyFieldNames) > 0 and valid-object(ProxyManager) then*/
/*        do:                                                                        */
/*            cProxyColumn = ProxyManager:ColumnSource(pcColumn).                    */
/*            if cProxyColumn > "" then                                              */
/*                return cProxyColumn.                                               */
/*        end.                                                                       */
        
        if num-entries(pcColumn,".") = 1 then 
        do:        
            // not attached - use FieldMap                
            if not valid-handle(DataBuffer:data-source) then
            do:
                iLookup = lookup(pcColumn,FieldMap).   
                if iLookup > 0 then
                    return entry(iLookup + 1,FieldMap).
                else do i = 1 to extent(BufferHandles):
                    hfld = BufferHandles[i]:buffer-field(pcColumn) no-error.
                    if valid-handle(hFld) then
                        return subst("&1.&2",BufferHandles[i]:name,pcColumn).
                end.  
                return pcColumn.   
            end.             
            // TODO this is a bit messy - need clenaup, but lots of testing needed  
            cColumnName = pcColumn.
            pcColumn = DataBuffer:name + "." + pcColumn.
            hBuffer  = DataBuffer.
        end.
        else do: 
            cTable = entry(1,pcColumn,".").
            cColumnName = entry(2,pcColumn,".").
            hDataset = DataBuffer:dataset.
            if DataBuffer:name = cTable then
                hBuffer = DataBuffer.
            else do:
                /* keep reference to parent relation as is  */
                if valid-handle(ParentRelation) and cTable = ParentRelation:parent-buffer:name then
                    return pcColumn.
                   
                hBuffer  = hDataSet:get-buffer-handle(cTable) no-error.     
            end.
        end.
        if valid-handle(hBuffer) then
        do:
            
            iLookup = lookup(pcColumn,hBuffer:data-source-complete-map).
            if iLookup > 0 then
            do:
                cDbColumn =  entry(iLookup + 1,hBuffer:data-source-complete-map).
                if hBuffer <> DataBuffer and lookup(entry(1,cDbColumn,"."),BufferNames) = 0 then
                    return pcColumn.
                return cDbColumn.
            end.
            else do:
                // fields in field  save manager is excluded from attahc and thus not in data-source-complete-map 
/*                if valid-object(FieldSaveManager) then                               */
/*                do:                                                                  */
/*                    if lookup(cColumnName,FieldSaveManager:FieldNames) > 0 then      */
/*                    do:                                                              */
/*                        cMappedname = StringUtil:GetMappedName(cColumnName,FieldMap).*/
/*                        if cMappedname > "" then                                     */
/*                            return cMappedName.                                      */
/*                        else                                                         */
/*                            return subst("&1.&2",BufferName,cColumnName).            */
/*                    end.                                                             */
/*                end.                                                                 */
                return pcColumn.
            end.    
        end.
        catch e as Progress.Lang.Error :         
            undo, throw new IllegalArgumentError(subst("Error when trying to resolve '&1' against data source",pcColumn),e).
        end catch.  
    end method.                   
    
    
    /** Convert sort expression column for QueryString 
       (second parse - column already transformed by ColumnSource(pccolumn)  
       implements IDataSourceMap interface used by QueryBuilder map query */ 
    method public IQuerySortEntry extent ColumnSort(pSort as IQuerySortEntry):
        define variable oSort      as IQuerySortEntry extent 1 no-undo.
        define variable oProxySort as IQuerySortEntry extent no-undo.
        
/*        if valid-object(ProxyManager) then              */
/*        do:                                             */
/*            oProxySort = ProxyManager:ColumnSort(pSort).*/
/*            if extent(oProxySort) > 0 then              */
/*                return oProxySort.                      */
/*        end.                                            */
        
        oSort[1] = pSort.
        return oSort.     
    end method.   
    
    // implements IDataSourceMap interface used by QueryBuilder map query 
    // override to change expression completely or return ? to ignore   
    method public IQueryEntry ColumnExpression(pPredicate as IQueryPredicate):
        return pPredicate. 
    end method.   
        
end class.