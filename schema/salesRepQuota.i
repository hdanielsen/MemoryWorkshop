/*------------------------------------------------------------------------------
 File        : schema/salesRepQuota.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   :  
 Created     : 08/03/2026 
 Notes       : expands database sports2020 table SalesRep.monthQuota arat  
------------------------------------------------------------------------------*/
define temp-table ttSalesRepQuota no-undo serialize-name "salesRepQuotas" {1}  before-table biSalesRepQuota
   field SalesRep                         as character   serialize-name "salesRep"
   field Month                            as integer     serialize-name "month"
   field Quota                            as int64       serialize-name "quota"
   field zz_seq                           as int64       serialize-hidden
   index SalesRepMonth as unique SalesRep Month
   index zz_seq as primary zz_seq
   .