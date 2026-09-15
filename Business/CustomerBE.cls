/*------------------------------------------------------------------------------
 File        : Business.CustomerBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:09.790-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.
using Pmfo.Core.Service.IClientRequest from propath.
using Pmfo.Core.Service.IClientGetRequest from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Util.DatasetUtil from propath.
using Pmfo.Util.TableUtil from propath.
using Pmfo.Core.BusinessLogic.DatasetBuilder from propath.

class Business.CustomerBE inherits BusinessEntity:

    {schema/customer.i}

    define dataset dsCustomer for ttCustomer.

    constructor CustomerBE():
        super(dataset dsCustomer:handle).
    end constructor.

    method protected override handle PrepareRequestDataset(pClientRequest as IClientRequest):
        define variable hDataset as handle no-undo.
        define variable cExpand as character no-undo.
        define variable oDatasetBuilder as DatasetBuilder no-undo.
        
        hDataset = super:PrepareRequestDataset(pCLientRequest).
        if type-of(pClientRequest,IClientGetRequest) then do:
            cExpand = cast(pClientRequest,IClientGetRequest):Expand.
            if cExpand > "" then 
            do: 
                oDatasetBuilder = new DatasetBuilder().
                hDataset = oDatasetBuilder:CreateExpandDataset(this-object, cExpand).
            end.
        end.     
        
   
        return hdataset.
        
    end method.       

end class.
