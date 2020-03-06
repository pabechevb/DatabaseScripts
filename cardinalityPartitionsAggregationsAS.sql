DECLARE @cmd VARCHAR(MAX)
SET @cmd = ''
CREATE TABLE #PartitionStat([Database] SYSNAME, [Cube] SYSNAME, [MeasureGroup] SYSNAME, [Partition] SYSNAME, [Aggregation] VARCHAR(128), [Size] BIGINT)
CREATE TABLE #Partitions ([ObjectParentPath] VARCHAR(MAX), [Partition] VARCHAR(128), [Start] INT, [Finish] INT, [Database] VARCHAR(128), [Cube] VARCHAR(128), [MeasureGroup] VARCHAR(128))
INSERT INTO #Partitions ([ObjectParentPath], [Partition]) SELECT * FROM OPENQUERY([LinkedServerName], 'SELECT DISTINCT [OBJECT_PARENT_PATH], [OBJECT_ID] FROM [$SYSTEM].[DISCOVER_OBJECT_ACTIVITY]')
DELETE FROM #Partitions WHERE [ObjectParentPath] NOT LIKE CHAR(37)+'.Partitions'
UPDATE #Partitions SET [Start] = CHARINDEX('.Databases.', [ObjectParentPath])+11
UPDATE #Partitions SET [Finish] = CHARINDEX('.', [ObjectParentPath], [Start])
UPDATE #Partitions SET [Database] = SUBSTRING([ObjectParentPath], [Start], [Finish]-[Start])
UPDATE #Partitions SET [Start] = CHARINDEX('.Cubes.', [ObjectParentPath])+7
UPDATE #Partitions SET [Finish] = CHARINDEX('.', [ObjectParentPath], [Start])
UPDATE #Partitions SET [Cube] = SUBSTRING([ObjectParentPath], [Start], [Finish]-[Start])
UPDATE #Partitions SET [Start] = CHARINDEX('.Measure Groups.', [ObjectParentPath])+16
UPDATE #Partitions SET [Finish] = CHARINDEX('.', [ObjectParentPath], [Start])
UPDATE #Partitions SET [MeasureGroup] = SUBSTRING([ObjectParentPath], [Start], [Finish]-[Start])
SELECT @cmd = @cmd + 'INSERT #PartitionStat EXEC (''SELECT * FROM OPENQUERY([LinkedServerName], ''''SELECT * FROM SYSTEMRESTRICTSCHEMA([$SYSTEM].[DISCOVER_PARTITION_STAT],[DATABASE_NAME]='''''''''+[Database]+''''''''',[CUBE_NAME]='''''''''+[Cube]+''''''''',[MEASURE_GROUP_NAME]='''''''''+[MeasureGroup]+''''''''',[PARTITION_NAME]='''''''''+[Partition]+''''''''')'''')'');'
  FROM #Partitions
EXEC (@cmd)
SELECT [p].[Database], [p].[Cube], [p].[MeasureGroup], [p].[Partition], [ps].[Aggregation], [ps].[Size]
  FROM #Partitions [p]
LEFT JOIN #PartitionStat [ps] ON [ps].[Database] = [p].[Database] AND [ps].[Cube] = [p].[Cube] AND [ps].[MeasureGroup] = [p].[MeasureGroup] AND [ps].[Partition] = [p].[Partition]
ORDER BY [Database], [Cube], [MeasureGroup], [Partition], [Aggregation]
DROP TABLE #Partitions
DROP TABLE #PartitionStat
