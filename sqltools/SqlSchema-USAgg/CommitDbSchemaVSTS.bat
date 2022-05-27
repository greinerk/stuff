pushd C:\PCA\SqlSchema-USAgg\
git add -A >> SqlSchema_log.txt 2>&1
git config --global core.safecrlf false
git commit -m "auto-commit by CommitDbSchemaVSTS.bat" >> SqlSchema_log.txt 2>&1
git push origin master >> SqlSchema_log.txt 2>&1
popd
