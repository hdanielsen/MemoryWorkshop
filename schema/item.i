/*------------------------------------------------------------------------------
 File        : schema/item.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:54.541-04:00
 Notes       : Mapped to database sports2020 table Item  
------------------------------------------------------------------------------*/
define temp-table ttItem no-undo serialize-name "items" {1}  before-table biItem
   // Allocated - inventory reserved for customers
   field Allocated                        as integer     serialize-name "allocated"
   field CatDescription                   as character   serialize-name "catDescription"
   field Category1                        as character   serialize-name "category1"
   field Category2                        as character   serialize-name "category2"
   field CatPage                          as integer     serialize-name "catPage"
   field ItemImage                        as clob        serialize-name "itemImage"
   field ItemImageCLob                    as clob        serialize-hidden  
   field ItemName                         as character   serialize-name "itemName"
   field ItemNum                          as integer     serialize-name "itemNum"
   // MinQty - Replenishment threshold.
   field MinQty                           as integer     serialize-name "minQuantity"
   // OnHand - inventory physically present
   field OnHand                           as integer     serialize-name "onHand"
   // OnOrder - inventory expected from suppliers
   field OnOrder                          as integer     serialize-name "onOrder"
   field Price                            as decimal     serialize-name "price"
   // ReOrder = Fixed replenishment quantity.
   field ReOrder                          as integer     serialize-name "reOrder"
   field Special                          as character   serialize-name "special"
   field Weight                           as decimal     serialize-name "weight"
   field zz_seq                           as int64       serialize-hidden
   index Category2ItemName Category2 ItemName
   index CategoryItemName Category1 ItemName
   index ItemNum as unique ItemNum
   index zz_seq as primary zz_seq
   .
   