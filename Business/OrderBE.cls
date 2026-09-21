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

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IQueryPredicate from propath.
using Ccs.BusinessLogic.QueryOperatorEnum from propath.
using Pmfo.Core.BusinessLogic.QueryPredicate from propath.
using Pmfo.Core.Error.BadRequestError from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntityFinder from propath.
using Pmfo.Core.BusinessLogic.BusinessEntityFinder from propath.

class Business.OrderBE inherits BusinessEntity:

    {schema/order.i}
    {schema/orderline.i}
    
    {schema/item.i reference-only}
    
    define dataset dsOrder for ttOrder, ttOrderLine
       data-relation order-lines for ttOrder, ttOrderLine relation-fields(orderNum,orderNum) nested foreign-key-hidden
       .
    
    constructor OrderBE():
        super(dataset dsOrder:handle).
    end constructor.
    
    method protected override void ValidateData(pRequest as IUpdateDataRequest, input dataset-handle phDataset ): 
        ValidateStaticData(dataset-handle phDataset by-reference ). 
    end method.    
   
    method protected void ValidateStaticData(input dataset dsOrder ):
        define variable oItemFinder as IBusinessEntityFinder no-undo.
        define variable dExtendedPrice as decimal no-undo.
        /* The finder wraps calls to another BusinessEntity to allow append of ttItem records for only the records we need. 
           This also ensures the that the underlying business entity is decoupled so that we do not depend on keeping 
           the BE alive to work on its data.  
           The BE is kept alive under the covers, but is cleared for each request and subsequently need to go to the data access
           It could be better to have this capability directly in the BE, but this would require optional append 
           when calling the Data Access. As of current the BE Fetch to DataAccess is a complete replace and deep copy of data.                     
        */
             
        oItemFinder = new BusinessEntityFinder('items').
        oItemFinder:Bind(output table ttItem bind).
        
        for each ttOrder where row-state(ttOrder) > 0:
            if ttOrder.shipDate = ? then 
                BufferError(buffer ttOrder:handle,substitute ("Order &1 does not have Shipdate",ttOrder.OrderNum),"shipdate").
                
            for each ttOrderline where ttOrderLine.Ordernum = ttOrder.OrderNum and row-state(ttOrderLine) > 0:
                
                // thw use of append requires that we only call if we do not alreay have it
                find ttItem where ttItem.itemNum = ttOrderLine.ItemNum no-error.
                if not avail item then do: 
                    oItemFinder:Find(ttOrderLine.ItemNum, output table ttItem append). 
                    find ttItem where ttItem.itemNum = ttOrderLine.ItemNum no-error.
                end.
                if not avail ttItem then 
                    undo, throw new BadRequestError(substitute("Item &1 does not exist",ttOrderLine.ItemNum)).
                
                // this is pretend business logic ... 
                if ttItem.OnHand + ttItem.OnOrder - ttOrderline.Qty <= 0 then
                    undo, throw new BadRequestError(substitute("There is only &1 items available for ordering (on hand &2 and on order is &3. You cannot order &3 &4 items",
                                                               ttItem.OnHand + ttItem.OnHand, ttItem.OnHand,ttItem.OnHand, ttOrderline.qty, ttItem.ItemName)).                  
                
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
    end method.    
    

end class.
