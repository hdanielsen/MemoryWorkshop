/*------------------------------------------------------------------------------
 File        : DataSource.EmployeeDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:21.679-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Util.Array from propath.
using Pmfo.Util.StringUtil from propath.

class DataSource.EmployeeDS inherits DataSource:

    {schema/employee.i reference-only}

    define public override property EntityName as character init "employees" no-undo get.

    constructor EmployeeDS():
        super(buffer Employee:handle).
    end constructor.

    method protected void Bind( input table ttEmployee bind):
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
        assign ttEmployee.EmpNum  = next-value (NextEmpnum).
    end method.
    
    method override protected void WriteBeginTransValidate( input dataset-handle  phDataset):
        define variable cChildren as character no-undo.
        if row-state(ttEmployee) = row-modified and ttEmployee.EmpNum <> biEmployee.empNum then
        do: 
            cChildren = GetChildList(biEmployee.EmpNum).
            if cChildren > "" then
              ThrowBufferError( 
                substitute("Cannot change employee EmpNum &1 to &2. The Employee has &3 records.", 
                           biEmployee.EmpNum,
                           ttEmployee.EmpNum,
                           StringUtil:GetMessageFromEntries(cChildren)
                          )   
            ).
        end.    
    end method.
    
    method override protected void DeleteBeginTransValidate( input dataset-handle  phDataset):
        define variable cChildren as character no-undo.
        cChildren = GetChildList(biEmployee.EmpNum).
        if cChildren > "" then
            ThrowBufferError( 
                substitute("Cannot delete employee &1 that has &2 records", 
                           biEmployee.EmpNum,
                           StringUtil:GetMessageFromEntries(cChildren)
                          )   
            ).
    end method.
    
    
    method protected character GetChildList(pEmpNum as integer):
        define variable cChildren as character no-undo.
        if can-find(first Benefits where Benefits.EmpNum = pEmpNum) then 
            cChildren = "Benefits".
        
        if can-find(first Family where Family.EmpNum = pEmpNum) then 
            cChildren = left-trim(substitute ("&1,&2","Family"),",").
            
        if can-find(first Timesheet where Timesheet.EmpNum = pEmpNum) then 
            cChildren = left-trim(substitute ("&1,&2","Timesheet"),",").
            
        if can-find(first Family where Family.EmpNum = pEmpNum) then 
            cChildren = left-trim(substitute ("&1,&2","Family"),",").
        
        if can-find(first Vacation where Vacation.EmpNum = pEmpNum) then 
            cChildren = left-trim(substitute ("&1,&2","Family"),",").
        
        return cChildren.
    
    end method.
    
    
end class.
