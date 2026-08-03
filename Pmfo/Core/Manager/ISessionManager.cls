
/*------------------------------------------------------------------------
    File        : ISessionManager
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Ccs.Common.ISessionManager.

interface Pmfo.Core.Manager.ISessionManager inherits ISessionManager:  
    define public property QueryTimeout   as integer   no-undo get. set. 
end interface.