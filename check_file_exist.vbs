'
' 
' Search for a specific filename(part of the filename) inside a directory
' Felipe Ferreira 08/2016 www.felipeferreira.net 

Option Explicit
Dim argcountcommand
Dim arg(25)
Dim strFile     'get from arg -f  
Dim intHours    'get from arg -t 
Dim path        'get from arg -p
Dim debug : debug = 0 
Dim oFile
Dim intError
dim strScriptFile : strScriptFile = WScript.ScriptFullname


debug =  0    ' SET 0 FOR SILENT MODE!

'@@@@@@@@@@@HANDLES THE ARGUMENTS@@@@@@@@@@@@@@@
GetArgs()
if argcountcommand = 0 then
    help()
elseif ((UCase(wscript.arguments(0))="-H") Or (UCase(wscript.arguments(0))="--HELP")) then
    help()
elseif(1 < argcountcommand < 5) then
    path = GetOneArg("-p")    
	strFile = GetOneArg("-f")    
	intHours = GetOneArg("-t")  
end if
 
 
'@@@@@@@@@@@HANDLES THE WARN AND CRITI OUTPUT@@@@@@@@@@@@@@@
CheckFolder path, strFile 
pt "Hours " &intHours
wscript.echo "OK - No errors found on " & path & " for the last " & intHours & "hrs"
wscript.quit(0)


Function CheckFolder(objFolder,strFile) 
'Check the if inside the folder the files of today is found 
'on error resume next
    Dim oFSO           'FileSystemObject
    Dim oFolder        'Handle to the folder
    Dim oSubFolders    'Handle to subfolders collection
    Dim oFileCollection 'All files of the folder
'Connect to folder object and files
    Set oFSO = CreateObject("Scripting.FileSystemObject")
'Checks if Folder exists
    If oFSO.FolderExists(objFolder) = False Then
     wscript.echo "UNKOWN - Folder " & objFolder & " was not founded!"        
     wscript.quit(3)
    end if
	Set oFolder = oFSO.GetFolder(objFolder)
    Set oFileCollection = oFolder.Files        'gets all files of current folder
    'Walk through each file in this folder collection and get the ones from today only 
    For each oFile in oFileCollection 'Gets its size based on the name.
	' pt "File: " & oFile.Name & " LastModifed: " & ofile.DateLastModified	
	 If DateDiff("h",oFile.DateLastModified,Now()) < cint(intHours)  Then
	    'pt " File: " & oFile.Name & " LastModifed: " & ofile.DateLastModified
       If instr(1,Ucase(oFile.name),Ucase(strFile)) Then          
	   'If instr(1,Ucase(oFile.name),Ucase("error")) Then          
	     wscript.echo "CRITICAL - Error found on " & path & oFile.Name & " at " & ofile.DateLastModified
		 wscript.quit(2)
       End if  
	 End If
    next
end function


Function Help()
'Prints out help    
        Dim str
        str="Check if a file exists inside a folder."&vbCrlF
		str="Also part of the filename and only for files modified today."&vbCrlF
        str=str&"cscript "& strScriptFile &" -p Path -f filename "&vbCrlF
        str=str&"cscript "& "cscript check_filesize.vbs -p c:\ -f vtapi.dll -w20 -c 30"&vbCrlF
        str=str&vbCrlF
        str=str&"-h [--help]                 Help."&vbCrlF
        str=str&"-p path                     Path where files are."&vbCrlF  
        str=str&"-f file1                    FileName to check for ."&vbCrlF          
        str=str&vbCrlF
        str=str&"By Felipe Ferreira August 2016, version 1.0." & vbCrlF
        wscript.echo str
        wscript.quit        
End Function

Function GetArgs()
'Get ALL arguments passed to the script
    On Error Resume Next        
    Dim i       
    argcountcommand=WScript.Arguments.Count     
    for i=0 to argcountcommand-1
        arg(i)=WScript.Arguments(i)
        'pt i & " - " & arg(i)
    next        
End Function
Function GetOneArg(strName)
    On Error Resume Next
    Dim i
    for i=0 to argcountcommand-1
        if (Ucase(arg(i))=Ucase(strName)) then
            GetOneArg=arg(i+1)
            Exit Function
        end if
    next        
End Function

 
 
function pt(txt)
if debug = 1 then
    wscript.echo txt
end if
end function
