
/*------------------------------------------------------------------------
    File        : IQueryEntry
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Ccs.BusinessLogic.IQueryEntry.
using Ccs.BusinessLogic.JoinEnum from propath.

interface Pmfo.Core.BusinessLogic.IQueryEntry inherits IQueryEntry:  
    // for error messages 
    method public character ToString(phBuffer as handle,plUseSerializeName as logical).
    method public character ToString(phBuffer as handle,plUseSerializeName as logical, plTrimParenthesis as logical).
    
end interface.