/*------------------------------------------------------------------------------
 File        : DataSource.SalesRepQuotaDS
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   :  
 Created     : 08/032026  
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Core.Error.NotImplementedError from propath.

class DataSource.SalesRepQuotaDS inherits DataSource:

    {schema/salesRepQuota.i reference-only}

    define public override property EntityName as character init "salesRepQuotas" no-undo get.

    constructor SalesRepQuotaDS():
        super(buffer SalesRep:handle).
    end constructor.

    method protected void Bind( input table ttSalesRepQuota bind):
    end method.

    method override protected void PrepareBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        pBuffer:set-callback("Before-fill","BeforeFill").
        hTable = pBuffer:table-handle.
        this-object:Bind (table-handle hTable bind).        
    end method.
    
    method override protected void PrepareSaveBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        hTable = pBuffer:table-handle.
        Bind (table-handle hTable bind).        
    end method.
    
    
    method override protected void WriteBeginTransValidate( input dataset-handle  phDataset):
        undo, throw new NotImplementedError("Save using SalesRepDS").
    end method.    
    
    method override protected void DeleteBeginTransValidate( input dataset-handle  phDataset):
        undo, throw new NotImplementedError("Delete using SalesRepDS").
    end method.
    
    method public void BeforeFill( input dataset-handle phDataset ):
        define variable iSeqNo as integer no-undo.
        define variable iTran     as integer no-undo.
        define variable cQuery    as character no-undo.
        define variable iGroup    as integer no-undo.
        define variable iMonth    as integer no-undo.
        
        QueryHandle:Query-open().
        QueryHandle:get-first().
        
        do while avail salesrep:
            do iMonth = 1 to extent(SalesRep.MonthQuota):
                create ttSalesRepQuota.
                assign 
                    ttSalesRepQuota.salesrep = SalesRep.salesrep
                    ttSalesRepQuota.month    = IMonth
                    ttSalesRepQuota.quota    = SalesRep.MonthQuota[iMonth]
                    iSeqNo                   = iSeqNo + 1
                    ttSalesRepQuota.zz_seq   = iSeqNo
                    .
            end.    
            QueryHandle:get-next().
        end.
        if Count then 
            TotalCount = iSeqNo.
        return no-apply. // prevent auto fill that still happens     
    
    end method.
    
end class.
