C:
CD \PCA\SqlSchema-USAgg\

call genSqlSchema.bat "(local)" "USAgg_Dev" "C:\PCA\SqlSchema-USAgg\USAgg_Dev"
if ERRORLEVEL NEQ 0 EXIT 1

call CommitDbSchemaVSTS.bat
if ERRORLEVEL NEQ 0 EXIT 1
