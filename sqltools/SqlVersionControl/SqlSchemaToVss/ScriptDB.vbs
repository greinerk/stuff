'************************************************************************
'  Script a Sql Server
'  
'  Command-line Parameters
'    ServerName			- Name of SQL Server being checked in 
'    DatabaseRE			- Regular expression matched against database name (optional)
'    ObjectRE			- Regular expression matched against object names (optional)
'    WorkingFolderRoot	- local file system folder to store scripts
'    SqlAuthentication	- True to use SQL login, False to use a Windows login
'    SqlLogin			- SQL login name
'    SqlPassword		- SQL login password
'    ScriptLogins		- True to script logins (default), False to not. (Checking many logins into VSS is very slow.)
'    ScriptUsers		- True to script users (default), False to not. (Checking many users into VSS is very slow.)
'    ForceExt			- Force file extension (instead of .prc, .job, etc.)
'    ForceExt			- Force file extension (instead of .prc, .job, etc.)
'    Verbose			- True to enable verbose output
'
'  See 
'  \Program Files\Microsoft SQL Server\80\Tools\DevTools\Include\sqldmo.h
'  for interesting comments concerning usage of the enums that have been
'  explicitly declared as constants in this script. 
'
'  Script methods of Table and BackupDevice require additional parameter
'
'  Creator: Bill Wunder
'
' Modified: 01/08/2003 - Kevin Greiner - Added SQL login methods and command-line parameters
' Modified: 01/23/2003 - Kevin Greiner - Added ForceExt command-line parameter
' Modified: 07/24/2009 - Kevin Greiner - Added Database Name filter
' Modified: 07/28/2009 - Kevin Greiner - Added regexp matching on object names
'************************************************************************

Option Explicit

' Global vars
Dim oSQLServer, oDatabase
Dim strDatabaseRE, strObjectRE
Dim oFileSystem, oFile, sFileName
Dim sWorkingFolderRoot, sWorkingFolder
Dim iScriptType, iScript2Type
Dim sTextStream
Dim strForceExt				' Force file extension
Dim bVerbose

'Constants
Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8

Const TristateUseDefault = -2
Const TristateTrue = -1
Const TristateFalse = 0

'enum SQLDMO.SQLDMO_SCRIPT_TYPE
Const SQLDMOScript_UseQuotedIdentifiers = -1
Const SQLDMOScript_None = 0
Const SQLDMOScript_Drops = 1
Const SQLDMOScript_ObjectPermissions = 2
Const SQLDMOScript_Default = 4
Const SQLDMOScript_PrimaryObject = 4
Const SQLDMOScript_ClusteredIndexes = 8
Const SQLDMOScript_Triggers = 16
Const SQLDMOScript_DatabasePermissions = 32
Const SQLDMOScript_Permissions = 34
Const SQLDMOScript_ToFileOnly = 64
Const SQLDMOScript_Bindings = 128
Const SQLDMOScript_AppendToFile = 256
Const SQLDMOScript_NoDRI = 512
Const SQLDMOScript_UDDTsToBaseType = 1024
Const SQLDMOScript_IncludeIfNotExists = 4096
Const SQLDMOScript_NonClusteredIndexes = 8192
Const SQLDMOScript_Aliases = 16384
Const SQLDMOScript_NoCommandTerm = 32768
Const SQLDMOScript_DRIIndexes = 65536
Const SQLDMOScript_Indexes = 73736
Const SQLDMOScript_IncludeHeaders = 131072
Const SQLDMOScript_OwnerQualify = 262144
Const SQLDMOScript_TransferDefault = 422143
Const SQLDMOScript_TimestampToBinary = 524288
Const SQLDMOScript_SortedData = 1048576
Const SQLDMOScript_SortedDataReorg = 2097152
Const SQLDMOScript_DRI_NonClustered = 4194304
Const SQLDMOScript_DRI_Clustered = 8388608
Const SQLDMOScript_DRI_Checks = 16777216
Const SQLDMOScript_DRI_Defaults = 33554432
Const SQLDMOScript_DRI_UniqueKeys = 67108864
Const SQLDMOScript_DRI_ForeignKeys = 134217728
Const SQLDMOScript_DRI_PrimaryKey = 268435456
Const SQLDMOScript_DRI_AllKeys = 469762048
Const SQLDMOScript_DRI_AllConstraints = 520093696
Const SQLDMOScript_DRIWithNoCheck = 536870912
Const SQLDMOScript_DRI_All = 532676608
Const SQLDMOScript_NoIdentity = 1073741824

'enum SQLDMO.SQLDMO_SCRIPT2_TYPE
Const SQLDMOScript2_Default = 0
Const SQLDMOScript2_AnsiPadding = 1
Const SQLDMOScript2_AnsiFile = 2
Const SQLDMOScript2_UnicodeFile = 4
Const SQLDMOScript2_NonStop = 8
Const SQLDMOScript2_NoFG = 16
Const SQLDMOScript2_MarkTriggers = 32
Const SQLDMOScript2_OnlyUserTriggers = 64
Const SQLDMOScript2_EncryptPWD = 128
Const SQLDMOScript2_SeparateXPs = 256
Const SQLDMOScript2_NoWhatIfIndexes = 512
Const SQLDMOScript2_AgentNotify = 1024
Const SQLDMOScript2_AgentAlertJob = 2048
Const SQLDMOScript2_FullTextIndex = 524288
Const SQLDMOScript2_LoginSID = 1048576 'BOL is wrong, says 8192
Const SQLDMOScript2_FullTextCat = 2097152
Const SQLDMOScript2_ExtendedProperty = 4194304
Const SQLDMOScript2_NoCollation = 8388608
Const SQLDMOScript2_JobDisable = 33554432
Const SQLDMOScript2_ExtendedOnly = 67108864
Const SQLDMOScript2_70Only = 16777216
Const SQLDMOScript2_DontScriptJobServer = 134217728

'enum SQLDMO.SQLDMO_PRIVILEGE_TYPE
Const SQLDMOPriv_Unknown = 0
Const SQLDMOPriv_Select = 1
Const SQLDMOPriv_Insert = 2
Const SQLDMOPriv_Update = 4
Const SQLDMOPriv_Delete = 8
Const SQLDMOPriv_Execute = 16
Const SQLDMOPriv_References = 32
Const SQLDMOPriv_AllObjectPrivs = 63 'Default
Const SQLDMOPriv_CreateTable = 128
Const SQLDMOPriv_CreateDatabase = 256
Const SQLDMOPriv_CreateView = 512
Const SQLDMOPriv_CreateProcedure = 1024
Const SQLDMOPriv_DumpDatabase = 2048
Const SQLDMOPriv_CreateDefault = 4096
Const SQLDMOPriv_DumpTransaction = 8192
Const SQLDMOPriv_CreateRule = 16384
Const SQLDMOPriv_DumpTable = 32768
Const SQLDMOPriv_CreateFunction = 65366
Const SQLDMOPriv_AllDatabasePrivs = 130944 'Default

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
	"Script: ScriptDB.vbs" + vbCRLF + _
	"" + vbCRLF + _
	"Purpose: retrieve SQL schema from a SQL Server and write it out to a directory structure." + vbCRLF + _
	"" + vbCRLF + _
	"Commandline Arguments: (/arg:value)" + vbCRLF + _
	"  /SqlServerName     - name of SQL Server to process" + vbCRLF + _
	"  /DatabaseRE        - regular expression matched again database name (optional)" + vbCRLF + _
	"  /ObjectRE          - regular expression matched against object names (optional)" + vbCRLF + _
	"                           http://msdn.microsoft.com/en-us/library/ms974570.aspx" + vbCRLF + _
	"  /SqlAuthentication - True = SQL login, False = Windows login" + vbCRLF + _
	"  /SqlLogin          - SQL login username (used only if SqlAuthentication = True" + vbCRLF + _
	"  /SqlPassword       - SQL login password (used only if SqlAuthentication = True" + vbCRLF + _
	"  /WorkingFolderRoot - folder where SQL schema structure will begin" + vbCRLF + _
	"  /ForceExt          - Force file extension (instead of .prc, .job, etc.)" + vbCRLF + _
	"  /ScriptLogins      - True = script logins (default), False = don't (many logins are slow to checkin to VSS)" + vbCRLF + _
	"  /ScriptUsers       - True = script users (default), False = don't (many logins are slow to checkin to VSS)" + vbCRLF + _
	"  /Verbose           - folder where SQL schema structure will begin" + vbCRLF + _
	"  /Verbose           - folder where SQL schema structure will begin" + vbCRLF + _
	" " + vbCRLF + _
	" The Regular Expressions examples:" + vbCRLF + _
	"    objects starting with b        ""^b.*""" + vbCRLF + _
	"    objects not starting with b    ""^((?!^b).)*$""" + vbCRLF + _
	"    objects not containing 'test'  ""^((?!.*test).)*$"""
End Sub

Function Process()
	Dim strSqlServerName		' Name of SQL Server being checked in 
	Dim bolSqlAuthentication	' Use SQL login?
	Dim strSqlLogin				' SQL login name
	Dim strSqlPassword			' SQL login password
	Dim bScriptLogins			' Script database logins?
	Dim bScriptUsers			' Script database users?

	' Read arguements from the command line
	strSqlServerName	= trim(WScript.Arguments.Named.Item("SqlServerName"))
	sWorkingFolderRoot	= trim(WScript.Arguments.Named.Item("WorkingFolderRoot"))
	strSqlLogin			= trim(WScript.Arguments.Named.Item("SqlLogin"))
	strSqlPassword		= trim(WScript.Arguments.Named.Item("SqlPassword"))
	strForceExt			= trim(WScript.Arguments.Named.Item("ForceExt"))

	strDatabaseRE = trim(WScript.Arguments.Named.Item("DatabaseRE"))
	If strDatabaseRE <> "" Then WScript.Echo "Filtering by DatabaseName RegExp: " & strDatabaseRE
	'WScript.Echo "Filtering by DatabaseName RegExp: " & strDatabaseRE

	strObjectRE = trim(WScript.Arguments.Named.Item("ObjectRE"))
	If strObjectRE <> "" Then WScript.Echo "Filtering by Object RegExp: " & strObjectRE
	'WScript.Echo "Filtering by Object RegExp: " & strObjectRE

	' check if user wants SQL or Windows authentication
	If ucase(trim(WScript.Arguments.Named.Item("SqlAuthentication"))) = "TRUE" Then
		bolSqlAuthentication = True
	Else
		bolSqlAuthentication = False
	End If

	' check if user wants to script database logins? (default to True)
	If ucase(trim(WScript.Arguments.Named.Item("ScriptLogins"))) = "FALSE" Then
		bScriptLogins = False
	Else
		bScriptLogins = True
	End If

	' check if user wants to script database users? (default to True)
	If ucase(trim(WScript.Arguments.Named.Item("ScriptUsers"))) = "FALSE" Then
		bScriptUsers = False
	Else
		bScriptUsers = True
	End If

	' check for verbose output
	If ucase(trim(WScript.Arguments.Named.Item("Verbose"))) = "TRUE" Then
		bVerbose = True
	Else
		bVerbose = False
	End If

	' need a file system instance and a DMO instance
	Set oFileSystem = CreateObject("Scripting.FileSystemObject")
	Set oSQLServer = CreateObject("SQLDMO.SQLServer")

	' Use SQL or Windows authentication
	If bolSQLAuthentication Then
		oSQLServer.LoginSecure = False ' use SQL authentication
	Else
		oSQLServer.LoginSecure = True 'trusted
	End If

	If oSQLServer.LoginSecure Then
		oSQLServer.Connect strSqlServerName
	Else
		oSQLServer.Connect strSqlServerName, strSqlLogin, strSqlPassword
	End If

	' verify the path and make sure empty subfolders for the server exists
	SetWorkingFolders strDatabaseRE

	On Error Resume Next

	ScriptAlerts
	ScriptBackupDevices
	ScriptJobs
	If bScriptLogins Then ScriptLogins
	ScriptOperators

	For Each oDatabase In oSQLServer.Databases
		' When it's supplied, filter by Database name
		If strDatabaseRE = "" OR (strDatabaseRE <> "" AND TestRE(strDatabaseRE,oDatabase.Name)) Then
			If Not oDatabase.SystemObject Then
				ScriptDB
				ScriptDataTypes
				ScriptDefaults
				ScriptFunctions
				ScriptProcedures
				ScriptRoles
				ScriptRules
				ScriptTables
				ScriptTriggers
				If bScriptUsers Then ScriptUsers
				ScriptViews
			End If
		End If
	Next 

	On Error Goto 0

	oSQLServer.DisConnect
	Set oSQLServer = Nothing

	Set oFileSystem = Nothing

	'Main = DTSTaskExecResult_Success
End Function


Function SetWorkingFolders(strDatabaseRE)
	Dim sDBFolder
	Dim oDatabase
	Dim sServerName

	If bVerbose Then WScript.Echo "Creating folders"

	If Right(sWorkingFolderRoot, 1) <> "\" Then
		sWorkingFolderRoot = sWorkingFolderRoot & "\"
	End If
	If oFileSystem.DriveExists(oFileSystem.GetDriveName(sWorkingFolderRoot)) Then
		If Not oFileSystem.FolderExists(sWorkingFolderRoot) Then
			sWorkingFolderRoot = oFileSystem.CreateFolder(sWorkingFolderRoot) & "\"
		End If
		If oFileSystem.FolderExists(sWorkingFolderRoot) Then
			If Len(oSQLServer.Name) < 2 Then
				' assume no param provided and script local default instance
				sWorkingFolderRoot = sWorkingFolderRoot & oSQLServer.NetName
			Else
				' use ~ instead of \ for named instance
				sWorkingFolderRoot = sWorkingFolderRoot & Replace(oSQLServer.Name, "\", "~")
			End If
			If oFileSystem.FolderExists(sWorkingFolderRoot) Then
				If bVerbose Then WScript.Echo "Deleting Folder: " & sWorkingFolderRoot
				' If VSS is open, the delete command will fail with "Permission denied."
				On Error Resume Next 
				Dim iLoop
				iLoop = 0
				Do 
					oFileSystem.DeleteFolder sWorkingFolderRoot, True 'even if read only
					If Err.Number > 0 Then
						WScript.Echo "Error deleting WorkingFolderRoot: " & sWorkingFolderRoot
						WScript.Echo "    Error # " & CStr(Err.Number) & ": " & Err.Description
					End If
				Loop While iLoop <= 5 And Err.Number > 0  
				On Error GoTo 0
			End If

			' If the folder could be deleted, recreate it.
			If Not oFileSystem.FolderExists(sWorkingFolderRoot) Then
				sWorkingFolderRoot = oFileSystem.CreateFolder(sWorkingFolderRoot) & "\"
			End If

			oFileSystem.CreateFolder (sWorkingFolderRoot & "\AgentAlerts")
			oFileSystem.CreateFolder (sWorkingFolderRoot & "\AgentOperators")
			oFileSystem.CreateFolder (sWorkingFolderRoot & "\BackupDevices")
			oFileSystem.CreateFolder (sWorkingFolderRoot & "\Jobs")
			oFileSystem.CreateFolder (sWorkingFolderRoot & "\Logins")

			For Each oDatabase In oSQLServer.Databases
				If strDatabaseRE = "" OR (strDatabaseRE <> "" AND TestRE(strDatabaseRE,oDatabase.Name)) Then
					' MSDN doc on VBScript RegExp http://msdn.microsoft.com/en-us/library/ms974570.aspx
					If Not oDatabase.SystemObject Then
						sDBFolder = oFileSystem.CreateFolder(sWorkingFolderRoot & "\" _
						& oDatabase.Name) & "\"
						oFileSystem.CreateFolder (sDBFolder & "\DataTypes")
						oFileSystem.CreateFolder (sDBFolder & "\Defaults")
						oFileSystem.CreateFolder (sDBFolder & "\Functions")
						oFileSystem.CreateFolder (sDBFolder & "\Procedures")
						oFileSystem.CreateFolder (sDBFolder & "\Roles")
						oFileSystem.CreateFolder (sDBFolder & "\Rules")
						oFileSystem.CreateFolder (sDBFolder & "\Tables")
						oFileSystem.CreateFolder (sDBFolder & "\Triggers")
						oFileSystem.CreateFolder (sDBFolder & "\Users")
						oFileSystem.CreateFolder (sDBFolder & "\Views")
					End If
				End If
			Next 

		End If
	End If

End Function


Function TestRE(Pattern, Test)
	Dim RE
	Set RE = CreateObject("VBScript.RegExp")
	RE.Pattern = Pattern
	RE.IgnoreCase = true ' Windows users don't expect case sensitivity
	TestRE = RE.Test(Test)
	'If bVerbose Then WScript.Echo "Matching '" & Pattern & "' to string '" & Test & "' result = " & RE.Test(Test)
End Function


Function ScriptDB()

	If bVerbose Then WScript.Echo oDatabase.Name & " database"

	iScriptType = SQLDMOScript_Default
	iScript2Type = SQLDMOScript2_Default
	sFileName = sWorkingFolderRoot & oDatabase.Name & "\CreateDB_" _
	& oDatabase.Name & GetFileExt(".DB")

	oFileSystem.CreateTextFile sFileName, True
	Set oFile = oFileSystem.GetFile(sFileName)
	Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
	sTextStream.Write oDatabase.Script(iScriptType, , iScript2Type)
	sTextStream.Close

End Function


Function ScriptDataTypes()

	Dim oUserDefinedDataType, iCount


	iCount = 0
	iScriptType = SQLDMOScript_Drops _
	Or SQLDMOScript_ObjectPermissions _
	Or SQLDMOScript_Default _
	Or SQLDMOScript_Bindings
	iScript2Type = SQLDMOScript2_Default
	sWorkingFolder = sWorkingFolderRoot & oDatabase.Name & "\DataTypes\"

	For Each oUserDefinedDataType In oDatabase.UserDefinedDatatypes
		If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oUserDefinedDataType.Name)) Then
			sFileName = sWorkingFolder & oUserDefinedDataType.Name & GetFileExt(".UDT")
			oFileSystem.CreateTextFile sFileName, True
			Set oFile = oFileSystem.GetFile(sFileName)
			Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
			sTextStream.Write "use " & oDatabase.Name
			sTextStream.WriteBlankLines (1)
			sTextStream.Write "GO"
			sTextStream.WriteBlankLines (1)
			sTextStream.Write oUserDefinedDataType.Script(iScriptType, , iScript2Type)
			sTextStream.Close
			iCount = iCount + 1
		End If
	Next 

	If bVerbose Then WScript.Echo oDatabase.Name & " scripted " & iCount & " DataTypes"

End Function


Function ScriptDefaults()

	Dim oDefault, iCount

	iCount = 0
	iScriptType = SQLDMOScript_Drops _
	Or SQLDMOScript_ObjectPermissions _
	Or SQLDMOScript_Default _
	Or SQLDMOScript_Bindings
	iScript2Type = SQLDMOScript2_Default
	sWorkingFolder = sWorkingFolderRoot & oDatabase.Name & "\Defaults\"

	For Each oDefault In oDatabase.Defaults
		If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oDefault.Name)) Then
			sFileName = sWorkingFolder & oDefault.Name & GetFileExt(".DFT")
			oFileSystem.CreateTextFile sFileName, True
			Set oFile = oFileSystem.GetFile(sFileName)
			Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
			sTextStream.Write "use " & oDatabase.Name
			sTextStream.WriteBlankLines (1)
			sTextStream.Write "GO"
			sTextStream.WriteBlankLines (1)
			sTextStream.Write oDefault.Script(iScriptType, , iScript2Type)
			sTextStream.Close
			iCount = iCount + 1
		End If
	Next 

	If bVerbose Then WScript.Echo oDatabase.Name & " scripted " & iCount & " Defaults"

End Function


Function ScriptFunctions()

	Dim oUserDefinedFunction, iCount

	iCount = 0
	iScriptType = SQLDMOScript_Drops _
	Or SQLDMOScript_ObjectPermissions _
	Or SQLDMOScript_OwnerQualify _
	Or SQLDMOScript_Default
	iScript2Type = SQLDMOScript2_Default
	sWorkingFolder = sWorkingFolderRoot & oDatabase.Name & "\Functions\"

	For Each oUserDefinedFunction In oDatabase.UserDefinedFunctions
		If Not oUserDefinedFunction.SystemObject Then
			If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oUserDefinedFunction.Name)) Then
				sFileName = sWorkingFolder & oUserDefinedFunction.Owner & "." _
				& oUserDefinedFunction.Name & GetFileExt(".UDF")
				oFileSystem.CreateTextFile sFileName, True
				Set oFile = oFileSystem.GetFile(sFileName)
				Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
				sTextStream.Write "use " & oDatabase.Name
				sTextStream.WriteBlankLines (1)
				sTextStream.Write "GO"
				sTextStream.WriteBlankLines (1)
				sTextStream.Write oUserDefinedFunction.Script(iScriptType, , iScript2Type)
				sTextStream.Close
				iCount = iCount + 1
			End If
		End If
	Next 

	If bVerbose Then WScript.Echo oDatabase.Name & " scripted " & iCount & " functions"

End Function


Function ScriptProcedures()

	Dim oStoredProcedure, iCount

	iCount = 0
	iScriptType = SQLDMOScript_Drops _
	Or SQLDMOScript_ObjectPermissions _
	Or SQLDMOScript_OwnerQualify _
	Or SQLDMOScript_Default
	iScript2Type = SQLDMOScript2_Default
	sWorkingFolder = sWorkingFolderRoot & oDatabase.Name & "\Procedures\"

	For Each oStoredProcedure In oDatabase.StoredProcedures
		If Not oStoredProcedure.SystemObject Then
			If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oStoredProcedure.Name)) Then
				'if procedure owner is a domain user the create file will (should)
				'blow up with an invalid path message
				sFileName = sWorkingFolder & Replace(oStoredProcedure.Owner, "\", "~") & "." _
				& oStoredProcedure.Name & GetFileExt(".PRC")
				oFileSystem.CreateTextFile sFileName, True
				Set oFile = oFileSystem.GetFile(sFileName)
				Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
				sTextStream.Write "use " & oDatabase.Name
				sTextStream.WriteBlankLines (1)
				sTextStream.Write "GO"
				sTextStream.WriteBlankLines (1)
				sTextStream.Write oStoredProcedure.Script(iScriptType, , iScript2Type)
				sTextStream.Close
				iCount = iCount + 1
			End If
		End If
	Next

	If bVerbose Then WScript.Echo oDatabase.Name & " scripted " & iCount & " procedures"

End Function


Function ScriptRoles()

	Dim oRole
	Dim oMembersQueryResult, iRow, iCount
	Dim oDBPermissionsSQLObjectList, oObjectPermissionsSQLObjectList, oPermission
	Dim DoIt

	iCount = 0
	iScriptType = SQLDMOScript_Drops _
	Or SQLDMOScript_Default
	iScript2Type = SQLDMOScript2_Default
	sWorkingFolder = sWorkingFolderRoot & oDatabase.Name & "\Roles\"

	For Each oRole In oDatabase.DatabaseRoles
		If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oRole.Name)) Then
			Set oMembersQueryResult = oRole.EnumDatabaseRoleMember()
			If oMembersQueryResult.Rows > 0 And Not (oRole.Name = "public") Then
				DoIt = 1
			End If

			If Not (oRole.IsFixedRole()) Then
				Set oDBPermissionsSQLObjectList = oRole.ListDatabasePermissions(SQLDMOPriv_AllDatabasePrivs)
				If oDBPermissionsSQLObjectList.Count > 0 Then
					DoIt = 1
				End If
				Set oObjectPermissionsSQLObjectList = oRole.ListObjectPermissions(SQLDMOPriv_AllObjectPrivs)
				If oObjectPermissionsSQLObjectList.Count > 0 Then
					DoIt = 1
				End If
			End If

			If DoIt = 1 Then

				iCount = iCount + 1
				sFileName = sWorkingFolder & oRole.Name & GetFileExt(".ROL")
				oFileSystem.CreateTextFile sFileName, True
				Set oFile = oFileSystem.GetFile(sFileName)
				Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
				sTextStream.Writeline "-- Role: " & oRole.Name
				sTextStream.Writeline "use " & oDatabase.Name
				sTextStream.WriteBlankLines (1)
				sTextStream.Write "GO"
				sTextStream.WriteBlankLines (1)

				If Not (oRole.IsFixedRole()) Then
					sTextStream.Write oRole.Script(iScriptType, , iScript2Type)
				End If

				' because everybody is in public
				If Not (oRole.Name = "public") Then 
					For iRow = 1 To oMembersQueryResult.Rows
						sTextStream.Writeline "exec sp_addrolemember [" & oRole.Name & "], [" _
						& oMembersQueryResult.GetColumnString(iRow, 1) & "]"
						sTextStream.WriteBlankLines (1)
						sTextStream.Writeline "GO"
						sTextStream.WriteBlankLines (1)
					Next
				End If

				If Not (oRole.IsFixedRole()) Then
					For Each oPermission In oDBPermissionsSQLObjectList
						sTextStream.Writeline "grant [" & oPermission.PrivilegeTypeName & "] to [" _
						& oPermission.Grantee & "]"
						sTextStream.WriteBlankLines (1)
					Next 

					For Each oPermission In oObjectPermissionsSQLObjectList
						sTextStream.Writeline "grant [" & oPermission.PrivilegeTypeName & "] on [" _
						& oPermission.ObjectOwner & "].[" _
						& oPermission.ObjectName & "] to [" _
						& oPermission.Grantee & "]"
						sTextStream.WriteBlankLines (1)
					Next 
				End If
				sTextStream.Close
				DoIt = 0
			End If
		End If

	Next 

	If bVerbose Then WScript.Echo oDatabase.Name & " scripted " & iCount & " Roles"

End Function


Function ScriptRules()

	Dim oRule, iCount

	iCount = 0
	iScriptType = SQLDMOScript_Drops _
	Or SQLDMOScript_ObjectPermissions _
	Or SQLDMOScript_Default _
	Or SQLDMOScript_Bindings
	iScript2Type = SQLDMOScript2_Default
	sWorkingFolder = sWorkingFolderRoot & oDatabase.Name & "\Rules\"

	For Each oRule In oDatabase.Defaults
		If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oRule.Name)) Then
			sFileName = sWorkingFolder & oRule.Name & GetFileExt(".RUL")
			oFileSystem.CreateTextFile sFileName, True
			Set oFile = oFileSystem.GetFile(sFileName)
			Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
			sTextStream.Write "use " & oDatabase.Name
			sTextStream.WriteBlankLines (1)
			sTextStream.Write "GO"
			sTextStream.WriteBlankLines (1)
			sTextStream.Write oRule.Script(iScriptType, , iScript2Type)
			sTextStream.Close
			iCount = iCount + 1
		End If
	Next 

	If bVerbose Then WScript.Echo oDatabase.Name & " scripted " & iCount & " Rules"

End Function


Function ScriptTables()

	Dim oTable, iCount

	iCount = 0
	' never script drop table
	iScriptType = SQLDMOScript_ObjectPermissions _
	Or SQLDMOScript_OwnerQualify _
	Or SQLDMOScript_Default _
	Or SQLDMOScript_Indexes _
	Or SQLDMOScript_DRI_All
	iScript2Type = SQLDMOScript2_NoWhatIfIndexes
	sWorkingFolder = sWorkingFolderRoot & oDatabase.Name & "\Tables\"

	For Each oTable In oDatabase.Tables
		If Not oTable.SystemObject Then
			If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oTable.Name)) Then
				sFileName = sWorkingFolder & oTable.Owner & "." & oTable.Name & GetFileExt(".TAB")
				oFileSystem.CreateTextFile sFileName, True
				Set oFile = oFileSystem.GetFile(sFileName)
				Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
				sTextStream.Write "use " & oDatabase.Name
				sTextStream.WriteBlankLines (1)
				sTextStream.Write "GO"
				sTextStream.WriteBlankLines (1)
				sTextStream.Write oTable.Script(iScriptType, , , iScript2Type)
				sTextStream.Close
				iCount = iCount + 1
			End If
		End If
	Next 

	If bVerbose Then WScript.Echo oDatabase.Name & " scripted " & iCount & " tables"

End Function


Function ScriptTriggers()

	Dim oTable, oTrigger, iCount

	iCount = 0
	' if you put the var in the createfolder you lose the trailing whack
	sWorkingFolder = sWorkingFolderRoot & oDatabase.Name & "\Triggers\"

	For Each oTable In oDatabase.Tables
		For Each oTrigger In oTable.Triggers
			If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oTrigger.Name)) Then
				If Not oTable.SystemObject Then
					iScriptType = SQLDMOScript_Drops _
					Or SQLDMOScript_OwnerQualify _
					Or SQLDMOScript_Default
					iScript2Type = SQLDMOScript2_Default
					sFileName = sWorkingFolder & oTrigger.Owner & "." & oTrigger.Name & GetFileExt(".TRG")

					oFileSystem.CreateTextFile sFileName, True
					Set oFile = oFileSystem.GetFile(sFileName)
					Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
					sTextStream.Write "use " & oDatabase.Name
					sTextStream.WriteBlankLines (1)
					sTextStream.Write "GO"
					sTextStream.WriteBlankLines (1)
					sTextStream.Write oTrigger.Script(iScriptType, , iScript2Type)
					sTextStream.Close
					iCount = iCount + 1
				End If
			End If
		Next 
	Next 

	If bVerbose Then WScript.Echo oDatabase.Name & " scripted " & iCount & " triggers"

End Function


Function ScriptUsers()

	Dim oUser, iCount

	iScriptType = SQLDMOScript_Drops _
	Or SQLDMOScript_Permissions _
	Or SQLDMOScript_Default
	iScript2Type = SQLDMOScript2_Default _
	Or SQLDMOScript2_LoginSID
	sWorkingFolder = sWorkingFolderRoot & oDatabase.Name & "\Users\"

	For Each oUser In oDatabase.Users
		If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oUser.Name)) Then
			sFileName = sWorkingFolder & GoodFileName(oUser.Name) & GetFileExt(".USR")
			oFileSystem.CreateTextFile sFileName, True
			Set oFile = oFileSystem.GetFile(sFileName)
			Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
			sTextStream.Write "use " & oDatabase.Name
			sTextStream.WriteBlankLines (1)
			sTextStream.Write "GO"
			sTextStream.WriteBlankLines (1)
			If oUser.Login <> "" Then
				sTextStream.WriteBlankLines (2)
				' never drop sa	
				If oUser.Login <> "sa" Then 
				sTextStream.Write oSQLServer.Logins(oUser.Login).Script(iScriptType, , iScript2Type)
			Else
				sTextStream.Write oSQLServer.Logins(oUser.Login).Script(SQLDMOScript_Default, , iScript2Type)
			End If
		End If
		sTextStream.WriteBlankLines (2)
		' never drop sa
		If oUser.Name <> "dbo" Then
			sTextStream.Write oUser.Script(iScriptType, , iScript2Type)
		Else
			sTextStream.Write oUser.Script(SQLDMOScript_Permissions Or SQLDMOScript_Default, , iScript2Type)
		End If
		sTextStream.Close
		iCount = iCount + 1
	End If
Next 

If bVerbose Then WScript.Echo oDatabase.Name & " scripted " & iCount & " Users"

End Function


Function ScriptViews()

	Dim oView, iCount

	iCount = 0
	iScriptType = SQLDMOScript_Drops _
	Or SQLDMOScript_ObjectPermissions _
	Or SQLDMOScript_OwnerQualify _
	Or SQLDMOScript_Default
	iScript2Type = SQLDMOScript2_Default
	sWorkingFolder = sWorkingFolderRoot & oDatabase.Name & "\Views\"

	For Each oView In oDatabase.Views
		If Not oView.SystemObject Then
			If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oView.Name)) Then
				sFileName = sWorkingFolder & oView.Owner & "." & oView.Name & GetFileExt(".PRC")
				oFileSystem.CreateTextFile sFileName, True
				Set oFile = oFileSystem.GetFile(sFileName)
				Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
				sTextStream.Write "use " & oDatabase.Name
				sTextStream.WriteBlankLines (1)
				sTextStream.Write "GO"
				sTextStream.WriteBlankLines (1)
				sTextStream.Write oView.Script(iScriptType, , iScript2Type)
				sTextStream.Close
				iCount = iCount + 1
			End If
		End If
	Next 

	If bVerbose Then WScript.Echo oDatabase.Name & " scripted " & iCount & " views"

End Function


Function ScriptAlerts()

	Dim oAlert

	If bVerbose Then WScript.Echo "Scripting alerts"

	iScriptType = SQLDMOScript_Default
	iScript2Type = SQLDMOScript2_Default

	For Each oAlert In oSQLServer.JobServer.Alerts
		If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oAlert.Name)) Then
			sFileName = sWorkingFolderRoot & "\AgentAlerts\" & GoodFileName(oAlert.Name) & GetFileExt(".ALR")
			oFileSystem.CreateTextFile sFileName, True
			Set oFile = oFileSystem.GetFile(sFileName)
			Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
			sTextStream.Write oAlert.Script(iScriptType, , iScript2Type)
			sTextStream.Close
		End If
	Next 

End Function


Function ScriptBackupDevices()

	Dim oBackupDevice

	If bVerbose Then WScript.Echo "Scripting backup devices"

	iScriptType = SQLDMOScript_Default
	iScript2Type = SQLDMOScript2_Default

	For Each oBackupDevice In oSQLServer.BackupDevices
		If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oBackupDevice.Name)) Then
			sFileName = sWorkingFolderRoot & "\BackupDevices\" & GoodFileName(oBackupDevice.Name) & GetFileExt(".BDV")
			oFileSystem.CreateTextFile sFileName, True
			Set oFile = oFileSystem.GetFile(sFileName)
			Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
			sTextStream.Write oBackupDevice.Script(iScriptType, , , iScript2Type)
			sTextStream.Close
		End If
	Next 

End Function


Function ScriptJobs()

	Dim oJob

	If bVerbose Then WScript.Echo "Scripting jobs"

	iScriptType = SQLDMOScript_Drops _
	Or SQLDMOScript_Default _
	Or SQLDMOScript_IncludeIfNotExists _
	Or SQLDMOScript_OwnerQualify
	iScript2Type = SQLDMOScript2_AgentNotify _
	Or SQLDMOScript2_AgentAlertJob

	For Each oJob In oSQLServer.JobServer.Jobs
		If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oJob.Name)) Then
			sFileName = sWorkingFolderRoot & "\Jobs\" & GoodFileName(oJob.Name) & GetFileExt(".JOB")
			oFileSystem.CreateTextFile sFileName, True
			Set oFile = oFileSystem.GetFile(sFileName)
			Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
			sTextStream.Write oJob.Script(iScriptType, , iScript2Type)
			sTextStream.Close
		End If
	Next 

End Function


Function ScriptLogins()

	Dim oLogin

	If bVerbose Then WScript.Echo "Scripting logins"

	iScriptType = SQLDMOScript_Drops _
	Or SQLDMOScript_Default _
	Or SQLDMOScript_IncludeIfNotExists
	iScript2Type = SQLDMOScript2_LoginSID _
	Or SQLDMOScript2_Default

	For Each oLogin In oSQLServer.Logins
		If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oLogin.Name)) Then
			sFileName = sWorkingFolderRoot & "\Logins\" & GoodFileName(oLogin.Name) & GetFileExt(".LGN")
			oFileSystem.CreateTextFile sFileName, True
			Set oFile = oFileSystem.GetFile(sFileName)
			Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
			sTextStream.Write oLogin.Script(iScriptType, , iScript2Type)
			sTextStream.Close
		End If
	Next 

End Function


Function ScriptOperators()

	Dim oOperator

	If bVerbose Then WScript.Echo "Scripting operators"

	iScriptType = SQLDMOScript_Default
	iScript2Type = SQLDMOScript2_Default

	For Each oOperator In oSQLServer.JobServer.Operators
		If strObjectRE = "" OR (strObjectRE <> "" AND TestRE(strObjectRE,oOperator.Name)) Then
			sFileName = sWorkingFolderRoot & "\AgentOperators\" & GoodFileName(oOperator.Name) & GetFileExt(".OPR")
			oFileSystem.CreateTextFile sFileName, True
			Set oFile = oFileSystem.GetFile(sFileName)
			Set sTextStream = oFile.OpenAsTextStream(ForWriting, TristateUseDefault)
			sTextStream.Write oOperator.Script(iScriptType, , iScript2Type)
			sTextStream.Close
		End If
	Next 

End Function


Function GoodFileName(sObjectName)

	sObjectName = Replace(sObjectName, "\", "~")
	sObjectName = Replace(sObjectName, "/", "~")
	sObjectName = Replace(sObjectName, ":", "~")
	sObjectName = Replace(sObjectName, "*", "~")
	sObjectName = Replace(sObjectName, "?", "~")
	sObjectName = Replace(sObjectName, """", "~")
	sObjectName = Replace(sObjectName, "<", "~")
	sObjectName = Replace(sObjectName, ">", "~")
	sObjectName = Replace(sObjectName, "|", "~")
	sObjectName = Replace(sObjectName, "$", "~")

	GoodFileName = sObjectName

End Function

Function GetFileExt(sUniqueExt)
	' If user specifies a file extension, use it all the time.

	If strForceExt = "" Then
		GetFileExt = sUniqueExt
	Else
		GetFileExt = strForceExt
	End If

End Function
