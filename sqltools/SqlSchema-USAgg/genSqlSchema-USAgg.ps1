
function GenerateDBScript([string]$ServerName, [string]$Database, [string]$DirectoryToSaveTo )
{
	# $ServerName='(local)' # enter the name of a server
	# $Database='USAgg_Dev' # enter the name of a database
	# $DirectoryToSaveTo='C:\PCA\SqlSchema-USAgg\USAgg_Dev' # enter the directory where to store SQL scripts for objects

	Log-Message "----------------------------------"
	Log-Message "start"
	
	# load SMO assembly, and if SQL 2008 DLLs are run, load the SMOExtended and SQLWMIManagement libraries
	$v = [System.Reflection.Assembly]::LoadWithPartialName( 'Microsoft.SqlServer.SMO')
	if ((($v.FullName.Split(','))[1].Split('='))[1].Split('.')[0] -ne '9') {
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended') | out-null
	}
	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoEnum') | out-null
	set-psdebug -strict # catch a few extra bugs
	$ErrorActionPreference = "stop"

	if (Test-Path -path $DirectoryToSaveTo) {
			Log-Message ("Cleaning output path: " + $DirectoryToSaveTo)
			Remove-Item $DirectoryToSaveTo -Recurse
		}

	# remove all existing SQL objects
	New-Item $DirectoryToSaveTo -type directory | out-null

	$My='Microsoft.SqlServer.Management.Smo'
	$srv = new-object ("$My.Server") $ServerName # Attach to the server
	if ($srv.ServerType-eq $null) # If it managed to find a server
					{
	   Log-Message "Server not found: '$ServerName' "
	   return                
	} 
	$scripter = new-object ("$My.Scripter") $srv # create the scripter
	$scripter.Options.AllowSystemObjects = $false
	#$scripter.Options.AnsiFile = $false
	$scripter.Options.AppendToFile = $false
	$scripter.Options.IncludeDatabaseContext = $false
	$scripter.Options.IncludeIfNotExists = $false
	$scripter.Options.ClusteredIndexes = $true
	$scripter.Options.Default = $true
	$scripter.Options.DriAll = $true
	$scripter.Options.Encoding = new-object("System.Text.ASCIIEncoding")
	$scripter.Options.ExtendedProperties = $false
	$scripter.Options.IncludeHeaders = $false
	$scripter.Options.Indexes = $true
	$scripter.Options.NoAssemblies = $true
	$scripter.Options.NoCollation = $true
	$scripter.Options.NonClusteredIndexes = $true
	$scripter.Options.ScriptDataCompression = $false
	#$scripter.Options.ToFileOnly = $true
	$scripter.Options.Triggers = $true
	$scripter.Options.WithDependencies = $false

	# first we get the bitmap of all the object types we want 
	$all =[long] [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::all `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::ExtendedStoredProcedure `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::PlanGuid `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::DatabaseEncryptionKey `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::DatabaseAuditSpecification `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::FullTextStopList `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::SearchPropertyList `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::Sequence `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::MessageType `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::ServiceQueue `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::ServiceContract `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::ServiceRoute `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::SqlAssembly `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::Synonym `
		-bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::Federation
	# and we store them in a datatable
	$d = new-object System.Data.Datatable

	# get everything except the servicebroker object, the information schema and system views
	$d=$srv.databases[$Database].EnumObjects([long]0x1FFFFFFF -band $all) | `
		Where-Object {$_.Schema -ne 'sys'-and $_.Schema -ne "information_schema" -and $_.DatabaseObjectTypes -ne 'ServiceBroker'}

	Log-Message "scripting SQL objects"

	# and write out each scriptable object as a file in the directory you specify
	$d| FOREACH-OBJECT { # for every object we have in the datatable.
		$SavePath="$($DirectoryToSaveTo)\$($_.DatabaseObjectTypes)"
		# create the directory if necessary (SMO doesn't)
		if (!( Test-Path -path $SavePath )) # create it if not existing
			{Try { New-Item $SavePath -type directory | out-null } 
			 Catch [system.exception]{
				Write-Error "error while creating '$SavePath' $_"
				 return
		  } 
		}

		# build output path, removing non-legal characters
		$Filename = "$SavePath\$($_.schema).$($_.name -replace '[\\\/\:\.]','-').sql";
		$Filename = $Filename.replace('*','@')

		# Create a single element URN array
		$UrnCollection = new-object ('Microsoft.SqlServer.Management.Smo.urnCollection')
		$URNCollection.add($_.urn)

		#Log-Message $Filename
		
		# script into memory
		$SqlScript = $scripter.script($URNCollection)
		
		# remove datetime stamp
		$SqlScript = $SqlScript -replace 'Last regenerated at .*', 'Last regenerated at %RemovedForVersionControl% */'
		
		# save to file
		Out-File -FilePath $Filename -InputObject $SqlScript -Encoding ASCII
		
	} 
	Log-Message "done"
}

function Log-Message
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$LogMessage
    )

    Write-Output ("{0} - {1}" -f (Get-Date -Format u), $LogMessage)
}

GenerateDBScript $args[0] $args[1] $args[2]
