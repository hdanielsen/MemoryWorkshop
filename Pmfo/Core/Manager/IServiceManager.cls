
/*------------------------------------------------------------------------
    File        : IServiceManager
    Purpose     : Main factory for classes and services for the application 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : Extends Ccs with code level methods with Create and more for 
                  central crud subclasses 
  ----------------------------------------------------------------------*/

using Ccs.Common.IServiceManager from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IEntity from propath.
using Pmfo.Core.DataLayer.IDataAccess from propath.
using Pmfo.Core.DataLayer.IDataSource from propath.
using Pmfo.Core.DataLayer.IUpdateTarget from propath.
using Pmfo.Core.DataLayer.IServiceDataAccess from propath.

interface Pmfo.Core.Manager.IServiceManager inherits IServiceManager: 
    define public property CodeTableSourceName     as character no-undo get. set. 
    define public property CheckForNewResources    as logical   no-undo get.  
    define public property DataSourceDirectory     as character no-undo get. set.
    define public property DataAccessDirectory     as character no-undo get. set.
    define public property EntityDirectory         as character no-undo get. set.
    define public property ServiceNames            as character no-undo get.  
    
    /* Returns a usable instance of the requested service if it already is started.
       @param P.L.Class The service class requested
       @param character An alias for the service. The implementation may choose to ignore this value.
       @return P.L.Object A usable instance 
       @throws P.L.AppError Thrown when no implementation can be found */
    method public Progress.Lang.Object getExistingService(input poService as class Progress.Lang.Class,
                                                          input poScope as Ccs.ServiceManager.ILifecycleScope).
    
    /* Destroys and flushes from any cache(s) objects of a specifc class scoped to the argument scope.
       @param P.L.Class The service class  requested
       @param ILifecycleScope A requested scope for which to stop services. */
    method public void stopServices(input poScope   as Ccs.ServiceManager.ILifecycleScope,
                                    input poService as class Progress.Lang.Class).  
    
    method public IDataSource CreateDataSource (pcName as char). 
    method public IUpdateTarget CreateUpdateTarget (pcName as char). 
    method public IDataAccess CreateDataAccess (pcName as char).
    
    method public IEntity CreateEntity (pcName as char).   
    method public IBusinessEntity CreateBusinessEntity (pcName as char).   
    
    method public logical CanFindDataSource( input pcName as character ).
    
    method public character extent GetKeys(input pcName as character).
    method public character GetKeyList(input pcName as character).
    
      
end interface.