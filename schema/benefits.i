/*------------------------------------------------------------------------------
 File        : schema/benefits.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/13/2026 07:21:31.585-04:00
 Notes       : Mapped to database sports2020 table Benefits  
------------------------------------------------------------------------------*/
define temp-table ttBenefits no-undo serialize-name "benefits" {1}  before-table biBenefits
   field DependentCare                    as integer     serialize-name "dependentCare"
   field EmpNum                           as integer     serialize-name "empNum"
   field HealthCare                       as character   serialize-name "healthCare"
   field LifeInsurance                    as integer     serialize-name "lifeInsurance"
   field MedicalSpending                  as integer     serialize-name "medicalSpending"
   field Pension401K                      as integer     serialize-name "pension401K"
   field StockPurchase                    as integer     serialize-name "stockPurchase"
   field zz_seq                           as int64       serialize-hidden
   index EmpNo as unique EmpNum
   index zz_seq as primary zz_seq
   .