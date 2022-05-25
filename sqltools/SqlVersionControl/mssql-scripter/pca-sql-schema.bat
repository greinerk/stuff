@echo off

rem Parameters
rem %1 server name
rem %2 db name
rem %3 SQL scripts root path

del /Q /S %3\%1\%2\*

@echo %date% %time%

call mssql-scripter -S %1 -d %2 -f %3\%1\%2 --file-per-object --exclude-use-database --display-progress --exclude-headers --exclude-schemas SQL# --exclude-types Synonym SqlAssembly

@echo %date% %time%

pushd %3\%1\%2

call %~dp0\pca-sql-schema-fix-files.bat StoredProcedure
call %~dp0\pca-sql-schema-fix-files.bat Table
call %~dp0\pca-sql-schema-fix-files.bat View
call %~dp0\pca-sql-schema-fix-files.bat User
call %~dp0\pca-sql-schema-fix-files.bat Schema
call %~dp0\pca-sql-schema-fix-files.bat SqlAssembly
call %~dp0\pca-sql-schema-fix-files.bat UserDefinedFunction
call %~dp0\pca-sql-schema-fix-files.bat UserDefinedAggregate
call %~dp0\pca-sql-schema-fix-files.bat UserDefinedDataType
call %~dp0\pca-sql-schema-fix-files.bat UserDefinedTableType

popd

@echo %date% %time%
