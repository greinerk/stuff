'**********************************************************************
'  Check a working directory into SourceSafe
'  
'  Command-line Parameters
'    VssSubProject       - Net Name of SQL Server being checked in 
'    SourceSafeShare     - Network location of SourceSafe DB
'    SourceSafeProject   - Project under which scripts will be stored (eg, $/webtrakdev/sql_schema)
'    SourceSafeUser      - needs checkin, checkout, delete rights  
'    SourceSafePassword  - (may not be required)
'    WorkingFolderRoot   - local file system folder holding scripts
'    DeleteMissingFolders- delete missing folders? (default = true)
'
' Creator: Bill Wunder
'
' Modified: 1/21/2003 - Kevin Greiner - Added command-line parameters
' Modified: 1/22/2003 - Kevin Greiner - Force the VSS working directory = WorkingFolderRoot
' Modified: 7/24/2009 - Kevin Greiner - add DeleteMissingFolder option
'************************************************************************
Option Explicit

' Global vars
Dim oFileSystem
Dim oDB, oRootProject
Dim oLog, sLogFile, sLogName, bLogOpen
Dim bVerbose, bDeleteMissingFolders

'Constants
'Textstream
Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8

Const TristateUseDefault = -2
Const TristateTrue = -1
Const TristateFalse = 0

'VSSItem.type
Const VSSITEM_PROJECT = 0
Const VSSITEM_FILE = 1

'VSSItem.IsCheckedout (not cumulative)
Const VSSFILE_NOTCHECKEDOUT = 0
Const VSSFILE_CHECKEDOUT = 1
Const VSSFILE_CHECKEDOUT_ME = 2

' have not confirmed value if flag is commented out
'Const VSSFLAG_BINBINARY = 1 'sets the added file type to binary.
Const VSSFLAG_BINTEST = 0 '(default) auto-detects the added file’s file type.
Const VSSFLAG_BINTEXT = 2 'sets the added file type to text.

Const VSSFLAG_CHKEXCLUSIVENO = 0 '(default if Multiple CheckOuts is enabled) allows the item to be checked out by multiple users
Const VSSFLAG_CHKEXCLUSIVEYES = 1 '(default if Multiple CheckOuts is disabled) prevents the item from being checked out by multiple users

Const VSSFLAG_CMPFULL = 512 'compare the full contents of the local file to the SourceSafe copy.
Const VSSFLAG_CMPTIME = 1024 'compare files through use of the file’s TimeStamp.
Const VSSFLAG_CMPCHKSUM = 1536 '(default) compare files through use of a checksum that it stores internally (preferred).
Const VSSFLAG_CMPFAIL = 2048 'assume the local file is out of date.

'Const VSSFLAG_DELNO = 0 '(default) local file(s) will not be deleted.
'Const VSSFLAG_DELYES = 1 'the local file(s) are deleted.
'Const VSSFLAG_DELNOREPLACE = 1 'the local file is left in its current condition with the read only flag set to true. (UndoCheckOut only)
Const VSSFLAG_DELNO = 262144 '(default) local file(s) will not be deleted.
Const VSSFLAG_DELYES = 524288 'the local file(s) are deleted.
Const VSSFLAG_DELNOREPLACE = 786432 'the local file is left in its current condition with the read only flag set to true. (UndoCheckOut only)

Const VSSFLAG_DELTANO = 1 'the file will not retain its historical versions.
Const VSSFLAG_DELTAYES = 0 '(default) the file will retain its historical versions.

'Const VSSFLAG_EOLCR = 1 'append a carriage return to the end of all text files that do not already end in one.
'Const VSSFLAG_EOLCRLF = 1 'append a carriage return and line feed to the end of all text files that do not already end in one.
'Const VSSFLAG_EOLLF = 1 'append a line feed to the end of all text files that do not already end in one.
Const VSSFLAG_EOLCR = 16 'append a carriage return to the end of all text files that do not already end in one.
Const VSSFLAG_EOLLF = 32 'append a line feed to the end of all text files that do not already end in one.
Const VSSFLAG_EOLCRLF = 48 'append a carriage return and line feed to the end of all text files that do not already end in one.

'Const VSSFLAG_FORCEDIRNO = 1 'SourceSafe commands act on the current folder.
'Const VSSFLAG_FORCEDIRYES = 0 '(default) commands act on the working folder.
Const VSSFLAG_FORCEDIRNO = 16384 'SourceSafe commands act on the current folder.
Const VSSFLAG_FORCEDIRYES = 32768 '(default) commands act on the working folder.

'Const VSSFLAG_GETNO = 1 'local file(s) (in the working folder or VSSItem.LocalSpec) are not replaced.
'Const VSSFLAG_GETYES = 0 '(default) the local file(s) in the working folder or VSSItem.LocalSpec are replaced.
Const VSSFLAG_GETNO = 134217728 'local file(s) (in the working folder or VSSItem.LocalSpec) are not replaced.
Const VSSFLAG_GETYES = 67108864 '(default) the local file(s) in the working folder or VSSItem.LocalSpec are replaced.

'Const VSSFLAG_HISTIGNOREFILES = 1 'file CheckIns are excluded from the current Collection.

Const VSSFLAG_KEEPNO = 65536 '(default) the CheckIn occurs (the local file is checked in and set to read only).
Const VSSFLAG_KEEPYES = 131072 'the file(s) remain checked out (the local file(s) are checked in and remain read-write).

Const VSSFLAG_RECURSNO = 4096 '(default) project is acted on non-recursively.
Const VSSFLAG_RECURSYES = 8192 'project is acted on recursively.

Const VSSFLAG_REPASK = 64 'flag serves no purpose. It may be used in future versions of SourceSafe.
Const VSSFLAG_REPREPLACE = 128 'the local file is replaced with the most recent copy from the database.
Const VSSFLAG_REPSKIP = 192 'will not replace local files that are writeable.
Const VSSFLAG_REPMERGE = 256 'SourceSafe will merge files together that have been simultaneously modified by multiple users.

Const VSSFLAG_TIMENOW = 4 '(default) TimeStamp of the local file is set to the current date and time.
Const VSSFLAG_TIMEMOD = 8 'TimeStamp of the local file is set to the file’s last modification date and time.
Const VSSFLAG_TIMEUPD = 12 'TimeStamp of the local file is set to the date and time that the file was last checked in.

Const VSSFLAG_UPDASK = 16777216 'flag serves no purpose. It may be used in future versions of SourceSafe.
Const VSSFLAG_UPDUNCH = 50331648 '(default) uncheck out unchanged files.
Const VSSFLAG_UPDUPDATE = 33554432 'check in unchanged files.

Const VSSFLAG_USERRONO = 1 'flag serves no purpose. It may be used in future versions of SourceSafe.
Const VSSFLAG_USERROYES = 2 'flag serves no purpose. It may be used in future versions of SourceSafe.

Const VSSRIGHTS_READ = 1
Const VSSRIGHTS_CHKUPD = 2
Const VSSRIGHTS_ADDRENREM = 4
Const VSSRIGHTS_DESTROY = 8
Const VSSRIGHTS_ALL = 15
Const VSSRIGHTS_INHERITED = 16

'***************************** main program ************************************************
main()

Private Function Main()

	If WScript.Arguments.Count = 0 Then
		ShowHelp()
	Else
		Select Case WScript.Arguments(0)
			Case "/?", "-h", "--help"
				ShowHelp()
			Case Else
				Process()
		End Select
	End If
End Function

Private Sub ShowHelp()
	WScript.Echo _
		"Script: CheckIn.vbs" + vbCRLF + _
		"" + vbCRLF + _
		"Purpose: Check a working directory into SourceSafe." + vbCRLF + _
		"" + vbCRLF + _
		"Commandline Arguments: (/arg:value)" + vbCRLF + _
		"  /VssSubProject        - Name of Visual SourceSafe subproject" + vbCRLF + _
		"  /SourceSafeShare      - Network location of SourceSafe DB" + vbCRLF + _
		"  /SourceSafeProject    - Project under which scripts will be stored ($/webtrakdev/sql_schema)" + vbCRLF + _
		"  /SourceSafeUser       - needs checkin, checkout, delete rights" + vbCRLF + _
		"  /SourceSafePassword   - (may not be required)" + vbCRLF + _
		"  /WorkingFolderRoot    - local file system folder holding files to checkin" + _
		"  /DeleteMissingFolders - delete missing folders (default = true)" + vbCRLF
End Sub


Function Process()
  
'set up connections to the SourceSafe database, the working directory
'check in existing VSS objects, add any new ones, and do a logical VSS
'delete of all objects with no mate in the working directory
  
  Dim oFolder, sFolderName
  Dim sShare, sProjectName, sVssSubProject
  Dim iLevel, StartTime
  
  StartTime = Now
    
  On Error GoTo 0
    
  'use this for formatting log output in the checkin drilldown
  bLogOpen = False
  
  Set oFileSystem = CreateObject("Scripting.FileSystemObject")
  
  ' check for verbose output
  If ucase(trim(WScript.Arguments.Named.Item("Verbose"))) = "TRUE" Then
	bVerbose = True
  Else
	bVerbose = False
  End If

  'SourceSafe Client must be installed for this to work
  Set oDB = CreateObject("SourceSafe")

  sShare = Trim(WScript.Arguments.Named.Item("SourceSafeShare"))
  If Right(sShare, 1) <> "\" Then
    sShare = sShare & "\"
  End If
  If Trim(WScript.Arguments.Named.Item("SourceSafeUser")) = "" Then
    oDB.Open sShare & "SRCSAFE.INI"
  Else
    oDB.Open sShare & "SRCSAFE.INI", _
                     Trim(WScript.Arguments.Named.Item("SourceSafeUser")), _
                     Trim(WScript.Arguments.Named.Item("SourceSafePassword"))
  End If

  sProjectName = Trim(WScript.Arguments.Named.Item("SourceSafeProject"))
  If Right(sProjectName, 1) <> "/" Then
    sProjectName = sProjectName & "/"
  End If
  ' use ~ in place of \
  sVssSubProject = Replace(Trim(WScript.Arguments.Named.Item("VssSubProject")), "\", "~")
  If Len(sVssSubProject) < 2 Then
    Exit Function ' bail - no implicit local server
  End If

  sFolderName = Trim(WScript.Arguments.Named.Item("WorkingFolderRoot"))
  If Right(sFolderName, 1) <> "\" Then
    sFolderName = sFolderName & "\"
  End If
  sFolderName = sFolderName & sVssSubProject
  VerifyFolder (sFolderName)
  Set oFolder = oFileSystem.GetFolder(sFolderName)
  
  bDeleteMissingFolders = Trim(WScript.Arguments.Named.Item("DeleteMissingFolders"))

  SetSourceSafeProject (sProjectName & sVssSubProject)
  
  ' Force the VSS Working Folder = WorkingFolderRoot
  oRootProject.LocalSpec = sFolderName
  
  OpenLog oFolder
                  
  CheckIn oRootProject, oFolder, 0 'iLevel starts at 0
       
  WriteLog "Elapsed Time: " & DateDiff("n", StartTime, Now) & " minutes", iLevel

  CloseLog
  
  Set oFileSystem = Nothing
  Set oDB = Nothing

End Function



Function SetSourceSafeProject(sHierarchy)
  Dim oProject
  Dim iErrorNbr
  
  If bVerbose Then WScript.Echo "SetSourceSafeProject: sHierarchy = " & sHierarchy

  On Error Resume Next
    Set oRootProject = oDB.VSSItem(sHierarchy, False)
    WScript.Echo "SetSourceSafeProject: Err = " & Err
    Select Case Err

      Case 0 ' found it
        oDB.CurrentProject = sHierarchy
      Case -2147166577 ' didn't find it
        'recursively try the parent project until one is found
		WScript.Echo "Looking for VSS parent project: " & sHierarchy
        SetSourceSafeProject Mid(sHierarchy, 1, InStrRev(sHierarchy, "/", Len(sHierarchy) - 1, 1))
        oRootProject.NewSubProject sHierarchy, "Added on " & Date & " by CheckIn.vbs"
        Set oRootProject = oDB.VSSItem(sHierarchy, False)
      Case Else 'something bad happened - stop now
        iErrorNbr = Err.Number
        On Error GoTo 0
        Err.Raise iErrorNbr, "SetSourceSafeProject", Err.Description
    End Select

  On Error GoTo 0
  
End Function


Function VerifyFolder(sFolderName)

  If Not (oFileSystem.FolderExists(sFolderName)) Then
    oFileSystem.CreateFolder sFolderName
  End If

End Function


Function CheckIn(oProject, oFolder, iLevel)
	Dim oItem, oSubProject, sSubProject
	Dim oSubFolder, oFile
	Dim bFound, bFoundToo
	Dim iItemCounter
	
	'conditional logic breaks if the array does not always exist
	ReDim Items(0)
  
	'for the rest project and folder hierarchy should match
	'so work down through the project once
	'if current item is a project call checkin
	'if current item is a file, check it in if it exists else add it
	'all deleted sourcesafe objects with a matching file system object
	'will be undeleted
	
	For Each oItem In oProject.Items(True) ' include deleted
		
		If oItem.Type = VSSITEM_PROJECT Then
			
			WriteLog oItem.Name, iLevel
			
			bFound = 0
			For Each oSubFolder In oFolder.SubFolders
				If oSubFolder.Name = oItem.Name Then
					bFound = 1
					If (oItem.Deleted) Then
						WriteLog "Deleted Folder Found: " & oItem.Name, iLevel
						'if already an active copy of a file name that is deleted
						'don't try to undelete, the checkin below will re-add
						For iItemCounter = 0 To UBound(Items)
							bFoundToo = 0
							If Items(iItemCounter) = oSubFolder.Name Then
								bFoundToo = 1
								WriteLog "Possible Dup Project in SourceSafe: " & oItem.Name, iLevel
								Exit For 'Item Count
							End If
						Next 'oItem
						If bFoundToo = 0 Then
							oItem.Deleted = False
							'just undeleted a folder, all decendants will also be undeleted
							'they will be checked later
							WriteLog "Folder Undeleted: " & oItem.Name, iLevel
						End If
					End If
					  
					sSubProject = oProject.Spec & "/" & oSubFolder.Name
					'If bVerbose Then Wscript.Echo "sSubProject = " & sSubProject
					Set oSubProject = oDB.VSSItem(sSubProject, False)
					  
					'Clear the LocalSpec. This forces CheckOut and CheckIn to use the Working folder inherited
					'from the root, which is set at the top.
					'oSubProject.LocalSpec = ""
					  
					CheckIn oSubProject, oSubFolder, iLevel + 1
					Exit For 'oSubFolders
				End If
			Next 'oSubFolder
			
		ElseIf oItem.Type = VSSITEM_FILE Then
            
			'still a performance gain possible here
			For Each oFile In oFolder.Files
				'keep the active log out of the processing
				If oItem.Name = oLog.Name Then
					bFound = 1
				Else
					bFound = 0
					If oItem.Name = oFile.Name Then
						bFound = 1
						' undelete any matching file found and update that file
						'if error here check for a duplicate name (1 deleted-1 not deleted)
						'blows up because doesn't know what the business rule for the dup is
						If (oItem.Deleted) Then
							'if already an active copy of a file name that is deleted
							'don't try to undelete, every thing is fine the way it is
							For iItemCounter = 0 To UBound(Items)
								bFoundToo = 0
								If IsEmpty(Items) Or Items(iItemCounter) = oFile.Name Then
									bFoundToo = 1
									WriteLog "Possible Dup File in SourceSafe: " & oItem.Name, iLevel
									Exit For 'Item Count
								End If
							Next 'oItem
							If bFoundToo = 0 Then
								'if there is a deleted and a not deleted (dups) do not undelete
								oItem.Deleted = False
								WriteLog "File Undeleted: " & oItem.Name, iLevel + 1
							End If
						End If 'is deleted
						'folder file found in VSS so check it in
						CheckInFile oItem, oFile, iLevel
						Exit For 'oFile
					End If ' 'a match
				End If 'not the log file
			Next 'oFile
		End If
		
		'if VSS item has no matching folder or file then delete from VSS
		If bFound = 0 And Not (oItem.Deleted) Then
			If oItem.Type = VSSITEM_PROJECT and Not bDeleteMissingFolders Then
				' Do Nothing
			Else
				oItem.Deleted = True  'implicitly recursive if project
				WriteLog "File/Folder Deleted: " & oItem.Name, iLevel + 1
			End If
		End If
		
	Next 'oItem

	'Now that all hierarchy has been checked for deleted VSS items
	'add any files in the current file folder that are not in VSS
	'This is acting on the current level only. Is this what you want?
	'Yes because any new projects and decendants of those projects
	'will be added later (recursively?)
	
	AddNew oProject, oFolder, iLevel
	
End Function


Function AddNew(oProject, oFolder, iLevel)
'this will add all new folders found in the file syatem to
'the VSS hierarchy as well as add any files and subfolders
'found in the new folder
	Dim oTryItem, sTryItem
	Dim oSubFolder, oFile
	Dim iErrorNbr

	On Error Resume Next

	For Each oSubFolder In oFolder.SubFolders
		sTryItem = oProject.Spec & "/" & oSubFolder.Name
		Set oTryItem = oDB.VSSItem(sTryItem, True) 'include deleted

		Select Case Err

			Case 0 ' found it
			
			Case -2147166577 ' didn't find it
				AddSubProject oProject, oSubFolder, iLevel
	
			Case Else 'something bad happened - but keep going
				WriteLog "Project Error (AddNew): " & Err.Number & ": " & Err.Description, iLevel
		End Select
	Next

	For Each oFile In oFolder.Files
		sTryItem = oProject.Spec & "/" & oFile.Name
		Set oTryItem = oDB.VSSItem(sTryItem, True) 'include deleted
		
		Select Case Err
			
			Case 0 ' found it
			  
			Case -2147166577 ' didn't find it
				AddFile oProject, oFile, iLevel
			
			Case Else 'something bad happened - but keep going
				WriteLog "File Error (AddNew): " & Err.Number & " " & Err.Description, iLevel
		End Select
	Next
  
	On Error GoTo 0

End Function


Function AddSubProject(oProject, oFolder, iLevel)
  Dim oFile, oSubFolder, oNewProject
  Dim sNewProject
  
  'no need to include checking for deleted files
  'they should have all been found at checkin
  sNewProject = oProject.Spec & "/" & oFolder.Name
  
  oProject.NewSubProject sNewProject, "added on " & Date
  Set oNewProject = oDB.VSSItem(sNewProject, False)

  ' now add child folders and decendant folders (top down order)
  For Each oSubFolder In oFolder.SubFolders
    AddSubProject oNewProject, oSubFolder, iLevel
    WriteLog "(AddSubProject) Add Project: " & oSubFolder.Name, iLevel
  Next 'oSubFolder

  If oFolder.Files.Count > 0 Then
    ' add all files in this folder
    For Each oFile In oFolder.Files
      AddFile oNewProject, oFile, iLevel
    Next 'oFile
  End If
     
End Function



Function AddFile(oProject, oFile, iLevel)
   
  If Not (oFile.Name = "vssver.scc") Then
    oProject.Add oFile.Path, "added " & Date
    WriteLog "Adding File: " & oFile.Path, iLevel
  End If

End Function



Function CheckInFile(oItem, oFile, iLevel)

  If oItem.IsDifferent(oFile.Path) Then
  
    'If this file isn't checked out to someone else, then I'll check it out
    If oItem.IsCheckedOut = VSSFILE_NOTCHECKEDOUT Then
		' Force the checked out file to reside in the working folder's hierarchy. This means we don't
		' need to set the VSS working folder for the root project. Must specify "VSSFLAG_GETNO" to
		' avoid overwriting the modified file with the VSS copy.
		oItem.CheckOut "Checked out by Checkin for Schema Pull:" & Date, oFile.Path, VSSFLAG_GETNO
		'WriteLog "File Checked out: " & oItem.Name, iLevel
    End If
     
    'Now try to check it back in
    If oItem.IsCheckedOut = VSSFILE_CHECKEDOUT_ME Then
		'oItem.CheckIn "Change Detected :" & Date, oFile.Path, VSSFLAG_CMPFULL + VSSFLAG_UPDUNCH
		oItem.CheckIn "Change Detected :" & Date, oFile.Path, VSSFLAG_CMPFULL + VSSFLAG_UPDUNCH
		WriteLog "File Changed: " & oFile.Name, iLevel
    Else
		WriteLog "Checked out by another user: " & oFile.Name, iLevel
    End If
    
  End If
  
  'If bVerbose Then WriteLog "File Unchanged: " & oFile.Path, iLevel
    
End Function


Function OpenLog(oFolder)
  Dim iErrorNbr
   
  sLogName = oFolder.Path & "\CheckInLog.txt"

  If bVerbose Then WScript.Echo "OpenLog LogName: " & sLogName

  On Error Resume Next
   Set oLog = oFileSystem.GetFile(sLogName)
   
   'set the log file read only bit off
   'sourcesafe tries to keep this bit set on
   Select Case Err.Number
   
     Case 0 ' found
       On Error GoTo 0
       
       ' no make sure it's not read only
       If oLog.Attributes And 1 Then
         oLog.Attributes = oLog.Attributes Xor 1
       End If
     Case 53 ' file not found
       On Error GoTo 0
       oFileSystem.CreateTextFile sLogName, True
       Set oLog = oFileSystem.GetFile(sLogName)
     
     Case Else 'something bad happened - stop now
        iErrorNbr = Err.Number
        On Error GoTo 0
        Err.Raise iErrorNbr
    End Select

  'init the log file
  Set sLogFile = oLog.OpenAsTextStream(ForWriting, TristateUseDefault)
  sLogFile.Close
  
  bLogOpen = True
  WriteLog "Checkin Start: " & Now, 0 'iLevel always 0 here

End Function


Function WriteLog(sEntry, iLevel)

	Dim iRetry
	On Error Resume Next

	If (bLogOpen = True) Then
		Do
			If Err <> 0 Then 
				WScript.Sleep 2000
				iRetry = iRetry + 1
				If bVerbose Then WScript.Echo Space(5 * iLevel) & "Error writing to log file. Waiting 2 sec..."
			End If
			Set sLogFile = oLog.OpenAsTextStream(ForAppending, TristateUseDefault)
			sLogFile.Writeline Space(5 * iLevel) & sEntry
		Loop While Err <> 0 And iRetry <= 5
		If bVerbose Then WScript.Echo Space(5 * iLevel) & sEntry
		sLogFile.Close
	End If

	On Error Goto 0

End Function


Function CloseLog()
  Dim sTryItem, oTryItem
  Dim iErrorNbr
    
  WriteLog "Checkin Complete: " & Now, 0 ' iLevel always 0
  
  bLogOpen = False
  sTryItem = oRootProject.Spec + "/" + oLog.Name
  
  On Error Resume Next
  Set oTryItem = oDB.VSSItem(sTryItem, False) 'exclude deleted

  Select Case Err

    Case 0 ' found it so check it in
      CheckInFile oTryItem, oLog, 0 'iLevel always 0
      
    Case -2147166577 ' didn't find it
      AddFile oRootProject, oLog, 0 'iLevel

    Case Else 'something bad happened - but keep going
        WriteLog "Error (CloseLog): " & Err.Number & " " & Err.Description, 0
    End Select
    
  On Error GoTo 0
    
End Function
