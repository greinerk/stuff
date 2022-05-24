
pushd %~dp0

call pca-sql-schema-by-type.bat awsql2019dev USAGG_DEV c:\pca\sql_schemas\mssql-scripter\
call pca-sql-schema-by-type.bat awsql2019dev USALCO_FRQ_DEV c:\pca\sql_schemas\mssql-scripter\

popd