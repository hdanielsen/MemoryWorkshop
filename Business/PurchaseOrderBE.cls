/*------------------------------------------------------------------------------
 File        : Business.PurchaseOrderBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:29.910-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntityFinder from propath.
using Pmfo.Core.BusinessLogic.BusinessEntityFinder from propath.
using Pmfo.Core.Error.BadRequestError from propath.

class Business.PurchaseOrderBE inherits BusinessEntity:

     
    {schema/purchaseOrder.i}
    {schema/purchaseOrderLine.i}
    {schema/item.i reference-only}
    
    define property MAX_STOCK as integer init 20000 no-undo get.
    
    define dataset dsPurchaseOrder for ttPurchaseOrder,ttPurchaseOrderLine
        data-relation order-lines for ttPurchaseOrder, ttPurchaseOrderLine relation-fields(PONum,PONum) nested foreign-key-hidden
       .

    constructor PurchaseOrderBE():
        super(dataset dsPurchaseOrder:handle).
    end constructor.
    
    method protected override void ValidateData(pRequest as IUpdateDataRequest, input dataset-handle phDataset ): 
        ValidateStaticData(dataset-handle phDataset by-reference ). 
    end method.    
    
    
    method protected void ValidateStaticData(input dataset dsPurchaseOrder ):
        define variable oItemFinder as IBusinessEntityFinder no-undo.
        oItemFinder = new BusinessEntityFinder('items').
        oItemFinder:Bind(output table ttItem bind).
         
        for each ttPurchaseOrderLine:
            find ttItem where ttItem.itemNum = ttPurchaseOrderLine.ItemNum no-error.
            if not avail item then do: 
                oItemFinder:Find(ttPurchaseOrderLine.ItemNum, output table ttItem append). 
                find ttItem where ttItem.itemNum = ttPurchaseOrderLine.ItemNum no-error.
            end.
            if not avail ttItem then 
                undo, throw new BadRequestError(substitute("Item &1 does not exits",ttPurchaseOrderLine.ItemNum)).
           
            if ttItem.OnHand + ttItem.OnOrder + ttPurchaseOrderLine.Qty >= MAX_STOCK then
                undo, throw new BadRequestError(substitute("There are &1 items on hand and &2 itmms on order. You cannot purchase &3 &4 items as it will exceed max allowed stock of &5",
                                                           ttItem.OnHand,ttItem.OnOrder, ttPurchaseOrderLine.qty, ttItem.ItemName,MAX_STOCK)). 
                 
        end.    
    end method.    
    
    
    
end class.
