 
 /*------------------------------------------------------------------------
    File        : IQueryPredicate
    Purpose     : extends Ccs with character properties for value and values
    Syntax      : 
    Description : Since dynamic queries should weap values in quotes to ensure 
                  correct decimal and date resolutiio fi the data in prepare-string
                  there is no need to have primitive holders for the values
    Author(s)   : hdaniels
    Created     : Tue Apr 02 15:51:12 EDT 2019
    Notes       : The implementaiton must deal woth the primitveholder properties
                  and either prevent them from being used or ensure they work 
                  with these fields 
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using Ccs.BusinessLogic.IQueryPredicate from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.

interface Pmfo.Core.BusinessLogic.IQueryPredicate inherits IQueryPredicate, IQueryEntry: 
    define public property StringValue  as character         no-undo get. set. 
    define public property StringValues as character extent  no-undo get. set. 
end interface.