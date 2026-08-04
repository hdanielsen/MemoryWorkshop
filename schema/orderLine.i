/*------------------------------------------------------------------------------
 File        : schema/orderLine.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:15.159-04:00
 Notes       : Mapped to database sports2020 table OrderLine  
------------------------------------------------------------------------------*/
define temp-table ttOrderLine no-undo serialize-name "orderLines" {1}  before-table biOrderLine
   field Discount                         as integer     serialize-name "discount"
   field ExtendedPrice                    as decimal     serialize-name "extendedPrice"
   field ItemNum                          as integer     serialize-name "itemNum"
   field LineNum                          as integer     serialize-name "lineNum"
   field OrderLineStatus                  as character   serialize-name "orderLineStatus"
   field OrderNum                         as integer     serialize-name "orderNum"
   field Price                            as decimal     serialize-name "price"
   field Qty                              as integer     serialize-name "quantity"
   field zz_seq                           as int64       serialize-hidden
   index ItemNum ItemNum
   index OrderLine as unique OrderNum LineNum
   index OrderLineStatus OrderLineStatus
   index zz_seq as primary zz_seq
   .