 
 /*------------------------------------------------------------------------
    File        : QueryDefinition
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/

 
block-level on error undo, throw.

using Ccs.BusinessLogic.JoinEnum from propath.
using Ccs.BusinessLogic.QueryOperatorEnum from propath.
using OpenEdge.BusinessLogic.QueryDefinition from propath.
using OpenEdge.Core.Assert from propath.
using OpenEdge.Core.Collections.ICollection from propath.
using Pmfo.Core.BusinessLogic.IQueryDefinition from propath.
using Pmfo.Core.BusinessLogic.IQueryGroup from propath.
using Pmfo.Core.BusinessLogic.QueryGroup from propath.
using Pmfo.Core.Error.IllegalOperationError from propath.
using Pmfo.Util.Array from propath.
using Pmfo.Core.BusinessLogic.IQueryEntry from propath.
using Ccs.BusinessLogic.IQuerySortEntry from propath.
using Pmfo.Core.BusinessLogic.IQueryPredicate from propath.

class Pmfo.Core.BusinessLogic.QueryDefinition  implements IQueryDefinition: 
    
    define public property QuerySelection as IQueryEntry no-undo
    get. protected set.

    /*------------------------------------------------------------------------------
        Purpose: Returns the list of query sort entries
        Notes:
    ------------------------------------------------------------------------------*/
    define public property QuerySort as IQuerySortEntry extent no-undo
    get. protected set.
    
    
    constructor public QueryDefinition (  ):
        super ().
    end constructor.

    constructor public QueryDefinition ( input pEntry as IQueryEntry ):
        assign this-object:QuerySelection = pEntry.
    end constructor.
    
    constructor public QueryDefinition ( input pEntry as IQuerySortEntry extent ):
        Assert:HasDeterminateExtent(pEntry, 'Query sort entries').
        QuerySort = pEntry.
    end constructor.
    
    constructor public QueryDefinition ( input pEntry as IQuerySortEntry ):
        define variable oEntry as IQuerySortEntry extent 1 no-undo.
        Assert:NotNull(pEntry, 'Query sort entry').
        oEntry[1] = pEntry.
        QuerySort = oEntry.
    end constructor.
    
    constructor public QueryDefinition ( input pEntry as IQueryEntry, input pSort as IQuerySortEntry extent ):
        this-object (input pEntry).
        QuerySort = pSort.
    end constructor.

    method override public character ToString():
        define variable cExpression as character no-undo.
        define variable i           as integer no-undo.
        if valid-object(QuerySelection) then 
            cExpression = "where " + QuerySelection:ToString().
        do i = 1 to extent(QuerySort):
            cExpression = cExpression 
                        + (if cExpression = "" then "" else " ")
                        + QuerySort[i]:ToString().
        end.
        return cExpression.    
    end.    
    
    
    
    method public logical RemoveEntries(pQueryEntries as IQueryEntry extent):
        define variable i   as integer no-undo.
        define variable lOk as logical no-undo.
        define variable lRemoved as logical no-undo.
        lok = true.
        do i = 1 to extent(pQueryEntries):
            lRemoved = RemoveEntry(pQueryEntries[i]).
            if lRemoved = false then
                lOk = false.
        end.    
        return lok.
    end method.    
    
    method public logical RemoveEntry(pQueryEntry as IQueryEntry):
        define variable lok as logical no-undo.
        define variable oGroup as IQueryGroup no-undo.
        if valid-object(QuerySelection) and QuerySelection = pQueryEntry then
        do:
            QuerySelection = ?.
            return true.
        end.
        else if type-of(QuerySelection,IQueryPredicate) then
        do:
            return false. 
        end.    
        if type-of(QuerySelection,IQueryGroup) then
        do:
            oGroup = cast(QuerySelection,IQueryGroup).
            lok = oGroup:RemoveEntry(pQueryEntry).
            if lok and extent(oGroup:Entries) = 1 then 
            do:
                QuerySelection = oGroup:Entries[1].
            end.    
            return lok.
        end.
        else 
            undo, throw new IllegalOperationError(subst("Cannot remove entry from group of type &1",QuerySelection:GetClass():TypeName)).       
    end method.
    
    method public logical AddEntries(pQueryEntries as IQueryEntry extent).
        define variable oGroup as IQueryGroup no-undo.
        if extent(pQueryEntries) > 1 then
        do: 
            oGroup = new QueryGroup(pQueryEntries).
            return AddEntry(oGroup).
        end.
        else 
            return AddEntry(pQueryEntries[1]).
    end method.    
    
    method public logical AddEntry(pQueryEntry as IQueryEntry):
        define variable oGroup as IQueryGroup no-undo.
        if not valid-object(QuerySelection) then
            QuerySelection = pQueryEntry.
        else if type-of(QuerySelection,IQueryGroup) then
            cast(QuerySelection,IQueryGroup):AddEntry(pQueryEntry).
        else     
            QuerySelection = new QueryGroup(cast(Array:ToArray(QuerySelection,pQueryEntry),IQueryEntry)).
        return true.
    end method.   
    
    method public logical AnyOr():
        define variable oPredicate as IQueryPredicate no-undo.
        define variable oGroup as IQueryGroup no-undo.
        define variable oCssGroup as Ccs.BusinessLogic.IQueryGroup no-undo.
        define variable i as integer no-undo.
        if not valid-object(QuerySelection) then
        do:
            return false.
        end.    
        else if type-of(QuerySelection,IQueryPredicate) then
        do:
            return false.
        end.    
        else if type-of(QuerySelection,IQueryGroup) then
        do:
            return oGroup:AnyOr().
        end.
        else if type-of(QuerySelection,Ccs.BusinessLogic.IQueryGroup) then
        do:
            oCssGroup = cast(QuerySelection,Ccs.BusinessLogic.IQueryGroup).
            do i = 1 to extent(oCssGroup:Entries):
                case oCssGroup:Entries[i]:Join:
                    when JoinEnum:Or or when JoinEnum:OrNot then 
                        return true.
                end.    
            end. 
            return false.     
        end. 
        else // there should not be any more types.. 
            undo, throw new IllegalOperationError(subst("Cannot get AnyOr() from type &1",QuerySelection:GetClass():TypeName)).        
     end method. 
    
    method public IQuerySortEntry extent RemoveSort():
        define variable oSort as IQuerySortEntry extent no-undo.
        if extent(QuerySort) <> ? then 
        do:
            oSort = QuerySort.
            extent(QuerySort) = ?.
        end.    
        return oSort.
    end.    
    
    method public logical SetSort(pSort as IQuerySortEntry):
        define variable oSort as IQuerySortEntry extent 1 no-undo.
        if extent(QuerySort) <> ? then 
        do:
            extent(QuerySort) = ?.
        end.    
        oSort[1] = pSort.
        QuerySort = oSort.
        return true.
    end.
    
    method public logical SetSort(pSort as IQuerySortEntry extent):
        if extent(QuerySort) <> ? then 
        do:
            extent(QuerySort) = ?.
        end.    
        QuerySort = pSort.
        return true.
    end method.
    
   
    
end class.