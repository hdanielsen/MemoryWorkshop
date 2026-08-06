/*------------------------------------------------------------------------------
 File        : schema/order.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:09.095-04:00
 Notes       : Mapped to database sports2020 table Order  
------------------------------------------------------------------------------*/
define temp-table ttOrder no-undo serialize-name "orders" {1}  before-table biOrder
   field BillToID                         as integer     serialize-name "billToID"
   field Carrier                          as character   serialize-name "carrier"
   field CreditCard                       as character   serialize-name "creditCard"
   field CustNum                          as integer     serialize-name "custNum"
   field Instructions                     as character   serialize-name "instructions"
   field OrderDate                        as date        serialize-name "orderDate"
   field OrderNum                         as integer     serialize-name "orderNum"
   field OrderStatus                      as character   serialize-name "orderStatus"
   field PO                               as character   serialize-name "purchaseOrder"
   field PromiseDate                      as date        serialize-name "promiseDate"
   field SalesRep                         as character   serialize-name "salesRep"
   field ShipDate                         as date        serialize-name "shipDate"
   field ShipToID                         as integer     serialize-name "shipToID"
   field Terms                            as character   serialize-name "terms"
   field WarehouseNum                     as integer     serialize-name "warehouseNum"
   field zz_seq                           as int64       serialize-hidden
   index CustOrder as unique CustNum OrderNum
   index OrderDate OrderDate
   index OrderNum as unique OrderNum
   index OrderStatus OrderStatus
   index SalesRep SalesRep
   index zz_seq as primary zz_seq
   .