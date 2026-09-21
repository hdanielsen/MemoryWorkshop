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

using Ccs.BusinessLogic.QueryOperatorEnum from propath.
using Pmfo.Core.BusinessLogic.BusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.IQueryGroup from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.BusinessLogic.QueryGroup from propath.
using Pmfo.Core.BusinessLogic.QueryPredicate from propath.
using Pmfo.Core.Error.BadRequestError from propath.
using Pmfo.Core.Manager.ServiceManager from propath.
using Pmfo.Util.Array from propath.
using Pmfo.Util.StringUtil from propath.
using Progress.Lang.Object from propath.

class Business.SupplierBE inherits BusinessEntity:

    {schema/supplier.i}
    {schema/supplierItemXRef.i}
    {schema/item.i}
    {schema/purchaseorder.i reference-only}
    
    // define item table with supplieridnum to expose items as collection under supplier to UI/WEB  
    define temp-table ttSupplierItem serialize-name "items" like ttItem use-index zz_seq
        field SupplierIDNum as integer serialize-name "supplierIDNum"
        index supplier-item as primary unique SupplierIDNum itemNum.
        .
    
    // public dataset for UI/WEB with supplier items to show items under supplier   
    define dataset dsSupplier for ttSupplier, ttSupplierItem
        data-relation sup-item for ttSupplier, ttSupplierItem relation-fields(SupplierIDNum,SupplierIDNum) nested foreign-key-hidden
        .
    
    // define buffer for suppplierfor the server dataset
    define buffer btSupplier for ttSupplier serialize-name "suppliers".
    
    // define dataset with xref and item for dataaccess request
    define dataset dsSupplierServer for btSupplier, ttSupplierItemXref, ttItem
        data-relation sup-xref for btSupplier, ttSupplierItemXref relation-fields(SupplierIDNum ,SupplierIDNum) nested foreign-key-hidden
        data-relation xref-item for ttSupplierItemXref, ttItem relation-fields(ItemNum,ItemNum) nested foreign-key-hidden
        .
    
    define property SupplierBE as IBusinessEntity no-undo 
        get():
            if not valid-object(SupplierBe) then 
                SupplierBe = ServiceManager:CreateBusinessEntity("purchaseOrders").
            return SupplierBE.     
        end get.
        set.    
    
    constructor SupplierBE():
        super(dataset dsSupplier:handle).
    end constructor.
    
     method protected override void ValidateData(pRequest as IUpdateDataRequest, input dataset-handle phDataset ): 
        ValidateStaticData(dataset-handle phDataset by-reference ). 
    end method.    
   
    method protected void ValidateStaticData(input dataset dsSupplier ):
        define variable iSupplerIdNums as integer extent no-undo. 
        define variable oQuery as IQueryGroup no-undo.
        for each biSupplier where row-state(biSupplier) = row-deleted:
            extent(iSupplerIdNums) = (if extent(iSupplerIdNums) = ? then 0 else extent(iSupplerIdNums)) + 1.
            iSupplerIdNums[extent(iSupplerIdNums)] = biSupplier.SupplierIDNum.
        end.    
        oQuery = new QueryGroup().
        oQuery:AddEntry(new QueryPredicate("SupplierIDNum",QueryOperatorEnum:InList,iSupplerIdNums)).
        oQuery:AddEntry(new QueryPredicate("PoStatus",QueryOperatorEnum:Ne,"Received")).
        SupplierBE:GetData(oQuery, output table ttPurchaseOrder).
        
        extent(iSupplerIdNums) = ?.
        for each ttPurchaseOrder break by ttPurchaseOrder.SupplierIDNum :
            if last-of(ttPurchaseOrder.SupplierIDNum) then 
            do:
               extent(iSupplerIdNums) = (if extent(iSupplerIdNums) = ? then 0 else extent(iSupplerIdNums)) + 1.
               iSupplerIdNums[extent(iSupplerIdNums)] = ttPurchaseOrder.SupplierIDNum.
            end.
        end.
        
        if extent(iSupplerIdNums) <> ? then 
            undo, throw new BadRequestError(substitute("Suppler Id&1 &2 cannot be deleted. &3 at least one Purchcase Order that has not been received",
                                               if extent(iSupplerIdNums) > 1 then "s" else "",
                                               StringUtil:GetMessageFromEntries(Array:ToString(iSupplerIdNums)),
                                               if extent(iSupplerIdNums) > 1 then "They have" else "It has"
                                               
                                            )
                            ).
            
    end method.
    
    // override to use a the server dataset to fethc data from server
    method protected override IGetDataResponse FetchData(input pRequest as IGetDataRequest, input-output dataset-handle phDataset):
        define variable oResponse as IGetDataResponse no-undo.
        
        oResponse = DataAccess:FetchData(CreateGetRequest(dataset dsSupplierServer:handle), input-output dataset dsSupplierServer ).
        CreateSupplierItems(dataset-handle phDataset by-reference , input dataset dsSupplierServer by-reference).
        
        return oResponse.
    end method.
    
    
    // override to submit the server dataset with xrefs to dataacces 
    method protected override Object SubmitData(input poUpdateDataRequest as IUpdateDataRequest, input-output dataset-handle phDataset):
         
        // create xrefs and items   
        CreateSupplierXrefs(dataset-handle phDataset by-reference, input dataset dsSupplierServer by-reference).
        
        super:SubmitData(poUpdateDataRequest,  input-output dataset dsSupplierServer by-reference).    
        if dataset dsSupplierServer:error then  
            ThrowDatasetError(dataset dsSupplierServer:handle). 
        empty temp-table ttSupplierItem.
        // create supplier items to return to UI
        CreateSupplierItems(dataset-handle phDataset by-reference , input dataset dsSupplierServer by-reference).
    
    end method.
    
    /* Create data for server dataset from UI dataset 
       items are created to check optimistic locking. 
       TODO - allow item values that reflects inventory and changes often to be ommitted for optimistic lock check  
    */   
    method protected void CreateSupplierXrefs(input dataset dsSupplier, input dataset dsSupplierServer ):
        temp-table ttSupplierItemXref:tracking-changes = true. 
        for each ttSupplierItem:
            create ttItem.
            buffer-copy ttSupplierItem to ttItem.
            create ttSupplierItemXRef.
            assign ttSupplierItemXref.SupplierIDNum = ttSupplierItem.SupplierIDNum
                   ttSupplierItemXref.ItemNum       = ttSupplierItem.ItemNum.
        end.           
        finally:
            temp-table ttSupplierItemXref:tracking-changes = false. 
        end finally.     
    end method. 
    
    /* Create data for poublic (UI/WEB) dataset from server dataset  */
    method protected void CreateSupplierItems(input dataset dsSupplier, input dataset dsSupplierServer ):
        for each ttSupplierItemXref: 
            find ttItem where ttItem.ItemNum = ttSupplierItemXref.ItemNum.
            create ttSupplierItem. 
            ttSupplierItem.SupplierIDNum = ttSupplierItemXRef.SupplierIDNum.
            buffer-copy ttItem to ttSupplierItem.
        end.    
    end method.    
        
end class.
