/*------------------------------------------------------------------------------
 File        : DataSource.PurchaseOrderDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:29.908-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Util.UpdateUtil from propath.

class DataSource.PurchaseOrderDS inherits DataSource:

    {schema/purchaseOrder.i reference-only}
    
    define public override property EntityName as character init "purchaseOrders" no-undo get.

    constructor PurchaseOrderDS():
        super(buffer PurchaseOrder:handle).
    end constructor.

    method protected void Bind( input table ttPurchaseOrder bind):
    end method.
    
    method override protected void PrepareBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        
        pBuffer:set-callback("After-Row-fill","AfterRow").
        hTable = pBuffer:table-handle.
        Bind (table-handle hTable bind).        
    end method.
    
    method override protected void PrepareSaveBuffer( input pBuffer as handle ):
        define variable hTable      as handle  no-undo.
 
        hTable = pBuffer:table-handle.
        this-object:Bind (table-handle hTable bind).    
    end method.
    
    method override protected void CreateBeginTransValidate( input dataset-handle  phDataset):
        define variable iNewPoNum as integer no-undo.
        iNewPoNum =  next-value (NextPonum).
      
        // propagate key change to all related tables and assign to self 
        UpdateUtil:UpdateKey(buffer ttPurchaseOrder:handle, "PONum",iNewPoNum).
        if ttPurchaseOrder.DateEntered <> today then 
            AddWarning(substitut("New Purchase Order &1 Data Entered was set to today",iNewPoNUm)).
        ttPurchaseOrder.DateEntered = today.
         
    end method.
    
end class.
