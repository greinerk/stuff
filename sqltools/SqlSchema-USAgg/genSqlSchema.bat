@echo off
Powershell.exe -executionpolicy remotesigned -File "C:\PCA\SqlSchema-USAgg\genSqlSchema-USAgg.ps1" "(local)" "USAgg_Dev" ".\USAgg_Dev"  >> SqlSchema_log.txt 2>&1
IF ERRORLEVEL 1 EXIT 1
