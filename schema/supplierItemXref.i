/*------------------------------------------------------------------------------
 File        : schema/supplierItemXref.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:56:06.400-04:00
 Notes       : Mapped to database sports2020 table SupplierItemXref  
------------------------------------------------------------------------------*/
define temp-table ttSupplierItemXref no-undo serialize-name "supplierItemXrefs" {1}  before-table biSupplierItemXref
   field ItemNum                          as integer     serialize-name "itemNum"
   field SupplierIDNum                    as integer     serialize-name "supplierIDNum"
   field zz_seq                           as int64       serialize-hidden
   index ItemNumSupplierID as unique ItemNum SupplierIDNum
   index SupplieridItemNum as unique SupplierIDNum ItemNum
   index zz_seq as primary zz_seq
   .