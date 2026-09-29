 
 /*------------------------------------------------------------------------
    File        : ClientRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Sun Mar 31 16:33:22 EDT 2019
    Notes       : Busness Entity Data or Update Request based on
                  public names 
                - Resource name, dataset serialize-name or table serialize-name
                  as exposed to the UI and used in REST URIs   
                - The request is newed without knowledge of the dataset or buffers
                  and passed to the BE that then uses it to identify the requested
                  dataset from the Collections.
                - Subclasses have geters that returns the request that is 
                  to be passed to the DataAccess based on a dataset parameter      
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using OpenEdge.Core.Collections.ICollection from propath.
using OpenEdge.Core.Collections.IIterator from propath.
using OpenEdge.Core.Collections.IStringStringMap from propath.
using OpenEdge.Core.String from propath.
using OpenEdge.DataAdmin.Error.IllegalOperationError from propath.
using Pmfo.Core.Error.BadRequestError from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.
using Pmfo.Core.Service.IClientRequest from propath.
using Pmfo.Util.Array from propath.
using Pmfo.Core.Error.OutOfBoundsError from propath.
using OpenEdge.Core.Collections.StringStringMap from propath.
using Pmfo.Util.StringUtil from propath.
using Pmfo.Core.Error.UnsupportedOperationError from propath.
using Pmfo.Util.ODataUtil from propath.

class Pmfo.Core.Service.ClientRequest abstract implements IClientRequest: 
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/ 
    define public property UriQuery     as IStringStringMap           no-undo 
        get. 
        protected set(pMap as IStringStringMap):
            if pMap = ? then 
                undo, throw new IllegalArgumentError("UriQuery cannot be null").
            DecodeUriQuery(pMap).  // see comment below    
            UriQuery = pmap.
        end.
    
    define public  property Method      as character no-undo get. protected set. 
        
    define public  property Collections as character extent no-undo get. protected set. 
    define public  property KeyWheres   as character extent no-undo get. set. 
    define public  property MetaDataProp as character init "metadata"    no-undo get.  
    
    define public property ContextProperties        as char extent no-undo get. protected set. 
    define public property ServiceURI  as character no-undo get. set. 
    
       
    constructor public ClientRequest ( pMethod as character, pServiceURI as character , pQuery as IStringStringMap):
        super ().
        Method = pMethod.
        ServiceURI = pServiceURI.
        UriQuery   = pQuery.
        AssignCollectionProperties(pServiceURI).
    end constructor.
  
    // subclasses override to decode uri query character values to support old web 
    // that replaces space with +.
    // The framework make sure that any value with + is added with spaces
    // to avoid any ambiguity   
    method protected void DecodeURIQuery(pURIQuery as IStringStringMap):
    end method.      
 
       
    method protected void AssertUriQuery(pQueryMap as IStringStringMap,pValidProps as char extent,pcTypeOrMethodForMessage as char):
        define variable cList      as character no-undo.
        define variable oKeyValues as ICollection no-undo.
        define variable oIterator  as IIterator no-undo.
        define variable cKey       as character no-undo.
        
        if extent(pValidProps) <> ? then
        do:
            cList = Array:ToString(pValidProps).
             
            oKeyValues = pQueryMap:KeySet.
            oIterator  = oKeyValues:Iterator().
             
            do while oIterator:HasNext():
                cKey =  cast(oIterator:Next(), String):Value.
                if cKey = "" then 
                   undo, throw new BadRequestError("The URL has an empty query option. Please remove any '&&' from the URL that has no value.").
                else if lookup(cKey,cList) = 0 then 
                    undo, throw new BadRequestError(BadQueryOptionError(cKey,pcTypeOrMethodForMessage)).
                 
            end.
        end.
         
    end method.    
    
    method protected character BadQueryOptionError(pcOption as character, pcTypeOrMethodForMessage as character ):
        return subst("'&1' is not a valid URI query option for &2",pcOption,pcTypeOrMethodForMessage).
    end.     
    
    method protected void AssignCollectionProperties(pServiceURI as character):
        ODataUtil:GetCollectionProperties(pServiceURI,output Collections, output KeyWheres).
    end method. 
    
    method protected void AssertCollections():
        define variable cCollectionList as character no-undo.
        define variable i as integer no-undo.
        cCollectionList = Array:ToString(Collections).
        do i = 1 to extent(Collections):
            if lookup(Collections[i],cCollectionList) <> i then
               undo, throw new BadRequestError(subst("Entity '&1' cannot be referenced twice in the URL",Collections[i])) .
             
        end.
    end method.    
        
    
    
end class.