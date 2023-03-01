-- create table with only the names of databases that are published
SELECT 
name as databasename
INTO #alldatabases
FROM sys.databases WHERE database_id > 4
CREATE TABLE #alltablesizes(
servername sysname,
databasename sysname,
schemaName sysname,
tablename sysname,
rowcounts INT,
totalspaceKB DECIMAL(18,2),
usedspaceKB DECIMAL(18,2),
unusedspaceKB DECIMAL(18,2),
captureddatetime datetime
  );
DECLARE @command VARCHAR(MAX);
-- run the below code to get table count from all the databases 
SET @command = '
USE [?]
IF DB_NAME() IN (SELECT databasename FROM #alldatabases)
BEGIN
INSERT #alltablesizes
SELECT 
@@servername as servername,
db_name() as databasename,    
    s.name AS schemaname,
t.name AS tablename,
    p.rows AS rowcounts,
    SUM(a.total_pages) * 8 AS totalspaceKB, 
    SUM(a.used_pages) * 8 AS usedspaceKB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS unusedspaceKB,
getdate() as captureddatetime
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.NAME NOT LIKE ''dt%'' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
--and t.name =''XXXX'' ---- replace the XXXX with table name
GROUP BY 
t.name, s.name, p.Rows
END';
EXEC sp_MSforeachdb @command
select * from #alltablesizes
order by 5 desc
drop table #alltablesizes
drop table #alldatabases
