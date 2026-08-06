/*------------------------------------------------------------------------------
 File        : schema/purchaseOrder.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:29.869-04:00
 Notes       : Mapped to database sports2020 table PurchaseOrder  
------------------------------------------------------------------------------*/
define temp-table ttPurchaseOrder no-undo serialize-name "purchaseOrders" {1}  before-table biPurchaseOrder
   field DateEntered                      as date        serialize-name "dateEntered"
   field PONum                            as integer     serialize-name "purchaseOrderNum"
   field POStatus                         as character   serialize-name "purchaseOrderStatus"
   field ReceiveDate                      as date        serialize-name "receiveDate"
   field SupplierIDNum                    as integer     serialize-name "supplierIDNum"
   field zz_seq                           as int64       serialize-hidden
   index PONum as unique PONum
   index zz_seq as primary zz_seq
   .