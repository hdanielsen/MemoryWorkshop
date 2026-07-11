
/*------------------------------------------------------------------------
    File        : IUpdateDataRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/


using Ccs.BusinessLogic.CommitScopeEnum from propath.

interface Pmfo.Core.BusinessLogic.IUpdateDataRequest:  
    define public property MainRequestedBuffer as character no-undo get. set.
      
    define public property CommitScope         as CommitScopeEnum no-undo get. set.   
     /* Optional comma separated list of tables that do not need or do not have
       an update target - read-only - yse Add- and RemoveNoTargetTable to edit */
    define public property NoTargetTables       as character no-undo get.  
    
    
   
end interface.