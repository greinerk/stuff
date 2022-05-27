pushd C:\PCA\SqlSchema-USAgg\

Powershell.exe -executionpolicy remotesigned -File GenerateDbSchema.ps1 "(local)" "USAgg_Dev" "user" "password" "."

popd
