/*------------------------------------------------------------------------------
 File        : DataSource.OrderLineDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:15.243-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.

class DataSource.OrderLineDS inherits DataSource:

    {schema/orderLine.i reference-only}

    define public override property EntityName as character init "orderLines" no-undo get.

    constructor OrderLineDS():
        super(buffer OrderLine:handle).
    end constructor.

    method protected void Bind( input table ttOrderLine bind):
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
    
    method override protected void WriteBeginTransValidate( input dataset-handle  phDataset):
        if row-state(ttOrderLine) = row-modified 
                                   and (ttOrderLine.OrderNum <> biOrderLine.orderNum 
                                        or 
                                        ttOrderLine.LineNum <> biOrderLine.LineNum) then 
            ThrowBufferError(substitute ("Order Num and Line num are readonly. Cannot change keys of OrderLine &1 &2",  biOrderLine.orderNum, biOrderLine.LineNUm)). 
        
    end method.    
    
    
     
    
end class.
