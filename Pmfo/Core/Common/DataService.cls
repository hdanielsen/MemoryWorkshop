 
 /*------------------------------------------------------------------------
    File        : DataService
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : Bootstraps framework classes newed from outside PAS (i.e unit test)    
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Pmfo.Core.Common.IDataService from propath.
using Pmfo.Core.Error.ApplicationError from propath.
using Pmfo.Core.Manager.StartupManager from propath.
using Pmfo.Util.AssertUtil from propath.

class Pmfo.Core.Common.DataService abstract implements IDataService : 
    
	constructor static DataService (  ):
	    define variable i as integer no-undo.
	    define variable cMessage as character no-undo.
	             
        if not valid-object(Ccs.Common.Application:StartupManager) then 
        do on error undo, throw:
            StartupManager:Instance. /* sets Application:StartupManager in contructor */
            // an error here is rather confusing, so clarifiy a little
            catch e as Progress.Lang.Error :
                // don't use line feed. this can end up in log or abl unit 
                do i = 1 to e:NumMessages:
                    cMessage = substitute("&1&2. ",cMessage,right-trim(e:GetMessage(i),".")).
                end.
                undo, throw new ApplicationError(subst("DataService static constructor error from StartupManager:Instance - &1",right-trim(cMessage))).    
            end catch.
        end.        
        
	end constructor.
    
    method public void Dispose(  ).
        Destroy().
    end.
    
    // throw error if property is not called from constructor or its own getter
    method public void AssertConstructorProperty ():
        AssertUtil:AssertConstructorProperty().
    end method.
    
    method public abstract void Destroy(  ).
    method public abstract void Initialize(  ).
 
end class.