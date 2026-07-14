/*------------------------------------------------------------------------------
 File        : Business.SupplierBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:56:00.302-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.SupplierBE inherits BusinessEntity:

    {schema/supplier.i}

    define dataset dsSupplier for ttSupplier.

    constructor SupplierBE():
        super(dataset dsSupplier:handle).
    end constructor.

end class.
