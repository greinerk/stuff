
pushd %~dp0

call mssql-scripter awsql2019dev USAGG_DEV c:\pca\sql_schemas\mssql-scripter\
call mssql-scripter awsql2019dev USALCO_FRQ_DEV c:\pca\sql_schemas\mssql-scripter\

popd