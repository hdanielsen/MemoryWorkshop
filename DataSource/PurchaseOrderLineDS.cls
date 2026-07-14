/*------------------------------------------------------------------------------
 File        : DataSource.PurchaseOrderLineDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 07:08:36.272-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.

class DataSource.PurchaseOrderLineDS inherits DataSource:

    {schema/purchaseOrderLine.i reference-only}

    define public override property EntityName as character init "purchaseOrderLines" no-undo get.

    constructor PurchaseOrderLineDS():
        super(buffer POLine:handle).
    end constructor.

    method protected void Bind( input table ttPurchaseOrderLine bind):
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
