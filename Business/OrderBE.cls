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

class Business.OrderBE inherits BusinessEntity:

    {schema/order.i}
    {schema/orderline.i}
    {schema/item.i}
    
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
        define variable oItemBe as IBusinessEntity no-undo.
        oItemBe = ServiceManager:CreateBusinessEntity("items").        
        define variable oQueryPredicate as IQueryPredicate no-undo.
        for each ttOrderline:
           find ttItem where ttItem.itemNum = ttOrderLine.ItemNum no-error.
           if not avail ttItem then do: 
                oQueryPredicate = new QueryPredicate("ItemNum",QueryOperatorEnum:Eq,ttOrderLine.ItemNum).
                oItemBe:GetData(oQueryPredicate,output table ttItem append).
                find ttItem where ttItem.itemNum = ttOrderLine.ItemNum no-error.
            end.    
            if not avail ttItem then 
                undo, throw new BadRequestError(substitute("Item &1 does not exits",ttOrderLine.ItemNum)).
                
         end.    
    end method.    
    

end class.
