/*------------------------------------------------------------------------------
 File        : schema/purchaseOrderLine.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 07:08:36.234-04:00
 Notes       : Mapped to database sports2020 table POLine  
------------------------------------------------------------------------------*/
define temp-table ttPurchaseOrderLine no-undo serialize-name "purchaseOrderLines" {1}  before-table biPurchaseOrderLine
   field Discount                         as integer     serialize-name "discount"
   field ExtendedPrice                    as decimal     serialize-name "extendedPrice"
   field ItemNum                          as integer     serialize-name "itemNum"
   field LineNum                          as integer     serialize-name "lineNum"          init ? // allow create of lines before po 
   field POLineStatus                     as character   serialize-name "lineStatus"       
   field PONum                            as integer     serialize-name "purchaseOrderNum" init ? // allow create of lines before po
   field Price                            as decimal     serialize-name "price"
   field Qty                              as integer     serialize-name "quantity"
   field zz_seq                           as int64       serialize-hidden
   index PONumLineNum as unique PONum LineNum
   index zz_seq as primary zz_seq
   .