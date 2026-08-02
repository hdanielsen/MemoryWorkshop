 
 /*------------------------------------------------------------------------
    File        : LokupBE
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Sun May 23 11:21:58 EDT 2021
    Notes       : 
  ----------------------------------------------------------------------*/
 
using Pmfo.Repository.business.LookupTypeBE.

block-level on error undo, throw.

class Business.LookupTypeBE inherits LookupTypeBE: 
    constructor public LookupTypeBE (  ):
        super ().
    end constructor.

    constructor protected LookupTypeBE (pcResource as character  ):
        define variable i as integer no-undo.
        define variable hBuffer as handle no-undo.
        super ().
      //  SetInheritedResource(pcResource).
        hBuffer = buffer ttLookupType:handle.
        do i = 1 to hBuffer:num-fields:
            
            if hBuffer:buffer-field(i):name = "EntityName" then
                hbuffer:buffer-field(i):serialize-hidden = false.
            else if hBuffer:buffer-field(i):name = "DisplayName" then 
                hbuffer:buffer-field(i):serialize-hidden = false.
            else if hBuffer:buffer-field(i):name = "ModelType" then 
                hbuffer:buffer-field(i):serialize-hidden = false.    
            else    
                hbuffer:buffer-field(i):serialize-hidden = true.
        end.
    end constructor.
end class.