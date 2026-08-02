/*------------------------------------------------------------------------------
 File        : Business.InventoryTransactionBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 08/02/2026 09:49:42.188-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.InventoryTransactionBE inherits BusinessEntity:

    {schema/inventoryTransaction.i}

    define dataset dsInventoryTransaction for ttInventoryTransaction.

    constructor InventoryTransactionBE():
        super(dataset dsInventoryTransaction:handle).
    end constructor.

end class.
