/*------------------------------------------------------------------------------
 File        : Business.SalesRepBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:40.537-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.SalesRepBE inherits BusinessEntity:

    {schema/salesRep.i}

    define dataset dsSalesRep for ttSalesRep.

    constructor SalesRepBE():
        super(dataset dsSalesRep:handle).
    end constructor.

end class.
