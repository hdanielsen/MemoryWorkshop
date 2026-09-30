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

using Business.ItemBE from propath.
using Ccs.BusinessLogic.QueryOperatorEnum from propath.
using Pmfo.Core.BusinessLogic.BusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.BusinessLogic.QueryPredicate from propath.
using Pmfo.Core.Manager.ServiceManager from propath.
using Pmfo.Util.Array from propath.
using Pmfo.Util.DatasetUtil from propath.
using Progress.Lang.Object from propath.

class Business.PurchaseOrderBE inherits BusinessEntity:

     
    {schema/purchaseOrder.i}
    {schema/purchaseOrderLine.i}
    {schema/item.i reference-only}
    {schema/supplierItemXref.i reference-only}
    {schema/supplier.i reference-only}
    
     // use to update inventory from purchaseorderline changes - Submitdata will grab the data from there and submit with purchaseorder 
    define protected property ItemBe as ItemBE no-undo get. set.
    
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
        // Call Item Be to validate and update item onorder - the updates items will be added to the submiot dataset in SubmitData
        ItemBE = cast(ServiceManager:CreateBusinessEntity('items'),ItemBE).
        ItemBe:ValidateAndUpdateInventory(this-object, table ttPurchaseOrder by-reference, table ttPurchaseOrderLine by-reference).
    end method.    
    
    // create purchaseOrders for a list of items and corresponding supplierItemXref   
    method public handle CreatePurchaseOrdersForItems(input table ttitem, input table ttsupplierItemXref, output dataset dsPurchaseOrder):  
        define variable oSupplierItemXrefBE as IBusinessEntity no-undo.
        define variable iMinOrder           as integer no-undo.
        define variable iPoNum              as integer no-undo.
        define variable iPolinenum          as integer no-undo.
        define variable oSupplierBE         as IBusinessEntity no-undo.
        
        temp-table ttPurchaseOrder:tracking-changes     = true.
        temp-table ttPurchaseOrderLine:tracking-changes = true.
              
        for each ttSupplierItemXref break by ttSupplierItemXRef.ItemNum:                                                                                             
            if first-of(ttSupplierItemXref.ItemNum) then
            do:
                find ttItem where ttitem.ItemNum = ttSupplierItemXref.ItemNum.
                create ttPurchaseOrderLine.
                assign
                    ttPurchaseOrderLine.ItemNum      = ttItem.ItemNum
                    ttPurchaseOrderLine.Price        = ttItem.Price
                    ttPurchaseOrderLine.POLineStatus = "Ordered"
                    ttPurchaseOrderLine.Qty          = min(ttItem.ReOrder,ttItem.MinQty - ((ttItem.OnHand - ttItem.Allocated) + ttitem.onorder))
                    .
            end.
        end.

        oSupplierBE = ServiceManager:CreateBusinessEntity("Suppliers").

        for each ttSupplierItemXref break by ttSupplierItemXRef.SupplierIDNum:
            if first-of(ttSupplierItemXref.SupplierIdNum) then
            do:
                if can-find(first ttPurchaseOrderLine where ttPurchaseOrderLine.ItemNum = ttSupplierItemXref.SupplierIdNum
                                                       and ttPurchaseOrderLine.PONum   = 0) then
                do:
                    oSupplierItemXrefBE:GetData(new QueryPredicate("SupplierIdNum",QueryOperatorEnum:Eq,ttSupplierItemXref.SupplierIdNum), output table ttSupplier) .

                    assign
                        iPonum     = iPonum + 1
                        iPolinenum = 0.

                    create ttPurchaseOrder.
                    assign
                        ttPurchaseOrder.PONum         = iPoNum
                        ttPurchaseorder.POStatus      = "Ordered"
                        ttPurchaseorder.SupplierIDNum = ttSupplieritemxref.supplieridnum
                        .
                    find ttSupplier where ttSupplier.SupplierIDNum = ttSupplieritemxref.supplieridnum.
                    for each ttPurchaseOrderLine where ttPurchaseOrderLine.ItemNum = ttSupplierItemXref.SupplierIdNum
                                                   and ttPurchaseOrderLine.PONum   = 0.
                        assign
                            iPolinenum                        = IPOlineNum + 1
                            ttPurchaseOrderLine.LineNum       = IPOLineNUm
                            ttPurchaseOrderLine.Discount      = ttSupplier.discount
                            ttPurchaseOrderLine.ExtendedPrice = (ttPurchaseOrderLine.Price * ttPurchaseOrderLine.qty) * (1 - ttPurchaseOrderLine.Discount)
                            .
                    end.
                end.
            end.
        end.
        
        finally:
            temp-table ttPurchaseOrder:tracking-changes     = false.
            temp-table ttPurchaseOrderLine:tracking-changes = false.
        end finally.    
    end method.
    
    // override to submit the server dataset with xrefs to dataacces 
    method protected override Object SubmitData(input poUpdateDataRequest as IUpdateDataRequest, input-output dataset-handle phDataset):
        define variable hDataset as handle no-undo.
        if valid-object(ItemBE)  then  
            hDataset = DatasetUtil:CreateDatasetFromMultipleDatasets(Array:ToArray(phDataset,ItemBE:GetItemInventoryDataForSubmit())).
        else 
            hDataset = phDataset.
       
        super:SubmitData(poUpdateDataRequest, input-output dataset-handle hDataset by-reference).         
        finally:
            if valid-object(hDataset) and hDataset:dynamic then 
                delete object hDataset.   
        end.
    end method.    
   
    
    
end class.
