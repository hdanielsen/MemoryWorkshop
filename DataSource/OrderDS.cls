/*------------------------------------------------------------------------------
 File        : DataSource.OrderDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:09.216-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Util.UpdateUtil from propath.

class DataSource.OrderDS inherits DataSource:

    {schema/order.i reference-only}
   
    define public override property EntityName as character init "orders" no-undo get.

    constructor OrderDS():
        super(buffer Order:handle).
    end constructor.

    method protected void Bind( input table ttOrder bind):
    end method.
    
    method override protected void PrepareBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        pBuffer:set-callback("After-Row-fill","AfterRow").
        hTable = pBuffer:table-handle.
        this-object:Bind (table-handle hTable bind).        
    end method.
    
    method override protected void PrepareSaveBuffer( input pBuffer as handle ):
        define variable hTable      as handle  no-undo.
 
        hTable = pBuffer:table-handle.
        this-object:Bind (table-handle hTable bind).    
    end method.
    
    method override protected void CreateBeginTransValidate( input dataset-handle  phDataset):
        define variable iNewOrderNum as integer no-undo.
        iNewOrderNum = next-value (NextOrdnum).
        // propagate key change to all related tables and assign to self 
        UpdateUtil:UpdateKey(buffer ttOrder:handle, "OrderNum",iNewOrderNum).
        
        if ttOrder.orderDate <> today then 
        do: 
            AddWarning("Order Date was set to today").
            assign ttOrder.orderDate = today.
        end.    
        if ttOrder.promiseDate = ? or ttOrder.promiseDate le ttOrder.OrderDate then
        do: 
            AddWarning("Promise Date was set to two weeks from now").
            assign ttOrder.promiseDate = today + 14.
        end. 
         
    end method.
    
    method override protected void WriteBeginTransValidate( input dataset-handle  phDataset):
        if row-state(ttOrder) = row-modified and ttOrder.OrderNum <> biOrder.orderNum then 
            ThrowBufferError(substitute ("Ordernum is readonly. Cannot change Order&1 to &2", biOrder.orderNum,ttOrder.orderNum),"OrderNUm"). 
        
    end method.    
    
    method override protected void DeleteBeginTransValidate( input dataset-handle  phDataset):
        // deleted orderlines is expected to be submitted from UI or bL 
        // Children are deleted first so they will be deeted at this point 
        if can-find(first OrderLine where OrderLine.OrderNum = biOrder.OrderNum) then
            ThrowBufferError(substitute ("Orderlines exist for Order &1. Cannot delete.",biOrder.Ordernum)).  
  
    end method.    
    
       // override to use static delete due to schema validation
    method public override logical SaveRow(phBeforeBuffer as handle):       
        if phBeforeBuffer:row-state = row-deleted then
        do: 
            FindAndCompareSource(phBeforeBuffer).
            delete order. //static due to schema delete validation
            return true.      
        end.
        else 
            return super:SaveRow(phBeforeBuffer).
           
    end method.   
    
    
end class.
