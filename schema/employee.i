/*------------------------------------------------------------------------------
 File        : schema/employee.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:21.598-04:00
 Notes       : Mapped to database sports2020 table Employee  
------------------------------------------------------------------------------*/
define temp-table ttEmployee no-undo serialize-name "employees" {1}  before-table biEmployee
   field Address                          as character   serialize-name "address"
   field Address2                         as character   serialize-name "address2"
   field BirthDate                        as date        serialize-name "birthDate"
   field City                             as character   serialize-name "city"
   field DeptCode                         as character   serialize-name "deptCode"
   field EmpNum                           as integer     serialize-name "empNum"
   field FirstName                        as character   serialize-name "firstName"
   field HomePhone                        as character   serialize-name "homePhone"
   field LastName                         as character   serialize-name "lastName"
   field Position                         as character   serialize-name "position"
   field PostalCode                       as character   serialize-name "postalCode"
   field SickDaysLeft                     as integer     serialize-name "sickDaysLeft"
   field StartDate                        as date        serialize-name "startDate"
   field State                            as character   serialize-name "state"
   field VacationDaysLeft                 as integer     serialize-name "vacationDaysLeft"
   field WorkPhone                        as character   serialize-name "workPhone"
   field zz_seq                           as int64       serialize-hidden
   index DeptCode DeptCode
   index EmpNo as unique EmpNum
   index Name as unique LastName FirstName
   index zz_seq as primary zz_seq
   .