
# Start Script
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# Set-ExecutionPolicy -ExecutionPolicy:Unrestricted -Scope:LocalMachine
#

function ExportDbSchema([string]$serverName, [string]$dbName, [string]$scriptpath)
{
	$Databases = Get-DbaDatabase -SqlInstance $serverName -Status Normal -ExcludeSystem
	foreach ($db in $Databases | Sort-Object) {
		Write-Output "Found db: $($db.Name)"
		if ($db.Name -like $dbname) { # uses wildcard matching (use -match for RE)
		
			$dbPath = "$($scriptpath)\$($db.Name)"
			Write-Output "db path: $($dbPath)"
			
			#call mssql-scripter -S %1 -d %2 -f %3\%1\%2 --file-per-object --exclude-use-database --display-progress --exclude-headers --exclude-schemas SQL# --include-types StoredProcedure Table UserDefinedAggregate UserDefinedDataType #UserDefinedFunction UserDefinedTableTypes UserDefinedType View
				
		}
	}
}

# function that moves files into object-specific folders
function MoveFiles([string]$filepath)
{
	#pushd %3\%1\%2
	#
	#mkdir UserDefinedFunctions
	#move *.UserDefinedFunction.sql UserDefinedFunctions
	#
	#mkdir StoredProcedures
	#move *.StoredProcedure.sql StoredProcedures
	#
	#mkdir Tables
	#move *.Table.sql Tables
	#
	#mkdir UserDefinedDataTypes
	#move *.UserDefinedDataType.sql UserDefinedDataTypes
	#
	#mkdir Views
	#move *.View.sql Views
	#
	#mkdir UserDefinedTableTypes
	#move *.UserDefinedTableType.sql UserDefinedTableTypes
	#
	#mkdir UserDefinedAggregates
	#move *.UserDefinedAggregate.sql UserDefinedAggregates
	#
	#popd
	
}

#=============
# Execute
#=============
ExportDbSchema $args[0] $args[1] $args[2]
