/*------------------------------------------------------------------------------
 File        : Business.OrderLineBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:15.245-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.OrderLineBE inherits BusinessEntity:

    {schema/orderLine.i}

    define dataset dsOrderLine for ttOrderLine.

    constructor OrderLineBE():
        super(dataset dsOrderLine:handle).
    end constructor.
    
    

end class.
