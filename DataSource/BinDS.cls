/*------------------------------------------------------------------------------
 File        : DataSource.BinDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/13/2026 07:22:00.502-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.

class DataSource.BinDS inherits DataSource:

    {schema/bin.i reference-only}

    define public override property EntityName as character init "bins" no-undo get.

    constructor BinDS():
        super(buffer Bin:handle).
    end constructor.

    method protected void Bind( input table ttBin bind):
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
        assign ttBin.BinNum = next-value(NextBinNum).
    end method.
    
end class.
