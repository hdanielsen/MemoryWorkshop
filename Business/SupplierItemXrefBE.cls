/*------------------------------------------------------------------------------
 File        : Business.SupplierItemXrefBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:56:06.466-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.SupplierItemXrefBE inherits BusinessEntity:

    {schema/supplierItemXref.i}

    {schema/purchaseOrderLine.i}
    
    define dataset dsSupplierItemXref for ttSupplierItemXref.

    constructor SupplierItemXrefBE():
        super(dataset dsSupplierItemXref:handle).
    end constructor.
     
    
end class.
