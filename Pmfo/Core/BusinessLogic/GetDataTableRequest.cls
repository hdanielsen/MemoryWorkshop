 
 /*------------------------------------------------------------------------
    File        : GetDataTableRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using Ccs.BusinessLogic.IQuerySortEntry from propath.
using OpenEdge.Core.Assert from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.IQueryDefinition from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.
using Pmfo.Core.BusinessLogic.QueryDefinition from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.

class Pmfo.Core.BusinessLogic.GetDataTableRequest implements IGetDataTableRequest: 
    /* Returns the number of records requested by the caller of the Business Entity getData method */
    define public property NumRecords as int64 no-undo get. set.
     
    /* Returns   paging context */
    define public property PagingContextEntry as IQueryEntry no-undo get. set. 
   
    /* Returns the paging context for compatibility  */
    define public property PagingContext           as character no-undo 
        get(): 
            if valid-object(PagingContextEntry) then
                return PagingContextEntry:ToString().
            else 
                return "".    
        end.
    
     
    /* Returns the abstract query defintion for this request */
    define public property QueryDefinition as IQueryDefinition no-undo get. set. 
         
    /* Returns the number of records to skip */
    define public property Skip as int64 no-undo 
        get():
            if this-object:skip = ? then 
                return 0.
            return this-object:skip.
        end.     
        set. 
    
    /* Returns the name of the ProDataset Table */
    define public property TableName as character no-undo 
        get.
        private set. 
    
    define public property ClientOnly      as logical no-undo  get. set.
    define public property FindUnique      as logical no-undo  get. set.
    define public property Count           as logical no-undo  get. set.
    define public property PageBackward    as logical no-undo  get. set.
    define public property ExternalPaging  as logical no-undo  get. set.
      // convenience to check if paging
    define public property IsPaging as logical no-undo
         get(): 
             return NumRecords > 0 or this-object:Skip > 0 or valid-object(PagingContextEntry). 
         end. 
         
    // set to true by DataRequestBuilder so the server can identify where to support innerjoin  
    define public property IsMainTable    as logical no-undo  get. set.
    
    // requested expand internal table names 
    define public property ClientExpands       as character   no-undo  get. set.
         
    // derrived from expands with option innerjoin=true - stored with table name
    define public property InnerJoinExpands as character no-undo  get. set.
     /* Returns   paging context */
   
    
    // derrived from apply with qualified aggregate options  
    define public property InnerJoinAggregates as character   no-undo  get. set. 
    //  see interface
    define public property ManualServerInnerJoins as character   no-undo  get. set.
    
      // performance option - see comment in interfave
    define public property SelectFields   as character no-undo get. set. 
    /* Returns the Query String for this table */
    define public property QueryString as character no-undo 
         get():
             define variable cQuery as character no-undo.
        if FindUnique then
            cQuery = subst("find &1",TableName).
        else    
            cQuery = subst("for each &1",TableName).
        
        if valid-object(QueryDefinition) then 
            cQuery = cQuery + " " + QueryDefinition:ToString().
        return cQuery. 
    end.     
   
    define public property SortExpression     as character   no-undo  
         get():
             define variable i as integer no-undo.
             define variable cExpression as character no-undo.
             if valid-object(QueryDefinition) then
             do:
                 do i = 1 to extent(QueryDefinition:QuerySort):
                     cExpression = cExpression 
                        + (if cExpression = "" then "" else " ")
                        + QueryDefinition:QuerySort[i]:ToString().
                 end.
                 return cExpression.
             end.
             return "".    
         end.  
       
    constructor public GetDataTableRequest ( input pTableName as character ):
        super ().
        Assert:NotNull(pTableName, 'Table name').
        assign this-object:TableName = pTableName.        
    end constructor.
    
    constructor public GetDataTableRequest ( input phHandle as handle ):
        super ().
        Assert:NotNull(phHandle, 'Table or buffer handle').
        case phHandle:type:
            when "buffer" then 
                assign this-object:TableName = phHandle:table-handle:name.        
            when "temp-table" then 
                assign this-object:TableName = phHandle:name.        
            otherwise
                undo, throw new IllegalArgumentError(substitute("Handle is of type &1",phHandle:type)).              
        end case.
    end constructor.
    
    
    method public logical AddQueryEntry(pQueryEntry as IQueryEntry):
        if not valid-object(QueryDefinition) then
        do: 
            QueryDefinition = new QueryDefinition().
        end.  
        return QueryDefinition:AddEntry(pQueryEntry).
    end method.
    
    
    method public logical SetQuerySort(pSort as IQuerySortEntry):
        if valid-object(QueryDefinition) then
            QueryDefinition:SetSort(pSort).
        else 
           QueryDefinition = new QueryDefinition(pSort).
        
        return true.    
    end method.
    
    method public logical SetQuerySort(pSort as IQuerySortEntry extent):
        if valid-object(QueryDefinition) then
            QueryDefinition:SetSort(pSort).
        else 
           QueryDefinition = new QueryDefinition(pSort).
        
        return true.    
    end method.
    
    
    
    method override public character ToString():
        return substitute('&1: query:&2; numrec:&3; skip:&4 cntxt:&5 count:&6',
                this-object:TableName,
                this-object:QueryString,
                this-object:NumRecords,
                this-object:Skip,
                this-object:PagingContext,
                this-object:Count
                ).
    end method.
end class.