
/*------------------------------------------------------------------------
    File        : generateResources.p
    Purpose     : Generate a json file with resource information for the 
                  ServiceManager.  

    Syntax      :

    Description : 

    Author(s)   : hdaniels
    Created     : Wed May 26 07:43:35 EDT 2021
    Notes       : The data is generated from r-code (or source),
                  DataAdminManager() for all connected DBs and 
                  the NameService. 
                  The NameService MUST resolve a unique public name from  
                  database table name and lookup table name/key in order to 
                  create datasource records of type "Table" and "CodeTable for 
                  BE temp-tables that does not have a physical <classname>DS.    
  ---------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

using Pmfo.Repository.Business.ResourceBE from propath.
//using Pmfo.Core.Common.IWarningMessageTableHolder from propath.

define variable oResourceBe as ResourceBE   no-undo.
oResourceBe = new ResourceBE().
oResourceBE:ReadFromSourceAndCacheData().
return "0". // PCT needs this to detect a successful run 