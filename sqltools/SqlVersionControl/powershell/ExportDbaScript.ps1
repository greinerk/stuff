
# Start Script
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# Set-ExecutionPolicy -ExecutionPolicy:Unrestricted -Scope:LocalMachine

#
# remote performance is about 1 object per second
#

function ExportDbaScript([string]$serverName, [string]$dbname, [string]$scriptpath)
{
	$options = New-DbaScriptingOption
	$options.ScriptSchema = $true
	$options.IncludeDatabaseContext  = $false
	$options.ClusteredIndexes  = $true
	$options.ColumnStoreIndexes  = $true
	$options.NonClusteredIndexes  = $true
	$options.DriAll = $true
	$options.IncludeHeaders = $false
	$Options.NoCommandTerminator = $false
	$Options.ScriptBatchTerminator = $true
	$Options.AnsiFile = $true
	$Databases = Get-DbaDatabase -SqlInstance $serverName -Status Normal -ExcludeSystem # -ExcludeDatabase master, model, msdb, tempdb
	foreach ($db in $Databases | Sort-Object) {
		Write-Output "Found db: $($db.Name)"
		if ($db.Name -like $dbname) { # uses wildcard matching (use -match for RE)
		
			$dbPath = "$($scriptpath)\$($db.Name)"
			Write-Output "db path: $($dbPath)"
			
			# remove all existing files but not folders. 
			Get-ChildItem $dbPath -Recurse -include *.sql | Remove-Item -Force
			
			# create paths
			New-Item -ItemType Directory -Force "$($scriptpath)\$($db.Name)\Tables"
			New-Item -ItemType Directory -Force "$($scriptpath)\$($db.Name)\Views"
			New-Item -ItemType Directory -Force "$($scriptpath)\$($db.Name)\StoredProcedures"
			New-Item -ItemType Directory -Force "$($scriptpath)\$($db.Name)\UserDefinedDataTypes"
			New-Item -ItemType Directory -Force "$($scriptpath)\$($db.Name)\UserDefinedFunctions"
			New-Item -ItemType Directory -Force "$($scriptpath)\$($db.Name)\UserDefinedTableTypes"
			New-Item -ItemType Directory -Force "$($scriptpath)\$($db.Name)\UserDefinedTypes"
			
			# export a script for the database itself
			Export-DbaScript -InputObject $db -FilePath $scriptpath\$dbname.sql -Encoding UTF8 -ScriptingOptionsObject $options -NoPrefix

			# export by object types
			$db.Tables | Where -Property Schema -NotIn "SQL#", "sys" | 
				foreach-object { export-dbascript -InputObject $_ -FilePath "$($scriptpath)\$($db.Name)\Tables\$($_.Schema).$($_.name).sql" -ScriptingOptionsObject $options -NoPrefix}

			$db.Views | Where -Property Schema -NotIn "SQL#", "sys" | 
				foreach-object { export-dbascript -InputObject $_ -FilePath "$($scriptpath)\$($db.Name)\Views\$($_.Schema).$($_.name).sql" -ScriptingOptionsObject $options -NoPrefix}

			$db.StoredProcedures | Where -Property Schema -NotIn "SQL#", "sys" | 
				foreach-object { export-dbascript -InputObject $_ -FilePath "$($scriptpath)\$($db.Name)\StoredProcedures\$($_.Schema).$($_.name).sql" -ScriptingOptionsObject $options -NoPrefix}

			$db.UserDefinedDataTypes | Where -Property Schema -NotIn "SQL#", "sys" | 
				foreach-object { export-dbascript -InputObject $_ -FilePath "$($scriptpath)\$($db.Name)\UserDefinedDataTypes\$($_.Schema).$($_.name).sql" -ScriptingOptionsObject $options -NoPrefix}

			$db.UserDefinedFunctions | Where -Property Schema -NotIn "SQL#", "sys" | 
				foreach-object { export-dbascript -InputObject $_ -FilePath "$($scriptpath)\$($db.Name)\UserDefinedFunctions\$($_.Schema).$($_.name).sql" -ScriptingOptionsObject $options -NoPrefix}

			$db.UserDefinedTableTypes | Where -Property Schema -NotIn "SQL#", "sys" |
				foreach-object { export-dbascript -InputObject $_ -FilePath "$($scriptpath)\$($db.Name)\UserDefinedTableTypes\$($_.Schema).$($_.name).sql" -ScriptingOptionsObject $options -NoPrefix}

			$db.UserDefinedTypes | Where -Property Schema -NotIn "SQL#", "sys" |
				foreach-object { export-dbascript -InputObject $_ -FilePath "$($scriptpath)\$($db.Name)\UserDefinedTypes\$($_.Schema).$($_.name).sql" -ScriptingOptionsObject $options -NoPrefix}
				
		}
	}
}

#=============
# Execute
#=============
ExportDbaScript $args[0] $args[1] $args[2]
