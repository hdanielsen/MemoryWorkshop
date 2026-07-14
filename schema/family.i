/*------------------------------------------------------------------------------
 File        : schema/family.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:27.910-04:00
 Notes       : Mapped to database sports2020 table Family  
------------------------------------------------------------------------------*/
define temp-table ttFamily no-undo serialize-name "families" {1}  before-table biFamily
   field BenefitDate                      as date        serialize-name "benefitDate"
   field BirthDate                        as date        serialize-name "birthDate"
   field CoveredOnBenefits                as logical     serialize-name "coveredOnBenefits"
   field EmpNum                           as integer     serialize-name "empNum"
   field Relation                         as character   serialize-name "relation"
   field RelativeName                     as character   serialize-name "relativeName"
   field zz_seq                           as int64       serialize-hidden
   index EmpNoRelativeName as unique EmpNum RelativeName
   index zz_seq as primary zz_seq
   .