/*------------------------------------------------------------------------------
 File        : schema/inventoryTrans.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:42.654-04:00
 Notes       : Mapped to database sports2020 table InventoryTrans  
------------------------------------------------------------------------------*/
define temp-table ttInventoryTrans no-undo serialize-name "inventoryTrans" {1}  before-table biInventoryTrans
   field BinNum                           as integer     serialize-name "binNum"
   field InvTransNum                      as integer     serialize-name "invTransNum"
   field InvType                          as character   serialize-name "invType"
   field ItemNum                          as integer     serialize-name "itemNum"
   field OrderNum                         as integer     serialize-name "orderNum"
   field PONum                            as integer     serialize-name "pONum"
   field Qty                              as integer     serialize-name "qty"
   field TransDate                        as date        serialize-name "transDate"
   field TransTime                        as character   serialize-name "transTime"
   field WarehouseNum                     as integer     serialize-name "warehouseNum"
   field zz_seq                           as int64       serialize-hidden
   index InvTransNum InvTransNum
   index zz_seq as primary zz_seq
   .