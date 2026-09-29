 
 /*------------------------------------------------------------------------
    File        : QueryWalker
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Wed Apr 03 07:11:59 EDT 2019
    Notes       : Pseudo visitor that doesn't need an accept in each class 
            TODO: The reason for not havIng an accept was done to use the CCS classes.
                  These are no longer inherited so this can be changed
                  (seem to work fine as-is though )  
 ----------------------------------------------------------------------*/
block-level on error undo, throw.

 
using Ccs.BusinessLogic.IQuerySortEntry from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.
using Pmfo.Core.BusinessLogic.IGetDataTableRequest from propath.
using Pmfo.Core.BusinessLogic.IQueryDefinition from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.
using Pmfo.Core.BusinessLogic.IQueryGroup from propath.
using Pmfo.Core.BusinessLogic.IQueryPredicate from propath.

class Pmfo.Core.BusinessLogic.QueryBuilder.QueryWalker: 
     
    method public void Traverse (pRequest as IGetDataRequest):
        define variable i as integer no-undo.
        do i = 1 to extent(pRequest:TableRequests):
            Traverse(pRequest:TableRequests[i]).  
        end.
    end method.     
    
    method public void Traverse (pTableRequest as IGetDataTableRequest):
        if valid-object(pTableRequest:QueryDefinition) then
            Traverse(pTableRequest:QueryDefinition).
    end method.     
    
    method public void Traverse (pQueryDef as IQueryDefinition):
        define variable i as integer no-undo.
        if valid-object(pQueryDef:QuerySelection) then
            Traverse(pQueryDef:QuerySelection).
        Traverse(pQueryDef:QuerySort).
    end method.     
    
    method public void Traverse (pQuerySortEntries as IQuerySortEntry extent):
        define variable i as integer no-undo.
        do i = 1 to extent(pQuerySortEntries):
            Traverse(pQuerySortEntries[i]).
        end.    
    end method.
       
    method public void Traverse (pQueryEntry as IQueryEntry):
       if type-of(pQueryEntry,IQueryGroup) then
           Traverse(cast(pQueryEntry,IQueryGroup)).
       else if type-of(pQueryEntry,IQueryPredicate) then
           Traverse(cast(pQueryEntry,IQueryPredicate)). 
          
    end method.     
    
    method public void Traverse (pQueryGroup as IQueryGroup):
        define variable i as integer no-undo.
        
        do i = 1 to extent(pQueryGroup:Entries):
            Traverse(pQueryGroup:Entries[i]).
        end.
    end method.     
    
    method public void Traverse (pPredicate as IQueryPredicate):
    
    end method.     
    
    method public void Traverse (pSort as IQuerySortEntry):
    
    end method.     
    
          
end class.