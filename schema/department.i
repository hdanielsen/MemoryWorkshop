/*------------------------------------------------------------------------------
 File        : schema/department.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:15.650-04:00
 Notes       : Mapped to database sports2020 table Department  
------------------------------------------------------------------------------*/
define temp-table ttDepartment no-undo serialize-name "departments" {1}  before-table biDepartment
   field DeptCode                         as character   serialize-name "departmentCode"
   field DeptName                         as character   serialize-name "departmentName"
   field zz_seq                           as int64       serialize-hidden
   index DeptCode as unique DeptCode
   index zz_seq as primary zz_seq
   .