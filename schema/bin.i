/*------------------------------------------------------------------------------
 File        : schema/bin.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/13/2026 07:22:00.418-04:00
 Notes       : Mapped to database sports2020 table Bin  
------------------------------------------------------------------------------*/
define temp-table ttBin no-undo serialize-name "bins" {1}  before-table biBin
   field BinName                          as character   serialize-name "binName"
   field BinNum                           as integer     serialize-name "binNum"
   field ItemNum                          as integer     serialize-name "itemNum"
   field Qty                              as integer     serialize-name "quantity"
   field WarehouseNum                     as integer     serialize-name "warehouseNum"
   field zz_seq                           as int64       serialize-hidden
   index BinNum as unique BinNum
   index ItemNum ItemNum
   index WarehouseNumItemNum WarehouseNum ItemNum
   index zz_seq as primary zz_seq
   .