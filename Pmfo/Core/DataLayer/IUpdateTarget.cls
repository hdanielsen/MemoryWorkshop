
/*------------------------------------------------------------------------
    File        : IUpdateTarget
    Purpose     : Extends IDataSource for update
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/

using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.DataLayer.IDataSource from propath.
using Pmfo.Core.DataLayer.ValidationHookEventType from propath.

interface Pmfo.Core.DataLayer.IUpdateTarget inherits IDataSource:  
    define public property OptimisticLockExceptFields as character no-undo get. 
  
    /* Prepare by attaching the data source to the DataSourceHandle 
    */  
   // method public logical PrepareSave(phBuffer as handle).
    method public logical PrepareSave(phBuffer as handle, pUpdateRequest as IUpdateDataRequest).
    
    method public void  ValidateRow(phBeforeBuffer as handle, pEventType as ValidationHookEventType).
    /* public api to save the data - called from a TransactionManager  */
    method public logical SaveRow(phBeforeBuffer as handle).
    
    /* DataAccess subscribes this to the Beforeupdate event fired before the update starts
       This fires outside the transaction
       Subclasses overrides this if they need to do something that cannot 
       be handled in the row level events 
       The override must do a for each to get the data   
    */ 
    method public void  BeforeUpdate (input dataset-handle phDataset).
    
    /* DataAccess subscribes this to the Afterupdate event fired when the update ends
       but before refresh of data
       This fires outside the transaction
       Subclasses overrides this if they need to do something that cannot 
       be handled in the row level events 
       The override must do a for each to get the data   
    */ 
    method public void  AfterUpdate (input dataset-handle phDataset).
    
    method public void FindSourceForUnmodifiedRow().
     
    method public void FindSource(plock as integer).
    method public void FindSource(phbuffer as handle,pDbBuffer as handle,plock as integer).
    
    method public void FindAndCompareSource().
    method public void FindAndCompareSource(phBuffer as handle).
    method public void FindAndCompareSource(phbuffer as handle,pFields as character).
     // TransactionManager will fire this if it finds an override in 
    // the concrete class
    // An error will be thrown if the CommitScopeEnum is not ALL 
    method public void DatasetTransactionEnd( input dataset-handle phDataset ).
        
end interface.
