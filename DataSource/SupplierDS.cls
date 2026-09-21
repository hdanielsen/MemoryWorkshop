/*------------------------------------------------------------------------------
 File        : DataSource.SupplierDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:56:00.298-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Util.UpdateUtil from propath.

class DataSource.SupplierDS inherits DataSource:

    {schema/supplier.i reference-only}

    define public override property EntityName as character init "suppliers" no-undo get.

    constructor SupplierDS():
        super(buffer Supplier:handle).
    end constructor.

    method protected void Bind( input table ttSupplier bind):
    end method.

    method override protected void PrepareBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        pBuffer:set-callback("After-Row-fill","AfterRow").
        hTable = pBuffer:table-handle.
        bind (table-handle hTable bind).        
    end method.
    
    method override protected void PrepareSaveBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        hTable = pBuffer:table-handle.
        bind (table-handle hTable bind).        
    end method.
    
    method override protected void CreateBeginTransValidate( input dataset-handle  phDataset):
        define variable iNewSupplierIDNum as integer no-undo.
        iNewSupplierIDNum = next-value(NextSupplNum).
        // propagate key change to all related tables in dataset and assign to self 
        UpdateUtil:UpdateKey(buffer ttSupplier:handle, "SupplierIDNum",iNewSupplierIDNum). 
    end method.
    
    method override protected void DeleteBeginTransValidate( input dataset-handle  phDataset):
        if can-find(first purchaseorder where PurchaseOrder.SupplierIDNum = biSupplier.SupplierIDNum) then 
            ThrowBufferError(substitute ("PurchaseOrders orders exist for Supplier &1. Cannot delete.",biSupplier.SupplierIDNum)).  
    end method.
end class.
