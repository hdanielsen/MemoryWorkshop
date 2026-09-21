/*------------------------------------------------------------------------
    File        : IQueryDefinition
    Purpose     : Interface that describes an abstract query definition
    Syntax      :
    Description :
    Notes       :
  ----------------------------------------------------------------------*/

using Ccs.BusinessLogic.IQuerySortEntry from propath.
using Ccs.BusinessLogic.QueryOperatorEnum from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.
using Pmfo.Core.BusinessLogic.IQueryPredicate from propath.

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

    method public character GetFieldReferences().
    method public character GetSortFieldReferences().
    method public character GetPredicateFieldReferences().
    method public character GetPredicateFieldReferences(pOperator as QueryOperatorEnum).  
    method public character GetPredicateFieldReferences(pOperators as QueryOperatorEnum extent).
    
    method public IQuerySortEntry extent GetSortEntries(pcField as character).
    method public IQuerySortEntry extent GetSortEntries(pcFields as character extent).
    method public IQueryEntry extent GetEntries(pcField as character).
    method public IQueryEntry extent GetEntries(pcFields as character extent).
    method public IQueryEntry extent GetEntries(pcField as character, pOperator as QueryOperatorEnum).
    method public IQueryEntry extent GetEntries(pcFields as character extent, pOperator as QueryOperatorEnum).
    method public IQueryEntry extent GetQualifiedEntries(pcQualifier as character).
    method public logical HasPredicate(pcField as character).
    method public logical HasPredicate(pcFields as character extent).
    method public logical HasPredicate(pcField as character, pOperator as QueryOperatorEnum).
    method public logical HasPredicate(pcFields as character extent, pOperator as QueryOperatorEnum).
    method public IQueryPredicate GetPredicate(pcField as character, pOperator as QueryOperatorEnum).
    method public IQueryPredicate GetPredicate(pcField as character).
    method public logical RemoveEntries(pQueryEntries as IQueryEntry extent).
    method public logical RemoveEntry(pQueryEntry as IQueryEntry).
  
    
end interface .
