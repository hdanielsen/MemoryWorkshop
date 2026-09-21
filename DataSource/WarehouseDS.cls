/*------------------------------------------------------------------------------
 File        : DataSource.WarehouseDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:56:23.788-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Util.StringUtil from propath.

class DataSource.WarehouseDS inherits DataSource:

    {schema/warehouse.i reference-only}

    define public override property EntityName as character init "warehouses" no-undo get.

    constructor WarehouseDS():
        super(buffer Warehouse:handle).
    end constructor.

    method protected void Bind( input table ttWarehouse bind):
    end method.

    method override protected void PrepareBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        pBuffer:set-callback("After-Row-fill","AfterRow").
        hTable = pBuffer:table-handle.
        Bind (table-handle hTable bind).        
    end method.
    
    method override protected void PrepareSaveBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        hTable = pBuffer:table-handle.
        Bind (table-handle hTable bind).        
    end method.
    
    method override protected void CreateBeginTransValidate( input dataset-handle  phDataset):
        ttWarehouse.WarehouseNum = next-value (NextWarenum).
    end method.
    
    method protected character GetChildList(pWarehouseNum as integer):
        define variable cChildren as character no-undo.
        if can-find(first Bin where Bin.WarehouseNum = pWarehousenum) then 
            cChildren = "Bin".
        
        if can-find(first InventoryTrans where InventoryTrans.WarehouseNum eq pWarehouseNum) then
            cChildren = left-trim(substitute ("&1,&2","Inventory Transaction"),",").
           
        return cChildren.
    
    end method.
    
    method override protected void DeleteBeginTransValidate( input dataset-handle  phDataset):
        define variable cChildren as character no-undo.
        cChildren = GetChildList(biWarehouse.WarehouseNum).
        if cChildren > "" then
            ThrowBufferError( 
                substitute("Cannot delete employee &1 that has &2 records", 
                           biWarehouse.WarehouseNum,
                           StringUtil:GetMessageFromEntries(cChildren)
                          )   
            ).
    end method.
    
    method override protected void WriteBeginTransValidate( input dataset-handle  phDataset):
       define variable cChildren as character no-undo.
       if row-state(ttWarehouse) = row-modified 
                                   and ttWarehouse.WarehouseNum <> biWarehouse.WarehouseNum then
       do: 
          cChildren = GetChildList(biWarehouse.WarehouseNum).
          if cChildren > "" then
              ThrowBufferError( 
                substitute("Cannot change Warehouse Num &1 to &2. The Warehouse has &3 records.", 
                           biWarehouse.WarehouseNum,
                           ttWarehouse.WarehouseNum,
                           StringUtil:GetMessageFromEntries(cChildren)
                          )   
            ).
        end.    
    end method.    
    
        
end class.
