/*------------------------------------------------------------------------------
 File        : Business.CustomerBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:09.790-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.
using Pmfo.Core.Service.IClientRequest from propath.
using Pmfo.Core.Service.IClientGetRequest from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Util.DatasetUtil from propath.
using Pmfo.Util.TableUtil from propath.
using Pmfo.Core.BusinessLogic.DatasetBuilder from propath.

class Business.CustomerBE inherits BusinessEntity:

    {schema/customer.i}

    define dataset dsCustomer for ttCustomer.

    constructor CustomerBE():
        super(dataset dsCustomer:handle).
    end constructor.

   
end class.
