
# Start Script
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

function main()
{
	Get-ChildItem -Path "." -Filter "*.StoredProcedure.sql" -Recurse | Rename-Item -NewName {$_.name -replace '.StoredProcedure.sql','.sql' }
	Get-ChildItem -Path "." -Filter "*.Table.sql" -Recurse | Rename-Item -NewName {$_.name -replace '.Table.sql','.sql' }
	Get-ChildItem -Path "." -Filter "*.UserDefinedDataType.sql" -Recurse | Rename-Item -NewName {$_.name -replace '.UserDefinedDataType.sql','.sql' }
	Get-ChildItem -Path "." -Filter "*.UserDefinedAggregate.sql" -Recurse | Rename-Item -NewName {$_.name -replace '.UserDefinedAggregate.sql','.sql' }
	Get-ChildItem -Path "." -Filter "*.UserDefinedFunction.sql" -Recurse | Rename-Item -NewName {$_.name -replace '.UserDefinedFunction.sql','.sql' }
	Get-ChildItem -Path "." -Filter "*.UserDefinedTableType.sql" -Recurse | Rename-Item -NewName {$_.name -replace '.UserDefinedTableType.sql','.sql' }
	Get-ChildItem -Path "." -Filter "*.UserDefinedType.sql" -Recurse | Rename-Item -NewName {$_.name -replace '.UserDefinedType.sql','.sql' }
	Get-ChildItem -Path "." -Filter "*.View.sql" -Recurse | Rename-Item -NewName {$_.name -replace '.View.sql','.sql' }
}

#=============
# Execute
#=============
main