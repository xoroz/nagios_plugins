'// Adapted for Nagio Check Memory by Felipe Ferreira 
Option Explicit
Const  retvalUnknown = 1
Dim    SYSDATA, SYSEXPLANATION  
Dim    b, strService, intMaxMem
Dim   x, intSleep,qry, objWMIService, colListOfServices, obj, objService, strComputer ' for restarting function 

if not ( WScript.Arguments.Count = 2 ) then
    WScript.Echo "Missing parameters: <process name> <Max Memory MB usage>"
	Wscript.quit 0 
end if

strComputer = "." 
strService = Wscript.Arguments(0)
intMaxMem = Wscript.Arguments(1)

b = CheckProcessMemory( "localhost", "", strService, intMaxMem )



if ( b = True )  then 
 WScript.Echo "OK - Process" &  StrService & " " & SYSEXPLANATION & " |mem=" & SYSDATA
 Wscript.quit 0 
else 
 WScript.Echo "CRITICAL - Service has been restarted " & SYSEXPLANATION & " |mem=" & SYSDATA
'RESTART SERVICE HERE 
 RestartService( StrService )
 Wscript.quit 2
end if 



' //////////////////////////////////////////////////////////////////////////////

Function RestartService(strService)
 intSleep = 7
'cleanup service name if has .exe 
if instr(strService, ".exe") then
  strService = Left(strService, Len(strService) - 4)
 end if 
 
 
 Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
 qry = "SELECT * FROM Win32_Service WHERE Name='" & strService & "'"
 Set colListOfServices = objWMIService.ExecQuery (qry)
 
 For Each objService in colListOfServices
  'WScript.Echo "Your "& strService & " service has been stoped" 
  objService.StopService()
  WSCript.Sleep intSleep

  'Set obj = CreateObject("Scripting.FileSystemObject") 'Calls the File System Object
  'obj.DeleteFile("D:\MosaicoWeb\at5mosaicoweb\webapps\FileSupply\temp\*.* ") 'Deletes the file throught the DeleteFile function
  
  objService.StartService()
  'WScript.Echo "Your "& strService & " service has been started" 
 Next 
  'WScript.Echo "Your "& strService & " service has been restarted" 
 end Function


Function CheckProcessMemory( strComputer, strCredentials, strProcessName, nMaxMB )

    Dim objWMIService

    CheckProcessMemory      = retvalUnknown  ' Default return value
    SYSDATA                 = ""             ' Will store the number of MBs used by the process
    SYSEXPLANATION          = ""             ' Set initial value

    If( Not getWMIObject( strComputer, strCredentials, objWMIService, SYSEXPLANATION ) ) Then
        Exit Function
    End If

    CheckProcessMemory      = checkProcessMemoryWMI( objWMIService, strComputer, strProcessName, nMaxMB, SYSDATA, SYSEXPLANATION )

End Function ' //////////////////////////////////////////////////////////////////////////////


Function checkProcessMemoryWMI( objWMIService, strComputer, strProcessName, nMaxMB, BYREF strSysData, BYREF strSysExplanation )

    Dim objProcess, colProcesses, nDiff

    checkProcessMemoryWMI          = retvalUnknown  ' Default return value

On Error Resume Next

    Set colProcesses = objWMIService.ExecQuery( "Select * from Win32_Process" )
    If( Err.Number <> 0 ) Then
        strSysData         = ""
        strSysExplanation  = "Unable to query WMI on computer [" & strComputer & "]"
        Exit Function
    End If
    If( colProcesses.Count <= 0  ) Then
        strSysData         = ""
        strSysExplanation  = "Win32_Process class does not exist on computer [" & strComputer & "]"
        Exit Function
    End If

On Error Goto 0

    For Each objProcess in colProcesses
        If( Err.Number <> 0 ) Then
            checkProcessMemoryWMI  = retvalUnknown
            strSysExplanation      = "Unable to list processes on computer [" & strComputer & "]"
            Exit Function 
        End If

        If UCase( objProcess.Name )= UCase( strProcessName ) Then
          nDiff                    = nMaxMB -  CInt( objProcess.WorkingSetSize / ( 1024 * 1024 ) )
          strSysData               = CInt( objProcess.WorkingSetSize / ( 1024 * 1024 ) )
          strSysExplanation        = "Memory usage=[" & CInt( objProcess.WorkingSetSize / ( 1024 * 1024 ) ) & "MB], maximum allowed=[" & nMaxMB & " MB]"
          If nDiff >= 0 then
             checkProcessMemoryWMI = True
          Else
             checkProcessMemoryWMI = False
          End if

          Exit Function 
        End If
    Next

    checkProcessMemoryWMI          = retvalUnknown
    strSysExplanation              = "Process [" & strProcessName & "] is not running on computer [" & strComputer & "]"

End Function 
' //////////////////////////////////////////////////////////////////////////////

' //////////////////////////////////////////////////////////////////////////////

Function getWMIObject( strComputer, strCredentials, BYREF objWMIService, BYREF strSysExplanation )	

On Error Resume Next

    Dim objNMServerCredentials, objSWbemLocator, colItems
    Dim strUsername, strPassword

    getWMIObject              = False

    Set objWMIService         = Nothing
    
    If( strCredentials = "" ) Then	
        ' Connect to remote host on same domain using same security context
        Set objWMIService     = GetObject( "winmgmts:{impersonationLevel=Impersonate}!\\" & strComputer &"\root\cimv2" )
    Else
        Set objNMServerCredentials = CreateObject( "ActiveXperts.NMServerCredentials" )

        strUsername           = objNMServerCredentials.GetLogin( strCredentials )
        strPassword           = objNMServerCredentials.GetPassword( strCredentials )

        If( strUsername = "" ) Then
            getWMIObject      = False
            strSysExplanation = "No alternate credentials defined for [" & strCredentials & "]. In the Manager application, select 'Options' from the 'Tools' menu and select the 'Server Credentials' tab to enter alternate credentials"
            Exit Function
        End If
	
        ' Connect to remote host using different security context and/or different domain 
        Set objSWbemLocator   = CreateObject( "WbemScripting.SWbemLocator" )
        Set objWMIService     = objSWbemLocator.ConnectServer( strComputer, "root\cimv2", strUsername, strPassword )

        If( Err.Number <> 0 ) Then
            objWMIService     = Nothing
            getWMIObject      = False
            strSysExplanation = "Unable to access [" & strComputer & "]. Possible reasons: WMI not running on the remote server, Windows firewall is blocking WMI calls, insufficient rights, or remote server down"
            Exit Function
        End If

        objWMIService.Security_.ImpersonationLevel = 3

    End If
	
    If( Err.Number <> 0 ) Then
        objWMIService         = Nothing
        getWMIObject          = False
        strSysExplanation     = "Unable to access '" & strComputer & "'. Possible reasons: no WMI installed on the remote server, no rights to access remote WMI service, or remote server down"
        Exit Function
    End If    

    getWMIObject              = True 

End Function
