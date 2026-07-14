/*------------------------------------------------------------------------------
 File        : Business.ItemBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:54.633-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.ItemBE inherits BusinessEntity:

    {schema/item.i}

    define dataset dsItem for ttItem.

    constructor ItemBE():
        super(dataset dsItem:handle).
    end constructor.

end class.
