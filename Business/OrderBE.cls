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

class Business.OrderBE inherits BusinessEntity:

    {schema/order.i}

    define dataset dsOrder for ttOrder.

    constructor OrderBE():
        super(dataset dsOrder:handle).
    end constructor.

end class.
