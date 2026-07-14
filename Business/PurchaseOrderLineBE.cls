/*------------------------------------------------------------------------------
 File        : Business.PurchaseOrderLineBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 07:08:36.274-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.PurchaseOrderLineBE inherits BusinessEntity:

    {schema/purchaseOrderLine.i}

    define dataset dsPurchaseOrderLine for ttPurchaseOrderLine.

    constructor PurchaseOrderLineBE():
        super(dataset dsPurchaseOrderLine:handle).
    end constructor.

end class.
