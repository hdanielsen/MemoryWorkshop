 
 /*------------------------------------------------------------------------
    File        : RestClient
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Tue Jul 14 07:13:17 EDT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using OpenEdge.Net.HTTP.RequestBuilder from propath.
using OpenEdge.Net.HTTP.ClientBuilder from propath.
using OpenEdge.Net.HTTP.HttpRequest from propath.
using OpenEdge.Net.HTTP.IHttpResponse from propath.
using OpenEdge.Net.URI from propath.
using Pmfo.Util.StringUtil from propath.
using Progress.Lang.Object from propath.
using OpenEdge.Net.HTTP.IHttpRequest from propath.
using OpenEdge.Net.HTTP.IHttpClient from propath.
using OpenEdge.Net.UriSchemeEnum from propath.
using OpenEdge.Core.Collections.StringStringMap from propath.

block-level on error undo, throw.

class Pmfo.Util.RestClient: 
    define public property uri as URI no-undo get. set.
    
    define protected property scheme      as UriSchemeEnum no-undo get. set.
    define protected property host        as character     no-undo get. set.
    define protected property port        as integer       no-undo get. set.
    define protected property ServicePath as character no-undo get. set.
  
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    constructor public RestClient (pScheme as UriSchemeEnum, pHostName as character, pPort as integer, pcService as character):
        super ().
        scheme = pScheme.
        host   = pHostName.
        port = pport.
        ServicePath = pcService.
    end constructor.
    
    method public IHttpResponse executePostRequest(pcResource as character,pBody as Object):
        return executeRequest("POST",pcResource, pBody,?).
    end method.    
    
    method public IHttpResponse executePutRequest(pcResource as character,pBody as Object):
        return executeRequest("PUT",pcResource, pBody,?).
    end method.    
    
    method public IHttpResponse executeDeleteRequest(pcResource as character,pBody as Object):
        return executeRequest("DELETE",pcResource, pBody,?).
    end method.    
    
    method public IHttpResponse executeGetRequest(pcResource as character):
        return executeRequest("GET",pcResource, ?,?).
        
    end method.    
    
    method private IHttpResponse executeRequest(pMethod as character,pcResource as character,  pBody as Object, pContentType as character):
        define variable oRequestbuilder as RequestBuilder no-undo.
        define variable oClientbuilder  as ClientBuilder no-undo.
        define variable oRequest        as IHttpRequest no-undo.
        define variable oClient         as IHttpClient no-undo.
        define variable oResponse       as IHttpResponse no-undo.
        
        oClientbuilder = ClientBuilder:Build()
                                      :SetNumRetries(5)
                                      :setRetryPause(1)
                                      :SetRequestTimeout(50).
        oclient = oClientbuilder:Client.
        
        uri = new URI(scheme,host,port,ServicePath + "/" + pcResource,new StringStringMap(),"").
                                      
        
        oRequestBuilder = RequestBuilder:build(pMethod,uri).
        
        if StringUtil:IsBlank(pContentType) then 
            oRequestBuilder:ContentType("application/json").
        else 
            oRequestBuilder:ContentType(pContentType).
        if valid-object(pBody) then 
            oRequestBuilder:withData(pBody).
        
        oRequest = oRequestBuilder:Request.
                                 
        oResponse = oClient:Execute(oRequest).
        return oResponse.
    end method.    

end class.