
/*------------------------------------------------------------------------
    File        : windowsapi.p
    Purpose     : wrapper for windows external procedures
    Description : 
    Author(s)   : hdaniels
    Created     : Sat Sep 05 09:30:15 EDT 2026
    Notes       : 64 bit
  ----------------------------------------------------------------------*/
 
block-level on error undo, throw.

procedure EnumDynamicTimeZoneInformation external "advapi32.dll":
    define input  parameter dwIndex                      as long no-undo. 
    define input  parameter lpDynamicTimeZoneInformation as memptr no-undo.  /* 432-byte DYNAMIC structure */
    define return parameter dwResult                     as long no-undo. 
end procedure.

/* call with pvData set-size to 1 to trick progress 64 bit to get size first (pcbData)
   and then use the size set-size of pvData (size to 0 first) when retireving the value */
procedure RegGetValueA external "advapi32.dll" :
    define input  parameter hkey          as long.       
    define input  parameter lpSubKey      as character.
    define input  parameter lpValue       as character.
    define input  parameter dwFlags       as long.
    define output parameter pdwType       as long.
    define input  parameter pvData        as memptr.
    define input-output parameter pcbData as long.       
    define return parameter vStatus       as long.       
end procedure.

procedure GetLocalTime external "kernel32.dll":
    define input-output parameter lpSystemTime as memptr.
end procedure.

procedure GetSystemTime external "kernel32.dll":
    define input-output parameter lpSystemTime as memptr.
end procedure.
  
/** GetTimeZoneInformation - from opsys with current daylight time saving info   
   lpTimeZoneInformation byte positions:Rtrsa
   - Bytes 1-4:  Bias (Long / 4-byte integer)
   - Bytes 69-72: StandardBias (Long)
   - Bytes 169-172: DaylightBias (Long) 
**/    
procedure GetTimeZoneInformation external "kernel32.dll":
    define input  parameter lpTimeZoneInformation as memptr.
    define return parameter dwResult              as long.
end procedure.

procedure GetTimeZoneInformationForYear external "kernel32.dll":
    define input  parameter wYear                        as short  no-undo.
    define input  parameter lpDynamicTimeZoneInformation as memptr no-undo. /* 432-byte DYNAMIC structure */
    define input  parameter lpTimeZoneInformation        as memptr no-undo.
    define return parameter bResult                      as long   no-undo.
end procedure.

procedure SystemTimeToTzSpecificLocalTime external "kernel32.dll":
    define input  parameter lpTimeZoneInformation as memptr no-undo. /* 172 byte structure */
    define input  parameter lpUniversalTime       as memptr no-undo.
    define input  parameter lpLocalTime           as memptr no-undo.
    define return parameter dwDynamicDaylightCode as long   no-undo. /* Returns 1 for Standard, 2 for DST */
end procedure.

procedure SystemTimeToTzSpecificLocalTimeEx external "kernel32.dll":
    define input  parameter  lpTimeZoneInformation as memptr no-undo. /* 432-byte DYNAMIC structure */
    define input  parameter  lpUniversalTime       as memptr no-undo. /* 16-byte UTC SYSTEMTIME */
    define input  parameter  lpLocalTime           as memptr no-undo. /* 16-byte Output SYSTEMTIME */
    define return parameter bResult                as long   no-undo. /* Returns 0 for failure, non-zero for success */
end procedure.

/** TzSpecificLocalTimeToSystemTime - from opsys with current daylight time saving info
    get the GMT time and daylight tiome saving flag for a local time   
**/
procedure TzSpecificLocalTimeToSystemTime external "kernel32.dll":
    define input  parameter lpTimeZoneInformation as memptr. /* Pointer to timeZoneInformation  172 byte structure  */
    define input  parameter lpLocalTime           as memptr. /* Pointer to input time  */
    define input  parameter lpSystemTime          as memptr. /* Pointer to output SYSTEMTIME */
    define return parameter opStatus              as long.   /* Returns structure indicator  */
end procedure.

procedure TzSpecificLocalTimeToSystemTimeEx external "kernel32.dll":
    define input parameter  lpDynamicTimeZoneInformation as memptr no-undo. /* 432-byte DYNAMIC_TIME_ZONE_INFORMATION struct */
    define input parameter  lpLocalTime                  as memptr no-undo. /* 16-byte Input local SYSTEMTIME struct */
    define input parameter  lpUniversalTime              as memptr no-undo. /* 16-byte Output UTC SYSTEMTIME struct */
    define return parameter bResult                      as long   no-undo. /* Returns 0 for failure, non-zero for success */
end procedure.

/* convert a wide char utf-16 to bytes 
   call with lpMultiByteStr set-size to 1 to trick progress 64 bit to return size iByteswritten
   and then use this size to set-size of lpMultiByteString (size to 0 first) to do the conversion */
    
procedure WideCharToMultiByte external "kernel32.dll":
    define input parameter  CodePage          as long.
    define input parameter  dwFlags           as long.
    define input parameter  lpWideCharStr     as memptr.
    define input parameter  cchWideChar       as long.
    define input parameter  lpMultiByteStr    as memptr. /* Real buffer container */
    define input parameter  cbMultiByte       as long.
    define input parameter  lpDefaultChar     as int64.
    define input parameter  lpUsedDefaultChar as int64.
    define return parameter iBytesWritten     as long.
end procedure.



