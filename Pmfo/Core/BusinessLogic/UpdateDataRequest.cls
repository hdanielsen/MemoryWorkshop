 
 /*------------------------------------------------------------------------
    File        : UpdateDataRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using Ccs.BusinessLogic.CommitScopeEnum from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.

class Pmfo.Core.BusinessLogic.UpdateDataRequest implements IUpdateDataRequest: 
    define public property CommitScope as CommitScopeEnum          no-undo 
        get():
            if CommitScope = ? then 
                return CommitScopeEnum:All.
            return CommitScope. 
        end. 
        set.
    
    define public property MainRequestedBuffer as character        no-undo get. set. 
    
    /* Optional comma separated list of tables that do not need or do not have
       an update target - read-only - use Add- and RemoveNoTargetTable to edit */
    define public property NoTargetTables      as character no-undo get. protected set.
    
          
    constructor public UpdateDataRequest (pBuffername as char):
        super ().
        MainRequestedBuffer = pBuffername.
    end constructor.
    
    // add a table name to the no target table list
    method public logical AddNoTargetTable (pTablename as character):
        if lookup(pTablename,NoTargetTables) = 0 then
        do:
            NoTargetTables = NoTargetTables 
                           + (if NoTargetTables = "" then "" else ",")
                           + pTablename.
            return true.              
        end.            
        return false.      
    end method.
      
    // remove a table name from the no target table list
    method public logical RemoveNoTargetTable (pTablename as character):
        define variable iTable as integer no-undo.
        iTable = lookup(pTablename,NoTargetTables).
        if iTable > 0 then
        do:
            entry(iTable,NoTargetTables) = "". 
            NoTargetTables = trim(NoTargetTables,",").
            NoTargetTables = replace(NoTargetTables,",,",",").
            return true.              
        end.            
        return false.
    end method.    
    
     
   method public override character ToString():
       return right-trim(subst("MainRequestedBuffer:&1 &2",
                    MainRequestedBuffer,
                    if NoTargetTables > "" then subst(" NoTargetTables:&1",NoTargetTables) else ""
                      
                   )). 
   end method.     
   
end class.