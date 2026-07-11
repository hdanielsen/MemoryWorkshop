
/*------------------------------------------------------------------------
    File        : RequestTypeEnum
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/

enum Pmfo.Core.BusinessLogic.RequestTypeEnum flags:  

    define enum SingleRow 
                SingleTopTable 
                MultiTable 
                MultiTableHideEmpty = MultiTable.

end enum.