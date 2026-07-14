/*------------------------------------------------------------------------------
 File        : Business.DepartmentBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:15.687-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.DepartmentBE inherits BusinessEntity:

    {schema/department.i}

    define dataset dsDepartment for ttDepartment.

    constructor DepartmentBE():
        super(dataset dsDepartment:handle).
    end constructor.

end class.
