/*------------------------------------------------------------------------------
 File        : Business.InvoiceBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:48.764-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.InvoiceBE inherits BusinessEntity:

    {schema/invoice.i}

    define dataset dsInvoice for ttInvoice.

    constructor InvoiceBE():
        super(dataset dsInvoice:handle).
    end constructor.

end class.
