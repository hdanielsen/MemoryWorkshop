 
 /*------------------------------------------------------------------------
    File        : GetDataTableResponse
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Notes       : 
  ----------------------------------------------------------------------*/ 

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.IGetDataTableResponse from propath.
using Pmfo.Core.Error.IllegalArgumentError from propath.

class Pmfo.Core.BusinessLogic.GetDataTableResponse implements IGetDataTableResponse: 
      /* Returns the paging context to be passed back to the business entity when requesting the next set */ 
    define public property NextPagingContext as character no-undo get. set. 
    
    /* Returns the paging context to be passed back to the business entity when requesting the previous set */
    define public property PreviousPagingContext as character no-undo get. set. 
    
    /* Returns the name of the ProDataset Table */
    define public property TableName as character no-undo 
        get.
        private set. 
    /* Returns is the result is exact (TRUE) or Guessed or Cached (FALSE) */
    define public property Exact  as logical no-undo get. set. 
    
    /* tells service how to create an URI id - if private the parent must be appended */
    define public property Public as logical no-undo 
        get. 
        set(plPublic as logical):
            if plPublic = ?
                then undo, throw new IllegalArgumentError("Parameter passed to set public is ?").
            Public = plPublic. 
        end. 
    
    // CSV of tt extent fields that should be trimmed (removing null) 
    define public property TrimExtentFields as character no-undo get. set.  
    // force use of nextpagelink when nextPagingContext has a value
    define public property UseNextPageLink as logical no-undo  get. set.  
  
    /* Returns the number of results for this table */
    define public property NumResults as int64 no-undo get. set. 
        
    constructor public GetDataTableResponse ( input pTableName as character ):
        TableName = pTableName.
    end constructor.
    
    constructor public GetDataTableResponse ( input pTableName as character, pNumResults as int64 ):
        this-object(input pTableName).
        NumResults = pNumResults.
    end constructor.
    
end class.