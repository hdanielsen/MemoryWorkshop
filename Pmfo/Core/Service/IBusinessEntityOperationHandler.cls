
/*------------------------------------------------------------------------
    File        : IBusinessEntityOperationHandler
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/

using OpenEdge.Core.Collections.IStringStringMap from propath.
using OpenEdge.Web.DataObject.IOperationHandler from propath.
using Pmfo.Core.BusinessLogic.IEntity from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Progress.Lang.Object from propath.

interface Pmfo.Core.Service.IBusinessEntityOperationHandler inherits IOperationHandler:  
                                                
    method public JsonObject ExecuteRead(
        pcMethod as character,
        pcBaseAppTransportServiceURI as character,
        pcServiceURI as character,
        pURIQuery as IStringStringMap,
        pEntity as IEntity). 
        
    method public JsonObject ExecuteUpdate(
        pcMethod as character,
        pMessageBody as Object,
        pcBaseAppTransportServiceURI as character,
        pcServiceURI as character,
        pURIQuery as IStringStringMap,
        pEntity as IEntity).
            
end interface.