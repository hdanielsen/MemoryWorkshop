/*------------------------------------------------------------------------------
 File        : Business.RefCallBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:36.037-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.RefCallBE inherits BusinessEntity:

    {schema/refCall.i}

    define dataset dsRefCall for ttRefCall.

    constructor RefCallBE():
        super(dataset dsRefCall:handle).
    end constructor.

end class.
