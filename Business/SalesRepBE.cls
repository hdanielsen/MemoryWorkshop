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
    {schema/salesRepQuota.i}

    define dataset dsSalesRep for ttSalesRep, ttSalesRepQuota
        data-relation for ttSalesRep, ttSalesRepQuota relation-fields(SalesRep,SalesRep) nested foreign-key-hidden.

    constructor SalesRepBE():
        super(dataset dsSalesRep:handle).
    end constructor.

end class.
