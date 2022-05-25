mkdir %1s
move *.%1.sql %1s
powershell -Command "Get-ChildItem -Filter '*.%1.sql' -Recurse | Rename-Item -NewName {$_.name -replace '.%1.sql','.sql' }"