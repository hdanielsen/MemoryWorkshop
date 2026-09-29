
/*------------------------------------------------------------------------
    File        : IClientRequest
    Purpose     : Track client properties from web request. Used to create
                  IGetRequest and IGetDataRequest to pass to BusinessEntity  
    Syntax      : 
    Author(s)   : hdaniels
    Created     : Sun Mar 31 15:46:35 EDT 2019
    Notes       : 
  ----------------------------------------------------------------------*/

using OpenEdge.Core.Collections.IStringStringMap from propath.
using OpenEdge.Core.Collections.ICollection from propath.

interface Pmfo.Core.Service.IClientRequest:  
    define public property ServiceURI             as character no-undo get.  
    define public property Method                 as character no-undo get.  
    define public property Collections            as character extent no-undo get.  
    define public property KeyWheres              as character extent no-undo get. set.
    define public property UriQuery               as IStringStringMap no-undo get. 
     
    define public property MetaDataProp as character  no-undo get.  
    define public property ContextProperties as char extent no-undo get.  
    
end interface.