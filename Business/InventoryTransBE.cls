/*------------------------------------------------------------------------------
 File        : Business.InventoryTransBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:42.692-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.InventoryTransBE inherits BusinessEntity:

    {schema/inventoryTrans.i}

    define dataset dsInventoryTrans for ttInventoryTrans.

    constructor InventoryTransBE():
        super(dataset dsInventoryTrans:handle).
    end constructor.

end class.
