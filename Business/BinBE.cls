/*------------------------------------------------------------------------------
 File        : Business.BinBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/13/2026 07:22:00.525-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.BinBE inherits BusinessEntity:

    {schema/bin.i}

    define dataset dsBin for ttBin.

    constructor BinBE():
        super(dataset dsBin:handle).
    end constructor.

end class.
