 
 /*------------------------------------------------------------------------
    File        : DataAccess
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using Ccs.BusinessLogic.CommitScopeEnum from propath.
using Ccs.Common.Application from propath.
using OpenEdge.BusinessLogic.UpdateDataRequest from propath.
using OpenEdge.Core.Assert from propath.
using OpenEdge.Core.Collections.IIterator from propath.
using OpenEdge.Core.Collections.IMap from propath.
using OpenEdge.Core.Collections.Map from propath.
using OpenEdge.Core.String from propath.
using OpenEdge.Core.WidgetHandle from propath.
using Pmfo.Core.BusinessLogic.GetDataRequest from propath.
using Pmfo.Core.BusinessLogic.GetDataResponse from propath.
using Pmfo.Core.BusinessLogic.GetDataTableResponse from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.Common.DataService from propath.
using Pmfo.Core.Common.LifecycleScope from propath.
using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Core.DataLayer.IDataAccess from propath.
using Pmfo.Core.DataLayer.IDataSource from propath.
using Pmfo.Core.DataLayer.IUpdateTarget from propath.
using Pmfo.Core.DataLayer.Update.ITransactionManager from propath.
using Pmfo.Core.DataLayer.Update.TransactionManager from propath.
using Pmfo.Core.Error.ApplicationError from propath.
using Pmfo.Core.Error.ConflictError from propath.
using Pmfo.Core.Error.IllegalOperationError from propath.
using Pmfo.Core.Error.LockTimeOutError from propath.
using Pmfo.Core.Error.NotFoundError from propath.
using Pmfo.Core.Error.NotImplementedError from propath.
using Pmfo.Core.Error.QueryTimeOutError from propath.
using Pmfo.Core.Error.RefreshError from propath.
using Pmfo.Core.Error.RequestTimeOutError from propath.
using Pmfo.Core.Error.ValidationError from propath.
using Pmfo.Core.Manager.IServiceManager from propath.
using Pmfo.Core.Manager.ISessionManager from propath.
using Pmfo.Util.BufferUtil from propath.
using Pmfo.Util.StringUtil from propath.
using Progress.Lang.Error from propath.
using Progress.Lang.Object from propath.
using OpenEdge.Core.Collections.ICollection from propath.
using Pmfo.Core.Common.IWarning from propath.
 

class Pmfo.Core.DataLayer.DataAccess abstract inherits DataService implements IDataAccess: 
    {Pmfo/Core/schema/warning.i}
     
    /* Event published before update starts. 
       DataSources may subscribe to this for example to change row-state  
    */
    define public event BeforeUpdate signature void (input dataset-handle phDataset). 
    
    define protected property DataSourceMap as IMap no-undo 
        get():
            if not valid-object(DataSourceMap) then 
                DataSourceMap = new Map().
            return DataSourceMap.    
        end.     
        set.
    
    
     /* Event published after update is done. 
       DataSources may subscribe to this for example check or change errors   
     */
    define public event AfterUpdate signature void (input dataset-handle phDataset). 
    
     
    define public abstract property Resource as character no-undo  
       get.
    
    define protected property DatasetHandle as handle get. 
       set(ph as handle):
           if valid-handle(DatasetHandle) and DatasetHandle <> ph then
               delete object DatasetHandle no-error.
           DatasetHandle = ph.    
       end.
   
    method override public void Destroy(  ):
    end method.
    
    method override public void Initialize(  ):
        
    end method.
    
    method public IGetDataResponse FetchData( input poRequest as IGetDataRequest, input-output dataset-handle phDataset ):
        define variable oDataSources       as IDataSource extent no-undo.
        
        define variable oTableResponses    as GetDataTableResponse  extent no-undo.
        define variable i                  as integer no-undo. 
        define variable iStopAfter         as integer no-undo.
        
        DatasetHandle = phDataset. // setter and destructor avoid memory leak
        
        StartDataSources(poRequest,phDataset).
        
        iStopAfter = poRequest:timeout no-error.
        
        if iStopAfter = 0 or iStopAfter = ?  then  
            iStopAfter = cast(Application:SessionManager,ISessionManager):QueryTimeout.
        
        do stop-after iStopAfter:
            this-object:Fill(phDataset).      
        end.
        
        oDataSources = cast(DataSourceMap:Values:ToArray(),IDataSource).
        extent(oTableResponses) = extent(oDataSources).
        do i = 1 to extent(oDataSources).
            oTableResponses[i] = new GetDataTableResponse(oDataSources[i]:DataBuffer:table-handle:name).
            if oDataSources[i]:NumRecords > 0 then 
            do:
                oTableResponses[i]:NextPagingContext = oDataSources[i]:NextRowKey.
            end.
            if oDataSources[i]:TotalCount > 0 then 
            do:
                oTableResponses[i]:NumResults = oDataSources[i]:TotalCount.
            end.
        end.   
       
        return new GetDataResponse(oTableResponses).          
        
        catch eStopAfter as Progress.Lang.StopAfter:
            undo, throw new QueryTimeOutError(eStopAfter,iStopAfter).        
        end catch.
        
        catch eConflictStop as Progress.Lang.LockConflict :
            undo, throw new LockTimeOutError("query",eConflictStop).    
        end catch.
        
        catch eStop as Progress.Lang.StopError :
            undo, throw new ApplicationError("Stop condition encountered during fetch of data. Errors may have been written to log. Please Contact IT",eStop).    
        end catch.

        finally:
            DataSourceMap:Clear().
        end finally.     
    end method.
    
    
    method protected void Fill(phDataset as handle):
        define variable StringKey as String no-undo.
        define variable oSource  as DataSource no-undo.
        define variable lOk as logical no-undo.
        lok = phdataset:fill(). // no way to suppress error
        if not lok then do:
           phDataset:empty-dataset.
           ThrowFillErrors(phDataset).
        end. 
    end method.  
    
    method protected void ThrowFillErrors (phDataset as handle):
        define variable oDataSources   as IDataSource extent no-undo.
        define variable oIterator      as IIterator no-undo.
        define variable oErrorIterator as IIterator no-undo.
        define variable oError         as Error no-undo.
        define variable oManyError     as ApplicationError no-undo.
        define variable iCount         as integer no-undo.
        define variable cMsg           as character no-undo.    
        define variable i as integer no-undo.
           
        oDataSources = cast(DataSourceMap:Values:ToArray(),IDataSource).
          
        cMsg = subst("Read of &1 failed",if phDataset:serialize-name > "" then quoter(phDataset:serialize-name) else "data").
        
        oManyError = new ApplicationError(cMsg).
        
        do i = 1 to extent(oDataSources):
            if valid-object(oDataSources[i]:FillErrors) then 
            do:
                oErrorIterator = oDataSources[i]:FillErrors:Iterator().
                do while oErrorIterator:HasNext():
                   oError = cast(oErrorIterator:Next(),Error).
                   iCount = iCount + 1.
                   oManyError:AddMessage(oError:GetMessage(1),oError:GetMessageNum(1)).
                end.
            end.
        end.
        if iCount = 1 then
        do:
            if type-of(oError,ApplicationError) then 
                undo, throw new ApplicationError(subst("&1. &2",cMsg,cast(oError,ApplicationError):GetStrippedMessage()),oError).
            else   
                undo, throw new ApplicationError(subst("&1. &2",cMsg,oError:GetMessage(1)),oError).
        end.    
        else if iCount = 0 then
            undo, throw new ApplicationError(subst("&1. &2",cMsg,"The errors have been written to the log. Please Contact IT.")).
        else  
            undo, throw oManyError.   
    end method.    
    
     
    method protected void StartSaveSources(poRequest as IUpdateDataRequest,phDataset as handle):
        define variable hBuffer         as handle      no-undo.
        define variable i               as integer     no-undo.
        define variable cNoTargetTables as character   no-undo.
        define variable oUpdateTarget   as IUpdateTarget no-undo.
        define variable oDataSource     as IDataSource no-undo.
        
        if type-of(poRequest,Pmfo.Core.BusinessLogic.IUpdateDataRequest) then
            cNoTargetTables = poRequest:NoTargetTables.     
        
        
        do i = 1 to phDataset:num-buffers:
            oUpdateTarget = ?.
            oDataSource   = ?.
            hBuffer = phDataset:get-buffer-handle(i).
             
            // This is too drastic - there are DS objects that retrieves other DS from GetDataSourceMap and they do not check if the class is valid
            // and they should no need to - 
            // The use of the map would need to be replaced with a class that can start sources as is done when using the client data manager 
            // BUT the startup is more complex here since prepare depends on parent          
            /// if (hbuffer:table-handle:has-records or (valid-handle(hbuffer:table-handle:before-table) and hbuffer:table-handle:before-table:has-records)) 
            // and 
            
            if cNoTargetTables = "" or lookup(hbuffer:table-handle:name,cNoTargetTables) = 0 then 
            do: 
                do on error undo, throw: 
                    oUpdateTarget = CreateSaveSource(hBuffer:table-handle:serialize-name).
                    catch e as Progress.Lang.Error :
                        // Ignore error could be a datasource - try again below. 
                        // As of current IUpdateTarget inherit IDataSources so if it is not
                        // found here it would not be found below either, but keep the independency 
                        
                    end catch.
                end.
                
                // Current DataSource implements both IDataSoyrce and IUpdateTargetsm 
                // but keep this code so that they could be separate interfaces in future  
                // We still want to start IDataSoirce since it would be a parent of \
                // updatetargets if in this dataset              
                if valid-object(oUpdateTarget) then 
                do:
                    BeforeUpdate:Subscribe(oUpdateTarget:BeforeUpdate).
                    AfterUpdate:Subscribe(oUpdateTarget:AfterUpdate).
                    
                    oUpdateTarget:PrepareSave(hBuffer,poRequest).
                    oDataSource = oUpdateTarget.
                end.    
                
                if not valid-object(oDataSource) then
                    oDataSource = CreateDataSource(hBuffer:table-handle:serialize-name).
                DataSourceMap:Put(new WidgetHandle(hBuffer), oDataSource).
            end. // has data and not in NOTargetTab;es 
        end.   
    end method.     
    
    method protected IUpdateTarget CreateSaveSource(pcName as character):
        return cast(Application:ServiceManager,IServiceManager):CreateUpdateTarget(pcName).
    end method.
    
    method protected IDataSource CreateDataSource(pcname as character):
        return cast(Application:ServiceManager,IServiceManager):CreateDataSource(pcName).
    end method.
        
    // override to handle named query
    method protected void StartDataSources(poRequest as IGetDataRequest, phDataset as handle):
        define variable i              as integer   no-undo.
        define variable hBuffer        as handle    no-undo.
       
        define variable iBuffer        as integer   no-undo.
        define variable cErrorTables   as character no-undo.
        define variable lClientOnly    as logical no-undo.
        define variable lOk            as logical no-undo.
        define variable hTopBuffers    as handle extent no-undo.
        define variable oDataSource    as IDataSource no-undo.
        
       // oDataSourceMap = GetDataSourceMap(phDataset).
         
        extent(hTopBuffers) = phDataset:num-top-buffers.
        
        // prepare may deactivate relation and add the buffer as top-buffer, so
        // keep track of the original top buffers to avoid preparing twice          
        do i = 1 to phDataset:num-top-buffers:
            hTopBuffers[i] = phDataset:get-top-buffer(i).
        end.
       
        do i = 1 to extent(hTopBuffers):
            StartDataSource(hTopBuffers[i],poRequest,?).
        end.    
        
        // check that at least one top table have a datasource   
        // we don't enforce requests for all top tables.
        // this will catch an unlikely case of no TableRequests sonce the size will be zerp and the extent ?
        if DataSourceMap:Size <> extent(poRequest:TableRequests) then
        do:
            do iBuffer = 1 to phDataset:num-top-buffers:
                if DataSourceMap:ContainsKey(new WidgetHandle(phDataset:get-top-buffer(iBuffer))) then
                do:
                    lok = true.
                    lClientOnly = false.
                    leave.
                end.
                else do:
                    cErrorTables = cErrorTables
                                 + (if cErrorTables = "" then "" else ",")
                                + phDataset:get-top-buffer(iBuffer):table-handle:name.
                end.
            end.
            if not lok then
            do:
                if lClientOnly then
                    undo, throw new IllegalOperationError("The GetDataRequest top table requests(s) are all Client Only requests").
                else
                    undo, throw new IllegalOperationError(subst("The GetDataRequest is missing request&1 for &2 top table&1 &3 in the dataset",
                                                            if num-entries(cErrorTables) = 1 then "" else "s",
                                                            if num-entries(cErrorTables) = 1 then "the" else "all",
                                                            StringUtil:GetMessageFromEntries(cErrorTables))).
            end.
        end.
    end method.    
    
    
    method protected IDataSource StartDataSource( phBuffer as handle,poRequest as IGetDataRequest,poParentTableRequest as IGetDataTableRequest):
    
        define variable oDataSource    as IDataSource no-undo.
        define variable oTableRequest  as IGetDataTableRequest  no-undo.
        define variable iChild         as integer no-undo. 
        define variable iBuffer        as integer no-undo.
        define variable hRelation      as handle no-undo.
        define variable lok            as logical no-undo.
        
        oTableRequest = GetDataTableRequest(poRequest,phBuffer).
        if valid-object(oTableRequest) then 
        do:    
            oDataSource = CreateDataSource(phBuffer:table-handle:serialize-name).
           
            if not valid-object(oDatasource) then 
                undo, throw new NotFoundError(subst("DataSource '&1'",phBuffer:serialize-name)).
                
            DataSourceMap:put(new WidgetHandle(phBuffer),oDataSource). 
            
           // DataSources:Put(new String(phBuffer:table-handle:name), oDataSource).
         
            if valid-object (poParentTableRequest) then 
                lok = oDataSource:Prepare(phBuffer,oTableRequest,poParentTableRequest).
            else
                lok = oDataSource:Prepare(phBuffer,oTableRequest).
            if lok then  
            do iChild = 1 to phBuffer:num-child-relations:
                hRelation = phBuffer:get-child-relation(iChild).
                // reposition is also a top-buffer so skip it here
                // the repos table does not use the parent relation in fill
                if hRelation:reposition = false and hRelation:recursive = false then
                    StartDataSource(hRelation:child-buffer,poRequest,oTableRequest).
            end.
            else 
                phBuffer:fill-mode = "no-fill".
                
        end. 
        else  // allow skip of top table - there will be a check to see that we have at least one  
            phBuffer:fill-mode = "no-fill".
         
        return oDataSource.
    end method.
    
    method protected IGetDataTableRequest GetDataTableRequest(pDataRequest as IGetDataRequest, phHandle as handle):
        define variable i as integer no-undo.
        define variable oTableRequest as IGetDataTableRequest no-undo.
        Assert:NotNull(pdataRequest,"Data Request passed to GetDataTableRequest").
        Assert:NotNull(phHandle,"Buffer or table-handle passed to GetDataTableRequest").
         
        if type-of(pDataRequest,GetDataRequest) then
        do:
            oTableRequest = pDataRequest:GetTableRequest(input phHandle).
        end.   
        else do i = 1 to extent(pDataRequest:TableRequests):
            case phHandle:type:
                when "buffer" then
                do:
                    if phHandle:table-handle:name = pDataRequest:TableRequests[i]:TableName then
                        oTableRequest =  pDataRequest:TableRequests[i].
                end.
                when "temp-table" then 
                do:
                    if phHandle:name = pDataRequest:TableRequests[i]:TableName then
                        oTableRequest = pDataRequest:TableRequests[i].
                end.         
            end case.
        end.                 
        return oTableRequest.
    end.  
      
    
    method public Object SubmitData( input poRequest as IUpdateDataRequest, input-output dataset-handle phDataset, output table-handle phWarning ):
        define variable hBuffer              as handle no-undo.
        define variable oRequestKey          as String no-undo.
        define variable lOk                  as logical no-undo.
        define variable oTransactionManager  as ITransactionManager no-undo.

        define variable lCanExecuteAsTransaction as logical no-undo.
        // error - failed validation that has not beem caught on client  
        //         so make sure they are thrown and shown to user 
        if phDataset:error then 
            undo, throw new ValidationError(). 
        
        // setter and destructor for DatasetHandle to avoid memory leak 
        // it cannot be deleted here since the method is not final and can be (and is) overridden 
        DatasetHandle = phDataset.  
        
        if not valid-object(poRequest:CommitScope) then 
            assign cast(poRequest,UpdateDataRequest):CommitScope = CommitScopeEnum:All.
        
        StartSaveSources(poRequest,phDataset). 
                   
        BeforeUpdate:publish(input dataset-handle  phdataset by-reference).
        
        if CommitScopeEnum:Nested:Equals(poRequest:CommitScope) then
             undo, throw new NotImplementedError("Support for Commit Scope Nested").
        else   
             oTransactionManager = new TransactionManager(DataSourceMap,poRequest).
        
        if valid-object(oTransactionManager) then
        do:
           // if valid-handle(phInfrastructureDataset) then 
            //    oTransactionManager:ProcessInfrastructureData:subscribe(ProcessInfrastuctureDataset).
            // validate and save all records 
            oTransactionManager:ProcessDataset(phdataset).
        end.
        
        do on error undo, throw:
            RefreshBuffers(DatasetHandle).
            catch e as Progress.Lang.Error :
                undo, throw new RefreshError(e).    
            end catch.
        end. 
        AfterUpdate:publish(input dataset-handle phdataset by-reference).
        
        CollectWarnings(cast(DataSourceMap:Values:ToArray(),IDataSource)).
        phWarning  = temp-table ttWarning:handle. 
        
         // bug workarond dataet:error is not detected on client when by-reference is used
        if phDataset:error then
            return new String("Error").
         
               
        catch eConflict as ConflictError :
            undo, throw eConflict.
        end catch.
        
        catch e as Progress.Lang.Error:
            if not phDataset:Error then 
                undo, throw e.
            return new String("Error").
        end catch.
        
        // Catch Progress.Lang.Stop errors since we use -catchStop 1
        catch eConflictStop as Progress.Lang.LockConflict :
            undo, throw new LockTimeOutError(eConflictStop).    
        end catch.
        catch eStopAfter as Progress.Lang.StopAfter :
            undo, throw new RequestTimeOutError("update",eStopAfter).    
        end catch.
        
        finally:
            DataSourceMap:Clear().
        end finally.   
    end method.
    
            
    method public void RefreshBuffers(phDataset as handle):
        define variable i as integer no-undo.
        do i = 1 to phDataset:num-top-buffers:
            RefreshBuffer(phDataset,phDataset:get-top-buffer(i),?).
        end.
        
    end method.     
    
    method protected void CollectWarnings (pDataSources as IDataSource  extent ):
        define variable oDataSources as IDataSource no-undo.
        define variable i as integer no-undo.
        do i = 1 to extent(pDataSources):
            if valid-object(pDataSources[i]:Warnings) then 
                CollectWarnings(pDataSources[i]:Warnings, pDataSources[i]:EntityName).
        end.
    end method.    
    
    method protected void CollectWarnings (pWarnings as ICollection, pcEntity as character):
        define variable iWarning     as integer no-undo.
        define variable oIterator    as IIterator no-undo.
        define variable oMsgIterator as IIterator no-undo.
        define variable oWarning     as IWarning no-undo.
        
        for each ttWarning by ttWarning.Seq descending.
            iWarning = ttWarning.seq.
            leave.
        end.
       
        oMsgIterator = pWarnings:Iterator().
        do while oMsgIterator:HasNext():
            create ttWArning.
            assign 
                oWarning = cast(oMsgIterator:Next(),IWarning)
                iWarning = iWarning + 1 
                ttWarning.entity    =pcEntity
                ttWarning.seq       = iWarning
                ttWarning.msg       = oWarning:Message
                ttWarning.fieldName = oWarning:FieldName
                .
        end.
        
    end method.    
    
    method public void RefreshBuffer(phDataset as handle,phBuffer as handle, poParentRequest as IGetDataTableRequest):
        define variable hQuery         as handle no-undo.
        define variable oDataSource    as IDataSource no-undo.
        define variable iChild         as integer no-undo.
        define variable hChildBuffer   as handle no-undo.
        define variable hRelation      as handle no-undo.
        define variable lok            as logical no-undo.
        define variable oRequest       as IGetDataTableRequest no-undo.
        define variable cJoin          as character no-undo.     
        
        if phBuffer:table-handle:has-records then 
        do:
            oDataSource = cast(DataSourceMap:Get(new WidgetHandle(phBuffer)),IDataSource).
            if valid-object(oDataSource) then
            do:   
            
                create query hQuery.
                hQuery:add-buffer(phBuffer).
                
                if valid-handle(phBuffer:parent-relation) then
                do: 
                   cJoin = BufferUtil:GetJoinExpression(phBuffer:parent-relation).
                   if cJoin > "" then
                      cJoin = "where " + cJoin.     
                end.
                hQuery:query-prepare(trim(subst("preselect each &1 &2",phBuffer:name,cJoin))).
                hQuery:query-open().
                hQuery:get-first.
                 
                do while phBuffer:avail:
                    if phBuffer:error = false and phBuffer:rejected = false then
                    do:
                        // todo - check return and avoid Refill if false (in most cases refillcurrentrow is ) 
                        oRequest = oDataSource:PrepareCurrent(phBuffer, poParentRequest).
                        if oDataSource:RefillCurrentRow() then
                        do:
                            do iChild  = 1 to phBuffer:num-child-relations:
                                hRelation = phBuffer:get-child-relation(iChild).
                                if hRelation:active 
                                and hRelation:reposition = false
                                and hRelation:recursive = false
                                then
                                do:
                                    hChildBuffer = phBuffer:get-child-relation(iChild):child-buffer.
                                    RefreshBuffer(phDataset,hChildBuffer,oRequest).
                                end.
                            end.
                        end.
                       // else delete?? 
                    end.
                    hQuery:get-next.
                end.
            end.
        end.
        finally:
            if valid-handle(hQuery) then
                delete object hQuery.        
        end finally.
    end method. 
    
   

   /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    destructor public DataAccess ( ):
        if valid-handle(DatasetHandle) then
        do: 
            delete object DatasetHandle no-error.
        end.
    end destructor.
    
    
end class.