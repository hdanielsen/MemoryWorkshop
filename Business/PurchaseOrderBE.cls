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

class Business.PurchaseOrderBE inherits BusinessEntity:

    {schema/purchaseOrder.i}

    define dataset dsPurchaseOrder for ttPurchaseOrder.

    constructor PurchaseOrderBE():
        super(dataset dsPurchaseOrder:handle).
    end constructor.

end class.
