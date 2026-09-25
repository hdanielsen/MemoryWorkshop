 
/*------------------------------------------------------------------------
   File        : TimeZoneUtil
   Purpose     : Convert dates to and from GSM based on TimeZoneName
   Syntax      : 
   Description : 
   Author(s)   : hdaniels
   Created     : Sun Sep 06 13:53:58 EDT 2026
   Notes       : Highly experimantal. 
                 All time zone related functions in ABL uses the session:time-source
                 This may have different timezone and dates from here may conflict 
                 with datetime-tz from regfular ABL   
 ----------------------------------------------------------------------*/



block-level on error undo, throw.

using Pmfo.Core.Error.BadRequestError from propath.
using Pmfo.Core.Error.NotImplementedError from propath.

class Pmfo.Util.TimeZoneUtil:
    define public property cachemempr as memptr get. set.
     
    define public static property TimeZoneName as character no-undo  
        get():
            return TimeZoneName.     
        end. 
        set(pcName as character).
            if TimeZoneName <> pcName then do: 
                TimeZoneName = PopulateDynamicTimeInformation(pcName).
            end.    
        end.
   
    // NOTE - caches a 420 byte memptr 
    define private static property DynamicTimeZoneInformation as memptr no-undo 
        get.
        private set(pTimezone as memptr):
            set-size(DynamicTimeZoneInformation) = 0.
            DynamicTimeZoneInformation = pTimeZone.
        end. 
        
    
    /* time zone offset - readonly.
       Can be used to set session:timezone temporarily during a request that 
       processes dates so that all ABL udatye processing uses this time zone
       NOTE: Keep in mind that session:timezone will not reflect daylight time 
             switch. w 
       CAUTION: If you do, make sure to track what it was and set it back 
              (probably also check and reset session:time-source)
    */            
    define public static property TimeZone as integer no-undo 
        get():  
            define variable dNow   as datetime no-undo.
            define variable dLocal as datetime no-undo.
            dNow = now.
            dLocal = GetLocalTimeFromSysTime(dNow).
            return integer(interval(dLocal,dNow,"minutes")).
        end.
    
    define private static property windowsAPI as handle 
        get():
            if not valid-handle(windowsAPI) then 
                run Core/Windows/windowsAPi.p persistent set windowsAPI.
            return windowsAPI.
        end.
        
        private set. 
	 
    constructor static TimeZoneUtil (  ):
        if opsys <> "win32" then 
            undo, throw new NotImplementedError(substitute("TimeZoneUtil is not implemented on &1",opsys)).
        TimeZoneName = "Eastern Standard Time".    
    end constructor.
    
    // get abl datetime from SYSTYPE memptr 
    method public static datetime GetDateTime 
        ( pSysType as memptr ):
     
        return datetime(
            get-short(pSysType, 3), //month
            get-short(pSysType, 7), //day
            get-short(pSysType, 1), //year
            get-short(pSysType, 9), //hour
            get-short(pSysType, 11), //minute
            get-short(pSysType, 13), //second
            get-short(pSysType, 15)  // millisecond
            ).
          
    end method.            
    
    method public static datetime GetLocalTimeFromSysTime(pdate as datetime): 
        define variable mSystime   as memptr no-undo.
       
        define variable mLocaltime as memptr no-undo. 
        define variable iResult as integer no-undo.
        
        msystime = GetSysTime(pdate).
        set-size(mLocaltime) = 16. 
        
        run SystemTimeToTzSpecificLocalTimeEx in windowsAPI
            (DynamicTimeZoneInformation,
            mSysTime,
            mLocaltime,
            output iResult).
        
        return GetDateTime(mLocaltime).
        finally:
            set-size(mSystime) = 0.
            set-size(mLocaltime) = 0.
        end finally. 
    end method.     
    
    // Get local time with time zone offset 
    // since this class xan override the opsys timezone converting the timezone offset 
    // must also come from here 
    method public static datetime-tz GetLocalTimeTZFromSysTime(pdate as datetime): 
        define variable dLocalDateTime as datetime no-undo.
        dLocalDateTime = GetLocalTimeFromSysTime(pdate).
         
        return datetime-tz(dLocalDateTime,interval(dLocalDateTime,pdate,"minutes")).
    end method.     
    
     
    /**     
    NOTE: 
    During the transition from daylight saving time to standard time, the local clock repeats. 
    A local time within the repeated window is ambiguous because it occurs twice, once in daylight 
    saving time and once in standard time. If such a local time is specified, this function treats 
    it as daylight saving time and applies the daylight saving time bias.
    During the transition from standard time to daylight saving time, the local clock jumps forward. 
    A local time within the skipped window is invalid because it does not have a valid UTC conversion.
    If such a local time is specified, the function treats it as standard time and applies the standard 
    time bias. */
    
    method public static datetime GetSysTimeFromLocalTime(pdate as datetime): 
        define variable mSystime   as memptr no-undo.
        define variable mLocaltime as memptr no-undo. 
        define variable iResult as integer no-undo.
        
        mLocaltime = GetSysTime(pdate).
        set-size(mSysTime) = 16. 
        
        run TzSpecificLocalTimeToSystemTimeEx in windowsAPI
            (DynamicTimeZoneInformation,
            mLocaltime,
            mSysTime,
            output iResult).
        
        return GetDateTime(mSystime).
         
    end method.     
    
    // get a SYSTIME memptr from ABL datetime
    method public static memptr GetSysTime 
        (pdateTime as datetime  ):
       
        /* Define trackers for the arithmetic breakdown */
        define variable millisecondsSinceMidnight as integer no-undo.
        define variable calculatedHour            as integer no-undo.
        define variable calculatedMinute          as integer no-undo.
        define variable calculatedSecond          as integer no-undo.
        define variable calculatedMsec            as integer no-undo.
        define variable pSystemtime               as memptr  no-undo.
        /* 1. Grab the total milliseconds since midnight from the DATETIME block */
        millisecondsSinceMidnight = mtime(pdateTime).
        
        set-size(pSystemTime) = 16.
        
        /* 2. Break down the time components mathematically */
        calculatedMsec   = millisecondsSinceMidnight modulo 1000.
        calculatedSecond = truncate(millisecondsSinceMidnight / 1000, 0) modulo 60.
        calculatedMinute = truncate(millisecondsSinceMidnight / 1000 / 60, 0) modulo 60.
        calculatedHour   = truncate(millisecondsSinceMidnight / 1000 / 60 / 60, 0).
        
        /* 3. Assign the mathematically extracted variables safely into the Win32 structure */
        put-short(pSystemTime, 1)  = year(pdateTime).
        put-short(pSystemTime, 3)  = month(pdateTime).
        put-short(pSystemTime, 5)  = weekday(pdateTime) - 1. /* Sunday maps from ABL 1 to Win32 0 */
        put-short(pSystemTime, 7)  = day(pdateTime).
        put-short(pSystemTime, 9)  = calculatedHour.
        put-short(pSystemTime, 11) = calculatedMinute.
        put-short(pSystemTime, 13) = calculatedSecond.
        put-short(pSystemTime, 15) = calculatedMsec.
               
        return pSystemTime.       
    end method.       
    
    method private static character PopulateDynamicTimeInformation(pcName as character): 
        define variable mDynamicStruct as memptr no-undo.
        define variable iCurrentindex  as integer no-undo.
        /* Win32 Constant Codes */
        define variable ERROR_SUCCESS       as integer initial 0   no-undo.
        define variable ERROR_NO_MORE_ITEMS as integer initial 259 no-undo.
        define variable iResult             as integer   no-undo.
        define variable cStandardname       as character no-undo.
        define variable mUtf16Struct        as memptr    no-undo.
        
        do while true:
            /* Clear structure memory before each iteration pass */
            set-size(mDynamicStruct) = 0.    
            set-size(mDynamicStruct) = 432. 
             
            /* Call the Enumerator */
            run EnumDynamicTimeZoneInformation in windowsAPI 
                (
                input ICurrentIndex, 
                input mDynamicStruct,
                output iResult).
   
            /* Break when Windows runs out of time zones */
            if iResult = ERROR_NO_MORE_ITEMS then leave.
            if iResult = ERROR_SUCCESS then do:
                /* Extract the Registry Key name (Offset 173, Unicode/Wide String) */
                set-size(mUtf16Struct) = 64.
                set-pointer-value(mUtf16Struct) = get-pointer-value(mDynamicStruct) + 4. 
          
                cStandardname = ConvertToAnsii(mutf16Struct).
                /* Check if this matches the remote time zone you are looking for */
                if cStandardname = pcName then do: 
                    DynamicTimeZoneInformation = mDynamicStruct.
                    /*                                                                                          */
                    /*                    message                                                               */
                    /*                                                                                          */
                    /*                        "Found Target Name"  cStandardname skip                           */
                    /*                        "Index Position: " icurrentIndex skip                             */
                    /*                        "Remote Base Bias (Minutes): " get-long(mDynamicStruct, 1) skip   */
                    /*                        "Dynamic DST Disabled here? " (get-byte(mDynamicStruct, 429) <> 0)*/
                    /*                        view-as alert-box information title "Remote Time Zone Lookup".    */
                    // return the requested name (called from TimeZoneName setter)     
                            
                    return pcname.
                end. 
            end.
            iCurrentindex = iCurrentIndex + 1.    
        end.
        undo, throw new BadRequestError(substitute("TimeZone not found with name &1 in registry",pcname)).
        finally:
             set-size(mDynamicStruct) = 0.
             // I have no idea why this is necessary...
             set-pointer-value(mUtf16Struct) = get-pointer-value(mDynamicStruct).
             set-size(mUtf16Struct) = 0.
        end finally.    
    end method.    
    
    
    method private static character ConvertToAnsii(putf16String as memptr):
        define variable mTargetAnsi as memptr   no-undo.
        define variable iTargetSize as integer  no-undo.
        define variable iFinalBytes as integer  no-undo.
        define variable cLongchar   as longchar no-undo.
        set-size(mTargetAnsi) = 1. // should really be 0, but Progress does not allow this
    
        // 1 first call to get the target size   
        // Never allocate wide buffers based purely on the get-size() or length of the input memptr. 
        // Multi-byte strings vary in length per character (UTF-8 strings use 1�4 bytes), whereas wide strings always take 
        // 2 bytes (wchar_t) per character element.
        run WideCharToMultiByte in windowsAPI
            (input  0,             /* CodePage (CP_ACP) */
            input  0,             /* dwFlags */
            input  putf16String,  /* lpWideCharStr (Your source pointer) */
            input  -1,            /* cchWideChar (Read until null terminator) */
            input  mTargetAnsi,   /* PASS UNALLOCATED MEMPTR - not possible for progress memptr
                                     (we cheat and set it to 1 above / NULL) */
            input  0,             /* cbMultiByte (Pass 0 to request size calculation) */
            input  0,             /* lpDefaultChar */
            input  0,             /* lpUsedDefaultChar */
            output iTargetSize /* Returns the count of bytes required */
            ).
    
        
        if iTargetSize > 0 then do:
            set-size(mTargetAnsi) = 0. 
            /* DYNAMICALLY ALLOCATE THE TARGET MEMORY BUFFER */
            set-size(mTargetAnsi) = iTargetSize.

            /* 2. EXECUTE THE ACTUAL TRANSCODING CONVERSION
               Now we pass the actual allocated 'mTargetAnsi' pointer and the verified size ceiling. */
            run WideCharToMultiByte in windowsAPI
                (input  0,
                input  0,
                input  putf16String,
                input  -1,
                input  mTargetAnsi,    /* Pass the actual target pointer memory address */
                input  iTargetSize, /* Pass the exact byte length we just allocated */
                input  0,
                input  0,
                output iFinalBytes
                ).
            if iFinalBytes > 0 then 
            do: 
               // return codepage-convert(get-string(mTargetAnsi, 1),session:cpinternal,"windows-1252").
                return get-string(mTargetAnsi, 1).
            end.
        end.
         
    end method.    
        
    
    
end class.