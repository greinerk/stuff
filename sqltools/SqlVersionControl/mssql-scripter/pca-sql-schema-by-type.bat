@echo off

rem Parameters
rem %1 server name
rem %2 db name
rem %3 SQL scripts root path

del /Q /S %3\%1\%2\*

call mssql-scripter -S %1 -d %2 -f %3\%1\%2\Tables                --continue-on-error --file-per-object --exclude-use-database --display-progress --exclude-headers --exclude-schemas SQL# --include-types Table
call mssql-scripter -S %1 -d %2 -f %3\%1\%2\StoredProcedures      --continue-on-error --file-per-object --exclude-use-database --display-progress --exclude-headers --exclude-schemas SQL# --include-types StoredProcedure
call mssql-scripter -S %1 -d %2 -f %3\%1\%2\Views                 --continue-on-error --file-per-object --exclude-use-database --display-progress --exclude-headers --exclude-schemas SQL# --include-types View
call mssql-scripter -S %1 -d %2 -f %3\%1\%2\UserDefinedAggregates --continue-on-error --file-per-object --exclude-use-database --display-progress --exclude-headers --exclude-schemas SQL# --include-types UserDefinedAggregate
call mssql-scripter -S %1 -d %2 -f %3\%1\%2\UserDefinedDataTypes  --continue-on-error --file-per-object --exclude-use-database --display-progress --exclude-headers --exclude-schemas SQL# --include-types UserDefinedDataType
call mssql-scripter -S %1 -d %2 -f %3\%1\%2\UserDefinedFunctions  --continue-on-error --file-per-object --exclude-use-database --display-progress --exclude-headers --exclude-schemas SQL# --include-types UserDefinedFunction
call mssql-scripter -S %1 -d %2 -f %3\%1\%2\UserDefinedTableTypes --continue-on-error --file-per-object --exclude-use-database --display-progress --exclude-headers --exclude-schemas SQL# --include-types UserDefinedTableTypes 
call mssql-scripter -S %1 -d %2 -f %3\%1\%2\UserDefinedTypes      --continue-on-error --file-per-object --exclude-use-database --display-progress --exclude-headers --exclude-schemas SQL# --include-types UserDefinedType

powershell -File fix-mssql-scripter-filenames.ps1
