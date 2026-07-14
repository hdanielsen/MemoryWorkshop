 
 /*------------------------------------------------------------------------
    File        : PublicNameBE
    Purpose     : Data for NameService 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : 3/19/2022
    Notes       :  
  ----------------------------------------------------------------------*/


block-level on error undo, throw.
 
using Pmfo.Repository.Business.PublicNameBE from propath.

class Business.PublicNameBE inherits PublicNameBE: 
    constructor public PublicNameBE (   ):
        super ().
    end constructor.
    
end class.