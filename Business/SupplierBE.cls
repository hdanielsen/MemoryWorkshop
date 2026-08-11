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
using Pmfo.Util.Array from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.

class Business.SupplierBE inherits BusinessEntity:

    {schema/supplier.i}
    {schema/supplierItemXRef.i}
    {schema/item.i}
    
    define temp-table ttSupplierItem serialize-name "items" like ttItem
        field SupplierIDNum as integer serialize-name "supplierIDNum"
        index supplier-item as primary unique SupplierIDNum itemNum.
        .
    
    define dataset dsSupplierServer for ttSupplier, ttSupplierItemXref, ttItem
        data-relation sup-xref for ttSupplier, ttSupplierItemXref relation-fields(SupplierIDNum ,SupplierIDNum) nested foreign-key-hidden
        data-relation xref-item for ttSupplierItemXref, ttItem relation-fields(ItemNum,ItemNum) nested foreign-key-hidden
        .
    
    define buffer btSupplier for ttSupplier serialize-name "suppliers".
    
    define dataset dsSupplier for btSupplier, ttSupplierItem
        data-relation sup-item for btSupplier, ttSupplierItem relation-fields(SupplierIDNum,SupplierIDNum) nested foreign-key-hidden
        .
     
    constructor SupplierBE():
        super(dataset dsSupplier:handle).
    end constructor.
    
    method protected override IGetDataResponse FetchData(input pRequest as IGetDataRequest, input-output dataset-handle phDataset):
        define variable oResponse as IGetDataResponse no-undo.
        
        oResponse = DataAccess:FetchData(CreateGetRequest(dataset dsSupplierServer:handle), input-output dataset dsSupplierServer ).
        CreateSupplierItems(dataset-handle phDataset , input dataset dsSupplierServer by-reference).
        
        return oResponse.
    end method.
    
    
    method protected void CreateSupplierItems(input dataset dsSupplier, input dataset dsSupplierServer ):
        for each ttSupplierItemXref: 
            find ttItem where ttItem.ItemNum = ttSupplierItemXref.ItemNum.
            create ttSupplierItem. 
            ttSupplierItem.SupplierIDNum = ttSupplierItemXRef.SupplierIDNum.
            buffer-copy ttItem to ttSupplierItem.
        end.    
    end method.    
        
end class.
