
/*------------------------------------------------------------------------
    File        : IGetDataTableResponse
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/

 
using Ccs.BusinessLogic.IGetTableResultCountResponse from propath.

interface Pmfo.Core.BusinessLogic.IGetDataTableResponse inherits IGetTableResultCountResponse: 
     /*------------------------------------------------------------------------------
        Purpose: Returns the paging context to be passed back to the business
                 entity when requesting the next set
        Notes:   Used for Paging. This value typically consists of record identifiers
                 (e.g. DATA-SOURCE ROWID retrieved by the RESTART-ROWID function
                 or other data required by the Business Entity to build the next
                 set of data in a follow up call).
    ------------------------------------------------------------------------------*/
    define public property NextPagingContext as character no-undo
    get.

    /*------------------------------------------------------------------------------
        Purpose: Returns the paging context to be passed back to the business
                 entity when requesting the previous set
        Notes:   Used for Paging. This value typically consists of record identifiers
                 (e.g. DATA-SOURCE ROWID retrieved by the RESTART-ROWID function
                 or other data required by the Business Entity to build the previous
                 set of data in a follow up call).
    ------------------------------------------------------------------------------*/
    define public property PreviousPagingContext as character no-undo
    get.

    /*------------------------------------------------------------------------------
        Purpose: Returns the name of the ProDataset Table
        Notes:   Identifies the table this IGetDataTableResponse belongs to
    ------------------------------------------------------------------------------*/
    define public property TableName as character no-undo
    get.
    
    define public property Public                as logical no-undo get. set.  
    define public property TrimExtentFields      as character no-undo get. set.  
       // force return of  nextPageLink as context for NextPagingContext 
    define public property UseNextPageLink       as logical no-undo get. set.
           
end interface.