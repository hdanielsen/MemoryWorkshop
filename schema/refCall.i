/*------------------------------------------------------------------------------
 File        : schema/refCall.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:35.950-04:00
 Notes       : Mapped to database sports2020 table RefCall  
------------------------------------------------------------------------------*/
define temp-table ttRefCall no-undo serialize-name "refCalls" {1}  before-table biRefCall
   field CallDate                         as date        serialize-name "callDate"
   field CallNum                          as character   serialize-name "callNum"
   field CustNum                          as integer     serialize-name "custNum"
   field Parent                           as character   serialize-name "parent"
   field SalesRep                         as character   serialize-name "salesRep"
   field Txt                              as character   serialize-name "txt"
   field zz_seq                           as int64       serialize-hidden
   index CallNum as unique CallNum
   index CustNum as unique CustNum CallNum
   index Sibling as unique Parent CallNum
   index zz_seq as primary zz_seq
   .