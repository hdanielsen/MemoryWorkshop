/*------------------------------------------------------------------------------
 File        : DataSource.SalesRepDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:55:40.536-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.

class DataSource.SalesRepDS inherits DataSource:

    {schema/salesRep.i reference-only}
    {schema/salesRepQuota.i reference-only}
    
    define public override property EntityName as character init "salesReps" no-undo get.

    constructor SalesRepDS():
        super(buffer SalesRep:handle).
    end constructor.

    method protected void Bind( input table ttSalesRep bind):
    end method.
    
    method protected void BindQuota( input table ttSalesRepQuota bind):
    end method.
    
    method override protected void PrepareBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        pBuffer:set-callback("After-Row-fill","AfterRow").
        hTable = pBuffer:table-handle.
        Bind (table-handle hTable bind).        
    end method.
    
    method override protected void PrepareSaveBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        define variable i as integer no-undo.
        hTable = pBuffer:table-handle.
        
        Bind (table-handle hTable bind).
        do i = 1 to pBuffer:num-child-relations:
            if pBuffer:get-child-relation (i):child-buffer:name = "ttSalesRepQuota" then
            do:
                hTable  = pBuffer:get-child-relation (i):child-buffer:table-handle.  
                BindQuota(input table-handle hTable bind).
            end.      
        end.        
         
    end method.
    
    method public override void BeforeUpdate (input dataset-handle phDataset).
        // turn off row-state so they are ignored by mointhquotads
        for each biSalesRepQuota:
             buffer biSalesRepQuota:accept-row-changes. // turn off row state - todo set to 0 for delete??)    
        end.    
    end method.
    
    method public override logical SaveRow(phBeforeBuffer as handle):
        define variable lOk as logical no-undo.
        define variable rid as rowid no-undo.       
        if phBeforeBuffer:row-state = row-deleted then
        do: 
            FindAndCompareSource(phBeforeBuffer).
            delete salesrep. //static due to schema delete validation
            return true.      
        end.
        else do:
            rid = phBeforeBuffer:after-rowid.
            lok = super:SaveRow(phBeforeBuffer).
            phBeforeBuffer:after-buffer:find-by-rowid(rid).
            FindSource(exclusive). 
            
            for each ttSalesRepQuota where ttSalesRepQuota.salesrep = SalesRep.SalesRep:
                SalesRep.MonthQuota[ttSalesrepQuota.Month] = ttSalesrepQuota.Quota.
            end.     
        end.   
     end method.   
end class.
