 
 /*------------------------------------------------------------------------
    File        : MemoryObjectBE
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : September 12 2020
    Notes       :  
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.MemoryObjectBE from propath.

class Business.MemoryObjectBE inherits MemoryObjectBE: 
     
    constructor public MemoryObjectBE (   ):
        super ( ).
    end constructor.

         
end class.