 
 /*------------------------------------------------------------------------
    File        : ClientRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Sun Mar 31 16:33:22 EDT 2019
    Notes       : The properties that expose url properties do NOT return 
                  default values  for poperties like skip, top and count 
                  It may be necessary to know if the prop was passed 
                  The caller must treat ? as default. 
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using OpenEdge.Core.Assert from propath.
using OpenEdge.Core.Collections.ICollection from propath.
using OpenEdge.Core.Collections.IStringStringMap from propath.
using OpenEdge.Core.StringConstant from propath.
using Pmfo.Core.Error.BadRequestError from propath.
using Pmfo.Core.Service.ClientRequest from propath.
using Pmfo.Core.Service.IClientGetRequest from propath.
using Pmfo.Util.Array from propath.
using Pmfo.Core.Error.UnsupportedOperationError from propath.
using Pmfo.Core.Error.NotImplementedError from propath.

class Pmfo.Core.Service.ClientGetRequest inherits ClientRequest implements IClientGetRequest: 
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    
    define public property SkipProp          as character init "skip"      no-undo get.  
    define public property NumRecordsProp    as character init "top"       no-undo get.  
    define public property SortProp          as character init "orderby"   no-undo get.  
    define public property FilterProp        as character init "filter"    no-undo get.  
    define public property CountProp         as character init "count"     no-undo get.  
    define public property PagingContextProp as character init "startId"   no-undo get. 
    define public property SelectProp        as character init "select"    no-undo get.  
    define public property ExpandProp        as character init "expand"    no-undo get.  
    define public property LevelsProp        as character init "levels"    no-undo get.  
    define public property TimeoutProp       as character init "timeout"   no-undo get.  
    define public property WildcardsProp     as character init "wildcards" no-undo get.  
    define public property ApplyProp         as character init "apply"     no-undo get.  
        
    define public property ResourceProperties   as char extent no-undo get. protected set.
    define public property CollectionProperties as char extent no-undo get. protected set.
    define public property KeyProperties        as char extent no-undo get. protected set.
   
    method public character GetChildFilter  (pcPathEntity as character):
        undo, throw new NotImplementedError().
    end method.      
    
    method public character GetExpandSelect  (pcPathEntity as character):
        undo, throw new NotImplementedError().
    end method.      
    
    method public character GetChildSort    (pcPathEntity as character). 
        undo, throw new NotImplementedError().
    end method.      
         
    
    
     define public property Apply as character no-undo 
        get():
            return string(UriQuery:Get(ApplyProp)).
        end.
        protected set.
        
    
 
    define public property Skip          as int64     no-undo 
        get():
            return int64(UriQuery:Get(SkipProp)).
            catch e as Progress.Lang.Error :
                undo, throw new BadRequestError(subst("&1=&2",SkipProp,string(UriQuery:Get(SkipProp))),e).    
            end catch.
        end. 
        
    define public property NumRecords    as int64     no-undo  
        get():
            return int64(UriQuery:Get(NumRecordsProp)).
            catch e as Progress.Lang.Error :
                undo, throw new BadRequestError(subst("&1=&2",NumRecordsProp,string(UriQuery:Get(NumRecordsProp))),e).    
            end catch.
        end.
         
    define public property Sort          as character no-undo
        get():
            return string(UriQuery:Get(SortProp)).
        end.  
        
    define public property Filter        as character no-undo 
        get():
            return string(UriQuery:Get(FilterProp)).
        end.  
        
    define public property Count         as logical   no-undo  
        get():
            return logical(UriQuery:Get(CountProp)).
            catch e as Progress.Lang.Error :
                undo, throw new BadRequestError(subst("&1=&2",CountProp,string(UriQuery:Get(CountProp))),e).    
            end catch.
        end.  
   
    define public property PagingContext as character no-undo  
        get():
            return string(UriQuery:Get(PagingContextProp)).
        end. 
         
    define public property Select         as character    no-undo 
        get():
            return  string(UriQuery:Get(SelectProp)).
        end.     
    
    define public property Levels         as integer    no-undo 
        get():
            return integer(UriQuery:Get(LevelsProp)).
            catch e as Progress.Lang.Error :
                undo, throw new BadRequestError(subst("&1=&2",LevelsProp,string(UriQuery:Get(LevelsProp))),e).    
            end catch.
        end.    
    
    define public property Timeout       as integer   no-undo  
        get():
            return integer(UriQuery:Get(TimeoutProp)).
            catch e as Progress.Lang.Error :
                undo, throw new BadRequestError(subst("&1=&2",TimeoutProp,string(UriQuery:Get(TimeoutProp))),e).    
            end catch.
        end.    
    
    define public property Wildcards      as logical   no-undo  
        get():
            return logical(UriQuery:Get(WildcardsProp)).
            catch e as Progress.Lang.Error :
                undo, throw new BadRequestError(subst("&1=&2",WildcardsProp,string(UriQuery:Get(WildcardsProp))),e).    
            end catch.
        end.  
        
     define public property Expand       as character   no-undo  
         get():
             return string(UriQuery:Get(ExpandProp)).
             catch e as Progress.Lang.Error :
                  undo, throw new BadRequestError(subst("&1=&2",ExpandProp,string(UriQuery:Get(ExpandProp))),e).    
             end catch.
         end.  
    
    define public property ExpandedRelations as ICollection no-undo get. set. 
    
    constructor public ClientGetRequest ( pServiceURI as character, pQuery as IStringStringMap ):
        this-object("GET",pServiceURI,pQuery).
    end method.
    
    constructor public ClientGetRequest ( pMethod as character, pServiceURI as character, pQuery as IStringStringMap ):
        super (pMethod, pServiceURI, pQuery).
        Assert:isTrue(pMethod = "GET" or pMethod = "HEAD","Method is GET or HEAD").
      
        /* from odata spec for reference - NOTE we do only support a subset of odata and also some that odata does not support  
        For GET, PATCH, and PUT requests the following rules apply:
�       Resource paths identifying a single entity, a complex type instance, a collection of entities, or a collection of complex type instances allow $compute, $expand and $select.
�       Resource paths identifying a collection allow $filter, $search, $count, $orderby, $skip, and $top.
�       Resource paths ending in /$count allow $filter and $search.
�       Resource paths not ending in /$count or /$batch allow $format.
        */
        /// for context links - does not have skip and  PagingContextProp since this is used for links where these point to next page
        ContextProperties = GetContextProperties ().
        CollectionProperties = GetCollectionProperties().
        KeyProperties = GetKeyProperties ().
        ResourceProperties = GetResourceProperties ().
    end constructor.
    
    method public character extent GetContextProperties ():
        return Array:ToArray(FilterProp,SortProp,NumRecordsProp,SelectProp,MetaDataProp,ExpandProp).
    end method. 
    
    method public character extent GetCollectionProperties():
        return Array:ToArray(FilterProp,CountProp,SortProp,SkipProp,NumRecordsProp,SelectProp,PagingContextProp,LevelsProp,MetaDataProp,ExpandProp,TimeoutProp,WildcardsProp,Applyprop).
    end method. 
    
    method protected character extent GetPrimitiveRequestProperties (pcFunctionname as character):
        if pcFunctionname = "count" then 
            return Array:ToArray(MetaDataProp,TimeoutProp,FilterProp).
        else     
            return Array:ToArray(MetaDataProp,TimeoutProp).
    end method.
    
    method public character extent GetKeyProperties ():
        return Array:ToArray(SelectProp,MetaDataProp,ExpandProp,TimeoutProp).
    end method. 
    
    method public character extent GetResourceProperties ():
        return Array:ToArray(SelectProp,MetaDataProp).
    end method. 
    
   
    
    // decode query character values to support old web that replaces space with +. found in some rest test tools at least 
    // NOTE -currently called from setter of URIQuery, which is invoked from constructor so you cannot use non-constant values/properties in here 
    method protected override void DecodeURIQuery(pURIQuery as IStringStringMap):
        define variable i as integer no-undo.
        define variable cSpacedProperties as character extent no-undo.
        if valid-object(pUriQuery) then
        do:
            cSpacedProperties = Array:ToArray(FilterProp,SortProp,PagingContextProp).
            do i = 1 to extent(cSpacedProperties):
               define variable cValue as longchar no-undo.
               cValue = pUriQuery:Get(cSpacedProperties[i]).
               // The framework makes sure that any value with + is added with spaces
               // to properties that may end up here to avoid any amibiguity   
               // - by adding ["field eq 'value'] instead of just [value]
               if index(cValue,StringConstant:SPACE) = 0 and index(cValue,"+") > 0 then
                   pUriQuery:put(cSpacedProperties[i],replace(cValue,"+",StringConstant:SPACE)).
            end.
        end.    
    end method.     
  
    
    method protected override void AssignCollectionProperties(pServiceURI as character):
         super:AssignCollectionProperties(pServiceURI).
         // The AssertCpllection was separated out since the ClientUpdateRequest mmy 
         // manage this in the GetUpdateRequestDataset after this 
         // The GetUpdateRequestDataset does the required validation also  
         AssertCollections().   
    end. 
end class.