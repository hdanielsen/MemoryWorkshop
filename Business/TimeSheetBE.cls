/*------------------------------------------------------------------------------
 File        : Business.TimeSheetBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:56:12.733-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.TimeSheetBE inherits BusinessEntity:

    {schema/timeSheet.i}

    define dataset dsTimeSheet for ttTimeSheet.

    constructor TimeSheetBE():
        super(dataset dsTimeSheet:handle).
    end constructor.

end class.
