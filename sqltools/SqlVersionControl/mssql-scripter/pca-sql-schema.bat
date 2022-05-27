@echo off

rem Parameters
rem %1 server name
rem %2 db name
rem %3 SQL scripts root path

SET "server=%1"
SET "db=%2"
SET "scripts=%scripts%"

rem remove colons & slashes from servername (used for multiple instances on the same SQL Server)
SET "b=_"
SET "a=:"
CALL SET server=%%server:%a%=%b%%%
SET "a=\"
CALL SET server=%%server:%a%=%b%%%

del /Q /S %scripts%\%server%\%db%\*

@echo %date% %time%

call mssql-scripter -S %server% -d %db% -f %scripts%\%server%\%db% --file-per-object --exclude-use-database --display-progress --exclude-headers --exclude-schemas SQL# --exclude-types Synonym SqlAssembly

@echo %date% %time%

pushd %scripts%\%server%\%db%

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
