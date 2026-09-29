/*------------------------------------------------------------------------------
 File        : DataSource.InvoiceDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:48.762-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.

class DataSource.InvoiceDS inherits DataSource:

    {schema/invoice.i reference-only}

    define public override property EntityName as character init "invoices" no-undo get.

    constructor InvoiceDS():
        super(buffer Invoice:handle).
    end constructor.

    method protected void Bind( input table ttInvoice bind):
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
        ttInvoice.invoicenum = next-value(NEXTINVNUM).
        if ttinvoice.InvoiceDate <> today then 
            AddWarning(substitute ("Invoice &1 Invpoice date set to today")).
        ttInvoice.InvoiceDate = today.
            
    end method.
    
    method override protected void DeleteBeginTransValidate( input dataset-handle  phDataset):
        // invoice date hack for memory workshop test
        if biInvoice.InvoiceDate gt today and  biInvoice.Amount > biInvoice.TotalPaid + biInvoice.Adjustment then
           ThrowBufferError(
              substitute("Cannot delete Invoice &1. The Amount is greater than TotalPaid + Adjustment",biInvoice.Invoicenum) 
           ). 
           
    end method.
    
    
end class.
