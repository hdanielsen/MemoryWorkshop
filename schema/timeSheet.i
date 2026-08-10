/*------------------------------------------------------------------------------
 File        : schema/timeSheet.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 07:08:58.573-04:00
 Notes       : Mapped to database sports2020 table TimeSheet  
------------------------------------------------------------------------------*/
define temp-table ttTimeSheet no-undo serialize-name "timeSheets" {1}  before-table biTimeSheet
 //  field AMTimeIn                         as character   serialize-name "timeInAM"
 //  field AMTimeOut                        as character   serialize-name "timeOutAM"
   field DayRecorded                      as date        serialize-name "dayRecorded"
   field EmpNum                           as integer     serialize-name "empNum"
   field OvertimeHours                    as decimal     serialize-name "overtimeHours"
 //  field PMTimeIn                         as character   serialize-name "timeInPM"
 //  field PMTimeOut                        as character   serialize-name "timeOutPM"
   field RegularHours                     as decimal     serialize-name "regularHours"
   field TypeRecorded                     as character   serialize-name "typeRecorded"
   field TimeIn                           as datetime    serialize-name "timeIn"
   field TimeOut                          as datetime    serialize-name "timeOut"
   field zz_seq                           as int64       serialize-hidden
   index EmpNoDayRecorded as unique EmpNum DayRecorded
   index zz_seq as primary zz_seq
   .