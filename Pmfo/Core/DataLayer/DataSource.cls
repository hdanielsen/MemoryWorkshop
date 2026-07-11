 
 /*------------------------------------------------------------------------
    File        : DataSource
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Sun Jun 28 09:48:44 EDT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Pmfo.Core.DataLayer.IDataSource.
using Pmfo.Core.DataLayer.IUpdateTarget.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using OpenEdge.Core.Collections.ICollection from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using OpenEdge.Core.Collections.IIterator from propath.
using Pmfo.Util.StringUtil from propath.
using Pmfo.Util.BufferUtil from propath.
using Pmfo.Core.DataLayer.DbQuery from propath.

block-level on error undo, throw.

class Pmfo.Core.DataLayer.DataSource inherits DbQuery implements IDataSource, IUpdateTarget abstract: 



    define public property Count as logical no-undo 
    get.
    set. 

    define public property DataBuffer as handle no-undo 
    get.
    set. 

    define public property EntityName as character no-undo 
    get.
    set. 

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
    end constructor.
    
    
    method public void AfterRow( input DATASET-HANDLE phDataset ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public void AfterUpdate( input DATASET-HANDLE phDataset ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public void BeforeUpdate( input DATASET-HANDLE phDataset ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public void Destroy(  ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public logical Fill(  ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public void FindAndCompareSource(  ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public void FindAndCompareSource( input phBuffer as handle ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public void FindAndCompareSource( input phbuffer as handle, input pFields as character ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public void FindSource( input plock as integer ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public void FindSource( input phBuffer as handle, input pLock as integer ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public void FindSource( input phbuffer as handle, input pDbBuffer as handle, input plock as integer ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public void FindSourceForUnmodifiedRow(  ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public void Initialize(  ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public logical Prepare( input phBuffer as handle, input pRequest as IGetDataTableRequest, input pParentRequest as IGetDataTableRequest ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public logical Prepare( input phBuffer as handle, input pRequest as IGetDataTableRequest ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public override logical Prepare(  ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public IGetDataTableRequest PrepareCurrent( input phBuffer as handle, input pParentRequest as IGetDataTableRequest ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public logical PrepareSave( input phBuffer as handle, input pUpdateRequest as IUpdateDataRequest ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method public logical RefillCurrentRow(  ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

     

    method public logical SaveRow( input phBeforeBuffer as handle ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

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