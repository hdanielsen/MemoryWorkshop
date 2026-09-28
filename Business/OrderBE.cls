/*------------------------------------------------------------------------------
 File        : Business.OrderBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:09.217-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Business.ItemBE from propath.
using Pmfo.Core.BusinessLogic.BusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.Manager.ServiceManager from propath.
using Pmfo.Util.Array from propath.
using Pmfo.Util.DatasetUtil from propath.
using Progress.Lang.Object from propath.

class Business.OrderBE inherits BusinessEntity:

    {schema/order.i}
    {schema/orderline.i}
    
    {schema/item.i reference-only}
    
    define dataset dsOrder for ttOrder, ttOrderLine
       data-relation order-lines for ttOrder, ttOrderLine relation-fields(orderNum,orderNum) nested foreign-key-hidden
       .
    
    // use to update inventory from orderline changes - Submitdata will grab the data form there and submit with order/orderlines 
    define protected property ItemBe as ItemBE no-undo get. set.
    
    constructor OrderBE():
        super(dataset dsOrder:handle).
    end constructor.
    
    method protected override void ValidateData(pRequest as IUpdateDataRequest, input dataset-handle phDataset ): 
        ValidateStaticData(dataset-handle phDataset by-reference ). 
    end method.    
   
    method protected void ValidateStaticData(input dataset dsOrder ):
        define variable dExtendedPrice as decimal no-undo.
        
        for each ttOrder where row-state(ttOrder) > 0:
            if ttOrder.shipDate = ? then 
                BufferError(buffer ttOrder:handle,substitute ("Order &1 does not have Shipdate",ttOrder.OrderNum),"shipdate").
                
            for each ttOrderline where ttOrderLine.Ordernum = ttOrder.OrderNum and row-state(ttOrderLine) > 0:
                dExtendedPrice = ttOrderline.Price * ttOrderLine.Qty * (1 - (ttOrderLine.Discount / 100)).
                if ttOrderline.ExtendedPrice > 0 and ttOrderline.ExtendedPrice <> dExtendedPrice then 
                    ThrowBufferError(buffer ttOrderLine:handle,
                                     substitute("Order &1 Line &2 Extended Price &3 is not valid. The Extended Price will be calculated if submitted as 0 or empty",
                                                 ttOrderLine.OrderNum,
                                                 ttOrderLine.LineNum,
                                                 ttOrderline.ExtendedPrice
                                     ),
                                    "extendedPrice").
                assign ttOrderline.ExtendedPrice = dExtendedPrice.          
            end.
        end.    
        ItemBE = cast(ServiceManager:CreateBusinessEntity('items'),ItemBE).
        ItemBe:ValidateAndUpdateInventory(this-object, table ttOrderLine by-reference).
            
    end method.    
    
    // override to submit the server dataset with xrefs to dataacces 
    method protected override Object SubmitData(input poUpdateDataRequest as IUpdateDataRequest, input-output dataset-handle phDataset):
        define variable hDataset as handle no-undo.
        // use itembe to submit items with onorder updated  
        if valid-object(ItemBE)  then    
            hDataset = DatasetUtil:CreateDatasetFromMultipleDatasets(Array:ToArray(ItemBE:GetItemInventoryDataForSubmit(),dataset dsOrder:handle)).
        else 
            hDataset = dataset dsOrder:handle.
       
        super:SubmitData(poUpdateDataRequest, input-output dataset-handle hDataset by-reference).         
        finally:
            if valid-object(hDataset) and hDataset:dynamic then
            do: 
                message "delete hdataset" 
                view-as alert-box.
                delete object hDataset.
            end.       
        end.
    end method.    
   
    

end class.
