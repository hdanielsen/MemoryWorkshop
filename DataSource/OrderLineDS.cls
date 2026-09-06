/*------------------------------------------------------------------------------
 File        : DataSource.OrderLineDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:15.243-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.

class DataSource.OrderLineDS inherits DataSource:

    {schema/orderLine.i reference-only}

    define public override property EntityName as character init "orderLines" no-undo get.

    constructor OrderLineDS():
        super(buffer OrderLine:handle).
    end constructor.

    method protected void Bind( input table ttOrderLine bind):
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
    
    method override protected void WriteEndTransValidate( input dataset-handle  phDataset):
        find item where Item.ItemNum = ttOrderLine.ItemNum.
        Item.OnOrder = Item.OnOrder + ttOrderLine.Qty.
              
        AddWarning("Item on hand is less than min qty","qty"). 
         
    end method.
    
    
end class.
