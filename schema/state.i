/*------------------------------------------------------------------------------
 File        : schema/state.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:55.059-04:00
 Notes       : Mapped to database sports2020 table State  
------------------------------------------------------------------------------*/
define temp-table ttState no-undo serialize-name "states" {1}  before-table biState
   field Region                           as character   serialize-name "region"
   field State                            as character   serialize-name "state"
   field StateName                        as character   serialize-name "stateName"
   field zz_seq                           as int64       serialize-hidden
   index State as unique State
   index zz_seq as primary zz_seq
   .