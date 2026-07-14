/*------------------------------------------------------------------------------
 File        : Business.VacationBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:56:18.746-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.VacationBE inherits BusinessEntity:

    {schema/vacation.i}

    define dataset dsVacation for ttVacation.

    constructor VacationBE():
        super(dataset dsVacation:handle).
    end constructor.

end class.
