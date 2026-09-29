 
 /*------------------------------------------------------------------------
    File        : ServiceManager
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Ccs.Common.IService from propath.
using Ccs.ServiceManager.ILifecycleScope from propath.
using OpenEdge.Core.Assert from propath.
using OpenEdge.Core.ISupportInitialize from propath.
using OpenEdge.Core.WidgetHandle from propath.
using OpenEdge.Net.HTTP.Filter.Writer.EntityWriterRegistry from propath.
using OpenEdge.Net.HTTP.StatusCodeEnum from propath.
using OpenEdge.Web.DataObject.IServiceRegistry from propath.
using OpenEdge.Web.DataObject.ServiceRegistryImpl from propath.
using OpenEdge.Web.DataObject.ServiceRegistryLoader from propath.
using OpenEdge.Web.DataObject.Writer.OperationHandlerRegistry from propath.
using OpenEdge.Web.SendExceptionError from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Core.BusinessLogic.IEntity from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.Common.INameService from propath.
using Pmfo.Core.Common.NameService from propath.
using Pmfo.Core.DataLayer.DynamicDataAccess from propath.
using Pmfo.Core.DataLayer.DynamicDataSource from propath.
using Pmfo.Core.DataLayer.IDataAccess from propath.
using Pmfo.Core.DataLayer.IDataAccessResource from propath.
using Pmfo.Core.DataLayer.IDataSource from propath.
using Pmfo.Core.DataLayer.IUpdateTarget from propath.
using Pmfo.Core.Error.ApplicationError from propath.
using Pmfo.Core.Error.IHttpErrorStatus from propath.
using Pmfo.Core.Error.NotFoundError from propath.
using Pmfo.Core.Error.NotImplementedError from propath.
using Pmfo.Core.Error.UnsupportedOperationError from propath.
using Pmfo.Core.Manager.IServiceManager from propath.
using Pmfo.Core.Manager.Manager from propath.
using Pmfo.Core.Service.BusinessEntityOperationHandler from propath.
using Pmfo.Core.Service.DataObjectService from propath.
using Pmfo.Core.Service.JsonEntityWriter from propath.
using Pmfo.Core.Service.OperationHandlerService from propath.
using Pmfo.Repository.Business.PublicNameBE from propath.
using Pmfo.Repository.Business.ResourceBE from propath.
using Pmfo.Repository.DataAccess.ResourceDA from propath.
using Pmfo.Repository.DataSource.DataAccessDS from propath.
using Pmfo.Repository.DataSource.DataSourceDS from propath.
using Pmfo.Repository.DataSource.DataSourceErrorDS from propath.
using Pmfo.Repository.DataSource.EntityDS from propath.
using Pmfo.Util.Array from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Progress.Lang.Error from propath.
using Progress.Lang.Object from propath.

// There are tow different canFind implementaions. 
// One that uses can-find and one that uses find sonce can-find is faster we want 
// to keep both implementations and use this preprocesor where clause to ensure 
// the logic is the same
 
 /* Bug? version afer 12.2 broke this 
&scop canfindwhere ttEntity~
 where ttEntity.Resource = pcname~
 and (not valid-object(pClass) or ttEntity.TypeName = pClass:TypeName)~
 and (plOnlyPublic = false or ttEntity.Public = plOnlyPublic)~
 and (plOnlyPublic = false or lookup('general',ttEntity.ServerTypes) > 0)
         */
                                  
class Pmfo.Core.Manager.ServiceManager inherits Manager implements IServiceManager : 
    
    /**
     @TODO 
    The temp-tables in resources-dataset are problematic as they are requested 
    in various create or canfind methods during load of ResourceBE and can then
    cause an endless loop since these methods will call refreshResouces since the 
    data has not been loaded yet. 
    This is currently handled by checking for the problematic names in the known
    cases and returning and starting objects when applicable before refreshResources 
    is called.
    Maybe a dedicated resource-bootstrap.json could be used for these 
    that is loaded directly before refreshResources is called so the data can 
    be found. The benefit of a .json is that it could be gnerated following the same 
    logic so that the subscribe* info is correct if we add hooks to them
    The challenge is to figure out when to call refreshReources and then merge the 
    data with and with the call to refreshresources.
    Another alternative is to make ResourceBE self contained so that it 
    does not call here. Possibly by having overrides of DatasetGetHandler 
    and/or ServiceManager that handles the calls without refreshResources
    **/ 
      
    {Pmfo/Repository/Business/defs/resources-dataset.i} 
    
    define protected property ResourceBe as ResourceBE no-undo get. set.
    
      
    define public property CodeTableSourceName     as character no-undo get. set.
    define public property CheckForNewResources    as logical   no-undo get. set. 
    define public property DataSourceDirectory     as character no-undo get. set.
    define public property DataAccessDirectory     as character no-undo get. set.
    define public property EntityDirectory         as character no-undo get. set.
    // after web in url  
    define public property ServiceNames            as character no-undo init "api" get. protected set.    
    
    define temp-table ttScopedService no-undo
        // as of current we only have dataset handle, which allows us to use index
        // with ILifeCycleScope we douwl need to use equals  
        // (not a big deal as there is not likely to be many scopes, 
        // so feel free to change to Object when necessary )
        field scope as handle  
        field service as Object
        index idxScope as primary unique scope service
        .
    
    // not in interface as of current - override in subclass initialize
    define public property CodeTableKeyType as character init "character" no-undo 
       get.
       protected set. 
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    method public override void dispose(  ):
        if valid-object(ResourceBe) then 
            delete object ResourceBE.
    end method.
    

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    constructor public ServiceManager (  ):
        super ().
    end constructor.

    // subclasses override if actions are needed on refresh
    // for example if a cached service has data that needs to be cleared if there 
    // are changes in BEs or similar 
    method protected void PostRefresh(): 
    end method.    
    
    // subclasses override if actions are needed on load of resourceBE
    method protected void PostLoadResources(): 
    end method.    
    
    // not in interface - used by tools only
    method public void RefreshResources():
       
        if CheckForNewResources then
        do:
            if not valid-object(ResourceBE) then
            do:
                LoadResources().
            end.    
            else if ResourceBE:NeedRefresh() then
            do: 
                dataset dsResources:empty-dataset().
                ResourceBE:GetData( dataset dsResources by-reference).
                PostRefresh(). 
            end.
        end.
        // catch this as we don't want 404 if something is missing for this BE        
        catch e as Progress.Lang.Error :
            undo, throw new ApplicationError("Resource config data is missing",e).
        end catch.
    end method.    
    
    /** create entity methods */
    method public IBusinessEntity CreateBusinessEntity( input pcName as character ):
        return cast(CreateEntity(pcName,false,false,get-class(IBusinessEntity)),IBusinessEntity).    
    end method.
    
    
    method public IBusinessEntity CreateBusinessEntityForTableRead (pcName as character):
        return cast(CreateEntity(pcName,false,true,get-class(IBusinessEntity)),IBusinessEntity).    
    end method.
   
    method public IEntity CreateEntity( input pcName as character ):
        return CreateEntity(pcName,false,false,?).    
    end method.
    
    method protected IEntity CreateEntity( input pcName as character, plOnlyPublic as logical, plSkipInitForTableRead as logical, pClass as Progress.Lang.Class ):
        define variable oEntity as IEntity no-undo.
        // cannot manage this with Temp-tables since it is used to populate them 
        // we use the method to allow overrides in subclass 
        if pcname = "resources" then
        do: 
            // NOte that if "resources" ever need to subscribe to receive CreateBusinessEntityForUpdate will need to be changed to handle this  
            if not valid-object(pClass) or get-class(Pmfo.Core.BusinessLogic.IBusinessEntity):Equals(pClass) then
            do:
                oEntity = new ResourceBE(). // bootstrap - do not use createEntoty... 
                oEntity:initialize().
                return oEntity.
             
            end.
            else if plOnlyPublic then
                undo, throw new NotFoundError(subst('Public Entity "&1"',pcName)).  
            else
                undo, throw new NotFoundError(subst('Entity "&1"',pcName)).  
       
        end.
        else if pcname = "publicNames" then
        do:
            // NOte that if "publicNames" ever need to subscribe to receive CreateBusinessEntityForUpdate will need to be changed to handle this
            if not valid-object(pClass) or get-class(Pmfo.Core.BusinessLogic.IBusinessEntity):Equals(pClass) then
            do:
                oEntity = CreatePublicNameBE().
                oEntity:initialize().
                return oEntity.
            end.
            else if plOnlyPublic then
                undo, throw new NotFoundError(subst('Public Entity "&1"',pcName)).
            else
                undo, throw new NotFoundError(subst('Entity "&1"',pcName)).

        end.
        
        RefreshResources().  
      
        // expression with valid-object apparently no longer works when not valid in v12 
        // (probably a bug fix as it may have erroneosly resolved to ? in older versions )   
        if valid-object(pClass) then 
            find ttEntity where ttEntity.Resource = pcname
                            and ttEntity.Typename = pClass:TypeName no-error.
        else                     
            find ttEntity where ttEntity.Resource = pcname no-error.
       
        if not avail ttEntity then
            undo, throw new NotFoundError(subst('Entity "&1"',pcName)).  
        
        if plOnlyPublic and ttEntity.public = false then
            undo, throw new NotFoundError(subst('Public Entity "&1"',pcName)).  
             
       
        oEntity = dynamic-new ttEntity.ClassName ().
        
        if plSkipInitForTableRead = false  then
        do:
            if type-of(oEntity,ISupportInitialize) then 
                cast(oEntity,ISupportInitialize):Initialize().
            else if type-of(oEntity,IService) then
                cast(oEntity,ISupportInitialize):Initialize().
        end.
        return oEntity.     
    end method.
    
    /** can find entity methods */
    method public logical CanFindBusinessEntity( input pcName as character ):
        return CanFindEntity(input pcName,false,get-class(IBusinessEntity)).
    end method.
    
    method public logical CanFindBusinessEntity( input pcName as character, output plClientOnly as logical ).
        if lookup(pcname,"resources") > 0 then
        do: 
            return true.
        end.
        // called from refreshResources  - ResourceBE so avoid endless loop
        // - TODO add a DatasetGetHandler override that skips the call to this?
        //  could also generate a resource-bootstrap-json with the tttEntoty   
        if lookup(pcname,"entities,dataSources,dataaccess,lookupTypes") > 0 then
        do: 
            return false.
        end.
        RefreshResources().    
        find ttEntity where ttEntity.Resource = pcname and ttEntity.TypeName = get-class(Pmfo.Core.BusinessLogic.IBusinessEntity):TypeName  no-error.
        if avail ttEntity then 
        do:
            plClientOnly = ttEntity.ClientOnly.
         
            return true.
        end.             
        else 
            return false.             
    end method. 
    
    method public logical CanFindEntity( input pcName as character ):
        return CanFindEntity(input pcName,false,?).
    end method.
    
    method public logical CanFindBusinessEntity( input-output pcName as character ):
        return CanFindEntity(input-output pcName,false,get-class(IBusinessEntity)).
    end method.
    
    
    method public logical CanFindEntity( input-output pcName as character ):
        return CanFindEntity(input-output pcName,false,?).
    end method.
    
    method public logical CanFindPublicBusinessEntity( input pcName as character ):
        return CanFindEntity(input pcName,true,get-class(IBusinessEntity)).
    end method.
    
    
    method public logical CanFindPublicEntity( input pcName as character ):
        return CanFindEntity(input pcName,true,?).
    end method.
    
    method public logical CanFindPublicBusinessEntity( input-output pcName as character ):
        return CanFindEntity(input-output pcName,true,get-class(IBusinessEntity)).
    end method.
    
    
    method public logical CanFindPublicEntity( input-output pcName as character ):
        return CanFindEntity(input-output pcName,true,?).
    end method.
    
    // main logic for can-find that does not return namre and thus can use can-find 
    method protected logical CanFindEntity( input pcName as character, plOnlyPublic as logical, pClass as Progress.Lang.Class ):
        RefreshResources().  
        return CanFindEntity(input-output pcName, plOnlyPublic, pClass).
    end method.
    
    // main logic for can-find that returns name for casing purposes 
    method protected logical CanFindEntity( input-output pcName as character, plOnlyPublic as logical, pClass as Progress.Lang.Class ):
        RefreshResources().
        // this was resolved by a can-find statement in 12.2 - does not work in newer versions -  
        find ttEntity where ttEntity.resource = pcName no-error.
        if avail ttEntity then 
        do:
            if  (not valid-object(pClass) or ttEntity.TypeName = pClass:TypeName)  
            and (plOnlyPublic = false) then
            do:
                pcName = ttentity.resource.
                return true.
            end.    
        end.             
        return false.                
    end method.
    
    method public logical CanFindDataSource( input pcName as character ):
        return can-find(ttDataSource where ttDataSource.EntityName = pcname). 
    end method.    
 
    method public IDataAccess CreateNewDataAccess(input pcName as character):
        return new DynamicDataAccess(pcName).     
    end method.
    
    method public IDataAccess CreateDataAccess( input pcName as character ):
        define variable oDataAccess as IDataAccess no-undo.
        // The meta DataAccess class cannot be managed by the temp-table since it is used to create them 
        // handle it here to allow override in application 
        // and to allow any code to use it as a regular class 
        if pcName = "resources" then 
            return new ResourceDA(). 
        
        RefreshResources().          
        
        find ttDataAccess where ttDataAccess.Resource = pcname no-error. 
        if avail ttDataAccess and ttDataAccess.TypeName = get-class(IDataAccess):TypeName then  
        do:
            oDataAccess = dynamic-new ttDataAccess.ClassName ().
        end.
        else if avail ttDataAccess then 
            undo, throw new NotFoundError(subst("'&1' is type '&2'. DataAccess '&1'",pcName,ttDataAccess.TypeName)).
        else do:
            oDataAccess = CreateNewDataAccess(pcName).
        end.     
        if type-of(oDataAccess,ISupportInitialize) then
            cast(oDataAccess,ISupportInitialize):Initialize().
        else if type-of(oDataAccess,IService) then
            cast(oDataAccess,IService):Initialize().  
        return oDataAccess.    
    end method.
    
    method public IUpdateTarget CreateUpdateTarget( input pcName as character ):
        define variable oSource as IDataSource no-undo.
        oSource = CreateDataSource(pcName).
        if type-of(oSource,IUpdateTarget) then 
            return cast(oSource,IUpdateTarget).
        else
            undo, throw new NotFoundError(subst('UpdateTarget "&1"',pcName)).    
    end method.
    
    // allow subclass override
    method protected EntityDS CreateEntityDS():
        return new EntityDS().       
    end method.
    
     // allow subvlass override
    method protected DataSourceDS CreateDataSourceDS():
        return new DataSourceDS().       
    end method.
    
     // allow subvlass override
    method protected DataSourceErrorDS CreateDataSourceErrorDS():
        return new DataSourceErrorDS().       
    end method.
      
      
     // allow subvlass override
    method protected DataAccessDS CreateDataAccessDS():
        return new DataAccessDS().       
    end method.
    
     // The pmfo PublicNameBE is abstract, so we need to new the application subclass 
    method protected PublicNameBE CreatePublicNameBE():
        define variable cClass as character no-undo.
        define variable oBE    as PublicNameBE no-undo.
        cClass =  subst("&1.&2",EntityDirectory,"PublicNameBE").
        oBE = dynamic-new cClass ().
        return oBE.       
    end method.
        
    method public final IDataSource CreateDataSource( input pcName as character ):
        define variable oSource  as IDataSource no-undo.
        define variable cMessage as character no-undo.
        
        // The meta classes cannot be managed by the temp-table since they create them 
        // handle them here to allow override in application 
        // and to allow any code to use them as regular classes 
        if pcName = "dataSources" then
            return CreateDataSourceDS().
        else if pcName = "entities" then 
            return CreateEntityDS().       
        else if pcName = "dataAccess" then 
            return CreateDataAccessDS().
        // used in resource.json generation will be called to cleanup existing
        // records may be added when generating datasource and a source cannot be found 
        // May not be an error, but could be)    
        else if pcName = "dataSourceErrors" then
            return CreateDataSourceErrorDS().
         
        RefreshResources().          
        
        find ttDataSource where ttDataSource.EntityName = pcName no-error. 
        if avail ttDataSource then
        do: 
            case ttDataSource.Type:
                when "class" then 
                do:
                    oSource = dynamic-new ttDataSource.ClassName().
                end.             
                when "table" then
                do:
                    oSource = new DynamicDataSource(ttDataSource.TableName).
                end.
                when "codeTable" then
                do:
                    if CodeTableKeyType = "integer" then
                        oSource = dynamic-new CodeTableSourceName (ttDataSource.TypeKey).
                    else
                        oSource = dynamic-new CodeTableSourceName (ttDataSource.TypeCode).
                end.     
            end.
            if type-of(oSource,ISupportInitialize) then
                cast(oSource,ISupportInitialize):Initialize().
            else if type-of(oSource,IService) then
                cast(oSource,IService):Initialize().
           
            return osource.
            
        end.
        
        return ?. 
    end method.
    
     // substituted in WriteDataSourceErrorToTheLog. Override in subclass for correct name
    method protected character GetCodeTableKeyFieldText():
         return "Lookup table character key field".  
    end method.
    
    method protected void WriteDataSourceErrorToTheLog(pcName as character):
        message subst("Could not create DataSource using public name '&1'. This most likely that the &2 value has been changed. It could also mean that a table name has changed or the DataSource was missing when resources.json was generated.",
                      pcName,
                      GetCodeTableKeyFieldText()). 
    end method.                
    
    method protected OpenEdge.Web.DataObject.DataObjectService CreateDataObjectService(pcName as character):
        return new DataObjectService(pcName).
    end method.
    
    method public Object GetService( input poService as Progress.Lang.Class ):
        define variable oRegistry as IServiceRegistry no-undo.
        define variable oService as Object no-undo.
        define variable i as integer no-undo.
        case poService:
            when get-class(IServiceRegistry) then
            do:
                oRegistry = new ServiceRegistryImpl().
                do i = 1 to num-entries(ServiceNames):
                    oRegistry:RegisterService(CreateDataObjectService(entry(i,ServiceNames))).
                end.
                return oRegistry.
            end.
            when get-class(OperationHandlerService) then
            do:
                oService = new OperationHandlerService().
            end.
            when get-class(ServiceRegistryLoader) then
            do:
                // ignore - let the DataObjectHandler default kick in
            end.
            when get-class(INameService) then
            do:
                oService = new NameService().
            end.
            
            otherwise        
                undo, throw new NotImplementedError(subst("GetService (Class &1)",poService:TypeName)).
        end.
        
        if type-of(oService,ISupportInitialize) then
            cast(oService,ISupportInitialize):Initialize().
        else if type-of(oService,IService) then
            cast(oService,IService):Initialize().
                     
        return oService.
        
    end method.
    
    method public Object GetService( input poService as Progress.Lang.Class, input poScope as ILifecycleScope ):
        return GetServiceInternal(poService, poScope, false).
    end method.
    
    method public Progress.Lang.Object getExistingService(input poService as class Progress.Lang.Class, input poScope as ILifecycleScope).
        return GetServiceInternal(poService, poScope, true).
    end method.
    
    method private Object GetServiceInternal( input poService as Progress.Lang.Class, input poScope as ILifecycleScope, plExistingOnly as logical ):
        define variable oScope  as Object no-undo.
        define variable oService as Object no-undo.
        define buffer bt for ttScopedservice. 
        define variable hHandle as handle no-undo.
        Assert:NotNull(poScope, "Scope").
        oScope = poScope:getScope().
        if type-of(oScope,WidgetHandle) then
        do:
            hHandle = cast(oScope,WidgetHandle):Value.
            for each ttScopedService where ttScopedService.scope = hHandle: 
                
                 if valid-object(ttScopedService.service) then
                 do:
                     if ttScopedService.service:getclass():IsA(poService) then
                         return ttScopedService.service.
                 end.
                 else // if somehow gone get rid of the recoird 
                     delete ttScopedService.        
            end.
            
            if plExistingOnly then   
                return ?.
            
             undo, throw new NotImplementedError(subst("GetService (Class &1), ILifecycleScope",poService:TypeName)).
            
/*            if valid-object(oService) then                         */
/*            do:                                                    */
/*                create ttScopedService.                            */
/*                assign                                             */
/*                    ttScopedService.scope   = hHandle              */
/*                    ttScopedService.service = oService             */
/*                    .                                              */
/*                                                                   */
/*                if type-of(oService,ISupportInitialize) then       */
/*                    cast(oService,ISupportInitialize):Initialize().*/
/*                else if type-of(oService,IService) then            */
/*                    cast(oService,IService):Initialize().          */
/*            end.                                                   */
/*            return oService.                                       */
        end. 
        else
            undo, throw new UnsupportedOperationError(subst("GetService with Scope of type &1",poScope:getScope():GetClass():TypeName)). 
    end method.
    
    /* Returns a usable instance of the requested service if it already is started.
       @param P.L.Class The service name requested
       @param character An alias for the service. The implementation may choose to ignore this value.
       @return P.L.Object A usable instance 
       @throws P.L.AppError Thrown when no implementation can be found */
  
    /* Destroys and flushes from any cache(s) objects of a specifc class scoped to the argument scope.
       @param P.L.Class The service name requested
       @param ILifecycleScope A requested scope for which to stop services. */
    method public void stopServices(input poScope as Ccs.ServiceManager.ILifecycleScope,
                                    input poService as class Progress.Lang.Class).  
        stopServicesInternal(poScope,poService).
    end method. 
    
    method public void stopServices( input poScope as ILifecycleScope ):
        stopServicesInternal(poScope,?).
    end method.
    
    method protected void stopServicesInternal(input poScope as ILifecycleScope,input poService as class Progress.Lang.Class):
        define variable oObject as Object no-undo.
        define variable hHandle as handle no-undo.
        
        // seems pointless to complain at this point so just ignore
        if valid-object(poScope) then
        do:
            oObject = poScope:getScope().
            if valid-object(oObject) and type-of(oObject,WidgetHandle) then
            do:
                hHandle = cast(oObject,WidgetHandle):Value.
                for each ttScopedService where ttScopedService.scope = hHandle:
                    if avail ttScopedService then
                    do:
                        if valid-object(ttScopedService.service) then
                        do:
                            if valid-object(poService) = false 
                            or ttScopedService.service:GetClass():isa(poService) then
                            do:    
                                if type-of(ttScopedService.service,ISupportInitialize) then
                                    cast(ttScopedService.service,ISupportInitialize):Destroy().
                                else if type-of(ttScopedService.service,IService) then
                                    cast(ttScopedService.service,IService):dispose().
                            end.
                        end.        
                        
                        if valid-object(ttScopedService.service) then
                        do:
                            if valid-object(poService) = false 
                            or ttScopedService.service:GetClass():isa(poService) then
                               delete object ttScopedService.service.
                          
                        end.    
                    end.
                    delete ttScopedService.    
                end.
            end.
        end.
    end method.
    
     
    // override in subclass
/*    method protected IValidationFindService GetValidationFindService(phHandle as handle):*/
/*        return new ValidationFindService(phHandle).                                      */
/*    end method.                                                                          */
        
    method public Object GetService( input poService as Progress.Lang.Class, input pcName as character ):
        define variable oErrorStatus as StatusCodeEnum no-undo.
        define variable pOriginalError as Error no-undo.
        case poService:
            when get-class(IEntity) then
            do:
                // true only if pubiic
                return CreateEntity(pcName,true,false,?).
            end.
            when get-class(IBusinessEntity) then
            do:
                // true only if pubiic
                return CreateEntity(pcName,true,false,get-class(IBusinessEntity)).
            end.
            
            when get-class(IDataAccess) then
            do:
                return CreateDataAccess(pcName).
            end.
           when get-class(IDataAccessResource) then
           do:
                return CreateDataAccessResource(pcName).
           end.
           when get-class(IDataSource) then
           do:
               return CreateDataSource(pcName).
           end.
           
           otherwise 
                undo, throw new NotImplementedError(subst("GetService (Class &1,name &2)",poService:TypeName,pcName)).
        end case.
        catch e as Progress.Lang.Error :
            if type-of(e,IHttpErrorStatus) then
                oErrorStatus = cast(e,IHttpErrorStatus):StatusCode.
            else 
                oErrorStatus = StatusCodeEnum:InternalServerError.    
            undo, throw new SendExceptionError(oErrorStatus,e).
        end catch.
    end method.
    
    
    // as of current only callable from GetService 
    method protected IDataAccessResource CreateDataAccessResource( input pcName as character ):
        define variable oDataAccessResource as IDataAccessResource no-undo.

        RefreshResources().          
        find ttDataAccess where ttDataAccess.Resource = pcname no-error. 
        if avail ttdataAccess then 
        do:
            oDataAccessResource = dynamic-new ttDataAccess.ClassName ().
        end.
        if type-of(oDataAccessResource,ISupportInitialize) then
            cast(oDataAccessResource,ISupportInitialize):Initialize().
        else if type-of(oDataAccessResource,IService) then
            cast(oDataAccessResource,IService):Initialize().  
        
        return oDataAccessResource.    
    end method.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    method protected void ImportConfig(  ):
        define variable oJson as JsonObject no-undo.
        oJson = LoadConfig("serviceConfig.json").
        
        EntityDirectory         = oJson:GetCharacter("EntityDirectory").
        DataAccessDirectory     = oJson:GetCharacter("DataAccessDirectory").
        DataSourceDirectory     = oJson:GetCharacter("DataSourceDirectory").
        CodeTableSourceName     = oJson:GetCharacter("CodeTableSourceName").
        CheckForNewResources    = oJson:GetLogical("CheckForNewResources").
        return.

    end method.
    
    method public override void initialize(  ):
       
        ImportConfig().
        
        // Note this should be based on config and possibly moved elsewhere 
        // when the Servicemanager is supporting non web clients
         /* Add the extended JsonEntityWriter  to the registry */
        EntityWriterRegistry:Registry:Put('application/json':u,              get-class(JsonEntityWriter)).
        EntityWriterRegistry:Registry:Put('application/vnd.progress+json':u, get-class(JsonEntityWriter)).
        /* Add the OperationHandlers to the registry */
        OperationHandlerRegistry:Registry:Put(get-class(IBusinessEntity):TypeName,GetBusinessEntityOperationHandlerClass()).
        
        LoadResources().
        // not needed anymore if no refresh is needed
        if not CheckForNewResources then
            delete object ResourceBe. 
             
    end method.
    
    // allow subclasses to override    
    method protected Progress.Lang.Class GetBusinessEntityOperationHandlerClass():  
        return get-class(BusinessEntityOperationHandler).
    end method. 
    
    method protected void LoadResources():
        define variable oGetDataRequest as IGetDataRequest no-undo.
        // use CreateBusinessEntity method to allow subclass override  
        if valid-object(ResourceBE) then
            delete object ResourceBE. 
        ResourceBE = cast(CreateBusinessEntity("resources"),ResourceBE).
        if CheckForNewResources then   
            ResourceBE:GetData(output dataset dsResources by-reference).
        else do:
            undo, throw new NotImplementedError("REsourceBE Get Data  JSON").
          //  oGetDataRequest = new GetDataRequest(new NamedQuery("JSON")).
          //  ResourceBE:GetData(oGetDataRequest,output dataset dsResources by-reference).
        end.
        // hook for subclasses 
        PostLoadResources().
    end method.    
    
    method public character extent GetKeys(input pcName as character).
        define variable cKeys    as character extent no-undo.
        define variable cKeyList as character no-undo.
        cKeylist  = GetKeyList(pcname).
        if cKeyList > "" then
            cKeys = Array:Split(cKeylist).
        return cKeys.    
    end method. 
    
    method public character GetKeyList(input pcName as character).
        define variable cKeyList as character  no-undo.
        
        RefreshResources().  
        
        find ttEntity where ttEntity.Resource = pcname no-error.
        if not avail ttEntity then
        do: 
            if lookup(pcName,"resources,lookupTypes,publicNames") > 0 then 
                undo, throw new UnsupportedOperationError(subst("GetKeys for meta entity &1 (before resources are loaded)",pcName)).
            undo, throw new NotFoundError(subst("Entity '&1'",pcName)). 
        end.     
        if ttEntity.TypeName <> "Pmfo.Core.BusinessLogic.IBusinessEntity" then 
            undo, throw new UnsupportedOperationError(subst("GetKeys for &1",ttEntity.TypeName)).
        else                     
            return ttEntity.KeyList. 
    end method. 
    
     
	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/
	destructor public ServiceManager ( ):
        dispose().
	end destructor.

end class.