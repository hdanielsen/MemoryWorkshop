/*------------------------------------------------------------------------------
 File        : Business.LocalDefaultBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:00.801-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.LocalDefaultBE inherits BusinessEntity:

    {schema/localDefault.i}

    define dataset dsLocalDefault for ttLocalDefault.

    constructor LocalDefaultBE():
        super(dataset dsLocalDefault:handle).
    end constructor.

end class.
