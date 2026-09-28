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
using Pmfo.Core.Error.NotImplementedError from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.GetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.GetDataRequest from propath.
using Pmfo.Core.Error.UnsupportedOperationError from propath.

class Business.SupplierBE inherits BusinessEntity:

    {schema/supplier.i}
    {schema/supplierItemXRef.i}
    {schema/item.i}
    {schema/purchaseOrder.i reference-only}
    {schema/purchaseOrderLine.i reference-only}
    
    // define item table with supplieridnum to expose items as collection directly under supplier to UI/WEB  
    define temp-table ttSupplierItem serialize-name "items" like ttItem use-index zz_seq before-table biSupplierItem
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
    
    define property PurchaseOrderBE as IBusinessEntity no-undo 
        get():
            if not valid-object(PurchaseOrderBE) then 
                PurchaseOrderBE = ServiceManager:CreateBusinessEntity("purchaseOrders").
            return PurchaseOrderBE.     
        end get.
        set.    
    
    constructor SupplierBE():
        super(dataset dsSupplier:handle).
    end constructor.
    
    method protected override void ValidateData(pRequest as IUpdateDataRequest, input dataset-handle phDataset ): 
        ValidateStaticData(dataset-handle phDataset by-reference ). 
    end method.    
   
    method protected void ValidateStaticData(input dataset dsSupplier ):
        define variable iDeleteSupplerIdNums as integer extent no-undo. 
        define variable oQuery               as IQueryGroup no-undo.
        define variable hPurchaseOrderTable  as handle     no-undo.
        
        // collect deleted supplierids   
        for each biSupplier where row-state(biSupplier) = row-deleted:
            extent(iDeleteSupplerIdNums) = (if extent(iDeleteSupplerIdNums) = ? then 0 else extent(iDeleteSupplerIdNums)) + 1.
            iDeleteSupplerIdNums[extent(iDeleteSupplerIdNums)] = biSupplier.SupplierIDNum.
        end.    
        
        // if any deleted found fetch active (not received) purchaseOrders to the supplier
        if extent(iDeleteSupplerIdNums) <> ? then 
        do:
            oQuery = new QueryGroup().
            oQuery:AddEntry(new QueryPredicate("SupplierIDNum",QueryOperatorEnum:InList,iDeleteSupplerIdNums)).
            oQuery:AddEntry(new QueryPredicate("PoStatus",QueryOperatorEnum:Ne,"Received")).
            // NOTE GetData(with output table does not support by-reference -    
            PurchaseOrderBE:GetData(oQuery, output table-handle hPurchaseOrderTable).
            if hPurchaseOrderTable:has-records then    
                ThrowHasNonReceievedPurchaseOrdersError(input table-handle hPurchaseOrderTable by-reference).  
        end.    
    end method.
    
   // method protected void CreatePurchaseOrder
    
    method protected void ThrowHasNonReceievedPurchaseOrdersError(input table ttPurchaseOrder ):
        define variable iSupplerIdNums as integer extent no-undo. 
        
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
        define variable i as integer no-undo.
        define variable oResponse as IGetDataResponse no-undo.
        define variable oServerRequest as IGetDataRequest no-undo.
        define variable oGetTableRequests as IGetDataTableRequest no-undo extent.
        
        /*
        Throw not implemented  errrorif extarnal dataset is passed. 
        Since another static dataset with ttSuppler is usasd the fetch data from server 
        we can only allow the internal dataset to be passed here. 
        Support for external would either require copy from the external to the internal 
        or a dynamic dataset with a buffer for the static ttSupplier to fetch to server   
        */   
        if phDataset <> dataset dsSupplier:handle then 
            undo, throw new NotImplementedError("Submit of external dataset", "The SupplierBE internal dataset must be used to fetch suppliers.").
     
        
        extent(oGetTableRequests) = dataset dsSupplierServer:num-buffers.
        // use the suppler request with request properties from client   
        oGetTableRequests[1]  = pRequest:TableRequests[1].  
        // create request for the other server side tables
        do i = 2 to dataset dsSupplierServer:num-buffers:
            oGetTableRequests[i] = new GetDataTableRequest(dataset dsSupplierServer:get-buffer-handle(i):table-handle:name).
        end.    
        oServerRequest = new GetDataRequest(oGetTableRequests).   
        
        // TODO the response for supplier is ok, but is should not have xrefs that is not exposed to cleint   
        oResponse = DataAccess:FetchData(oServerRequest, input-output dataset dsSupplierServer ).
        
        CreateSupplierItems(dataset-handle phDataset by-reference , input dataset dsSupplierServer by-reference).
        
        return oResponse.
    end method.
    
    
    // override to submit the server dataset with xrefs to dataacces 
    method protected override Object SubmitData(input poUpdateDataRequest as IUpdateDataRequest, input-output dataset-handle phDataset):
        /*
        Throw not implemented  errrorif extranl dataset is passed. 
        Since another static dataset with the static ttSuppler is submitted to data access we can only allow the internal dataset to be submitted
        Support for external would either require copy from the external to the internal or a dynamic dataset with a buffer for the static ttSupplier
        to send to data access   
        */   
        if phDataset <> dataset dsSupplier:handle then 
            undo, throw new NotImplementedError("Submit of external dataset", "The SupplierBE internal dataset must be used to update/delete suppliers.").
        
        // create xrefs and items   
        CreateSupplierXrefsForSubmit(dataset-handle phDataset by-reference, input dataset dsSupplierServer by-reference).
        
        super:SubmitData(poUpdateDataRequest,  input-output dataset dsSupplierServer by-reference).    
        
        if dataset dsSupplierServer:error then  
            ThrowDatasetError(dataset dsSupplierServer:handle). 
        
        // create supplier items to return to UI - pass true to empty first 
        CreateSupplierItems(dataset-handle phDataset by-reference, input dataset dsSupplierServer by-reference).
    
    end method.
    
    /* Create data for server dataset from UI dataset 
       items are needed as parent of xref. Will also go through optimistic lock check. 
       TODO - allow item values that reflects inventory and changes often to be ommitted for optimistic lock check  
    */   
    method protected void CreateSupplierXrefsForSubmit(input dataset dsSupplier, input dataset dsSupplierServer ):
        /* While we expose the full item to the client we do not allow modifications of items 
           only remove from supplier (delete xref) or add to supplier(create xref) 
          (the same item can be under other suppliers in this dataset) */
        for each ttSupplierItem where row-state(ttSupplierItem) = row-modified:
            undo, throw new UnsupportedOperationError("The submitted item has been modified. Only create (add to supplier) or delete (remove from supplier) is supported for items under a Supplier."). 
        end.
        
        for each ttSupplierItem where row-state(ttSupplierItem) = row-created:
            create ttItem.
            buffer-copy ttSupplierItem to ttItem.
            temp-table ttSupplierItemXref:tracking-changes = true. 
            create ttSupplierItemXRef.
            assign ttSupplierItemXref.SupplierIDNum = ttSupplierItem.SupplierIDNum
                   ttSupplierItemXref.ItemNum       = ttSupplierItem.ItemNum.
            
            finally:
                temp-table ttSupplierItemXref:tracking-changes = false. 
            end finally.       
        end.
       
        // use for each biSupplierItem to reach the deleted  
        for each biSupplierItem where row-state(biSupplierItem) = row-deleted:
            create ttItem.
            buffer-copy biSupplierItem to ttItem.
            
            create ttSupplierItemXRef.
            assign ttSupplierItemXref.SupplierIDNum = biSupplierItem.SupplierIDNum
                   ttSupplierItemXref.ItemNum       = biSupplierItem.ItemNum.
                   
            // delete with tracking changes on to submit to server 
            temp-table ttSupplierItemXref:tracking-changes = true. 
            delete ttSupplierItemXref.
            finally:
                temp-table ttSupplierItemXref:tracking-changes = false. 
            end finally.       
        end.           
                   
        finally:
            temp-table ttSupplierItemXref:tracking-changes = false. 
        end finally.     
    end method. 
    
    /* Create data for poublic (UI/WEB) dataset from server dataset  */
    method protected void CreateSupplierItems(input dataset dsSupplier, input dataset dsSupplierServer):
        empty temp-table ttSupplierItem.
        for each ttSupplierItemXref: 
            find ttItem where ttItem.ItemNum = ttSupplierItemXref.ItemNum.
            create ttSupplierItem. 
            ttSupplierItem.SupplierIDNum = ttSupplierItemXRef.SupplierIDNum.
            buffer-copy ttItem to ttSupplierItem.
        end.    
    end method.    
        
end class.
