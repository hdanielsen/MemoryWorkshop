/*------------------------------------------------------------------------------
 File        : schema/customer.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:09.667-04:00
 Notes       : Mapped to database sports2020 table Customer  
------------------------------------------------------------------------------*/
define temp-table ttCustomer no-undo serialize-name "customers" {1}  before-table biCustomer
   field Address                          as character   serialize-name "address"
   field Address2                         as character   serialize-name "address2"
   field Balance                          as decimal     serialize-name "balance"
   field City                             as character   serialize-name "city"
   field Comments                         as character   serialize-name "comments"
   field Contact                          as character   serialize-name "contact"
   field Country                          as character   serialize-name "country"
   field CreditLimit                      as decimal     serialize-name "creditLimit"
   field CustNum                          as integer     serialize-name "custNum"
   field Discount                         as integer     serialize-name "discount"
   field EmailAddress                     as character   serialize-name "emailAddress"
   field Fax                              as character   serialize-name "fax"
   field Name                             as character   serialize-name "name"
   field Phone                            as character   serialize-name "phone"
   field PostalCode                       as character   serialize-name "postalCode"
   field SalesRep                         as character   serialize-name "salesRep"
   field State                            as character   serialize-name "state"
   field Terms                            as character   serialize-name "terms"
   field zz_seq                           as int64       serialize-hidden
   index CountryPost Country PostalCode
   index CustNum as unique CustNum
   index Name Name
   index SalesRep SalesRep
   index zz_seq as primary zz_seq
   .