 
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

block-level on error undo, throw.

class Pmfo.Util.RestClient: 
    define public property uri as URI no-undo get. set.
    
    method public IHttpResponse executePostRequest(pBody as Object):
        return executeRequest("POST", pBody,?).
    end method.    
    
    method public IHttpResponse executePutRequest(pBody as Object):
        return executeRequest("PUT", pBody,?).
    end method.    
    
    method public IHttpResponse executeDeleteRequest(pBody as Object):
        return executeRequest("DELETE", pBody,?).
    end method.    
    
    method public IHttpResponse executeGetRequest():
        return executeRequest("GET", ?,?).
    end method.    
    
    method private IHttpResponse executeRequest(pMethod as character, pBody as Object, pContentType as character):
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
                                        
        
        oRequestBuilder = RequestBuilder:build(pMethod,uri).
        
        if StringUtil:IsBlank(pContentType) then 
            oRequestBuilder:ContentType(pContentType).
        
        if valid-object(pBody) then 
            oRequestBuilder:withData(pBody).
        
        oRequest = oRequestBuilder:Request.
                                 
        oClient:Execute(oRequest).
    end method.    

end class.