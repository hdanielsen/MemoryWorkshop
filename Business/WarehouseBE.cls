/*------------------------------------------------------------------------------
 File        : Business.WarehouseBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:56:23.790-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.WarehouseBE inherits BusinessEntity:

    {schema/warehouse.i}

    define dataset dsWarehouse for ttWarehouse.

    constructor WarehouseBE():
        super(dataset dsWarehouse:handle).
    end constructor.

end class.
