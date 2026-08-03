/*------------------------------------------------------------------------------
 File        : Business.SalesRepQuotaBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   :  
 Created     :  
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.SalesRepQuotaBE inherits BusinessEntity:

    {schema/salesRepQuota.i}

    define dataset dsSalesRepQuota for ttSalesRepQuota.

    constructor SalesRepQuotaBE():
        super(dataset dsSalesRepQuota:handle).
    end constructor.

end class.
