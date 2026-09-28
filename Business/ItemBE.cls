/*------------------------------------------------------------------------------
 File        : Business.ItemBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:54.633-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Business.OrderBE from propath.
using Business.OrderLineBE from propath.
using Business.PurchaseOrderBE from propath.
using Ccs.BusinessLogic.QueryOperatorEnum from propath.
using Pmfo.Core.BusinessLogic.BusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.QueryPredicate from propath.
using Pmfo.Core.Error.BadRequestError from propath.
using Pmfo.Core.Manager.ServiceManager from propath.
using Pmfo.Util.Array from propath.
using Pmfo.Util.DatasetUtil from propath.

class Business.ItemBE inherits BusinessEntity:

    {schema/item.i}
    {schema/purchaseOrder.i}
    {schema/purchaseOrderLine.i}
    {schema/supplierItemXref.i}
   
    {schema/orderLine.i reference-only}
    {schema/supplier.i reference-only}
    
    define dataset dsItem for ttItem.
    
    define buffer btItem for ttItem.
    
    define dataset dsItemSupplierXref for btItem, ttSupplierItemXref
        data-relation item-sup for btItem, ttSupplierItemXref relation-fields(ItemNum,ItemNum).
    
    // track BE that uses ItemBe to update and validate inventory 
    define protected property Owner as IBusinessEntity no-undo get. set.   

    constructor ItemBE():
        super(dataset dsItem:handle).
    end constructor.
    
    // validate orderline item and add or remove qty to/from allocated
    method public void ValidateAndUpdateInventory(input pOwner as IBusinessEntity, input table ttOrderline):
        define variable iItemNums   as integer extent no-undo.
        define variable oGetRequest as IGetDataRequest no-undo.
        
        for each ttOrderline where row-state(ttorderLine) > 0 break by ttOrderline.ItemNum :
            if last-of(ttOrderline.ItemNum) then 
            do:
                extent (iItemNums) = (if extent(iItemNums) = ? then 0 else extent(IItemNums)) + 1. 
                iItemNums[extent(iItemNums)] = ttOrderline.ItemNum.
            end.
        end.   
        
        for each biOrderline where row-state(biorderLine) = row-deleted break by biOrderline.ItemNum:
            if last-of(biOrderline.ItemNum) then 
            do:
                if Array:Find(biOrderline.ItemNum,iItemNums) = 0 then 
                do:
                    extent (iItemNums) = (if extent(iItemNums) = ? then 0 else extent(IItemNums)) + 1. 
                    iItemNums[extent(iItemNums)] = biOrderline.ItemNum.
                end.
            end.
        end.   
                
        oGetRequest = CreateGetRequest(dataset dsItem:handle).
        
        oGetRequest:TableRequests[1]:AddQueryEntry(new QueryPredicate("ItemNum",QueryOperatorEnum:InList,iItemNums)).
        GetData(oGetRequest).
        
        Owner = pOwner.
        
        // substract deleted or before value for modified
        for each biOrderLine where row-state(biOrdeRLine) = row-deleted or row-state(biOrdeRLine) = row-modified:
            find ttItem where ttitem.ItemNum = biOrderLine.ItemNum no-error.
            if not avail ttItem then
                undo, throw new BadRequestError(substitute("OrderNum &1 OrderLine &2 Item Id &3 does not exist",biOrderLine.Ordernum,biOrderLine.LineNum,biOrderline.ItemNum)). 
            temp-table ttitem:tracking-changes = true.
            ttItem.Allocated = ttItem.Allocated - biOrderline.qty.      
            temp-table ttitem:tracking-changes = false.
        end.    
        
        // add qty of created or modified
        for each ttOrderLine where row-state(ttorderLine) > 0:
            find ttItem where ttitem.ItemNum = ttOrderLine.ItemNum no-error.
            if not avail ttItem then
                undo, throw new BadRequestError(substitute("OrderNum &1 OrderLine &2 Item Id &3 does not exist",ttOrderLine.Ordernum,ttOrderLine.LineNum,ttOrderline.ItemNum)). 
            temp-table ttitem:tracking-changes = true.
            ttItem.Allocated = ttItem.Allocated + ttOrderline.qty.      
            temp-table ttitem:tracking-changes = false.
        end.    
        
        
    end method.
    
    // validate purchaseorderline item and add or remove qty to/from onorder
    method public void ValidateAndUpdateInventory(input pOwner as IBusinessEntity, input table ttPurchaseOrder, input table ttPurchaseOrderline):
        define variable iItemNums   as integer extent no-undo.
        define variable oGetRequest as IGetDataRequest no-undo.
        
        for each ttPurchaseOrderline break by ttPurchaseOrderline.ItemNum:
            if last-of(ttPurchaseOrderline.ItemNum) then 
            do:
                extent (iItemNums) = (if extent(iItemNums) = ? then 0 else extent(IItemNums)) + 1. 
                iItemNums[extent(iItemNums)] = ttPurchaseOrderline.ItemNum.
            end.
        end.   
        
        for each biPurchaseOrderline break by biPurchaseOrderline.ItemNum:
            if last-of(biPurchaseOrderline.ItemNum) then 
            do:
                if Array:Find(biPurchaseOrderline.ItemNum, iItemNums) = 0 then 
                do:
                    extent (iItemNums) = (if extent(iItemNums) = ? then 0 else extent(IItemNums)) + 1. 
                    iItemNums[extent(iItemNums)] = biPurchaseOrderline.ItemNum.
                end.
            end.
        end.   
        
        if extent(iItemNums) > 0 then 
        do:
            oGetRequest = CreateGetRequest(dataset dsItemSupplierXref:handle).
            
            oGetRequest:TableRequests[1]:AddQueryEntry(new QueryPredicate("ItemNum",QueryOperatorEnum:InList,iItemNums)).
            
            GetData(oGetRequest,output dataset dsItemSupplierXref by-reference).
            
            UpdateItemOnOrder(table ttItem by-reference, table ttSupplierItemXref by-reference, table ttPurchaseOrder by-reference, table ttPurchaseOrderline by-reference).
        end.
    end method.
    
    method protected integer NumItemsAvailable(buffer ttItem for ttItem):
        return (ttItem.OnHand - ttItem.Allocated) + ttitem.onorder. 
    end method.     
    
    method public handle GetItemInventoryDataForSubmit():
        define variable iReorderItemNums        as integer extent no-undo.
        define variable oSupplierItemXrefBE     as IBusinessEntity no-undo.
        define variable oPurchaseOrderBE        as PurchaseOrderBE no-undo.
        define variable hPurchaseOrderDS        as handle no-undo.
        define variable hPurchaseOrderTable     as handle no-undo.
        define variable hPurchaseOrderLineTable as handle no-undo.
        define variable iPoNum                  as integer no-undo.
        define variable iPolinenum              as integer no-undo.
        define variable oSupplierBE             as IBusinessEntity no-undo.
        
        temp-table ttItem:tracking-changes = false.
              
        if type-of(Owner,OrderBE) or type-of(Owner,OrderLineBE) then do:
            for each ttItem where row-state(ttitem) > 0:
                if ttItem.MinQty > NumItemsAvailable(buffer ttitem) then do: 
                    extent (iReorderItemNums) = (if extent(iReorderItemNums) = ? then 0 else extent(iReorderItemNums)) + 1. 
                    iReorderItemNums[extent(iReorderItemNums)] = ttItem.ItemNum.
                end.
            end.
            
            if extent (iReorderItemNums) > 0 then  
            do: 
                oSupplierItemXrefBE = ServiceManager:CreateBusinessEntity("SupplieritemXrefs").        
                oSupplierItemXrefBE:GetData(new QueryPredicate("ItemNum",QueryOperatorEnum:InList,iReorderItemNums), output table ttSupplierItemXref). 
                
                oPurchaseOrderBE = cast(ServiceManager:CreateBusinessEntity("PurchaseOrders"),PurchaseOrderBE).
                oPurchaseOrderBE:CreatePurchaseOrdersForItems(input table ttItem by-reference, input table ttSupplierItemXref by-reference, output dataset-handle hPurchaseOrderDS).
                
                hPurchaseOrderTable     = DatasetUtil:GetBufferBySerializeName(hPurchaseOrderDS,"purchaseOrders"):table-handle.
                hPurchaseOrderLineTable = DatasetUtil:GetBufferBySerializeName(hPurchaseOrderDS,"purchaseOrderLines"):table-handle.
                UpdateItemOnOrder(table ttItem by-reference, table ttSupplierItemXref by-reference, input table-handle hPurchaseOrderTable by-reference, input table-handle hPurchaseOrderLineTable by-reference).
                
                // retirn dataset with both items and purcassorders to be submotted with order  
                return DatasetUtil:CreateDatasetFromMultipleDatasets(Array:ToArray(dataset dsItem:handle, hPurchaseOrderDS)).
            end.
            
        end.  
        
        return dataset dsItem:handle. 
    end method.   
     
          
    method protected void UpdateItemOnOrder(input table ttItem, table ttSupplierItemXref, input table ttPurchaseOrder, input table ttPurchaseOrderline):
        // subtract deleted or before value of modifed from on order
        for each biPurchaseOrder where row-state(biPurchaseOrder) = row-deleted or row-state(biPurchaseOrder) = row-modified:
            for each biPurchaseOrderLine where biPurchaseOrderLine.PONum = biPurchaseOrder.PoNum 
                                           and (row-state(biPurchaseOrderLine) = row-deleted or row-state(biPurchaseOrderLine) = row-modified) :
                find ttItem where ttitem.ItemNum = biPurchaseOrderline.ItemNum no-error.
                if not avail ttItem then
                    undo, throw new BadRequestError(substitute("Purchase Order &1 Line &2 Item Id &3 does not exist",biPurchaseOrderline.PONum,biPurchaseOrderline.LineNum,biPurchaseOrderline.ItemNum)). 
                
                temp-table ttitem:tracking-changes = true.
                ttItem.OnOrder = ttItem.OnOrder - biPurchaseOrderline.qty.      
                temp-table ttitem:tracking-changes = false.
                
            end.
        end.
        for each ttPurchaseOrder where row-state(ttPurchaseOrder) > 0:
            for each ttPurchaseOrderLine where ttPurchaseOrderLine.PONum = ttPurchaseOrder.PoNum and row-state(ttPurchaseOrderLine) > 0: 
                find ttItem where ttitem.ItemNum = ttPurchaseOrderline.ItemNum no-error.
                if not avail ttItem then
                    undo, throw new BadRequestError(substitute("OrderNum &1 OrderLine &2 Item Id &3 does not exist",ttPurchaseOrderline.PONum,ttPurchaseOrderline.LineNum,ttPurchaseOrderline.ItemNum)). 
                find ttSupplierItemXref where ttSupplierItemXref.SupplierIDNum = ttPurchaseOrder.SupplierIDNum and ttSupplierItemXref.ItemNum = ttPurchaseOrderline.ItemNum no-error.
                if not avail ttSupplierItemXref then
                    undo, throw new BadRequestError(substitute("Supplier &1 is not a valid Supplier for Item Id &2 (OrderNum &3 OrderLine &4)",ttPurchaseOrder.SupplierIDNum,ttPurchaseOrderline.ItemNum,ttPurchaseOrderline.PONum,ttPurchaseOrderline.LineNum)). 
               
                temp-table ttitem:tracking-changes = true.
                ttItem.OnOrder = ttItem.OnOrder + ttPurchaseOrderline.qty.      
                temp-table ttitem:tracking-changes = false.
            end.
        end.
            
    end.    

	 
          
end class.
