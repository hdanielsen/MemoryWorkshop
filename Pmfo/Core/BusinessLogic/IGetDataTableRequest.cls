
/*------------------------------------------------------------------------
    File        : IGetDataTableRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/

using Ccs.BusinessLogic.IQuerySortEntry from propath.
using Pmfo.Core.BusinessLogic.IQueryDefinition from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.

interface Pmfo.Core.BusinessLogic.IGetDataTableRequest:
     
     /*------------------------------------------------------------------------------
        Purpose: Returns the paging context
        Notes:   Used for Paging. This value typically consists of record identifiers
                 (e.g. DATA-SOURCE ROWID retrieved by the RESTART-ROWID function of
                 the previous call into IBusinessEntity:GetData or other data required
                 by the Business Entity to build the next set of data).
                 The value passed in is the value of the NextPagingContext property
                 of the IGetDataTableResponse for the table
    ------------------------------------------------------------------------------*/
    define public property PagingContext as character no-undo
    get.

    /*------------------------------------------------------------------------------
        Purpose: Returns the number of records requested by the caller of the
                 Business Entity getData method
        Notes:   Used for Paging. When the value is 0, the business entity is expected
                 to return all (remaining) records. When the value is ? the business
                 entity is expected to return a reasonable default number of records
                 to the caller. Negative values indicate paging in backwards direction
                 is requested.
    ------------------------------------------------------------------------------*/
    define public property NumRecords as int64 no-undo
    get. set.

    /*------------------------------------------------------------------------------
        Purpose: Returns the abstract query defintion for this request
        Notes:   Typically used as an alternative to the QueryString
    ------------------------------------------------------------------------------*/
    define public property QueryDefinition as IQueryDefinition no-undo
    get. set.

    /*------------------------------------------------------------------------------
        Purpose: Returns the Query String for this table
        Notes:   Query Strings must be expressed using the fields of the temp-table.
                 It's the task of the Business Entity or Data Access class to translate
                 the Query String into the form understood by the actual DBMS in case
                 field names require mapping etc.
                 Query Strings must be provided in the following format
                 CustNum = 42
                 CustNum = 42 AND OrderStatus = "Ordered"
    ------------------------------------------------------------------------------*/
    define public property QueryString as character no-undo
    get.

    /*------------------------------------------------------------------------------
        Purpose: Returns the number of records to skip
        Notes:   Used for Paging. Typically the value of (page# - 1) * NumRecords is
                 passed in when requesting a certain page of result records
    ------------------------------------------------------------------------------*/
    define public property Skip as int64 no-undo
    get. set.

    /*------------------------------------------------------------------------------
        Purpose: Returns the name of the ProDataset Table
        Notes:   Identifies the table this IGetDataTableRequest belongs to
    ------------------------------------------------------------------------------*/
    define public property TableName as character no-undo
    get. 
    
    define public property SelectFields   as character no-undo get. set. 
         
    /* Returns   paging context */
    define public property FindUnique          as logical     no-undo  get. set.
    define public property Count               as logical     no-undo  get. set.
    define public property PageBackward        as logical     no-undo  get. set.
    define public property SortExpression      as character   no-undo  get.  
    
    define public property IsPaging            as logical      no-undo get. 
    define public property PagingContextEntry  as IQueryEntry no-undo get. set.  
    
    
    method public logical AddQueryEntry(pQueryEntry as IQueryEntry).
    method public logical SetQuerySort(pSort as IQuerySortEntry).
    method public logical SetQuerySort(pSort as IQuerySortEntry extent).
         
end interface.