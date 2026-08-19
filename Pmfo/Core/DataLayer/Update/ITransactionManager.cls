
/*------------------------------------------------------------------------
    File        : ITransactionManager
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Sun Aug 04 16:24:38 EDT 2019
    Notes       : 
  ----------------------------------------------------------------------*/

using Ccs.BusinessLogic.CommitScopeEnum from propath.
using OpenEdge.Core.Collections.IMap from propath.

interface Pmfo.Core.DataLayer.Update.ITransactionManager :  
    define public property UpdateTargets as IMap no-undo get. 
    define public property CommitScope   as CommitScopeEnum no-undo get.   
    define public property ShallowDelete as logical no-undo get. 
    
    method public void ProcessDataset(phDataset as handle).
    
end interface.