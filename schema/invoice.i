/*------------------------------------------------------------------------------
 File        : schema/invoice.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:48.663-04:00
 Notes       : Mapped to database sports2020 table Invoice  
------------------------------------------------------------------------------*/
define temp-table ttInvoice no-undo serialize-name "invoices" {1}  before-table biInvoice
   field Adjustment                       as decimal     serialize-name "adjustment"
   field Amount                           as decimal     serialize-name "amount"
   field CustNum                          as integer     serialize-name "custNum"
   field InvoiceDate                      as date        serialize-name "invoiceDate"
   field Invoicenum                       as integer     serialize-name "invoicenum"
   field OrderNum                         as integer     serialize-name "orderNum"
   field ShipCharge                       as decimal     serialize-name "shipCharge"
   field TotalPaid                        as decimal     serialize-name "totalPaid"
   field zz_seq                           as int64       serialize-hidden
   index CustNum CustNum
   index InvoiceDate InvoiceDate
   index InvoiceNum as unique Invoicenum
   index OrderNum OrderNum
   index zz_seq as primary zz_seq
   .