/*------------------------------------------------------------------------------
 File        : schema/warehouse.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:56:23.725-04:00
 Notes       : Mapped to database sports2020 table Warehouse  
------------------------------------------------------------------------------*/
define temp-table ttWarehouse no-undo serialize-name "warehouses" {1}  before-table biWarehouse
   field Address                          as character   serialize-name "address"
   field Address2                         as character   serialize-name "address2"
   field City                             as character   serialize-name "city"
   field Country                          as character   serialize-name "country"
   field Phone                            as character   serialize-name "phone"
   field PostalCode                       as character   serialize-name "postalCode"
   field State                            as character   serialize-name "state"
   field WarehouseName                    as character   serialize-name "warehouseName"
   field WarehouseNum                     as integer     serialize-name "warehouseNum"
   field zz_seq                           as int64       serialize-hidden
   index WarehouseName WarehouseName
   index WarehouseNum as unique WarehouseNum
   index zz_seq as primary zz_seq
   .