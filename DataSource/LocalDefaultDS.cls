/*------------------------------------------------------------------------------
 File        : DataSource.LocalDefaultDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:00.798-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.

class DataSource.LocalDefaultDS inherits DataSource:

    {schema/localDefault.i reference-only}

    define public override property EntityName as character init "localDefaults" no-undo get.

    constructor LocalDefaultDS():
        super(buffer LocalDefault:handle).
    end constructor.

    method protected void Bind( input table ttLocalDefault bind):
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
        assign ttLocalDefault.LocalDefNum = next-value(NextLocalDefnum).
    end method.
       
    method public override logical SaveRow(phBeforeBuffer as handle):       
        if phBeforeBuffer:row-state = row-deleted then
        do: 
            FindAndCompareSource(phBeforeBuffer).
            delete LocalDefault. //static due to schema delete validation
            return true.      
        end.
        else 
            return super:SaveRow(phBeforeBuffer).
           
     end method.   
end class.
