
/*------------------------------------------------------------------------
    File        : sessionstartup.p
    Purpose     : Start session services for pas application servers 
    Syntax      : Session startup procedure: Core/Startup/sessionstartup.p
    Description :  
    Author(s)   :
    Created     :
    Notes       : Define as Session startup procedure for pas abl application 
----------------------------------------------------------------------*/

/* ***************************  Declarations  ************************** */
using Ccs.Common.Application from propath.
using Pmfo.Core.Manager.StartupManager from propath.
using Pmfo.Core.Manager.ISessionManager from propath.
using Pmfo.Core.Error.ApplicationError from propath.

/* ***************************  Definitions  ************************** */
define input parameter pcOptions as character no-undo. // mandatory - not in use

define variable cStartupErrorTmpl   as character       no-undo
    init "Error during start or initialization of &1: &2". 
 
/* ***************************  Main ************************** */
do on error undo, throw:
    StartupManager:ConfigDirectory = "config".
    StartupManager:Instance. // bootstrap to Application:startupManager happens in constructor
    if session:remote then
        message "Managers started".
    catch e as Progress.Lang.Error :
        if session:remote then
             message subst(cStartupErrorTmpl,"StartupManager") skip
                         e:GetMessage(1).
        else 
            undo, throw new ApplicationError(subst(cStartupErrorTmpl,"StartupManager",e:GetMessage(1))).             
    end catch.    
end.






