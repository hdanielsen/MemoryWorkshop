/*------------------------------------------------------------------------------
 File        : DataSource.ItemDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:54.632-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.

class DataSource.ItemDS inherits DataSource:

    {schema/item.i reference-only}

    define public override property EntityName as character init "items" no-undo get.

    constructor ItemDS():
        super(buffer Item:handle).
    end constructor.

    method protected void Bind( input table ttItem bind):
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
        assign ttitem.ItemNum = next-value (NextItemnum).
    end method.
    
    method override protected void DeleteBeginTransValidate( input dataset-handle  phDataset):
        if can-find(first OrderLine where OrderLine.ItemNum = biItem.itemNum) then
            ThrowBufferError(substitute ("Orderlines exist for Item &1. Cannot delete.",biItem.itemnum)).  
            
        if can-find(first Bin where Bin.ItemNum = biItem.itemNum) then
            ThrowBufferError(substitute ("Bins exist for Item &1. Cannot delete.",biItem.itemnum)).  
           
    end method.   
    
     // override to use static delete due to schema validation
    method public override logical SaveRow(phBeforeBuffer as handle):       
        if phBeforeBuffer:row-state = row-deleted then
        do: 
            FindAndCompareSource(phBeforeBuffer).
            delete item. //static due to schema delete validation
            return true.      
        end.
        else 
            return super:SaveRow(phBeforeBuffer).
           
    end method.   
    
end class.
