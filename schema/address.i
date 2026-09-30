/*------------------------------------------------------------------------------
 File        : schema/address.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Hdaniels 
 Created     : 09/07/2026 
 Notes       : Normalized from sports2020 table BillTo, Customer, Employee, ShipTo 
               Supplier and Warehouse   
------------------------------------------------------------------------------*/
define temp-table ttAddress no-undo serialize-name "addresses" {1}  before-table biAddress
   field Address                          as character   serialize-name "address"
   field Address2                         as character   serialize-name "address2"
   field City                             as character   serialize-name "city"
   field Country                          as character   serialize-name "country"
   field PostalCode                       as character   serialize-name "postalCode"
   field State                            as character   serialize-name "state"
   field billToCount                      as integer     serialize-name "billToCount"
   field customerCount                    as integer     serialize-name "customerCount"
   field employeeCount                    as integer     serialize-name "employeeCount"
   field shipToCount                      as integer     serialize-name "shipToCount"
   field supplierCount                    as integer     serialize-name "supplierCount"
   field warehouseCount                   as integer     serialize-name "warehouseCount"
   field addressId                        as character   serialize-name "id"
   field zz_seq                           as int64       serialize-name "seq"
   index key as unique addressid 
   index Address as unique Address Address2 City Country PostalCode
   index zz_seq as primary zz_seq
   .