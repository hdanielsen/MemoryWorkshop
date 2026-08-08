/*------------------------------------------------------------------------------
 File        : DataSource.SupplierDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:56:00.298-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.

class DataSource.SupplierDS inherits DataSource:

    {schema/supplier.i reference-only}

    define public override property EntityName as character init "suppliers" no-undo get.

    constructor SupplierDS():
        super(buffer Supplier:handle).
    end constructor.

    method protected void Bind( input table ttSupplier bind):
    end method.

    method override protected void PrepareBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        pBuffer:set-callback("After-Row-fill","AfterRow").
        hTable = pBuffer:table-handle.
        bind (table-handle hTable bind).        
    end method.
    
    method override protected void PrepareSaveBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        hTable = pBuffer:table-handle.
        bind (table-handle hTable bind).        
    end method.
    
    method override protected void CreateBeginTransValidate( input dataset-handle  phDataset):
        define variable iNewOrderNum as integer no-undo.
        
        ttSupplier.SupplierIDNum = next-value(NextSupplNum).
    end method. 
end class.
