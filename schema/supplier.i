/*------------------------------------------------------------------------------
 File        : schema/supplier.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:56:00.256-04:00
 Notes       : Mapped to database sports2020 table Supplier  
------------------------------------------------------------------------------*/
define temp-table ttSupplier no-undo serialize-name "suppliers" {1}  before-table biSupplier
   field Address                          as character   serialize-name "address"
   field Address2                         as character   serialize-name "address2"
   field City                             as character   serialize-name "city"
   field Comments                         as character   serialize-name "comments"
   field Country                          as character   serialize-name "country"
   field Discount                         as integer     serialize-name "discount"
   field LoginDate                        as date        serialize-name "loginDate"
   field Name                             as character   serialize-name "name"
   field Password                         as character   serialize-name "password"
   field Phone                            as character   serialize-name "phone"
   field PostalCode                       as character   serialize-name "postalCode"
   field ShipAmount                       as integer     serialize-name "shipAmount"
   field State                            as character   serialize-name "state"
   field SupplierIDNum                    as integer     serialize-name "supplierIDNum"
   field zz_seq                           as int64       serialize-hidden
   index SupplierID as unique SupplierIDNum
   index zz_seq as primary zz_seq
   .