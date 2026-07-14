/*------------------------------------------------------------------------------
 File        : Business.FamilyBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:27.952-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.FamilyBE inherits BusinessEntity:

    {schema/family.i}

    define dataset dsFamily for ttFamily.

    constructor FamilyBE():
        super(dataset dsFamily:handle).
    end constructor.

end class.
