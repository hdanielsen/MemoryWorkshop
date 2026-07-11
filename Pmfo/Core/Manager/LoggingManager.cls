 
/*------------------------------------------------------------------------
   File        : LoggingManager
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : hdaniels
   Created     : Thu Jun 06 10:03:56 EDT 2019
   Notes       : 
 ----------------------------------------------------------------------*/

 

block-level on error undo, throw.

using Ccs.Common.Application from propath.
using Pmfo.Core.Manager.ILoggingManager from propath.
using OpenEdge.Web.IWebRequest from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.
using Pmfo.Core.Error.NotImplementedError from propath.
using Pmfo.Core.Manager.IServiceManager from propath.
using Pmfo.Core.Manager.Manager from propath.
using Pmfo.Util.IMemoryLogger from propath.
using Pmfo.Util.QueryUtil from propath.
using Progress.Json.ObjectModel.JsonArray from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Pmfo.Core.Manager.ISessionManager from propath.

class Core.Manager.LoggingManager inherits Manager implements ILoggingManager: 
    
    define public property IsWebRequestLogActive as logical no-undo get. set.
    
    define public property LogEveryWebRequest as logical no-undo get. set.
    
    define protected property ServiceManager as IServiceManager no-undo
        get():
            return cast(Application:ServiceManager,IServiceManager).
        end get.
        
    
       
    define protected property MemoryLogger as IMemoryLogger  no-undo
        get():
            // let the ServiceManager control the lifecycle 
            return cast(ServiceManager:getService(get-class(IMemoryLogger)),IMemoryLogger).
        end.
         
    constructor public LoggingManager (  ):
        super ().
    end constructor.
 
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    
    
    method override public void Initialize(  ):
        ImportConfig().
    end method.
    
    /*------------------------------------------------------------------------------
    Purpose:
    Notes:
   ------------------------------------------------------------------------------*/
    method protected void ImportConfig(  ):
        define variable oJson  as JsonObject no-undo.
        define variable i      as integer    no-undo.
        define variable oArray as JsonArray  no-undo.
        do on error undo, throw:
            oJson = LoadConfig("logging.json").
            catch e as Progress.Lang.Error :
              // for now allow no file      
            end catch.                
        end.
        // the DataObjecHandler will call LogWebRequest if this is true
        if valid-object(oJson) then 
        do:
            IsWebRequestLogActive = oJson:GetLogical("MemoryObjects").
            LogEveryWebRequest = oJson:GetLogical("LogEveryWebRequest"). 
        end.
        return.

    end method.
    
    
    method public void LogWebRequest(pWebRequest as IWebRequest ):
        MemoryLogger:Log(pWebRequest).
    end method.
    
    
    method public void logError( input pcContextMessage as character, input poErr as Progress.Lang.Error, input pcSubSystem as character, input piLogLevel as integer ):
        undo, throw new NotImplementedError(). 
    end method.

    method public void logMessage( input pcMessage as character, input pcSubSystem as character, input piLogLevel as integer ):
        undo, throw new NotImplementedError(). 
    end method.

    method public character updateLogEntryTypes(  ):
        undo, throw new NotImplementedError(). 
    end method.

    method public integer updateLoggingLevel(  ):
        undo, throw new NotImplementedError(). 
    end method.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    destructor public LoggingManager ( ):
        Dispose().
    end destructor.
    
    method override public void Dispose(  ):
    end method.

end class.