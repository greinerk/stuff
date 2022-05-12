Option Explicit 
'constants
 
Const adOpenStatic = 3
Const ForReading = 1
Const adLockReadOnly = 1
Const adCmdStoredProc = 4
Const adVarChar = 200 
Const adParamInput = 1
Const SQLDMOScript2_ExtendedProperty = 4194304
Const SQLDMOScript2_Default = 0
Const SQLDMOScript_Default = 4
Const SQLDMOScript_Drops = 1
Const SQLDMOScript_ObjectPermissions = 2
Const SQLDMOScript_Indexes = 73736 
Const SQLDMOScript_DRI_All = 532676608 
Const SQLDMOScript_Triggers = 16
Const VSSFLAG_BINTEXT = 3145728 
Const ForAppending = 8
Const ForWriting = 2
 
CONST VSSPath = "c:\Program Files\Microsoft Visual Studio\common\vss\srcsafe.ini"
CONST VSSRoot="$/SQLCode" ' note if you are going to use the root of your Source Safe Database use $, not $/
CONST VSSAdminAccount = "admin"
CONST VSSAdminAccountPassword = ""
CONST FileRepositoryPath = "C:\VisualSS\SQLCode"
 
'variables
Dim path, ProjectPath, versionNumber, ConnectionString, VSSDate, VSSComment
Dim VSSLabelComment, VSSUserName, VSSVersionNumber, ServerName, RecordCount, objTS, DatabaseName
Dim MyArray, arraymember, totalpath, objSQLServer, objFso, objVSS, database, SQLServerVersion, NormalizedSQLServerName
Dim VSSItem, Item, flag, StoredProcedure, VSSProjectPath, objCommand, objConnection, objRecordSet, ConnectionString1, strSelect
Dim ErrorNumber, ErrorDescription, version, LogFileName, LogFile, objFile, DifferenceLogFileName, DifferenceLogFile, Table, ObjectType, View
dim UserDefinedFunction
 
'On Error Resume Next
 
'object creation
Set objSQLServer = CreateObject("SQLDMO.SQLServer")
Set objFso = CreateObject("Scripting.FileSystemObject")
set objVSS = CreateObject("SourceSafe")
 
'retreiving the Server Name 
ServerName = wscript.arguments(0)
 
'fixing SQL Server Instance Names - our project path in VSS and the file system replaces the instance name with an underscore
NormalizedSQLServerName = replace(ServerName,"\","_")
 
wscript.echo "NormalizedSQLServerName: " +  NormalizedSQLServerName 
 
CreateFileRepositoryPath FileRepositoryPath + "\" + NormalizedSQLServerName 
 
'Creating Run Log 
CreateRunLogFile
 
'Creating Difference Log 
CreateDifferenceLogFile
 
'connecting to Visual Source Safe
ConnectToVSS
 
flag=0
'Connecting To SQL Server
ConnecttoSQL
 
if flag=0 then
CreateFileRepositoryServerAndDatabasesPaths
 
if ErrorNumber=0 then
 on error goto 0
 
 'determining SQL Server version
 SQLServerVersion = objSQLServer.VersionMajor
 
 'creating the project paths for the databases
 set VSSItem = objVSS.VSSItem("$/")
 
 flag = 0
 for each item in VSSItem.Items
  if lcase("$/" + item.Name) = lcase(VSSRoot) then
   flag = 1
   exit for
  end if
 next
 
 if flag = 0 then
  'this means the SQL Server VSS code repository folder has not been created yet
        
  'creating the visual source safe path
  wscript.echo "Creating the VSS Project Path " + VSSRoot + "for SQL Server code"
  WriteLog "Creating the VSS Project Path " + VSSRoot + "for SQL Server code"
  objVSS.VSSItem("$/").NewSubProject (VSSRoot)
  if err.number<> 0 then
   WriteLog "ERROR: " + Err.description
  else 
   WriteLog "new project for " + VSSRoot + " created"
  end if  
 end if
  
 set VSSItem = objVSS.VSSItem(VSSRoot)
 flag = 0
 for each item in VSSItem.Items
  if lcase(item.Name) = lcase(NormalizedSQLServerName) then
   flag = 1
   exit for
  end if
 next
 if flag = 0 then
  'this means the SQL Server is not yet under version control
  wscript.echo "adding " + NormalizedSQLServerName + " to version control"
  WriteLog "adding " + NormalizedSQLServerName + " to version control"
  objVSS.VSSItem(VSSRoot).NewSubProject (NormalizedSQLServerName)
  if err.number<> 0 then
   WriteLog "ERROR: " + Err.description
  else 
   WriteLog "new project for " + NormalizedSQLServerName + " created"
  end if  
 end if
 
 for each database in objSQLServer.Databases
  DatabaseName = Database.Name
  If not database.systemobject and database.Status = 0 then
   Set VSSItem = objVSS.VSSItem(VSSRoot + "/" + NormalizedSQLServerName )
   flag = 0
   path = FileRepositoryPath + "\" + NormalizedSQLServerName + "\" + DatabaseName
   for each item in VSSItem.Items
    if lcase(item.Name) = lcase(DatabaseName) then
     wscript.echo "database " + DatabaseName + " already under version control"
     flag = 1
     exit for
    end if
   next
   if flag = 0 then
    'this means the SQL Server database is not yet under version control
       
    'creating the visual source safe path
    wscript.echo "adding " + DatabaseName + " to version control"
    WriteLog "adding " + DatabaseName + " to version control"
    objVSS.VSSItem(VSSRoot).NewSubProject (NormalizedSQLServerName + "/" + DatabaseName)
    if err.number<> 0 then
     WriteLog "ERROR: " + Err.description
    else 
     WriteLog "new sub project for " + NormalizedSQLServerName + "/" + DatabaseName  + " created"
    end if  
   end if
   StoredProcedures
   Tables
   Views
   if objSQLServer.VersionMajor > 7 then
    UserDefinedFunctions
   end if 
  end if
 next
end if 
end if
 
Sub StoredProcedures
 ObjectType="Procedure"
 wscript.echo "Checking in Stored Procedures"
 WriteLog "Checking in Stored Procedures"
 VSSProjectPath = VSSRoot+"/"+ NormalizedSQLServerName+"/" + DatabaseName
 WriteLog "path is : " + path
 WriteLog "VSSProjectPath is : " + VSSProjectPath
 
 For Each StoredProcedure In Database.StoredProcedures
  if StoredProcedure.SystemObject = false then
   'existence check
   Wscript.echo "Proc Name: " + StoredProcedure.Name
   WriteLog "Proc Name: " + StoredProcedure.Name
  
   'check to see if the proc is under source control - if not add it
   'check to see if the proc is checked out - if so bail
   'if proc is checked in, compare to see if it is different from what is in the database
   'if the same, bail
   'if so check in 
   
   'checking to see if proc is under source control 
   Set VSSItem = objVSS.VSSItem(VSSRoot + "/" + NormalizedSQLServerName + "/" + DatabaseName)
   flag = 0
   for each item in VSSItem.Items
    if lcase(item.Name) = lcase(StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC") then
     wscript.echo "proc " + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC" + " already under version control"
     flag = 1
     exit for
    end if
   next
   set VSSItem=Nothing
   if flag=1 then 
    'stored procedure is already under source control
    'checking to see if it is checked out
    if objVSS.VSSItem(VSSProjectPath).Items(False).Item(StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC").IsCheckedOut = False then
     WriteLog "proc "+ StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC"+"is under version control already and is not checked out" 
         
     wscript.echo DatabaseName + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + " is in VSS and not checked out "
     WriteLog DatabaseName + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + " is in VSS and not checked out"
    
     'check it out. You must check the proc out to release read only lock
     WriteLog "Checking " + DatabaseName + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + " out of VSS"
     
     objVSS.VSSItem(VSSProjectPath).Items(False).Item(StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC").Checkout "Versioning System", path + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC"
     
     'script it out
     StoredProcedure.Script SQLDMOScript_Default + SQLDMOScript_Drops + SQLDMOScript_ObjectPermissions, path + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC1", SQLDMOScript2_ExtendedProperty
     
     'check for differences, if so check in
     Wscript.echo "Checking in " + StoredProcedure.Owner + "." + StoredProcedure.Name
     WriteLog "Checking in " + StoredProcedure.Owner + "." + StoredProcedure.Name + " to check for differences"
     If objVSS.VSSItem(VSSProjectPath).Items(False).Item(StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC").IsDifferent(path + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC1") = True Then
      'before we script this proc out, let's make sure it has versioning info on it.
      'SQLDMO does not support versioning so we have to use ADO to connect and add the versioning
      For Each Version In objVSS.VSSItem(VSSProjectPath).Items(False).Item(StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC").Versions
       VSSVersionNumber = Version.versionNumber
      Next
      wscript.echo "proc " + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC" + "is different, updating VSS"
      
      if objSQLServer.VersionMajor>7 then
       'now we have the latest extended properties let's update the proc with them.
       Call ExtendedProperties("VSSDate", Date, StoredProcedure.Owner, StoredProcedure.Name)
       Call ExtendedProperties("VSSComment", "This is the " & (VSSVersionNumber + 1) & " version of this proc", StoredProcedure.Owner, StoredProcedure.Name)
       Call ExtendedProperties("VSSUserName", objVSS.UserName, StoredProcedure.Owner, StoredProcedure.Name)
       Call ExtendedProperties("VSSVersionNumber", VSSVersionNumber + 1, StoredProcedure.Owner, StoredProcedure.Name)
      end if 
      
      'we have to script it out again to get the version info correct
      'first we delete the old script
      on error goto 0
 
      objFso.DeleteFile(path + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC1")
      objFso.DeleteFile(path + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC")
      
      StoredProcedure.Script SQLDMOScript_Default + SQLDMOScript_Drops + SQLDMOScript_ObjectPermissions, path + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC", SQLDMOScript2_ExtendedProperty
      objVSS.VSSItem(VSSProjectPath).Items(False).Item(StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC").Checkin "Versioining System", path + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC"
      WriteDifferenceLog "Proc " + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC in Database " + DatabaseName + " on Server " + ServerName + " has changed"
     Else
      'proc is the same, check it back in
      objVSS.VSSItem(VSSProjectPath).Items(False).Item(StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC").UndoCheckout path + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC"
      objFso.DeleteFile(path + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC1")
     End If
    else 
     WriteLog StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC is checked out"
     'objFso.DeleteFile(path + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC1")
    End If
   else
    wscript.echo DatabaseName + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + " is not in VSS"
 
    Wscript.echo "Proc does not exist, lets add it"
    if objSQLServer.VersionMajor>7 then
     Wscript.echo "Before we do that, let's tag it with extended properties"
         'before we add it we must add the extended properties to the proc
            
         Wscript.echo "adding Extended Properties to " + StoredProcedure.Owner + "." + StoredProcedure.Name
           
         Call ExtendedProperties("VSSDate", Date, StoredProcedure.Owner, StoredProcedure.Name)
         Call ExtendedProperties("VSSComment", "This is the initial sync of the proc", StoredProcedure.Owner, StoredProcedure.Name)
         Call ExtendedProperties("VSSUserName", objVSS.UserName, StoredProcedure.Owner, StoredProcedure.Name)
         Call ExtendedProperties("VSSVersionNumber", "1", StoredProcedure.Owner, StoredProcedure.Name)
        end if
           
        Wscript.echo "Checking in " + StoredProcedure.Owner + "." + StoredProcedure.Name
        wscript.echo "path is " + path
        StoredProcedure.Script SQLDMOScript_Default + SQLDMOScript_Drops + SQLDMOScript_ObjectPermissions, path + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC", SQLDMOScript2_ExtendedProperty
        wscript.echo VSSProjectPath
    objVSS.VSSItem(VSSProjectPath).Add path + "\" + StoredProcedure.Owner + "." + StoredProcedure.Name + ".PRC", VSSFLAG_BINTEXT
   end if
  end if
 Next
 
End Sub
 
Sub ExtendedProperties (PropertyName, PropertyValue, OwnerName, ProcedureName)
 Dim RecordCount 
 set objCommand = CreateObject("ADODB.Command")
 set objConnection  = CreateObject("ADODB.Connection")
 set objRecordSet = CreateObject("ADODB.Recordset")
 wscript.echo connectionstring
 wscript.echo DatabaseName
 ConnectionString = "Provider = SQLOLEDB.1;Integrated Security = SSPI;Persist Security Info = False;Data1 Source = .;Initial Catalog = ;" 
 ConnectionString1 = replace(ConnectionString,"Catalog = ;","Catalog = " + DatabaseName + ";")
 ConnectionString = replace(ConnectionString1,";Data1 Source = .;",";Data Source = " + ServerName + ";")
 wscript.echo ConnectionString 
    objConnection.ConnectionString = ConnectionString 
    objConnection.Open
    'lets check to see if the functions exist
 strSelect = "SELECT name FROM  ::fn_listextendedproperty ('" + PropertyName + "', 'user', '" + OwnerName + "', '" + ObjectType + "', '" + ProcedureName + "', NULL, default)"
 wscript.echo strSelect 
    objRecordSet.Open strSelect, objConnection, adOpenStatic, adLockReadOnly
    RecordCount = objRecordSet.RecordCount
    wscript.echo recordcount
    objRecordSet.Close
    objCommand.ActiveConnection = objConnection
    objCommand.CommandType = adCmdStoredProc
    If RecordCount = 0 Then
 wscript.echo "Adding" 
 objCommand.CommandText = "sp_addextendedproperty"
    Else
 objCommand.CommandText = "sp_updateextendedproperty"
 wscript.echo "updating" 
    End If
    
    objCommand.Parameters.Append objCommand.CreateParameter("@name", adVarChar, adParamInput, 256, PropertyName)
    objCommand.Parameters.Append objCommand.CreateParameter("@value", adVarChar, adParamInput, 128, PropertyValue)
    objCommand.Parameters.Append objCommand.CreateParameter("@level0type", adVarChar, adParamInput, 128, "user")
    objCommand.Parameters.Append objCommand.CreateParameter("@level0name", adVarChar, adParamInput, 256, OwnerName)
    objCommand.Parameters.Append objCommand.CreateParameter("@level1type", adVarChar, adParamInput, 128, ObjectType)
    objCommand.Parameters.Append objCommand.CreateParameter("@level1name", adVarChar, adParamInput, 256, ProcedureName)
    objCommand.Execute
    Set objCommand = Nothing
    objConnection.Close
End Sub
 
Sub CreateFileRepositoryPath (path)
 'this function creates the necessary file structure for the file repository
 wscript.echo "Path is : " + path 
 totalpath=""
 If objFso.FolderExists(path) = False Then
  MyArray = Split(path, "\")
  For arraymember = 0 To UBound(MyArray)
   If objFso.FolderExists(totalpath +  MyArray(arraymember) ) Then
    totalpath = totalpath + MyArray(arraymember) + "\"
     Else
      totalpath = totalpath + MyArray(arraymember) + "\"
      wscript.echo totalpath 
    objFso.CreateFolder (totalpath)
    errornumber=Err.Number 
    errordescription=Err.Description
    if errornumber<> 0 then  
     wscript.echo "Error Creating Path " + path  + " Error description " + errordescription
    else
     wscript.echo "Path " + path  + " Created"
    end if 
   End If
  Next 
 End If
End Sub
 
Sub WriteLog (Message)
 logFile.WriteLine Message
end sub
 
Sub WriteDifferenceLog (Message)
 DifferenceLogFile.WriteLine Message
end sub
 

Sub CreateRunLogFile
 
LogFileName = FileRepositoryPath + "\RunLog"+replace(cstr(date),"/","-")+ ".log"
wscript.echo logFileName
if objFso.FileExists(LogFileName) = TRUE then 
 set objFile = objFso.GetFile(LogFileName)
 set logFile = objFile.OpenAsTextStream(ForAppending)
 WriteLog "Hello from " + ServerName
else
 set logFile = objFso.CreateTextFile(LogFileName)
 WriteLog "Hello from " + ServerName
end if 
 
End Sub
 
Sub ConnectToVSS
WriteLog "connecting to Visual Source Safe"
objVSS.Open VSSPath, VSSAdminAccount, VSSAdminAccountPassword
if Err.Number <> 0 then
WriteLog "ERROR: " + Err.Description
else
WriteLog "Connected to VSS"
end if 
 
End Sub
 
Sub ConnectToSQL
 
WriteLog "Connecting to SQL Server " + ServerName
 
objSQLServer.LoginSecure = True
on error resume next
obJSQLServer.Connect ServerName
errorNumber=Err.Number
errorDescription=Err.description
 
if errorNumber =-2147467259 then
 WriteLog "ERROR: can't connect to " + ServerName
 flag=1
elseif errorNumber <> 0 then
 WriteLog "ERROR: " + errorDescription
else
 WriteLog "Successfully connected to " + ServerName
end if 
on error goto 0
End Sub
 
Sub CreateDifferenceLogFile
 
DifferenceLogFileName = FileRepositoryPath + "\DifferenceLog"+replace(cstr(date),"/","-")+ ".log"
wscript.echo DifferencelogFileName
if objFso.FileExists(DifferenceLogFileName) = TRUE then 
 set objFile = objFso.GetFile(DifferenceLogFileName)
 set DifferencelogFile = objFile.OpenAsTextStream(ForAppending)
 WriteDifferenceLog "Hello from " + ServerName
else
 set DifferencelogFile = objFso.CreateTextFile(DifferenceLogFileName)
 WriteDifferenceLog "Hello from " + ServerName
end if 
 

end sub
 

Sub Tables
 ObjectType="Table"
 wscript.echo "Checking in Tables"
 WriteLog "Checking in Tables"
 VSSProjectPath = VSSRoot+"/" + NormalizedSQLServerName+"/" + DatabaseName
 WriteLog "path is : " + path
 WriteLog "VSSProjectPath is : " + VSSProjectPath
 
 For Each Table In Database.Tables
  if Table.SystemObject = false then
   'existence check
   Wscript.echo "Proc Name: " + Table.Name
   WriteLog "Proc Name: " + Table.Name
  
   'check to see if the Table is under source control - if not add it
   'check to see if the Table is checked out - if so bail
   'if Table is checked in, compare to see if it is different from what is in the database
   'if the same, bail
   'if so check in 
   
   'checking to see if Table is under source control 
   Set VSSItem = objVSS.VSSItem(VSSRoot + "/" +  NormalizedSQLServerName + "/" + DatabaseName)
   flag = 0
   for each item in VSSItem.Items
    if lcase(item.Name) = lcase(Table.Owner + "." + Table.Name + ".TAB") then
     wscript.echo "proc " + Table.Owner + "." + Table.Name + ".TAB" + " already under version control"
     flag = 1
     exit for
    end if
   next
   set VSSItem=Nothing
   if flag=1 then 
    'stored procedure is already under source control
    'checking to see if it is checked out
    if objVSS.VSSItem(VSSProjectPath).Items(False).Item(Table.Owner + "." + Table.Name + ".TAB").IsCheckedOut = False then
     WriteLog "proc "+Table.Owner + "." + Table.Name + ".TAB"+"is under version control already and is not checked out" 
         
     wscript.echo DatabaseName + "\" + Table.Owner + "." + Table.Name + " is in VSS and not checked out "
     WriteLog DatabaseName + "\" + Table.Owner + "." + Table.Name + " is in VSS and not checked out"
    
     'check it out. You must check the Table out to release read only lock
     WriteLog "Checking " + DatabaseName + "\" + Table.Owner + "." + Table.Name + " out of VSS"
     
     objVSS.VSSItem(VSSProjectPath).Items(False).Item(Table.Owner + "." + Table.Name + ".TAB").Checkout "Versioning System", path + "\" + Table.Owner + "." + Table.Name + ".TAB"
     
     'script it out
     Table.Script SQLDMOScript_Default + SQLDMOScript_Drops + SQLDMOScript_ObjectPermissions + SQLDMOScript_Triggers+ SQLDMOScript_Indexes + SQLDMOScript_DRI_All, path + "\" + Table.Owner + "." + Table.Name + ".TAB1",, SQLDMOScript2_ExtendedProperty
     
      
     'check for differences, if so check in
     Wscript.echo "Checking in " + Table.Owner + "." + Table.Name
     WriteLog "Checking in " + Table.Owner + "." + Table.Name + " to check for differences"
     If objVSS.VSSItem(VSSProjectPath).Items(False).Item(Table.Owner + "." + Table.Name + ".TAB").IsDifferent(path + "\" + Table.Owner + "." + Table.Name + ".TAB1") = True Then
      if objSQLServer.VersionMajor>7 then
       'before we script this Table out, let's make sure it has versioning info on it.
       'SQLDMO does not support versioning so we have to use ADO to connect and add the versioning
       For Each Version In objVSS.VSSItem(VSSProjectPath).Items(False).Item(Table.Owner + "." + Table.Name + ".TAB").Versions
        VSSVersionNumber = Version.versionNumber
       Next
       wscript.echo "proc " + Table.Owner + "." + Table.Name + ".TAB" + "is different, updating VSS"
       'now we have the latest extended properties let's update the Table with them.
       Call ExtendedProperties("VSSDate", Date, Table.Owner, Table.Name)
       Call ExtendedProperties("VSSComment", "This is the "  & (VSSVersionNumber + 1) & " version of this proc", Table.Owner, Table.Name)
       Call ExtendedProperties("VSSUserName", objVSS.UserName, Table.Owner, Table.Name)
       Call ExtendedProperties("VSSVersionNumber", VSSVersionNumber + 1, Table.Owner, Table.Name)
      end if
      'we have to script it out again to get the version info correct
      'first we delete the old script
      on error goto 0
 
      objFso.DeleteFile(path + "\" + Table.Owner + "." + Table.Name + ".TAB1")
      objFso.DeleteFile(path + "\" + Table.Owner + "." + Table.Name + ".TAB")
      
      Table.Script SQLDMOScript_Default + SQLDMOScript_Triggers + SQLDMOScript_Drops + SQLDMOScript_ObjectPermissions + SQLDMOScript_Indexes + SQLDMOScript_DRI_All, path + "\" + Table.Owner + "." + Table.Name + ".TAB",, SQLDMOScript2_ExtendedProperty 
      objVSS.VSSItem(VSSProjectPath).Items(False).Item(Table.Owner + "." + Table.Name + ".TAB").Checkin "Versioining System", path + "\" + Table.Owner + "." + Table.Name + ".TAB"
      WriteDifferenceLog "Proc " + Table.Owner + "." + Table.Name + ".TAB in Database " + DatabaseName + " on Server " + ServerName + " has changed"
     Else
      'proc is the same, check it back in
      objVSS.VSSItem(VSSProjectPath).Items(False).Item(Table.Owner + "." + Table.Name + ".TAB").UndoCheckout path + "\" + Table.Owner + "." + Table.Name + ".TAB"
      objFso.DeleteFile(path + "\" + Table.Owner + "." + Table.Name + ".TAB1")
     End If
    else 
     WriteLog Table.Owner + "." + Table.Name + ".TAB is checked out"
     'objFso.DeleteFile(path + "\" + Table.Owner + "." + Table.Name + ".TAB1")
    End If
   else
    wscript.echo DatabaseName + "\" + Table.Owner + "." + Table.Name + " is not in VSS"
 
    Wscript.echo "Proc does not exist, lets add it"
    
    if objSQLServer.VersionMajor > 7 then
     Wscript.echo "Before we do that, let's tag it with extended properties"
         'before we add it we must add the extended properties to the proc
             
         Wscript.echo "adding Extended Properties to " + Table.Owner + "." + Table.Name
        
         Call ExtendedProperties("VSSDate", Date, Table.Owner, Table.Name)
         Call ExtendedProperties("VSSComment", "This is the initial sync of the proc", Table.Owner, Table.Name)
         Call ExtendedProperties("VSSUserName", objVSS.UserName, Table.Owner, Table.Name)
         Call ExtendedProperties("VSSVersionNumber", "1", Table.Owner, Table.Name)
        end if 
           
        Wscript.echo "Checking in " + Table.Owner + "." + Table.Name
        wscript.echo "path is " + path
        Table.Script SQLDMOScript_Default + SQLDMOScript_Triggers+ SQLDMOScript_Drops + SQLDMOScript_ObjectPermissions + SQLDMOScript_Indexes + SQLDMOScript_DRI_All, path + "\" + Table.Owner + "." + Table.Name + ".TAB",, SQLDMOScript2_ExtendedProperty 
        
    objVSS.VSSItem(VSSProjectPath).Add path + "\" + Table.Owner + "." + Table.Name + ".TAB", VSSFLAG_BINTEXT
   end if
  end if
 Next
 
End Sub
 

Sub Views
 ObjectType="View"
 wscript.echo "Checking in Views"
 WriteLog "Checking in Views"
 VSSProjectPath = VSSRoot +"/" + NormalizedSQLServerName+"/" + DatabaseName
 WriteLog "path is : " + path
 WriteLog "VSSProjectPath is : " + VSSProjectPath
 
 For Each View In Database.Views
  if View.SystemObject = false then
   'existence check
   Wscript.echo "Proc Name: " + View.Name
   WriteLog "Proc Name: " + View.Name
  
   'check to see if the View is under source control - if not add it
   'check to see if the View is checked out - if so bail
   'if View is checked in, compare to see if it is different from what is in the database
   'if the same, bail
   'if so check in 
   
   'checking to see if View is under source control 
   Set VSSItem = objVSS.VSSItem(VSSRoot + "/" +  NormalizedSQLServerName + "/" + DatabaseName)
   flag = 0
   for each item in VSSItem.Items
    if lcase(item.Name) = lcase(View.Owner + "." + View.Name + ".VIEW") then
     wscript.echo "proc " + View.Owner + "." + View.Name + ".VIEW" + " already under version control"
     flag = 1
     exit for
    end if
   next
   set VSSItem=Nothing
   if flag=1 then 
    'stored procedure is already under source control
    'checking to see if it is checked out
    if objVSS.VSSItem(VSSProjectPath).Items(False).Item(View.Owner + "." + View.Name + ".VIEW").IsCheckedOut = False then
     WriteLog "proc "+View.Owner + "." + View.Name + ".VIEW"+"is under version control already and is not checked out" 
         
     wscript.echo DatabaseName + "\" + View.Owner + "." + View.Name + " is in VSS and not checked out "
     WriteLog DatabaseName + "\" + View.Owner + "." + View.Name + " is in VSS and not checked out"
    
     'check it out. You must check the View out to release read only lock
     WriteLog "Checking " + DatabaseName + "\" + View.Owner + "." + View.Name + " out of VSS"
     
     objVSS.VSSItem(VSSProjectPath).Items(False).Item(View.Owner + "." + View.Name + ".VIEW").Checkout "Versioning System", path + "\" + View.Owner + "." + View.Name + ".VIEW"
     
     'script it out
     View.Script SQLDMOScript_Default + SQLDMOScript_Drops + SQLDMOScript_ObjectPermissions, path + "\" + View.Owner + "." + View.Name + ".VIEW1", SQLDMOScript2_ExtendedProperty
     
     'check for differences, if so check in
     Wscript.echo "Checking in " + View.Owner + "." + View.Name
     WriteLog "Checking in " + View.Owner + "." + View.Name + " to check for differences"
     If objVSS.VSSItem(VSSProjectPath).Items(False).Item(View.Owner + "." + View.Name + ".VIEW").IsDifferent(path + "\" + View.Owner + "." + View.Name + ".VIEW1") = True Then
      if objSQLServer.VersionMajor > 7 then
       'before we script this View out, let's make sure it has versioning info on it.
       'SQLDMO does not support versioning so we have to use ADO to connect and add the versioning
       For Each Version In objVSS.VSSItem(VSSProjectPath).Items(False).Item(View.Owner + "." + View.Name + ".VIEW").Versions
        VSSVersionNumber = Version.versionNumber
       Next
       wscript.echo "proc " + View.Owner + "." + View.Name + ".VIEW" + "is different, updating VSS"
       'now we have the latest extended properties let's update the View with them.
       Call ExtendedProperties("VSSDate", Date, View.Owner, View.Name)
       Call ExtendedProperties("VSSComment", "This is the "  & (VSSVersionNumber + 1) & " version of this proc", View.Owner, View.Name)
       Call ExtendedProperties("VSSUserName", objVSS.UserName, View.Owner, View.Name)
       Call ExtendedProperties("VSSVersionNumber", VSSVersionNumber + 1, View.Owner, View.Name)
      end if 
      'we have to script it out again to get the version info correct
      'first we delete the old script
      on error goto 0
 
      objFso.DeleteFile(path + "\" + View.Owner + "." + View.Name + ".VIEW1")
      objFso.DeleteFile(path + "\" + View.Owner + "." + View.Name + ".VIEW")
      
      View.Script SQLDMOScript_Default + SQLDMOScript_Drops + SQLDMOScript_ObjectPermissions, path + "\" + View.Owner + "." + View.Name + ".VIEW", SQLDMOScript2_ExtendedProperty
      objVSS.VSSItem(VSSProjectPath).Items(False).Item(View.Owner + "." + View.Name + ".VIEW").Checkin "Versioining System", path + "\" + View.Owner + "." + View.Name + ".VIEW"
      WriteDifferenceLog "Proc " + View.Owner + "." + View.Name + ".VIEW in Database " + DatabaseName + " on Server " + ServerName + " has changed"
     Else
      'proc is the same, check it back in
      objVSS.VSSItem(VSSProjectPath).Items(False).Item(View.Owner + "." + View.Name + ".VIEW").UndoCheckout path + "\" + View.Owner + "." + View.Name + ".VIEW"
      objFso.DeleteFile(path + "\" + View.Owner + "." + View.Name + ".VIEW1")
     End If
    else 
     WriteLog View.Owner + "." + View.Name + ".VIEW is checked out"
     'objFso.DeleteFile(path + "\" + View.Owner + "." + View.Name + ".VIEW1")
    End If
   else
    wscript.echo DatabaseName + "\" + View.Owner + "." + View.Name + " is not in VSS"
 
    Wscript.echo "Proc does not exist, lets add it"
    
    if objSQLServer.VersionMajor > 7 then
     Wscript.echo "Before we do that, let's tag it with extended properties"
         'before we add it we must add the extended properties to the proc
            
         Wscript.echo "adding Extended Properties to " + View.Owner + "." + View.Name
        
         Call ExtendedProperties("VSSDate", Date, View.Owner, View.Name)
         Call ExtendedProperties("VSSComment", "This is the initial sync of the proc", View.Owner, View.Name)
         Call ExtendedProperties("VSSUserName", objVSS.UserName, View.Owner, View.Name)
         Call ExtendedProperties("VSSVersionNumber", "1", View.Owner, View.Name)
        end if 
           
        Wscript.echo "Checking in " + View.Owner + "." + View.Name
        wscript.echo "path is " + path
        View.Script SQLDMOScript_Default + SQLDMOScript_Drops + SQLDMOScript_ObjectPermissions, path + "\" + View.Owner + "." + View.Name + ".VIEW", SQLDMOScript2_ExtendedProperty
        
    objVSS.VSSItem(VSSProjectPath).Add path + "\" + View.Owner + "." + View.Name + ".VIEW", VSSFLAG_BINTEXT
   end if
  end if
 Next
 
End Sub
 

Sub CreateFileRepositoryServerAndDatabasesPaths
 wscript.echo "creating file paths for server and databases"
 wscript.echo path
 for each database in objSQLServer.Databases
  DatabaseName = Database.Name
  If not database.systemobject then
   path = FileRepositoryPath + "\" + NormalizedSQLServerName + "\" + DatabaseName
   CreateFileRepositoryPath path
  end if
 next
End Sub
 
Sub UserDefinedFunctions
 ObjectType="Function"
 wscript.echo "Checking in UserDefinedFunctions"
 WriteLog "Checking in UserDefinedFunctions"
 VSSProjectPath = VSSRoot +"/" + NormalizedSQLServerName+"/" + DatabaseName
 WriteLog "path is : " + path
 WriteLog "VSSProjectPath is : " + VSSProjectPath
 
 For Each UserDefinedFunction In Database.UserDefinedFunctions
  if UserDefinedFunction.SystemObject = false then
   'existence check
   Wscript.echo "Proc Name: " + UserDefinedFunction.Name
   WriteLog "Proc Name: " + UserDefinedFunction.Name
  
   'check to see if the UserDefinedFunction is under source control - if not add it
   'check to see if the UserDefinedFunction is checked out - if so bail
   'if UserDefinedFunction is checked in, compare to see if it is different from what is in the database
   'if the same, bail
   'if so check in 
   
   'checking to see if UserDefinedFunction is under source control 
   Set VSSItem = objVSS.VSSItem(VSSRoot + "/" +  NormalizedSQLServerName + "/" + DatabaseName)
   flag = 0
   for each item in VSSItem.Items
    if lcase(item.Name) = lcase(UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC") then
     wscript.echo "proc " + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC" + " already under version control"
     flag = 1
     exit for
    end if
   next
   set VSSItem=Nothing
   if flag=1 then 
    'stored procedure is already under source control
    'checking to see if it is checked out
    if objVSS.VSSItem(VSSProjectPath).Items(False).Item(UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC").IsCheckedOut = False then
     WriteLog "proc "+UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC"+"is under version control already and is not checked out" 
         
     wscript.echo DatabaseName + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + " is in VSS and not checked out "
     WriteLog DatabaseName + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + " is in VSS and not checked out"
    
     'check it out. You must check the UserDefinedFunction out to release read only lock
     WriteLog "Checking " + DatabaseName + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + " out of VSS"
     
     objVSS.VSSItem(VSSProjectPath).Items(False).Item(UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC").Checkout "Versioning System", path + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC"
     
     'script it out
     UserDefinedFunction.Script SQLDMOScript_Default + SQLDMOScript_Drops + SQLDMOScript_ObjectPermissions, path + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC1", SQLDMOScript2_ExtendedProperty
     
      
     'check for differences, if so check in
     Wscript.echo "Checking in " + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name
     WriteLog "Checking in " + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + " to check for differences"
     If objVSS.VSSItem(VSSProjectPath).Items(False).Item(UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC").IsDifferent(path + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC1") = True Then
      'before we script this UserDefinedFunction out, let's make sure it has versioning info on it.
      'SQLDMO does not support versioning so we have to use ADO to connect and add the versioning
      For Each Version In objVSS.VSSItem(VSSProjectPath).Items(False).Item(UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC").Versions
       VSSVersionNumber = Version.versionNumber
      Next
      wscript.echo "proc " + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC" + "is different, updating VSS"
      'now we have the latest extended properties let's update the UserDefinedFunction with them.
      Call ExtendedProperties("VSSDate", Date, UserDefinedFunction.Owner, UserDefinedFunction.Name)
      Call ExtendedProperties("VSSComment", "This is the " & (VSSVersionNumber + 1) & " version of this proc", UserDefinedFunction.Owner, UserDefinedFunction.Name)
      Call ExtendedProperties("VSSUserName", objVSS.UserName, UserDefinedFunction.Owner, UserDefinedFunction.Name)
      Call ExtendedProperties("VSSVersionNumber", VSSVersionNumber + 1, UserDefinedFunction.Owner, UserDefinedFunction.Name)
      'we have to script it out again to get the version info correct
      'first we delete the old script
      on error goto 0
 
      objFso.DeleteFile(path + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC1")
      objFso.DeleteFile(path + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC")
      
      UserDefinedFunction.Script SQLDMOScript_Default + SQLDMOScript_Drops + SQLDMOScript_ObjectPermissions, path + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC", SQLDMOScript2_ExtendedProperty
      objVSS.VSSItem(VSSProjectPath).Items(False).Item(UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC").Checkin "Versioining System", path + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC"
      WriteDifferenceLog "Proc " + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC in Database " + DatabaseName + " on Server " + ServerName + " has changed"
     Else
      'proc is the same, check it back in
      objVSS.VSSItem(VSSProjectPath).Items(False).Item(UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC").UndoCheckout path + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC"
      objFso.DeleteFile(path + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC1")
     End If
    else 
     WriteLog UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC is checked out"
     'objFso.DeleteFile(path + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC1")
    End If
   else
    wscript.echo DatabaseName + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + " is not in VSS"
 
    Wscript.echo "Proc does not exist, lets add it"
    Wscript.echo "Before we do that, let's tag it with extended properties"
        'before we add it we must add the extended properties to the proc
           
        Wscript.echo "adding Extended Properties to " + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name
       
        Call ExtendedProperties("VSSDate", Date, UserDefinedFunction.Owner, UserDefinedFunction.Name)
        Call ExtendedProperties("VSSComment", "This is the initial sync of the proc", UserDefinedFunction.Owner, UserDefinedFunction.Name)
        Call ExtendedProperties("VSSUserName", objVSS.UserName, UserDefinedFunction.Owner, UserDefinedFunction.Name)
        Call ExtendedProperties("VSSVersionNumber", "1", UserDefinedFunction.Owner, UserDefinedFunction.Name)
           
        Wscript.echo "Checking in " + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name
        wscript.echo "path is " + path
        UserDefinedFunction.Script SQLDMOScript_Default + SQLDMOScript_Drops + SQLDMOScript_ObjectPermissions, path + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC", SQLDMOScript2_ExtendedProperty
        
    objVSS.VSSItem(VSSProjectPath).Add path + "\" + UserDefinedFunction.Owner + "." + UserDefinedFunction.Name + ".FUNC", VSSFLAG_BINTEXT
   end if
  end if
 Next
 
End Sub
 
