
/*------------------------------------------------------------------------
    File        : IHttpErrorStatus
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : 2019
    Notes       : 
  ----------------------------------------------------------------------*/

using OpenEdge.Net.HTTP.StatusCodeEnum from propath.
using Progress.Lang.Error from propath.

interface Pmfo.Core.Error.IHttpErrorStatus :  
    define public property StatusCode as StatusCodeEnum no-undo get. 
end interface.