/*------------------------------------------------------------------------------
 File        : Business.EmployeeBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:21.681-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.EmployeeBE inherits BusinessEntity:

    {schema/employee.i}

    define dataset dsEmployee for ttEmployee.

    constructor EmployeeBE():
        super(dataset dsEmployee:handle).
    end constructor.

end class.
