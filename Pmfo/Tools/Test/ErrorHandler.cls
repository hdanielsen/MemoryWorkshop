 
 /*------------------------------------------------------------------------
    File        : ErrorHandler
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Wed Aug 05 04:09:05 EDT 2026
    Notes       : 
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using OpenEdge.Core.Assert from propath.
using OpenEdge.Core.StringConstant from propath.
using OpenEdge.Web.SendExceptionError from propath.
using Pmfo.Core.Error.ApplicationError from propath.
using Progress.Json.ObjectModel.JsonArray from propath.
using Progress.Json.ObjectModel.JsonConstruct from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Progress.Lang.AppError from propath.
using Progress.Lang.Error from propath.

class Pmfo.Tools.Test.ErrorHandler: 
    
    define public property ShowErrors as logical no-undo get. set. 
 
    define public property ShowErrorsInWindow as logical   no-undo 
       get. 
       set(plShow as logical):
           if plShow then
               ShowErrors = true.
           ShowErrorsInWindow = plShow.     
       end. 
       
    define protected property ErrorEntity as JsonConstruct no-undo get. set. 
    
       
    method public void  Showerror (pError as Error):
       
        define variable hWindow as handle no-undo.
        define variable oJson as JsonObject no-undo.
        define variable oJsonArray as JsonArray no-undo.
        define variable cLong as longchar no-undo.
        define variable cCaller as character no-undo.
        
        if ShowErrorsInWindow then
        do:
            WriteError(pError).
            DisplayError(ErrorEntity,"").
        end.
        else do:

            if type-of(pError,ApplicationError) then
            do:
                if valid-object(cast(pError,ApplicationError):InnerError) then
                   pError = cast(pError,ApplicationError):InnerError.
            end.
            else if type-of(pError,SendExceptionError) then
            do:
                if valid-object(cast(pError,SendExceptionError):InnerError) then
                   pError = cast(pError,SendExceptionError):InnerError.
            end.
            message "Error:" skip pError:GetMessage(1) skip
                    "InnerError:" skip perror skip
                    "CallStack" skip pError:CallStack
               view-as alert-box.

       end.
            
 
    end method.
    
    method public void DisplayError(pJson as JsonConstruct, pcCaller as character):
        define variable hWindow as handle no-undo.
        define variable oJson as JsonObject no-undo.
        define variable oJsonArray as JsonArray no-undo.
        define variable cLong as longchar no-undo.
        define variable cCaller as character no-undo.
        
        run Pmfo/Tools/Gui/Wincode.w persistent set hWindow.
        if type-of(pJson,JsonObject) then
        do:
           oJson = cast(pJson,JsonObject).
            oJson:Write(input-output cLong, yes).
        end.
        else if type-of(ErrorEntity,JsonArray) then
        do:
            oJsonArray = cast(ErrorEntity,JsonArray).
            oJsonArray:Write(input-output cLong, yes).
        end.     
        
        clong = replace(cLong,"[","").
        clong = replace(cLong,"]","").
        clong = replace(cLong,"~{","").
        clong = replace(cLong,"~}" + StringConstant:LF,"").
        clong = replace(cLong,"~}","").       
        clong = replace(cLong,"~"","").
        clong = replace(cLong,",","").
        clong = replace(cLong,"~~,","").
        clong = replace(cLong,"~\\","~\").
        clong = replace(cLong,"~\/","/").
        // these may come from the error class - not from writeError
       // clong = replace(cLong,"errorMsg","Error Msg").
       // clong = replace(cLong,"errorNum","Error Num").
        if pcCaller = "" then 
        do:              
            cCaller = entry(1,program-name(2)," ").
            if cCaller = "handleError" then  
                cCaller = entry(1,program-name(3)," ").
        end.
        else 
            cCaller = pcCaller.
        run SetContent in hWindow ("Error","Test",cCaller,cLong).
        run SetWidth in hWindow(160).
        run SetHeight in hWindow(20).
        run SetCloseOnEscape in hWindow.
        run SetCloseOnSpace in hWindow.
        run MoveToTop in hWindow.
        wait-for close of hWindow.
        return.
    end method.    
    
    method protected void WriteError(input poError as Progress.Lang.Error):
        define variable oResponse as JsonObject no-undo.
        define variable oError as JsonObject no-undo.
        define variable oErrorList as JsonArray no-undo.
        define variable iLoop as integer no-undo.
        define variable cRetVal as character no-undo.
        define variable iMax as integer no-undo.
        define variable oProp as Progress.Reflect.Property no-undo.
        define variable oInner as Progress.Lang.Error no-undo.
        define variable istart as integer no-undo.
        define variable oComplexError as JsonConstruct no-undo.
         
        Assert:NotNull(poError, 'Error').
        /* build the current error */
        assign oResponse  = new JsonObject()
               oErrorList = new JsonArray()
               iMax       = poError:NumMessages
               iStart = 1  
               .
        
/*        if type-of(poError, ComplexError) then                              */
/*        do:                                                                 */
/*             oComplexError = cast(poError,ComplexError):JsonMessages.       */
/*             if type-of(oComplexError,JsonObject) then                      */
/*                 oResponse:Add("dataErrors",cast(oComplexError,JsonObject)).*/
/*             else                                                           */
/*                 oResponse:Add("dataErrors",cast(oComplexError,JsonArray)). */
/*        end.                                                                */
/*        else do:                                                            */
            if type-of(poError, AppError) then
            do:
                if cast(poError, AppError):ReturnValue > "" then
                do:
                   assign oError = new JsonObject().
                   oErrorList:Add(oError).
                   oError:Add('errorMsg', cast(poError, AppError):ReturnValue).
                   oError:Add('errorNum', 0).
                   iStart = 2.
                end.
            end.
            if(type-of(poError,ApplicationError)) then
            do iLoop = iStart to iMax:
               oErrorList:Add(cast(poError,ApplicationError):GetError(iLoop)).   
            end.
            else do iLoop = iStart to iMax:
                assign oError = new JsonObject().  
                oErrorList:Add(oError).
                oError:Add('errorMsg' , poError:GetMessage(iLoop)).
                oError:Add('errorNum', poError:GetMessageNum(iLoop)).
            end.
            oResponse:Add('Errors':u, oErrorList).
/*        end.*/
        case true:
            // single error? add an simple JSON object
            when not valid-object(this-object:ErrorEntity) then
            do:
                assign this-object:ErrorEntity = oResponse.
            end.
            // if there's already an array, add to it                
            when type-of(this-object:ErrorEntity, JsonArray) then
                cast(this-object:ErrorEntity, JsonArray):Add(oResponse).
            
            // if there's a single json object, switch to an array
            when type-of(this-object:ErrorEntity, JsonObject) then
            do:
                assign oErrorList = new JsonArray().
                oErrorList:Add(cast(this-object:ErrorEntity, JsonObject)).
                oErrorList:Add(oResponse).
                
                assign this-object:ErrorEntity = oErrorList.
            end.
        end case.
        
/*        if session:debug-alert then                              */
/*            oResponse:Add('type':u, poError:GetClass():TypeName).*/
/*                                                                 */
        if poError:CallStack ne ? then
        do:
            assign oErrorList = new JsonArray()
                   iMax       = num-entries(poError:CallStack, StringConstant:LF)
                   .
            oResponse:Add('Stack':u, oErrorList).
            do iLoop = 1 to iMax:
                oErrorList:Add(entry(iLoop, poError:CallStack, StringConstant:LF)).
            end.
        end.
    end method.    
end class.