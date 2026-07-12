/*------------------------------------------------------------------------------
 File        : DataSource.BenefitsDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/12/2026 07:10:08.360-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.

class DataSource.BenefitsDS inherits DataSource:

    {schema/benefits.i reference-only}

    define public override property EntityName as character init "benefits" no-undo get.

    constructor BenefitsDS():
        super(buffer Benefits:handle).
    end constructor.

    method protected void Bind( input table ttBenefits bind):
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
    
end class.
