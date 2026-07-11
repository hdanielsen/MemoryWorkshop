 
 /*------------------------------------------------------------------------
    File        : IQueryPredicate
    Purpose     : extends Ccs with character properties for value and values
    Syntax      : 
    Description : Different from Ccs - since dynamic queries should wrap values 
                  in quotes to ensure correct decimal and date resolution the 
                  data in prepare-string there is no need to have primitive holders 
                  for the values
    Author(s)   : hdaniels
       ----------------------------------------------------------------------*/


block-level on error undo, throw.

using Ccs.BusinessLogic.IQueryPredicate from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.

interface Pmfo.Core.BusinessLogic.IQueryPredicate inherits IQueryPredicate, IQueryEntry: 
    define public property StringValue  as character         no-undo get. set. 
    define public property StringValues as character extent  no-undo get. set. 
end interface.