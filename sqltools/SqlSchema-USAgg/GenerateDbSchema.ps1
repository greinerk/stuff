#Start file
#Set-ExecutionPolicy RemoteSigned
#.\GenerateDbSchema.ps1 "192.168.50.151\sql2012" "CMCERMS_QA" ".\"
#Set-ExecutionPolicy -ExecutionPolicy:Unrestricted -Scope:LocalMachine
function GenerateDBScript([string]$serverName, [string]$dbname, [string]$dbuser, [string]$dbpassword, [string]$scriptpath )
{
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
	[System.Reflection.Assembly]::LoadWithPartialName("System.Data") | out-null
	[System.Reflection.Assembly]::LoadWithPartialName("System.Text") | out-null

	$dbnamesafe = $dbname -replace "\\", "_"
	$srv = new-object "Microsoft.SqlServer.Management.SMO.Server" $serverName
	$srv.ConnectionContext.LoginSecure=$true; 
	#$srv.ConnectionContext.LoginSecure=$false; 
	#$srv.ConnectionContext.set_Login($dbuser); 
	#$srv.ConnectionContext.set_Password($dbpassword)  
	$srv.ConnectionContext.ApplicationName="GenerateDbSchema"
	
	#$srv.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.View], "IsSystemObject")
	$srv.SetDefaultInitFields($true) # get all fields for all objects
	$db = New-Object "Microsoft.SqlServer.Management.SMO.Database"
	$db = $srv.Databases.Item($dbname)

	$options = New-Object "Microsoft.SqlServer.Management.SMO.ScriptingOptions"
	$options.AllowSystemObjects = $false
	$options.AnsiFile = $true
	$options.AppendToFile = $false
	$options.IncludeDatabaseContext = $false
	$options.IncludeIfNotExists = $false
	$options.ClusteredIndexes = $true
	$options.Default = $true
	$options.DriAll = $true
	$options.ExtendedProperties = $false
	$options.IncludeHeaders = $false
	$options.Indexes = $true
	$options.NoAssemblies = $true
	$options.NoCollation = $true
	$options.NonClusteredIndexes = $true
	$options.ScriptDataCompression = $false
	$options.ToFileOnly = $true
	$options.Triggers = $true
	$options.WithDependencies = $false
	
	# remove existing SQL scripts
	#out-host -InputObject ("Removing: " + ((join-path $scriptpath $dbnamesafe) + "\*.sql"))
	#remove-item ((join-path $scriptpath $dbnamesafe) + "\*.sql") -recurse -force
	
	# Tables
	New-Item ($scriptpath + "\" + $dbnamesafe + "\Tables\") -type directory -force | out-null
	$outputpath = join-path $scriptpath ($dbnamesafe + "\Tables\") -resolve
	out-host -InputObject $outputpath
	remove-item ($outputpath + "*.sql") -recurse
	ForEach ($tb in $db.Tables)
	{
		# if ($tb.Name -like "*tblPaybackCalculatorsInsul*") 
		# {

		# 6/7/16 KDG - the code below doesn't work
		# Use reflection to set internal field
		# See http://stackoverflow.com/questions/26479793/inconsistent-default-constraints-from-sql-server-management-objects-smo
		ForEach ($col in $tb.Columns)
		{
			# if ($col.DefaultConstraint -ne $null)
			if ($col.DefaultConstraint)
			{
				# write-host ("default constraint: " + $col.DefaultConstraint.Name)
				$info = $col.DefaultConstraint.GetType().GetField("forceEmbedDefaultConstraint", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
				# write-host ($info.Name + ": " + $info.GetValue($col.DefaultConstraint))
				$info.SetValue($col.DefaultConstraint, $true)
				# write-host ($info.Name + ": " + $info.GetValue($col.DefaultConstraint))
			}
		}
		$options.FileName = $outputpath + $tb.Schema + "." + $tb.Name + ".sql"
		$tb.Script($options)
		
		# }
	}
	
	# return
	
	# Views
	New-Item ($scriptpath + "\" + $dbnamesafe + "\Views\") -type directory -force | out-null
	$outputpath = join-path $scriptpath ($dbnamesafe + "\Views\") -resolve
	out-host -InputObject $outputpath
	remove-item ($outputpath + "*.sql") -recurse
	ForEach ($vw in ($db.Views | where {$_.IsSystemObject -eq $false}))
	{
		$options.FileName = $outputpath + $vw.Schema + "." + $vw.Name + ".sql"
		$vw.Script($options)
	}
	
	# Stored Procedures
	New-Item ($scriptpath + "\" + $dbnamesafe + "\StoredProcedures\") -type directory -force | out-null
	$outputpath = join-path $scriptpath ($dbnamesafe + "\StoredProcedures\") -resolve
	out-host -InputObject $outputpath
	remove-item ($outputpath + "*.sql") -recurse
	ForEach ($sp in ($db.StoredProcedures | where {$_.IsSystemObject -eq $false}))
	{
		$options.FileName = $outputpath + $sp.Schema + "." + $sp.Name + ".sql"
		$sp.Script($options)
	}
	
	# Functions
	New-Item ($scriptpath + "\" + $dbnamesafe + "\Functions\") -type directory -force | out-null
	$outputpath = join-path $scriptpath ($dbnamesafe + "\Functions\") -resolve
	out-host -InputObject $outputpath
	remove-item ($outputpath + "*.sql") -recurse
	ForEach ($udf in ($db.UserDefinedFunctions | where {$_.IsSystemObject -eq $false}))
	{
		$options.FileName = $outputpath + $udf.Schema + "." + $udf.Name + ".sql"
		$udf.Script($options)
	}

}

GenerateDBScript $args[0] $args[1] $args[2] $args[3] $args[4]
