/*------------------------------------------------------------------------------
 File        : Business.FeedbackBE
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:36.953-04:00
 Notes       :   
------------------------------------------------------------------------------*/

block-level on error undo, throw.

using Pmfo.Core.BusinessLogic.BusinessEntity from propath.

class Business.FeedbackBE inherits BusinessEntity:

    {schema/feedback.i}

    define dataset dsFeedback for ttFeedback.

    constructor FeedbackBE():
        super(dataset dsFeedback:handle).
    end constructor.

end class.
