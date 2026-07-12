/*------------------------------------------------------------------------------
 File        : Business.BillToBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/12/2026 07:24:08.077-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.BillToBE inherits BusinessEntity:

    {schema/billTo.i}

    define dataset dsBillTo for ttBillTo.

    constructor BillToBE():
        super(dataset dsBillTo:handle).
    end constructor.

end class.
