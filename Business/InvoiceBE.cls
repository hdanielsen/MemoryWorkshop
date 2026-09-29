/*------------------------------------------------------------------------------
 File        : Business.InvoiceBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:48.764-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Ccs.BusinessLogic.QueryOperatorEnum from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.QueryPredicate from propath.
using Pmfo.Core.BusinessLogic.IQueryDefinition from propath.
using Pmfo.Core.BusinessLogic.QueryDefinition from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.

class Business.InvoiceBE inherits BusinessEntity:

    {schema/invoice.i}
    
    
    {schema/order.i reference-only}
    {schema/orderline.i reference-only}
    
    define dataset dsorder for ttOrder, ttOrderline.

    define dataset dsInvoice for ttInvoice.

    constructor InvoiceBE():
        super(dataset dsInvoice:handle).
    end constructor.
    
    method protected override void ValidateData(pRequest as IUpdateDataRequest, input dataset-handle phDataset ): 
        ValidateStaticData(dataset-handle phDataset by-reference ). 
    end method.    
   
    method protected void ValidateStaticData(input dataset dsInvoice ):
        define variable hPurchaseOrderTable  as handle          no-undo.
        define variable oOrderBE             as IBusinessEntity no-undo.
        define variable oRequest             as IGetDataRequest no-undo.
        define variable oTableRequest        as IGetDataTableRequest no-undo.
        define variable oQueryDefinition     as IQueryDefinition  no-undo.
        define variable hDataset             as handle no-undo.
        define variable hInvoiceTable         as handle no-undo.
        define variable hOrderTable          as handle no-undo.
        define variable hOrderLineTable      as handle no-undo.
        
        oOrderBE = ServiceManager:CreateBusinessEntity("orders").
        oRequest = CreateGetRequest(oOrderBE:datasets[1]).
        
        for each ttInvoice where row-state(ttInvoice) = row-created:
            oQueryDefinition = new QueryDefinition().
            oQueryDefinition:AddEntry(new QueryPredicate("OrderNum",QueryOperatorEnum:Eq,ttInvoice.OrderNum)).
            oRequest:TableRequests[1]:QueryDefinition = oQueryDefinition.
            oOrderBE:GetData(oRequest, output dataset-handle hDataset).
            
            hOrderTable     = hDataset:get-buffer-handle(1):table-handle.
            hOrderLineTable = hDataset:get-buffer-handle(2):table-handle.
            
            UpdateInvoiceFromOrder(buffer ttinvoice, input table-handle hOrderTable by-reference, input table-handle hOrderLineTable by-reference).  
        end.     
    end method.
    
    
    method protected void UpdateInvoiceFromOrder(buffer ttinvoice for ttinvoice, input table ttOrder, input table ttorderline ):
        define variable iCount as integer no-undo.
        
        find ttOrder no-error.
        if ambiguous Order then 
            undo, throw new IllegalArgumentError("UpdateInvoiceFromOrder called with more than on ttOrder present").  
        
        ttInvoice.custNum =  ttOrder.custnum.
         
        for each ttOrderline:
            ttInvoice.amount = ttInvoice.amount + ttOrderline.ExtendedPrice.
        end.
        //TODO use item weight...
        ttInvoice.shipCharge = ttInvoice.amount * 0.05.
        
    end method.     
    
end class.
