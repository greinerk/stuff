@echo off

rem Parameters
rem %1 server name
rem %2 db name
rem %3 SQL scripts root path

call mssql-scripter -S %1 -d %2 -f %3\%1\%2 --file-per-object --exclude-use-database --display-progress --exclude-headers --exclude-schemas SQL# --include-types StoredProcedure Table UserDefinedAggregate UserDefinedDataType UserDefinedFunction UserDefinedTableTypes UserDefinedType View

pushd %3\%1\%2

mkdir UserDefinedFunctions
move *.UserDefinedFunction.sql UserDefinedFunctions

mkdir StoredProcedures
move *.StoredProcedure.sql StoredProcedures

mkdir Tables
move *.Table.sql Tables

mkdir UserDefinedDataTypes
move *.UserDefinedDataType.sql UserDefinedDataTypes

mkdir Views
move *.View.sql Views

mkdir UserDefinedTableTypes
move *.UserDefinedTableType.sql UserDefinedTableTypes

mkdir UserDefinedAggregates
move *.UserDefinedAggregate.sql UserDefinedAggregates

popd
