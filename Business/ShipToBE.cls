/*------------------------------------------------------------------------------
 File        : Business.ShipToBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:46.997-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.ShipToBE inherits BusinessEntity:

    {schema/shipTo.i}

    define dataset dsShipTo for ttShipTo.

    constructor ShipToBE():
        super(dataset dsShipTo:handle).
    end constructor.

end class.
