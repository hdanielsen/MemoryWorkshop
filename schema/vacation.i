/*------------------------------------------------------------------------------
 File        : schema/vacation.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:56:18.701-04:00
 Notes       : Mapped to database sports2020 table Vacation  
------------------------------------------------------------------------------*/
define temp-table ttVacation no-undo serialize-name "vacations" {1}  before-table biVacation
   field EmpNum                           as integer     serialize-name "empNum"
   field EndDate                          as date        serialize-name "endDate"
   field StartDate                        as date        serialize-name "startDate"
   field zz_seq                           as int64       serialize-hidden
   index EmpNoStartDate as unique EmpNum StartDate
   index zz_seq as primary zz_seq
   .