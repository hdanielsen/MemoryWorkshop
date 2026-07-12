/*------------------------------------------------------------------------------
 File        : schema/billTo.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/12/2026 07:22:00.116-04:00
 Notes       : Mapped to database sports2020 table BillTo  
------------------------------------------------------------------------------*/
define temp-table ttBillTo no-undo serialize-name "billTos" {1}  before-table biBillTo
   field Address                          as character   serialize-name "address"
   field Address2                         as character   serialize-name "address2"
   field BillToID                         as integer     serialize-name "billToID"
   field City                             as character   serialize-name "city"
   field Contact                          as character   serialize-name "contact"
   field CustNum                          as integer     serialize-name "custNum"
   field Name                             as character   serialize-name "name"
   field Phone                            as character   serialize-name "phone"
   field PostalCode                       as character   serialize-name "postalCode"
   field State                            as character   serialize-name "state"
   field zz_seq                           as int64       serialize-hidden
   index CustNumBillTo as unique CustNum BillToID
   index zz_seq as primary zz_seq
   .