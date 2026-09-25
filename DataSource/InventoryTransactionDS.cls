/*------------------------------------------------------------------------------
 File        : DataSource.InventoryTransactionDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 08/02/2026 09:49:42.170-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Util.TimeZoneUtil from propath.

class DataSource.InventoryTransactionDS inherits DataSource:

    {schema/inventoryTransaction.i reference-only}

    define public override property EntityName as character init "inventoryTransactions" no-undo get.

    constructor InventoryTransactionDS():
        super(buffer InventoryTrans:handle).
    end constructor.

    method protected void Bind( input table ttInventoryTransaction bind):
    end method.

    method override protected void PrepareBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        pBuffer:set-callback("After-Row-fill","AfterRow").
        hTable = pBuffer:table-handle.
        Bind (table-handle hTable bind).        
    end method.
    
    method override protected void PrepareSaveBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        hTable = pBuffer:table-handle.
        Bind (table-handle hTable bind).        
    end method.
    
    method public override character GetDataSourceKeys(phNuffer as handle):
        return "InvTransNum". // No unique key in db! If there are duplicate data in the db then this is a terrible workaround. 
    end method.
        
    // override to manage the timein and timeput date tiem fields not mapped 
    // database fields directly
    method override protected void WriteEndTransValidate( input dataset-handle  phDataset):
        define variable cStringIn  as character no-undo.
        define variable cStringOut as character no-undo.
        define variable lpmin as logical no-undo. 
        define variable lpmout as logical no-undo.   
        
        // convert to GSM time 
        ttInventoryTransaction.TransactionTime = TimeZoneUtil:GetSysTimeFromLocalTime(ttInventoryTransaction.TransactionTime).
        
        findSource(exclusive-lock).
        
        // store as date and time string
        assign
            InventoryTrans.TransDate = date(ttInventoryTransaction.TransactionTime).
            InventoryTrans.TransTime = string(integer(mtime(ttInventoryTransaction.TransactionTime) / 1000),"HH:MM").
        
    end method.
    
    
    method public override void AfterRow(input dataset-handle phDataset):
        //convert to datetime from date and time
        ttInventoryTransaction.TransactionTime = 
            datetime(substitute("&1 &2",string(InventoryTrans.TransDate,"99-99-9999"),InventoryTrans.TransTime)).
          
        // convert from GMT in dastabse to local time as defined by TimeZoneUtil:TimeZoneName 
        ttInventoryTransaction.TransactionTime = TimeZoneUtil:GetLocalTimeFromSysTime(ttInventoryTransaction.TransactionTime).
        super:AfterRow(input dataset-handle phDataset by-reference).
    end method.
 
end class.
