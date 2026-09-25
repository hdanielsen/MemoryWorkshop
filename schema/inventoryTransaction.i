/*------------------------------------------------------------------------------
 File        : schema/inventoryTransaction.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 08/02/2026 09:49:42.131-04:00
 Notes       : Mapped to database sports2020 table InventoryTrans  
------------------------------------------------------------------------------*/
define temp-table ttInventoryTransaction no-undo serialize-name "inventoryTransactions" {1}  before-table biInventoryTransaction
   field BinNum                           as integer     serialize-name "binNum"
   field InvTransNum                      as integer     serialize-name "invTransNum"
   field InvType                          as character   serialize-name "invType"
   field ItemNum                          as integer     serialize-name "itemNum"
   field OrderNum                         as integer     serialize-name "orderNum"
   field PONum                            as integer     serialize-name "purchaseOrderNum"
   field Qty                              as integer     serialize-name "quantity"
   field TransactionTime                  as datetime    serialize-name "transactionTime"
   field WarehouseNum                     as integer     serialize-name "warehouseNum"
   field zz_seq                           as int64       serialize-hidden
   index InvTransNum as unique InvTransNum // not unique in db!  
   index zz_seq as primary zz_seq
   .