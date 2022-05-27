@echo off

echo %date% %time%

set curr_date=%date%
set curr_time=%time%

pushd %~dp0

rem AWSQL2019DEV

rem call pca-sql-schema.bat awsql2019dev ABET_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev AllianceAutoERP_Dev c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev GlobalReserves_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev JuniorAchievement_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev OGTrustVisionSystem_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev Printech_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev Sephora_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev TateBywater_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev USAGG_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev USALCO_FRQ_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

rem AWSQL2019DEV/1434

call pca-sql-schema.bat awsql2019dev\sql2016 AccuTech_DEV c:\pca\sql_schemas\mssql-scripter-2\
call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev_sql2016

rem call pca-sql-schema.bat awsql2019dev:1434 ASIFieldTracker_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev:1434 CMCERMS_DEV_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev:1434 MarshCoverageMaster_Dev c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev:1434 MFACAdvantage_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev:1434 Orgill_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev:1434 PCA_Dev c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev:1434 PCAProjectTemplate_Dev c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev:1434 PCASQLAudit_DEV c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev
rem 
rem call pca-sql-schema.bat awsql2019dev:1434 UnionTankCar_Dev c:\pca\sql_schemas\mssql-scripter-2\
rem call git-update.bat c:\pca\sql_schemas\mssql-scripter-2\awsql2019dev

popd

@echo Started  %curr_date% %curr_time%
@echo Finished %date% %time%
