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
    
    method override protected void WriteBeginTransValidate( input dataset-handle  phDataset):
        if row-state(ttOrderLine) = row-modified 
                                   and (ttOrderLine.OrderNum <> biOrderLine.orderNum 
                                        or 
                                        ttOrderLine.LineNum <> biOrderLine.LineNum) then 
            ThrowBufferError(substitute ("Order Num and Line num are readonly. Cannot change keys of OrderLine &1 &2",  biOrderLine.orderNum, biOrderLine.LineNUm)). 
        
    end method.    
    
    
    method override protected void WriteEndTransValidate( input dataset-handle  phDataset):
        find item where Item.ItemNum = ttOrderLine.ItemNum.
        Item.OnOrder = Item.OnOrder + ttOrderLine.Qty.
              
        AddWarning("Item on hand is less than min qty","qty"). 
         /*** from item trigger 
         IF Item.MinQty >
   ((Item.OnHand - Item.Allocated) + item.onorder) THEN DO:
  
   FIND FIRST supplieritemxref where supplieritemxref.itemnum =
   item.itemnum NO-LOCK NO-ERROR.
   
   IF AVAIL supplieritemxref THEN DO:
        
        FIND supplier WHERE supplier.supplieridnum =
            supplieritemxref.supplieridnum NO-LOCK NO-ERROR.       
       
        IF AVAIL supplier THEN DO:
             CREATE purchaseorder.
             ASSIGN 
                purchaseorder.DateEntered = today
                purchaseorder.POStatus = "Ordered"
                purchaseorder.SupplierIDNum = supplieritemxref.supplieridnum.
              
             CREATE poline.
             ASSIGN
             poline.ponum = purchaseorder.ponum
             poline.linenum = 1
             poline.Discount = supplier.discount
             poline.Itemnum = item.itemnum
             poline.Price = item.price
             poline.qty = item.reorder
             poline.ExtendedPrice = (item.price * poline.qty) * (1 - supplier.discount).
             item.onorder = item.onorder + item.reorder.
  
     /******
             MESSAGE "Purchase Order: " purchaseorder.ponum " for " Item.ItemName
             ", Item Number: " Item.ItemNum " has been generated."
             VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
     *******/
        END. /* If avail suplier*/
     
  END. /*if avail supplieritemxref*/
END.
  ***/
         
         
         
         
    end method.
    
    
end class.
