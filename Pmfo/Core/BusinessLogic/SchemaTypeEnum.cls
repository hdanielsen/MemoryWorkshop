
/*------------------------------------------------------------------------
    File        : SchemaTypeEnum
    Purpose     : Define a type for schema data in cases where it is necessary to 
                  separate the types    
                  
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
  ----------------------------------------------------------------------*/

enum Pmfo.Core.BusinessLogic.SchemaTypeEnum :  

    define enum Table = 1 // avoid 0 
                Field 
                Sequence
                CodeTable.

end enum.