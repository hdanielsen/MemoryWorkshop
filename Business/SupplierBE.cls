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
using Progress.Lang.Object from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.

class Business.SupplierBE inherits BusinessEntity:

    {schema/supplier.i}
    {schema/supplierItemXRef.i}
    {schema/item.i}
    
    define temp-table ttSupplierItem serialize-name "items" like ttItem use-index zz_seq
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
         dataset dsSupplierServer:write-json("file","C:\MemoryWorkshop-test\Temp\get-supplierserver.json",yes,?,no,yes,yes).
        CreateSupplierItems(dataset-handle phDataset by-reference , input dataset dsSupplierServer by-reference).
        
        return oResponse.
    end method.
    
    method protected override Object SubmitData(input poUpdateDataRequest as IUpdateDataRequest, input-output dataset-handle phDataset):
         
        CreateSupplierXrefs(dataset-handle phDataset by-reference, input dataset dsSupplierServer by-reference).
          dataset dsSupplierServer:write-json("file","C:\MemoryWorkshop-test\Temp\post-supplierserver.json",yes,?,no,yes,yes).
      
        super:SubmitData(poUpdateDataRequest,  input-output dataset dsSupplierServer by-reference).    
        if dataset dsSupplierServer:error then  
            ThrowDatasetError(dataset dsSupplierServer:handle). 
        dataset dsSupplierServer:write-json("file","C:\MemoryWorkshop-test\Temp\posted-supplierserver.json",yes,?,no,yes,yes).
        empty temp-table ttSupplierItem.
        CreateSupplierItems(dataset-handle phDataset by-reference , input dataset dsSupplierServer by-reference).
        phDataset:write-json("file","C:\MemoryWorkshop-test\Temp\returned-supplier.json",yes,?,no,yes,yes).
    
    end method.
    
    method protected void CreateSupplierXrefs(input dataset dsSupplier, input dataset dsSupplierServer ):
        temp-table ttSupplierItemXref:tracking-changes = true. 
        for each ttSupplierItem:
            create ttItem.
            buffer-copy ttSupplierItem to ttItem.
            create ttSupplierItemXRef.
            assign ttSupplierItemXref.SupplierIDNum = ttSupplierItem.SupplierIDNum
                   ttSupplierItemXref.ItemNum       = ttSupplierItem.ItemNum.
        end.           
             
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
