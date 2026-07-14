/*------------------------------------------------------------------------------
 File        : schema/shipTo.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:46.947-04:00
 Notes       : Mapped to database sports2020 table ShipTo  
------------------------------------------------------------------------------*/
define temp-table ttShipTo no-undo serialize-name "shipTos" {1}  before-table biShipTo
   field Address                          as character   serialize-name "address"
   field Address2                         as character   serialize-name "address2"
   field City                             as character   serialize-name "city"
   field Comments                         as character   serialize-name "comments"
   field Contact                          as character   serialize-name "contact"
   field CustNum                          as integer     serialize-name "custNum"
   field Name                             as character   serialize-name "name"
   field Phone                            as character   serialize-name "phone"
   field PostalCode                       as character   serialize-name "postalCode"
   field ShipToID                         as integer     serialize-name "shipToID"
   field State                            as character   serialize-name "state"
   field zz_seq                           as int64       serialize-hidden
   index CustNumShipTo as unique CustNum ShipToID
   index zz_seq as primary zz_seq
   .