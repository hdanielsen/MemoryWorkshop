 
 /*------------------------------------------------------------------------
    File        : DataSource
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using Ccs.BusinessLogic.IQuerySortEntry from propath.
using OpenEdge.Core.Collections.ICollection from propath.
using OpenEdge.Core.Collections.IIterator from propath.
using OpenEdge.Core.StringConstant from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.
using Pmfo.Core.BusinessLogic.IQueryPredicate from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.BusinessLogic.QueryBuilder.QueryBuilder from propath.
using Pmfo.Core.DataLayer.DbQuery from propath.
using Pmfo.Core.DataLayer.IDataSource from propath.
using Pmfo.Core.DataLayer.IUpdateTarget from propath.
using Pmfo.Core.DataLayer.ValidationHookEventType from propath.
using Pmfo.Core.Error.ApplicationError from propath.
using Pmfo.Core.Error.BadRequestError from propath.
using Pmfo.Core.Error.ConflictError from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.
using Pmfo.Core.Error.IllegalOperationError from propath.
using Pmfo.Core.Error.IllegalStateError from propath.
using Pmfo.Core.Error.NotFoundError from propath.
using Pmfo.Core.Error.NotImplementedError from propath.
using Pmfo.Core.Error.TableNotFoundError from propath.
using Pmfo.Core.Error.TransactionError from propath.
using Pmfo.Core.Error.UnsupportedOperationError from propath.
using Pmfo.Util.Array from propath.
using Pmfo.Util.BufferUtil from propath.
using Pmfo.Util.ErrorStringUtil from propath.
using Pmfo.Util.QueryUtil from propath.
using Pmfo.Util.ServiceInfo from propath.
using Pmfo.Util.StringUtil from propath.
using Progress.Lang.AppError from propath.
using Progress.Lang.Error from propath.
using Pmfo.Core.Common.Warning from propath.
using Pmfo.Core.Common.IWarning from propath.
using OpenEdge.Core.Collections.IList from propath.
using OpenEdge.Core.Collections.List from propath.
using Progress.Lang.Object from propath.

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
   
    define public property DataBuffer     as handle    no-undo 
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
        
      // set for fields that are not supposed to be optimistic locked checked or saved automatically
    define public property OptimisticLockExceptFields   as character init ? no-undo get. protected set.
  
    // set to true to avoid lobs in save row changes (i.e. when images are stored to disk)
    define protected property NoLobs         as logical   no-undo get. protected set.
    
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

    // This just be set to "" in prepare
    // It is typically called after fill when npaging when DataSourcehandle:next-rowid has data
    // But ut can also be assigned in cases where the paging has to be managed manually in before-fill  
    define public property NextRowKey as character no-undo  
        get():
            define variable iSource         as integer   no-undo.
            define variable hSource         as handle    no-undo.
            define variable rRowid          as rowid     no-undo.
            if NextRowKey = "" or NextRowKey = ? then 
            do:
                do iSource = 1 to extent(BufferHandles):
                    if BufferHandle = BufferHandles[iSource] then 
                        leave.
                end.  
                if not valid-handle(DataSourcehandle) then 
                    return ?. // Added after removing create datasource from the setter since it caused memory leak on save (report execute)
                             //  TODO can this ever happen    
                hSource = DataSourcehandle:get-source-buffer (iSource).
                rRowid = DataSourcehandle:next-rowid(iSource).
               // assumed to be because we're not paging 
                if rRowid = ? then 
                    return ?.
                NextRowKey =  GetNextRowKey(hSource, rRowid).     
            end.
            return NextRowKey.
        end.     
        protected set.      

    define public    property Warnings        as IList   no-undo 
        get. 
        protected set(pWarns as IList):
            Warnings = pWarns.
          //  HasWarning = true.
        end. 
    
    define public property NumRecords as int64 no-undo 
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
    
    method public void AfterRow(input dataset-handle phDataset):
      
        RecordCounter = RecordCounter + 1.
        if valid-handle(SeqFieldHandle) then 
            SeqFieldHandle:buffer-value = RecordCounter.

        if Count and TotalCount = ? then
        do:
            TotalCount = QueryHandle:num-results.
        end.
    end method. 

    method public void AfterUpdate( input DATASET-HANDLE phDataset ):

    end method.

    method public void BeforeUpdate( input DATASET-HANDLE phDataset ):

    end method.

    method public void Destroy ():
        delete object Datasourcehandle no-error.
    end method.

    method public logical Fill(  ):
        define variable rDummy as rowid extent no-undo.
        this-object:Fill (0,rDummy).
    end method.     
        // returns the row num that matces the start rowids to allow  
    // BeforeFillWithPaging get rid of the rows prior to this
    // 
    method protected int64 Fill(pagesize as int64, pStartIds as rowid extent).
        define variable hDs as handle.
        define variable i as integer no-undo.
        define variable cFieldMaps as character extent no-undo.
        define variable cExceptLists as character extent no-undo.
        define variable iChild as integer no-undo.
        define variable hChild as handle no-undo.
        define variable iStartRow as int64 no-undo. 
        define variable lFoundStart as logical init ? no-undo.
        QueryHandle:query-open().   
        QueryHandle:get-first(). 
        hds = DataBuffer:dataset.
        
        SplitFieldMap(FieldMap, output cFieldMaps,output cExceptLists).      
       
        do while QueryHandle:get-buffer-handle(1):avail:
 
           // if lSkip = false then
            do on error undo, throw:
                DataBuffer:buffer-create().
                /*                if iStartRow = 0 and extent(pStartIds) <> ?  then*/
                /*                   lFoundStart = true.                           */
                /*                                                                 */
                do i = 1 to  QueryHandle:num-buffers:
                    if QueryHandle:get-buffer-handle(i):avail then
                    do:
                        DataBuffer:buffer-copy(QueryHandle:get-buffer-handle(i),cExceptLists[i],cFieldMaps[i]).
                    /*                        if lFoundStart = true                                          */
                    /*                        and extent(pStartIds) <> ?                                     */
                    /*                        and pStartIds[i] <> QueryHandle:get-buffer-handle(i):rowid then*/
                    /*                           lFoundStart = false.                                        */
                       
                    end.    
                end.
                AfterRow(dataset-handle hds by-reference).
                
                /*                if lFoundStart then           */
                /*                    iStartRow = RecordCounter.*/
                
                do iChild = 1 to Databuffer:num-child-relations:
                    hChild = DataBuffer:get-child-relation (iChild):child-buffer .
                    hChild:fill().
                end.   
                 
                if pagesize > 0 then 
                do: 
                    if (extent(pStartIds) = ?  and RecordCounter > pageSize) then 
                    do: 
                        NextRowKey = GetNextRowKey(BufferHandle, BufferHandle:rowid).
                        DataBuffer:buffer-delete.
                        return 0.
                    end.  
                end.     
                catch e as Progress.Lang.Error :
                    if e:GetMessageNum(1) = 132  then
                    do: 
                       // ignore already exists if merge
                       // TODO check up front?? getuniqueindexes 
                       // - get value from db using field map
                       //   dataBuffer find-unique  
                        DataBuffer:buffer-delete.
                    end.   
                    else 
                        undo, throw e.
                end catch.
            end.
            QueryHandle:get-next(). 
            
        end.
        return 0.  
    end method.
     
    
    method public logical RefillCurrentRow().
        define variable hDs as handle.
        define variable i as integer no-undo.
        define variable lok as logical no-undo.   
        define variable cFieldMaps as character extent no-undo.
        define variable cExceptLists as character extent no-undo.
        
        if NoConnectNeeded or NoQueryCreate then
            // if no connect or no create needed in updatable dataource the refresh must be dealt with differently 
            // typically ensure all values are redresehed on save - i.e. call RowAfter and a add an empty override of RefillCurrentRow 
  
            undo, throw new IllegalStateError(subst("RefillCurrentRow called in DataSource with &1 set to true. Please Contact IT.",
                if NoConnectNeeded then "NoConnectNeeded" else "NoQueryCreate")
                ).
        QueryHandle:query-open().  
        QueryHandle:get-first(). 
        hds = DataBuffer:dataset.
        
        SplitFieldMap(FieldMap, output cFieldMaps,output cExceptLists).      
        do while QueryHandle:get-buffer-handle(1):avail:
            do i = 1 to QueryHandle:num-buffers:
                if QueryHandle:get-buffer-handle(i):avail then
                do:
                    DataBuffer:buffer-copy(QueryHandle:get-buffer-handle(i),cExceptLists[i],cFieldMaps[i]).
                end.    
            end.
          
            AfterRow(dataset-handle hds by-reference).
            lok = QueryHandle:get-next(). 
            if lok then 
            do:
                undo, throw new IllegalStateError("More than one row available for refill").
            end.    
            return true. 
        end.
        return false.  
    end method.
    
    method public void FindAndCompareSource():
        if DataBuffer:avail = false and DataBuffer:before-buffer:avail and DataBuffer:before-buffer:row-state = row-deleted then
            FindAndCompareSource(DataBuffer:before-buffer).
        else     
            FindAndCompareSource(DataBuffer).
    end method.
    
    // default find for unmodified in transaction  find and compare exclusive  
    method public void FindSourceForUnmodifiedRow().
        FindSource(exclusive-lock).
    end method. 
    
    method public void FindAndCompareSource(phBuffer as handle):
        FindAndCompareSource(phbuffer,"").
    end method.
    
    method public void FindAndCompareSource(phBuffer as handle, pcfields as character):
        define variable cChanges as character no-undo.
        define variable lchanged as logical no-undo.
        define variable i as integer no-undo.
        define variable hFld as handle no-undo.
        define variable cFld as character no-undo.
        define variable cPublicChanges as character no-undo.
        lchanged = FindAndCompareSource(phbuffer, pcfields, output cChanges).
        if lchanged then 
        do:
            do on error undo, throw:
                cPublicChanges = BufferUtil:GetFieldLabels(Databuffer,cChanges).
                // if there are spaces in the changes the ConflcitError will use as-is 
                // so  we nee to beatify before we pass
                cPublicChanges = StringUtil:GetMessageFromEntries(cPublicChanges, "and", true). // true add quotes 
                // needs more testing so for now jusat use the internal names if there is an error
                catch e as IllegalArgumentError:
                    cPublicChanges = pcFields.     
                end catch.
            end.        
            
            undo, throw new ConflictError(phbuffer,cPublicChanges).
        end.    
    end method.
    
    method protected logical FindAndCompareSource(phbuffer as handle, output pChanges as character):
        return FindAndCompareSource(phbuffer, "", output pChanges).
    end method.
    
    method protected logical FindAndCompareSource(phBuffer as handle, input pcfields as character, output pcChanges as character):
        
        if not phBuffer:avail then
            undo, throw new IllegalStateError(subst("Buffer '&1' is not available",phBuffer:name)).
            
        if phbuffer = DataBuffer:before-buffer then
        do:
            if phBuffer:row-state = row-created then
            do: 
                phBuffer = Databuffer.
                if phBuffer:avail = false or phBuffer:rowid <> DataBuffer:before-buffer:after-rowid then
                    phBuffer:find-by-rowid (DataBuffer:before-buffer:after-rowid).  
            end.    
        end.
        else if phBuffer = DataBuffer then 
        do: 
            if phBuffer:row-state = row-modified then
            do: 
                phBuffer = DataBuffer:before-buffer.
                if phBuffer:avail = false or phBuffer:rowid <> DataBuffer:before-rowid then
                    phBuffer:find-by-rowid (DataBuffer:before-rowid).
            end.    
        end.
        else 
            undo, throw new IllegalStateError(subst("Buffer '&1' is not a valid buffer reference for DataSource '&2'",phBuffer:name,EntityName)).
        FindSource(phbuffer, BufferHandle, exclusive-lock).
        pcChanges = CompareBufferWithDb(phbuffer,pcfields,true).
        
        return pcChanges > "".  
    end method.
  
     // void - throws error if not found
    method public void FindSource(plock as integer):
        FindSource(DataBuffer,BufferHandle,pLock). 
    end.    
    
    method public void FindSource(phBuffer as handle, pLock as integer):
         FindSource(phBuffer,BufferHandle,pLock). 
    end method.
     
    // void - throws error if not found
    method public void FindSource(phbuffer as handle,pDbBuffer as handle,plock as integer):
        define variable cWhere as character no-undo.
        define variable oError as AppError     no-undo.
        cWhere = SourceWhere(phbuffer,pDbBuffer).
        
        pDbBuffer:find-unique (cWhere,plock). 
        catch e as Progress.Lang.Error :
            if e:GetMessageNum(1) = 138 or e:GetMessageNum(1) = 3166 then
            do: 
                oError = new TableNotFoundError(phbuffer,GetFindCurrentRowRequest(phBuffer)).
                oError:AddMessage(subst("Database query 'find &1 &2' throws error:~n&3",BufferName,cWhere,e:GetMessage(1)),?).  
                undo, throw oError.
            end.
            else 
                undo, throw e.
        end catch.
    end.    
    
     // separated out to allow override for cases where there are more than one unique key and this need to be controlled 
    method protected Pmfo.Core.BusinessLogic.IGetDataTableRequest GetFindCurrentRowRequest(phBuffer as handle):
        return QueryUtil:GetFindCurrentRowRequest(phBuffer).
    end method.
    
    /*
    Get the TT column mapped to the database field    
    Will return data also if DataSOurcer is no prepared, but this 
    is not 100% reliable as the field may not exist in the TT when prepared 
    */
    method public character SourceColumn (pcDbColumn as char):
        define variable iLookup    as integer    no-undo.
        define variable cFieldmap  as character no-undo.
       
        if num-entries(pcDbColumn,".") <> 2 then 
            undo, throw new IllegalArgumentError(subst("Database field name '&1' must be qualified with table name",pcDbColumn)).      
        
        // support schema info when bnot prepared used by AlertArguments   
        if not valid-handle(Databuffer) then 
        do: 
            cFieldmap = GetUnpreparedFieldMap(pcDbColumn).
            iLookup = lookup(pcDbColumn,cFieldmap).
            if iLookup > 0 then
                return entry(iLookup - 1,cFieldmap).
            else 
                return entry(2,pcDBcolumn,".").        
        end.    
        else do:
            iLookup = lookup(pcDbColumn,DataBuffer:data-source-complete-map).
            if iLookup > 0 then
                return entry(iLookup - 1,DataBuffer:data-source-complete-map).
              
            return "".   
        end. 
    end method.         
    
    method protected character SourceWhere(phbuffer as handle, phDbBuffer as handle):
        define variable cDbKeys     as character no-undo.
        define variable cDbKey      as character no-undo.
        define variable cKey        as character no-undo.
        define variable i           as integer no-undo.
        define variable iSource     as integer no-undo.  
        define variable cWhere      as character no-undo.
        define variable cAnd        as character no-undo.
        define variable hFld        as handle no-undo.
        define variable cFieldWhere as character no-undo.
        define variable cValue      as character no-undo.
        define variable lUseBefore  as logical no-undo.
        define variable cErrorTmpl as character 
            init  "Buffer '&1' is not a before or after buffer for the Data Buffer table '&2'"
            no-undo.
        if not phBuffer:avail then
            undo, throw new IllegalStateError(subst("Buffer '&1' is not available",phBuffer:name)).
         
        if valid-handle(phbuffer:after-buffer) then
        do:  
            if phBuffer:after-buffer:table-handle <> DataBuffer:table-handle then
            do:
                undo, throw new IllegalOperationError(subst(cErrorTmpl,phBuffer:name,DataBuffer:table-handle:name)).
            end.
            // use to decide how to get exprtression from proxy
            lUseBefore = phBuffer:row-state <> row-created.
        end.
        else if phBuffer:table-handle <> DataBuffer:table-handle then
            undo, throw new IllegalOperationError(subst(cErrorTmpl,phBuffer:name,DataBuffer:table-handle:name)).
          
        if valid-handle(phbuffer:after-buffer) and phBuffer:row-state = row-created then  
            phBuffer = phbuffer:after-buffer.
          
        cDbKeys = GetDataSourceKeys(phDbBuffer).
         
        cAnd = " where".
        if cDbKeys = 'rowid' then 
        do:
            undo, throw new IllegalStateError(subst("Cannot find a unique record for class &1 because the database table key is rowid. A unique key consisting of field name(s) must be defined. This can be done in a GetDataSourceKeys override in the class.", this-object:GetClass():TypeName)).
        end.    
         
        do i = 1 to num-entries(cDbKeys):
            assign
                cDbKey = subst("&1.&2",phDbBuffer:name,entry(i,cDbKeys))
                cKey   = SourceColumn(cDbKey)
                .
             // if the key is not mapped check if it is managed as a field object    
            if cKey = "" then 
            do: 
                undo, throw new IllegalStateError(subst("Database field &1 is not mapped and not defined as constant or proxy",cDbKey)).     
            end.
            else do:
                assign
                    hFld   = phBuffer:buffer-field(entry(2,cKey,"."))
                    cValue = hFld:buffer-value.
                     
                if hFld:data-type = "character" or hFld:data-type = "longchar" or hFld:data-type begins "date" then 
                    cValue = quoter(cValue).
                cFieldWhere = subst("&1 = &2",cDbKey,cValue).
            end.  
                   
            assign   
                cWhere = cWhere + subst("&1 &2",cAnd,cFieldWhere)
                cAnd   = " and"
                .        
        end.
      
        return cWhere.
    end.    
    
    method protected void FindSources(pLock as integer):
        define variable hBeforebuffer as handle no-undo.
        define variable i as integer no-undo.
        hBeforebuffer = BufferUtil:AssertAndGetBeforebuffer(DataBuffer).
        do i = 1 to extent(BufferHandles):
            FindSource(hBeforebuffer,BufferHandles[i],pLock).
        end.               
    end method.
    
    method public void Initialize(  ):
       
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
        oRequest = pRequest. 
        
        BufferHandles = GetBufferHandles(oRequest, pParentRequest).
        
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
            
            if valid-object(pParentRequest) then
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
        else  
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
    
    method protected void AddWarning(pcMsg as character):
        AddWarning(new Warning(pcmsg)). 
    end method.
    
    method protected void AddWarning(pcMsg as character, pcField as character):
        AddWarning(new Warning(pcmsg,pcField)). 
    end method.
    
    method protected void AddWarning(pWarning as IWarning):
        if not valid-object(Warnings) then
        do:
            Warnings = new List().
        end.    
        Warnings:Add(pWarning).
    end method.
    
    method protected void AddWarnings(pWarnings as ICollection):
        define variable oIter as IIterator no-undo.
        define variable oObject as Object no-undo.
        if not valid-object(Warnings) then
        do:
            Warnings = new List().
        end.    
        oIter = pWarnings:Iterator().
        do while oIter:HasNext():
            oObject = oIter:Next().
            if type-of(oObject,IWarning) = false then
                undo, throw new IllegalArgumentError(subst("Collection with &1 objects",oObject:GetClass():TypeName)). 
        end.     
        Warnings:AddAll(pWarnings).
    end method.
    
    method public override logical Prepare(  ):
        
      undo, throw new NotImplementedError( ).

    end method.
    
    // called from refreshBuffer - in order to use mapping and after row when refreshing data 
    method public IGetDataTableRequest PrepareCurrent( input phBuffer as handle, input pParentRequest as IGetDataTableRequest ):
        define variable oTableRequest as Pmfo.Core.BusinessLogic.IGetDataTableRequest no-undo.
        oTableRequest = GetFindCurrentRowRequest(phBuffer).
        Prepare(phBuffer,oTableRequest,pParentRequest).
        return oTableRequest.
    end method.

    method final public logical PrepareSave( phBuffer as handle,pUpdateRequest as IUpdateDataRequest ):
        DataBuffer = phBuffer.
        extent(BufferHandles) = ?.
        BufferHandles = GetSaveBufferHandles().
        PrepareSaveBuffer(phBuffer).   
        CreateSaveSource(phBuffer,FieldMap).
    end method. 
    
    // create the data-source and attach - override in subclass if cannot attach
    method protected void CreateSaveSource(phBuffer as handle, pcFieldMap as character):
        define variable i             as integer no-undo.
        define variable cHiddenFields as character no-undo.
        define variable cExcept       as character no-undo.
        define variable iJoinField    as integer no-undo.
        define variable lKeepattached as logical no-undo.
        
        if extent(BufferHandles) = ? or not valid-handle(BufferHandles[1])  then
            undo, throw new IllegalOperationError("CreateSaveSource in DataSource with no database buffers").
        if valid-object(DataSourcehandle) then
            delete object DataSourcehandle. 
        create data-source DataSourcehandle.
        
        do i = 1 to extent(BufferHandles):
            DataSourcehandle:add-source-buffer(BufferHandles[i],GetDataSourceKeys(BufferHandles[i])).
        end.    
        
        cHiddenFields = BufferUtil:GetHiddenFields(phBuffer).
        if lookup(BufferUtil:SeqFieldName,cHiddenFields) > 0 then 
            cHiddenFields = StringUtil:RemoveEntryFromList(BufferUtil:SeqFieldName,cHiddenFields).
         
        phBuffer:attach-data-source(DataSourceHandle,pcFieldMap,?).
        if cHiddenfields > "" then  
        do: 
           
             // DEFECT OCTA-39132 
             // - Case #:  01028213 - work around -
            // was decided to not be a bug, but it is quite problematic when having hidden fields
            // need to set both to supress the reset of before values 
            // for unchanged hidden fields different than db  
            // used in SaveRow
            // This requires logic in saverow to apply the current value to the afte table
            // if there are no changes - otherwise the value, which will be set from default
            // and not from client for hidden fields will be saved and override the data  
            DataSourceHandle:merge-by-field = false.
            DataSourceHandle:prefer-dataset = true.
           
        end.
                
    end method.
    
    method protected character GetDataSourceKeys ( pDatasourcebuffer as handle ):
        return pDatasourcebuffer:keys.
    end method.
    
    method protected handle extent GetSaveBufferHandles ():
        return GetBufferHandles().
    end method.

    method protected character GetRowErrorMessage(pcMessage as char,piState as integer):
        return pcMessage.
    end.    
    
    // create a temp buffer for a qualified field name for calls that uses datasource for schema info  
    method protected character GetUnpreparedFieldMap(pcDbColumn as character):
        define variable hBuffer as handle no-undo.
        if num-entries(pcDBColumn,".") = 2 then
        do: 
            if not valid-handle(Databuffer) then 
            do: 
                if extent(BufferHandles) = ? then
                do:
                    create buffer hbuffer for table entry(1,pcDBcolumn,".").
                    extent(BufferHandles) = 1.
                    BufferHandles[1] = hBuffer.
                end.   
                return getFieldMap().
            end.    
            else 
                undo, throw new IllegalOperationError("Call to GetUnpreparedFieldMap when prepared. Please Contact IT.").
        end.
        else 
            undo, throw new IllegalArgumentError("Unqualfied Db Column parameter. Please Contact IT.").
        
        finally:
            if valid-handle(hBuffer) then 
            do:
                delete object hBuffer.
                extent(BufferHandles) = ?.                  
            end.
        end.
    end. 
    
    
    method public void ValidateRow(phBeforeBuffer as handle, pEventType as ValidationHookEventType):
        define variable hDataset as handle no-undo.
        define variable hAfter   as handle no-undo.
        hDataset = phBeforebuffer:dataset.
        
    //    AssertHookEvent(pEventType).
        
        if phBeforeBuffer:row-state <> row-deleted then
        do:
            hAfter = phBeforeBuffer:after-buffer.
            hAfter:find-by-rowid(phBeforeBuffer:after-rowid).
        end.        
        
        case pEventType:
            when ValidationHookEventType:Begin then
                case phBeforeBuffer:row-state:
                    when row-deleted then
                        DeleteBeginTransValidate(input dataset-handle hDataset by-reference).
                    when row-modified then
                        WriteBeginTransValidate(input dataset-handle hDataset by-reference).
                    when row-created then
                        do:
                            CreateBeginTransValidate(input dataset-handle hDataset by-reference).
                            WriteBeginTransValidate(input dataset-handle hDataset by-reference).
                        end.
                end. // phBeforeBuffer:row-state 
            when ValidationHookEventType:End then
                case phBeforeBuffer:row-state:
                    when row-deleted then
                        DeleteEndTransValidate(input dataset-handle hDataset by-reference).
                    when row-modified then
                        WriteEndTransValidate(input dataset-handle hDataset by-reference).
                    when row-created then
                        do:
                            CreateEndTransValidate(input dataset-handle hDataset by-reference).
                            WriteEndTransValidate(input dataset-handle hDataset by-reference).
                        end.
                end. // phBeforeBuffer:row-state  
           
             
        end case. // pEventType   
            
    end method.
    
    method public logical SaveRow(phBeforeBuffer as handle):
        define variable lOk as logical no-undo.
        define variable cAllChanges as character no-undo.
        define variable cChanges as character no-undo.
        // save-row-changes for delete will optimistic lock check every field
        // FindAndCompareSource ignores the serialize-hidden fields
        if phBeforeBuffer:row-state = row-deleted then
        do: 
            // NoLobs is honored in the compare  
            FindAndCompareSource(phBeforeBuffer).
            lok = BufferHandle:buffer-delete().
            return lok.      
        end.
        else do:
            if phBeforebuffer:row-state = row-modified then
            do: 
                // CreateSaveSource sets prefer-dataset true and merge-by-field false  if there are any 
                // hidden fields  to workaround
                // DEFECT OCTA-39132 
                // - Case #:  01028213 - bug work around -
                // SAVE-ROW-CHANGES causes before table buffer to get updated with the values from the AFTER-BUFFER
                // changed to documentation bug...
                // so we need a workaround, and call FindAndCompareSource to check for changes since these settings
                // supresses optimistic lock from save-row-changes    
                if DataSourceHandle:prefer-dataset and DataSourceHandle:merge-by-field = false then
                do: 
                    FindAndCompareSource(phBeforeBuffer).
                    // save-row-changes will update all values, so hiddenfields witrh no changes
                    // will get the default value
                    // - so if the before and after is the same set after from the DB 
                    //   so that it does not overwrite                        
                    ApplyHiddenFieldsValuesFromDB(phBeforebuffer,BufferHandle).
                end.   
            end.     
            lok = phBeforeBuffer:save-row-changes(1,"",NoLobs). 
        end.
 
        catch e1 as ConflictError:
            undo, throw e1.
        end.
        catch e2 as class Error:
            SaveRowErrorHandler(e2, phBeforeBuffer, UpdateSource,cAllChanges).
        end.
         
    end method.
    
    method public void DatasetTransactionEnd( input dataset-handle phDataset ).
    end method.
    
    method protected void SaveRowErrorHandler  (pe as Error, phBeforeBuffer as handle, piSource as integer, pcChanges as character):
        define variable cMsg              as character no-undo.
        define variable cField            as character no-undo.
        define variable hField            as handle no-undo.
        define variable cKeyExpression    as character no-undo.
        define variable hDataFields       as handle extent no-undo.
        define variable hSourceFields     as handle extent no-undo.
        define variable cChanges          as character no-undo.
        
        // don't  wrap illlegalstate  
        if type-of(pe,IllegalStateError) then 
            undo, throw pe. 
        cMsg = pe:GetMessage(1).
        
        if piSource > 0 then 
        do: 
            //cMsg = right-trim(replace(cMsg,subst("(&1)",pe:GetMessageNum(1)),"")).
            case pe:GetMessageNum(1):
                // lead attributes due to invalid handle and bad data-source-complete ref errors then throw as-is to get full staclk 
                when 10068 or when 12780 then 
                    undo, throw pe.
                
                when 11894  then // KEYS phrase for data source buffer <db buffer> contains ROWID and no filed in <before image table> is mapped to the rowid durng attach source                          
                    do: 
                        cMsg = subst("Cannot save &1 changes ",BufferUtil:GetRowName(DataBuffer))
                            + subst("because the database table key is rowid. A unique key consisting of field name(s) must be defined. This can be done in a GetDataSourceKeys override in the &1 DataSource.",
                            this-object:GetClass():TypeName).
                    end.    
                when 11913  then // SAVE-ROW-CHANGES found <name> record with conflicting change by another user. (11913) 
                    do on error undo, throw: 
                        Databuffer:find-by-rowid (phBeforeBuffer:after-rowid).
                        FindSources(exclusive-lock).
                    
                        cChanges = CompareBufferWithDb(phBeforeBuffer, "",true, output hDataFields, output hSourceFields).
                    
                        if cChanges > "" then 
                            StringUtil:AppendEntry(pcChanges, cChanges). 
                    
                        if pcChanges > "" then     
                            ThrowConflictError(phBeforebuffer,BufferUtil:GetFieldLabels(Databuffer,pcChanges)).
                        else
                            ThrowConflictError(phBeforebuffer).  
                        catch e1 as ConflictError :
                            undo, throw e1.
                        end.
                        catch e2 as Progress.Lang.Error :
                            BufferError(phBeforeBuffer, GetRowErrorMessage(e2:GetMessage(1),phBeforeBuffer:row-state)).
                        end catch.     
                    end.    
                when 132  then 
                    do: //** <file-name> already exists with <field/value...>. (132) 
                        cMsg = GetPublicAlreadyExistsMessage(cmsg, phBeforebuffer, piSource).
                    end.
                when 138 // <file-name> record not on file
                or 
                when 11912 /* Unable to find record for db buffer <name> during SAVE-ROW-CHANGES. */ then 
                    do: //** <file-name> record not on file. (132)
                    // use the QueryUtil to get the QueryPredicate:ToString(buffer,useserializename)
                        cKeyExpression = cast(QueryUtil:GetCurrentRowKeyEntry(phBeforeBuffer),Pmfo.Core.BusinessLogic.IQueryEntry):ToString(phBeforeBuffer,true).
                        cMsg = subst("&1 where &2 does not exist",BufferUtil:GetRowName(phBeforeBuffer,true),cKeyExpression).
                    end.
                when 275 or when 110 then 
                    do: // ** <Field-name> is mandatory, but has a value of ?. (275)
                     // ** <file-name>.<field-name> is mandatory, but has unknown (?) value. (110). 
                        cField = entry(2,cMsg," ").
                        if num-entries(cField,".") > 1 then 
                            cField = entry(2,CField,".").
                    
                        hfield = phBeforebuffer:buffer-field(cField) no-error.
                        if valid-handle(hField) then
                        do:
                            entry(2,cMsg," ") = BufferUtil:GetFieldLabel(hField).
                        end.     
                    end.
                otherwise do:
                    // DataAccess jcjust return "ERROR" as string if dataset error, so make sure
                    // the error is added to the buffer to reach the client
                    // (TODO? num-messages? probably not important as the secondary ABL messages are typically not helpful   
                    if phBeforeBuffer:dataset:error then
                        cMsg = pe:GetMessage(1).
                    else     
                        undo, throw pe.
                end.       
            end.
        end.
        BufferError(phBeforeBuffer, GetRowErrorMessage(cMsg,phBeforeBuffer:row-state)).
    end method.
    
    
    method protected character CompareBufferWithDb(phBuffer as handle, pcFields as character,plHonorExceptFields as logical):
        define variable hDummy1 as handle extent no-undo.
        define variable hDummy2 as handle extent no-undo.
        
        return CompareBufferWithDb(phBuffer,pcfields,plHonorExceptFields,output hdummy1, output hDummy2). 
    end method.
    
    method protected character CompareBufferWithDb(phBuffer as handle,pcfields as character, plHonorExceptFields as logical, output phDataFields as handle extent, output phSourceFields as handle extent ):
        define variable cFieldMaps        as character extent no-undo.
        define variable cExceptLists      as character extent no-undo.
        define variable i                 as integer          no-undo.
        define variable cHiddenFields     as character no-undo.
        define variable cLobs             as character no-undo.
        define variable iLob              as integer no-undo.
        define variable cLobField         as character no-undo.
        define variable cChanges          as character no-undo.
        define variable cBufferChanges    as character no-undo.
        define variable cProxyChanges     as character no-undo.
        define variable hBeforebuffer     as handle no-undo.
        define variable hDatafields       as handle extent no-undo.
        define variable hSourcefields     as handle extent no-undo.
        define variable hDatafieldsWork   as handle extent no-undo.
        define variable hSourcefieldswork as handle extent no-undo.
        define variable cMetricChanges    as character no-undo.
        define variable cExceptFields     as character no-undo.
        if not phBuffer:avail then
            undo, throw new IllegalStateError(subst("Buffer '&1' is not available",phBuffer:name)).
      
        if not BufferHandle:avail then
            undo, throw new IllegalStateError(subst("Database table '&1' is not available",BufferHandle:name)).
        // @TODO - test and fix the following 
        // the field maps is likely not necessary since buffer compare uses the attach field map if 
        // one buffer is dataset buffer and the other is datasource buffer 
        
        SplitFieldMap(FieldMap, output cFieldMaps,output cExceptLists).        
        cHiddenFields = BufferUtil:GetHiddenFields(phBuffer).
        if plHonorExceptFields then 
            cExceptFields = OptimisticLockExceptFields.
        
        if NoLobs then 
            cLobs = GetLobFields().  
        
        do i = 1 to extent(BufferHandles):
            if BufferHandle = BufferHandles[i] then
            do: 
                cExceptLists[i] = trim(cExceptLists[i] + "," + cHiddenFields,",").
                if cExceptFields > "" then
                   cExceptLists[i] = trim(cExceptLists[i] + "," + cExceptFields,",").
                if NoLobs and cLobs > "" then 
                do iLob = 1 to num-entries(cLobs): 
                    cLobField = entry(iLob,cLobs).
                    if lookup(cLobField,cExceptLists[i]) = 0 then
                        cExceptLists[i] = cExceptLists[i] 
                            + (if cExceptLists[i] = "" then "" else ",") 
                            + cLobField.
                end.
                     
                if phBuffer:buffer-compare(BufferHandle,"case-sensitive",cExceptLists[i] ,cFieldMaps[i]) = false then
                do:
                    extent(hDataFields) = ?.
                    extent(hSourceFields) = ?.
                    
                    // if sonething is different return the field names  
                    cBufferChanges = BufferUtil:CompareFields(phBuffer, BufferHandle, cExceptLists[i],pcfields, output hDataFields, output hSourceFields).
                     
                    if cBufferChanges > "" then
                    do:
                        cChanges = left-trim(subst("&1,&2",cChanges,cBufferChanges),",").
                        if extent(phdatafields) > 0 then
                        do:
                            assign
                                extent(hDataFieldsWork) = ?
                                extent(hSourceFieldsWork) = ?
                                hDataFieldsWork = phDataFields
                                hSourcefieldswork = phSourceFields
                                extent(phDataFields) = ?
                                extent(phSourceFields) = ?
                                phDataFields   = Array:mergeArrays(hDataFieldsWork, hDataFields)
                                phSourceFields = Array:mergeArrays(hSourceFieldsWork, hSourceFields)
                                .
                        end.
                        else 
                            assign                        
                                phDataFields = hDatafields
                                phSourceFields = hSourcefields
                                .
                    end.    
                end.
            end.    
        end.
        return cChanges.  
    end method.
    
    method protected void SplitFieldMap(pcFieldMap as character, output pcFieldPairs as character extent, output pcExceptList as character extent):
        define variable cMaps as character extent no-undo.
        define variable i as integer no-undo.
        define variable j as integer no-undo.
        define variable cTTField  as character no-undo.
        define variable cDbField  as character no-undo.
        define variable cDbTable  as character no-undo.
        define variable iTable    as integer no-undo.
        define variable iArrayPos as integer no-undo.
        extent(pcFieldPairs) = extent(BufferHandles).
        extent(pcExceptList) = extent(BufferHandles).
        if pcFieldMap > "" then
        do i = 1 to num-entries(pcFieldMap) by 2:
            assign
                cTTField = entry(i,pcFieldMap)
                cDbField = entry(i + 1,pcFieldMap)
                cDbTable = if num-entries(cDbField,".") = 2 then entry(1,cDbField,".") 
                           else if cDbField begins "rowid(" then StringUtil:ExtractParenthesis(cDbField,true) 
                           else BufferName
                iTable = lookup(cDbTable,BufferNames)
                pcFieldPairs[iTable] = pcFieldPairs[iTable] 
                              + (if pcFieldPairs[iTable] = "" then "" else ",")
                              + cTTField
                              + ","
                              + cDbField.
            // we must put all mapped fields in except list for other tables for buffer-copy to work like fill 
            exceptloop:
            do j = 1 to extent(pcExceptList):
                if j <> iTable then   
                do:
                    iArrayPos = index(cTtField,"[").  
                    if iArrayPos > 0 then
                    do:
                        cTTField = substring(cTTField,1,iArrayPos - 1).
                        if lookup(cTTField,pcExceptList[j]) > 0 then 
                            next exceptloop.
                    end.    
                    pcExceptList[j] = pcExceptList[j]
                        + (if pcExceptList[j] = "" then "" else ",") 
                        + cTtField.
                end.                                     
            end.     
        end. 
    end.    
    
    // hidden fields are not attached and prefer-dataset and DataSourceHandle:merge-by-field is set to true 
    // to ensure before values are not overridden in save-row-changes 
    // see comments in SaveRow  about-DataSourceHandle:prefer-dataset
    // This method ensures that hdiden fields that actually have been changed in the BE are saved  
    method private void ApplyHiddenFieldsValuesFromDB(phBeforeBuffer as handle, phDbSource as handle):
        define variable cHiddenFields as character no-undo.
        define variable i             as integer no-undo.
        define variable hField        as handle no-undo.
        define variable hBeforeField  as handle no-undo.
        define variable cDbField      as character no-undo.
        define variable hDbField      as handle no-undo.
        define variable hBuffer       as handle no-undo.
        define variable cField        as character no-undo.
        define variable iArrayPos     as integer no-undo.
        define variable iExtent       as integer no-undo.
        // annoying behavior - the record is lost during save-row-changes  
        hBuffer = phBeforebuffer:after-buffer. 
        hBuffer:find-by-rowid (phBeforebuffer:after-rowid).  
        cHiddenFields = BufferUtil:GetHiddenFields(hBuffer).
                
        do i = 1 to num-entries(cHiddenFields):
            cField = entry(i,CHiddenFields). 
            // skip the seqence - not really a problem since there will be no db field.. 
            if cField <> BufferUtil:SeqFieldName then
            do: 
                hField       = hBuffer:buffer-field(entry(i,CHiddenFields)).
                hBeforeField = phBeforebuffer:buffer-field(entry(i,CHiddenFields)).
                if hField:buffer-value = hBeforeField:buffer-value then
                do:  
                    cDbField = StringUtil:GetMappedName(subst("&1.&2",hBuffer:name,hField:name),hBuffer:data-source-complete-map).
                    if cDbField > "" and cDbField begins BufferHandle:name + "." then
                    do:
                        iArrayPos = index(cDbField,"[").  
                        if iArrayPos > 0 then
                        do:
                            iExtent = integer(right-trim(substring(cDbField,iArrayPos + 1),"]")).
                            cDbField = substring(cDbField,1,iArrayPos - 1).
                        end.
                        hDbfield = BufferHandle:buffer-field(entry(2,cDbField,".")) no-error.   
                        if valid-handle(hDBField) then 
                            hField:buffer-value = hDbField:buffer-value(IarrayPos).                             
                    end.         
                end.
            end.  
        end.    
    end method. 
    
    method protected handle GetAndAssertErrorBuffer():
        if DataBuffer:before-buffer:avail and DataBuffer:before-buffer:row-state = row-deleted then
            return DataBuffer:before-buffer.
        else if DataBuffer:Avail = false then
        do:
            undo, throw new IllegalOperationError(subst("Error in error handling: Buffer '&1' is not available",DataBuffer:name)).
        end.         
        return DataBuffer.    
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
    
    method protected character GetLobFields ():
        define variable i       as integer no-undo.
        define variable cFields as character no-undo.
        define variable hFld    as handle no-undo. 
        do i = 1 to DataBuffer:num-fields:
            hFld = Databuffer:buffer-field(i).
            if hFld:data-type = "BLOB" or hFld:data-type = "CLOB" then 
                cFields = cFields 
                    + (if cFields = "" then "" else ",")
                    + hFld:name. 
        end.    
        return cFields.
        
    end method.
    
    
     // allow subclasses to customize alreayd exists error - default to replace db table with GetRowname the 
    method protected character GetPublicAlreadyExistsMessage(pcMessage as character,phBeforebuffer as handle, piSource as integer):
        return replace(pcMessage,BufferHandles[piSource]:name,BufferUtil:GetRowName(phBeforeBuffer)).
    end method.
    
    method protected void ThrowConflictError(phBeforebuffer as handle):
        undo, throw new ConflictError(phBeforeBuffer). 
    end method.    
    
    method protected void ThrowConflictError(phBeforebuffer as handle,pcchanges as character):
        undo, throw new ConflictError(phBeforeBuffer,pcChanges). 
    end method. 
      
    method protected void BufferError(hBuffer as handle,pcMsg as character):
        ErrorStringUtil:AddError(hBuffer, pcMsg).
    end method.    
    
    method protected void BufferError(hBuffer as handle,pcMsg as character, pcField as character):
        ErrorStringUtil:AddError(hBuffer, pcMsg, pcField).
    end method.    
    
    method protected void ThrowBufferError(hBuffer as handle,pcMsg as character):
        ErrorStringUtil:AddError(hBuffer, pcMsg).
        undo, throw new TransactionError().
    end method. 
    
    method protected void ThrowBufferError(hBuffer as handle,pcMsg as character, pcField as character):
        ErrorStringUtil:AddError(hBuffer, pcMsg, pcField).
        undo, throw new TransactionError().
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
        define variable cProxyColumn as character no-undo.
        define variable cColumnName as character no-undo.
        define variable cMappedName as character no-undo.
        
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
        oSort[1] = pSort.
        return oSort.     
    end method.   
    
    // implements IDataSourceMap interface used by QueryBuilder map query 
    // override to change expression completely or return ? to ignore   
    method public IQueryEntry ColumnExpression(pPredicate as IQueryPredicate):
        return pPredicate. 
    end method.   
    
    // hook
    method protected void CreateBeginTransValidate(input dataset-handle phDataset):
    end method.    
    
    // hook
    method protected void CreateEndTransValidate(input dataset-handle phDataset):
    end method.    
    
    // hook
    method protected void WriteBeginTransValidate(input dataset-handle phDataset):
    end method.    
   
    // hook
    method protected void WriteEndTransValidate(input dataset-handle phDataset):
    end method.
   
    // hook 
    method protected void DeleteBeginTransValidate(input dataset-handle phDataset):
    end method.    
    
    // hook
    method protected void DeleteEndTransValidate(input dataset-handle phDataset):
    end method.     
end class.