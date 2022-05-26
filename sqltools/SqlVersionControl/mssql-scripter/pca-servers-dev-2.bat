
@echo %date% %time%

set curr_date=%date%
set curr_time=%time%

pushd %~dp0

call pca-sql-schema.bat awsql2019dev ABET_DEV c:\pca\sql_schemas\mssql-scripter-2\
call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

call pca-sql-schema.bat awsql2019dev AllianceAutoERP_Dev c:\pca\sql_schemas\mssql-scripter-2\
call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

call pca-sql-schema.bat awsql2019dev GlobalReserves_DEV c:\pca\sql_schemas\mssql-scripter-2\
call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

call pca-sql-schema.bat awsql2019dev JuniorAchievement_DEV c:\pca\sql_schemas\mssql-scripter-2\
call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

call pca-sql-schema.bat awsql2019dev OGTrustVisionSystem_DEV c:\pca\sql_schemas\mssql-scripter-2\
call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

call pca-sql-schema.bat awsql2019dev Printech_DEV c:\pca\sql_schemas\mssql-scripter-2\
call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

call pca-sql-schema.bat awsql2019dev Sephora_DEV c:\pca\sql_schemas\mssql-scripter-2\
call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

call pca-sql-schema.bat awsql2019dev TateBywater_DEV c:\pca\sql_schemas\mssql-scripter-2\
call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

call pca-sql-schema.bat awsql2019dev USAGG_DEV c:\pca\sql_schemas\mssql-scripter-2\
call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

call pca-sql-schema.bat awsql2019dev USALCO_FRQ_DEV c:\pca\sql_schemas\mssql-scripter-2\
call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

popd

@echo Started  %curr_date% %curr_time%
@echo Finished %date% %time%
