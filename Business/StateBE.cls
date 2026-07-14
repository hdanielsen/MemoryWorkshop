/*------------------------------------------------------------------------------
 File        : Business.StateBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:55.098-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.StateBE inherits BusinessEntity:

    {schema/state.i}

    define dataset dsState for ttState.

    constructor StateBE():
        super(dataset dsState:handle).
    end constructor.

end class.
