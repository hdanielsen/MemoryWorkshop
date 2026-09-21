/*------------------------------------------------------------------------------
 File        : DataSource.AddressDS
 Purpose     : Unified view of addresses  BillTo, Customer, Employee, ShipTo 
               Supplier and Warehouse   
 Syntax      : 
 Description :  
 Author(s)   : hdaniels
 Created     : 09/07/2026 
 Notes       : 
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.DataLayer.DataSource from propath.
using Pmfo.Core.Error.UnsupportedOperationError from propath.
using Pmfo.Core.Error.ApplicationError from propath.
using OpenEdge.Core.StringConstant from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Util.Array from propath.
using Pmfo.Util.QueryUtil from propath.
 

class DataSource.AddressDS inherits DataSource:

    {schema/Address.i reference-only}
   
    define public override property EntityName as character init "addresses" no-undo get.
     
    define protected variable GetRequest as IGetDataTableRequest no-undo.
    
    constructor AddressDS():
        super().
        NoConnectNeeded = false. // override super with no param
        NoQueryCreate = true. // ensures GetBufferHandles is called 
    end constructor.

    method protected void Bind( input table ttAddress bind):
    end method.
 
    method override protected void PrepareBuffer( input pBuffer as handle ):
        define variable hTable as handle no-undo.
        pBuffer:set-callback("before-fill","BeforeFill").
        hTable = pBuffer:table-handle.
        this-object:Bind (table-handle hTable bind).
    end method.
    
    method override protected void PrepareSaveBuffer( input pBuffer as handle ):
        undo, throw new UnsupportedOperationError("Update of Addresses").
    end method.
    
    method protected override handle extent GetBufferHandles(pRequest as IGetDataTableRequest,pParentRequest as  IGetDataTableRequest):
        GetRequest = pRequest.              
        return Array:ToArray(buffer BillTo:handle,buffer Customer:handle,buffer Employee:handle,buffer ShipTo:handle, buffer Supplier:handle,buffer Warehouse:handle).                                                                       
    end method.                                                                                                                        
                                                                                                                                       
    method public void BeforeFill( input dataset-handle phDataset ):
        define variable hQuery      as handle    no-undo.
        define variable cSort       as character no-undo.
        define variable iCount      as integer   no-undo.
        define variable iNumRecords as integer   no-undo.
        define variable lDelete     as logical   no-undo.
        define variable iBuffer     as integer   no-undo.
        define variable cFilter     as character no-undo.
        
        do iBuffer = 1 to extent(BufferHandles):
            FillFromSource(input table ttAddress by-reference, BufferHandles[iBuffer],iBuffer).
        end.
        
        if valid-object(GetRequest) then 
        do:
            cSort = GetRequest:SortExpression.
            cFilter = GetRequest:QueryString.
            iNumRecords = GetRequest:NumRecords. 
            message GetRequest:QueryDefinition:QuerySelection:ToString() skip
                    GetRequest:QueryDefinition:GetPredicateFieldReferences() skip
                  "has"  GetRequest:QueryDefinition:HasPredicate("country")
                    
                    
            view-as alert-box.
        end. 
        message cFilter
            view-as alert-box.
        if cSort > "" or iNumRecords > 0 then 
        do:
            create query hQuery.
            hQuery:add-buffer(DataBuffer).
            hQuery:query-prepare(trim(substitute("for each &1 &2",
                DataBuffer:name,
                if cSort > "" then cSort else "")
                )
                ).
           
            hQuery:query-open().
            hQuery:get-first.
            do while DataBuffer:avail:
                iCount = iCount + 1.
                hQuery:get-next.
                if lDelete = false and iNumRecords > 0 and iCount > iNumRecords then do:
                    lDelete = true. 
                    NextRowKey = DataBuffer::AddressId.
                    NumRecords = iCount - 1.
                end.    
                if lDelete then DataBuffer:buffer-delete.
                else DataBuffer::zz_seq = iCount. // sorting for json
            end.
        end.
        
        return no-apply. // prevent auto fill that still happens     
        finally:
            if valid-handle(hQuery) then 
                delete object hQuery.         
        end finally.
    end method.
    
    // fill ttaddres with data from database tables with address info
    method protected void FillFromSource(input table ttAddress, phBuffer as handle, piKeyNumber as integer):
        define variable hQuery        as handle no-undo.
        define variable lFound        as logical no-undo.
        define variable hCountfield   as handle no-undo.  
        define variable hCountryfield as handle no-undo.  
        
        create query hQuery.
        
        hQuery:add-buffer (phBuffer).
        hQuery:query-prepare (substitute("for each &1 no-lock",phBuffer:name)).
        hQuery:query-open().
        hQuery:get-first().
        
        hCountField   = buffer ttAddress:buffer-field(substitute("&1Count",phBuffer:name)). 
        // track country field since some tables do not have country 
        hCountryfield = phBuffer:buffer-field("country") no-error.   
         
        do while phBuffer:avail:
            
            lFound =  buffer ttAddress:find-unique(
                substitute(
                "where address = '&1' and address2 = '&2' and City = '&3' and Country = '&4' and postalCode = '&5' and state = '&6'",
                phBuffer::address,
                phBuffer::address2,
                phBuffer::city,
                if valid-handle(hCountryField) then hCountryField:buffer-value else "USA",
                phBuffer::postalCode,
                phBuffer::state
                     
                )
                ) no-error.
           
            if not lFound then do: 
                create ttAddress.
                assign
                    ttAddress.AddressId  = "|||||" // there is a fill method that block use of fill function... 
                    ttAddress.Address    = phBuffer::Address
                    ttAddress.Address2   = phBuffer::Address2
                    ttAddress.City       = phBuffer::City
                    ttAddress.Country    = if valid-handle(hCountryField) then hCountryField:buffer-value else "USA"                   
                    ttAddress.PostalCode = phBuffer::PostalCode                    
                    ttAddress.State      = phBuffer::State                    
                    .
             
            end.
            assign
                hCountField:buffer-value = hCountField:buffer-value + 1.
            entry(piKeyNumber,ttAddress.AddressId,"|") = GetBufferKey(phbuffer,phBuffer:rowid).
            
            hQuery:get-next.
             
        end. // do while phBuffer:avail
        
    end method.
    
    method protected character GetBufferKey(phSourceBuffer as handle,pRowid as rowid):
          
        define variable iField          as integer   no-undo.
        
        define variable hFld            as handle    no-undo.
        define variable cField          as character no-undo.
        define variable cValue          as character no-undo.
        define variable cRowKey         as character no-undo.
        define variable lHasSpaceOrPlus as logical   no-undo.
        define variable cKeys           as character no-undo.
        
        phSourceBuffer:find-by-rowid (pRowid,no-lock).
        
        if phSourceBuffer:avail then 
        do:
            cKeys = phSourceBuffer:Keys.
            do iField = 1 to num-entries(cKeys).
                cField = entry(iField,cKeys).
                hFld   = phSourceBuffer:buffer-field(cField).
                if hFld:data-type begins "date" then
                do:
                    cValue = quoter(iso-date(hFld:buffer-value),"'").
                end.
                else if (hfld:data-type = "character" or hFld:data-type = "longchar") then
                do:
                    assign
                        cValue          = hFld:buffer-value
                        lHasSpaceOrPlus = index(CValue,StringConstant:SPACE) > 0 or index(cValue,"+") > 0
                        cValue      = quoter(cValue,"'")
                        .
                end.        
                else
                    cValue = hFld:buffer-value.
               
                /* if hasspaceorplus use field name in expression so we can safely decode bad encoders like certain REST testing tools...
                   some REST tools will encode space as +, but not if there already is a + 
                   this is indeterministic since a value with + and no space could origin from both space and +
                */     
                if num-entries(cKeys) = 1 and not lHasSpaceOrPlus then 
                do:
                    cRowKey = cValue.
                end.
                else do:
                    cRowKey = cRowKey 
                        + (if cRowKey = "" then "" else " and ")
                        + substitute("&1 eq &2",cField,cValue)  
                        . 
                        
                end.     
            end.
        end.
        else 
            undo, throw new ApplicationError("Data source not available for row key").               
        
        return cRowKey.
        
        catch e1 as ApplicationError :
            undo, throw e1.
        end.
        catch e2 as Progress.Lang.Error :
           
            undo, throw new ApplicationError("Could not identify row key",e2).               
        end catch. 
        
    end method.    
    
end class.
