
@echo %date% %time%

pushd %~dp0

call pca-sql-schema.bat awsql2019dev USAGG_DEV c:\pca\sql_schemas\mssql-scripter-2\
call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

call pca-sql-schema.bat awsql2019dev USALCO_FRQ_DEV c:\pca\sql_schemas\mssql-scripter-2\
call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

popd

@echo %date% %time%
