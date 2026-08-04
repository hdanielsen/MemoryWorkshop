
/*------------------------------------------------------------------------
    File        : filedata.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : hdaniels
    Created     : Fri Feb 15 12:06:28 EST 2019
    Notes       :
  ----------------------------------------------------------------------*/
 define temp-table fileData  no-undo {1} before-table beforeFileData  
    field fullPath    as character   label "File Path" format "x(40)"
    field fullName    as character   label "File Name" format "x(32)"
    field fileExt     as character   label "Extension" format "xx"
    field fileType    as character   label "File Type" format "x(25)" 
    field fileTime    as datetime-tz label "Modified Time"
    index idxFileDate is primary fullPath fullName fileTime
 .

