/*------------------------------------------------------------------------------
 File        : schema/feedback.i
 Purpose     : 
 Syntax      : 
 Description :  
 Author(s)   : Code generator Pmfo.Tools.AppBuilder.CodeGenerator
 Created     : 07/14/2026 06:54:36.885-04:00
 Notes       : Mapped to database sports2020 table Feedback  
------------------------------------------------------------------------------*/
define temp-table ttFeedback no-undo serialize-name "feedbacks" {1}  before-table biFeedback
   field Comments                         as character   serialize-name "comments"
   field Company                          as character   serialize-name "company"
   field Contact                          as character   serialize-name "contact"
   field Department                       as character   serialize-name "department"
   field EmailAddress                     as character   serialize-name "emailAddress"
   field Fax                              as character   serialize-name "fax"
   field Phone                            as character   serialize-name "phone"
   field Rating                           as integer     serialize-name "rating"
   field zz_seq                           as int64       serialize-hidden
   index Department Department
   index Rating Rating
   index zz_seq as primary zz_seq
   .