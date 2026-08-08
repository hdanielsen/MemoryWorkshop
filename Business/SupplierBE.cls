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
    {schema/supplierItemXRef.i}
    {schema/item.i}

    define dataset dsSupplier for ttSupplier, ttSupplierItemXref, ttItem
        data-relation sup-xref for ttSupplier, ttSupplierItemXref relation-fields(SupplierIDNum ,SupplierIDNum) nested foreign-key-hidden
        data-relation xref-item for ttSupplierItemXref, ttItem relation-fields(ItemNum,ItemNum) nested foreign-key-hidden
        .
     
    constructor SupplierBE():
        super(dataset dsSupplier:handle).
    end constructor.

end class.
