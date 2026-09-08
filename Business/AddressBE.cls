/*------------------------------------------------------------------------------
 File        : Business.AddressBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : hdaniels
 Created     : 09/07/2026 
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.AddressBE inherits BusinessEntity:

    {schema/address.i}

    define dataset dsAddress for ttAddress.

    constructor AddressBE():
        super(dataset dsAddress:handle).
        ReadOnly = true.
    end constructor.
   

end class.
