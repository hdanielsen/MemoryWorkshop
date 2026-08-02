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
    
end class.
