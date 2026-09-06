
/*------------------------------------------------------------------------
    File        : IDataAccess
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/

 
using Progress.Lang.Object from propath.
using Pmfo.Core.BusinessLogic.IGetDataResponse from propath.
using Pmfo.Core.BusinessLogic.IUpdateDataRequest from propath.
using Pmfo.Core.Common.IResource from propath.
using Pmfo.Core.BusinessLogic.IGetDataRequest from propath.

interface Pmfo.Core.DataLayer.IDataAccess inherits IResource:  
    method public IGetDataResponse FetchData ( input poRequest as IGetDataRequest, input-output dataset-handle phDataset ).
    method public Object SubmitData( input poRequest as IUpdateDataRequest, input-output dataset-handle phDataset, output table-handle phWarning ).
end interface.