/*------------------------------------------------------------------------
    File        : IQueryDefinition
    Purpose     : Interface that describes an abstract query definition
    Syntax      :
    Description :
    Notes       :
  ----------------------------------------------------------------------*/

using Pmfo.Core.BusinessLogic.IQueryEntry from propath.
using Ccs.BusinessLogic.IQuerySortEntry from propath.

interface Pmfo.Core.BusinessLogic.IQueryDefinition:

    /*------------------------------------------------------------------------------
        Purpose: Returns the list of query predicates or query groups for this query
                 definition
        Notes:
    ------------------------------------------------------------------------------*/
    define public property QuerySelection as IQueryEntry no-undo
    get.

    /*------------------------------------------------------------------------------
        Purpose: Returns the list of query sort entries
        Notes:
    ------------------------------------------------------------------------------*/
    define public property QuerySort as Ccs.BusinessLogic.IQuerySortEntry extent no-undo
    get.
    
    method public logical AddEntries(pQueryEntries as IQueryEntry extent).
    method public logical AddEntry(pQueryEntry as IQueryEntry).
    method public logical SetSort(pSort as IQuerySortEntry):
    method public logical SetSort(pSort as IQuerySortEntry extent):
    
end interface .
