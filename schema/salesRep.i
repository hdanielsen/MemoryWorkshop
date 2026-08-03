/*------------------------------------------------------------------------------
 File        : schema/salesRep.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:40.499-04:00
 Notes       : Mapped to database sports2020 table SalesRep  
------------------------------------------------------------------------------*/
define temp-table ttSalesRep no-undo serialize-name "salesReps" {1}  before-table biSalesRep
   field Region                           as character   serialize-name "region"
   field RepName                          as character   serialize-name "repName"
   field SalesRep                         as character   serialize-name "salesRep"
   field zz_seq                           as int64       serialize-hidden
   index SalesRep as unique SalesRep
   index zz_seq as primary zz_seq
   .