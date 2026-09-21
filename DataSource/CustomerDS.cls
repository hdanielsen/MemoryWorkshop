/*------------------------------------------------------------------------------
 File        : DataSource.CustomerDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:09.770-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Core.Error.BadRequestError from propath.

class DataSource.CustomerDS inherits DataSource:

    {schema/customer.i reference-only}

    define public override property EntityName as character init "customers" no-undo get.

    constructor CustomerDS():
        super(buffer Customer:handle).
    end constructor.

    method protected void Bind( input table ttCustomer bind):
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
        assign ttCustomer.CustNum = next-value (NextCustnum).
    end method.
    
    method override protected void WriteBeginTransValidate( input dataset-handle  phDataset):
        if row-state(ttCustomer) = row-modified and ttCustomer.custNum <> biCustomer.custNum then 
            ThrowBufferError(substitute ("CustNum is readonly. Cannot change Customer Cust Num &1 to &2",biCustomer.CustNum,ttCustomer.custNum),"CustNUm"). 
        
    end method.
    
    
    method override protected void DeleteBeginTransValidate( input dataset-handle  phDataset):
        /* Customer record cannot be deleted if outstanding invoices are found */
        find first invoice no-lock where Invoice.CustNum = biCustomer.CustNum no-error.
        find first order no-lock of customer no-error.
        if available invoice and invoice.amount <= invoice.totalpaid + invoice.adjustment then do:
            if not available order then 
                return.
           // else throw error at end of this method     
        end.
        else if available Invoice then 
            ThrowBufferError(substitute("Outstanding Unpaid Invoice Exists, cannot delete Customer &1",biCustomer.custnum)).  
        
        if available Order then
            ThrowBufferError(substitute ("Open orders exist for Customer &1. Cannot delete.",biCustomer.custnum)).  
    end method.
     
    
    
end class.
