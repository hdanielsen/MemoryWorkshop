/*------------------------------------------------------------------------------
 File        : DataSource.RefCallDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:36.035-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.

class DataSource.RefCallDS inherits DataSource:

    {schema/refCall.i reference-only}

    define public override property EntityName as character init "refCalls" no-undo get.

    constructor RefCallDS():
        super(buffer RefCall:handle).
    end constructor.

    method protected void Bind( input table ttRefCall bind):
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
        assign ttRefCall.CallNum = string(next-value (NextRefNum),"999999").
    end method.
end class.
