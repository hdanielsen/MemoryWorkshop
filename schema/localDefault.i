/*------------------------------------------------------------------------------
 File        : schema/localDefault.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:00.760-04:00
 Notes       : Mapped to database sports2020 table LocalDefault  
------------------------------------------------------------------------------*/
define temp-table ttLocalDefault no-undo serialize-name "localDefaults" {1}  before-table biLocalDefault
   field Country                          as character   serialize-name "country"
   field CurrencySymbol                   as character   serialize-name "currencySymbol"
   field DateFormat                       as character   serialize-name "dateFormat"
   field LocalDefNum                      as integer     serialize-name "localDefNum"
   field PostalFormat                     as character   serialize-name "postalFormat"
   field PostalLabel                      as character   serialize-name "postalLabel"
   field Region1Label                     as character   serialize-name "region1Label"
   field Region2Label                     as character   serialize-name "region2Label"
   field TelFormat                        as character   serialize-name "telFormat"
   field zz_seq                           as int64       serialize-hidden
   index LocalDefNum as unique LocalDefNum
   index zz_seq as primary zz_seq
   .