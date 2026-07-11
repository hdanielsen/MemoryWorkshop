/*------------------------------------------------------------------------
    File        : IQueryDefinition
    Purpose     : Interface that describes an abstract query definition
    Syntax      :
    Description :
    Notes       :
  ----------------------------------------------------------------------*/

using Pmfo.Core.BusinessLogic.IQueryEntry from propath.

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

end interface .
