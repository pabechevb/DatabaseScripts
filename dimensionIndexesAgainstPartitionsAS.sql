DECLARE @cmd VARCHAR(MAX)
SET @cmd = ''
CREATE TABLE #PartitionDimensionStat([Database] SYSNAME, [Cube] SYSNAME, [MeasureGroup] SYSNAME, [Partition] SYSNAME, [Dimension] SYSNAME, [Attribute] SYSNAME, [Indexed] INT, [CountMin] INT, [CountMax] INT)
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
SELECT @cmd = @cmd + 'INSERT #PartitionDimensionStat EXEC (''SELECT * FROM OPENQUERY([LinkedServerName], ''''SELECT * FROM SYSTEMRESTRICTSCHEMA([$SYSTEM].[DISCOVER_PARTITION_DIMENSION_STAT],[DATABASE_NAME]='''''''''+[Database]+''''''''',[CUBE_NAME]='''''''''+[Cube]+''''''''',[MEASURE_GROUP_NAME]='''''''''+[MeasureGroup]+''''''''',[PARTITION_NAME]='''''''''+[Partition]+''''''''')'''')'');'
  FROM #Partitions
EXEC (@cmd)
SELECT [p].[Database], [p].[Cube], [p].[MeasureGroup], [p].[Partition], [pds].[Dimension], [pds].[Attribute], [pds].[Indexed], [pds].[CountMin], [pds].[CountMax]
  FROM #Partitions [p]
LEFT JOIN #PartitionDimensionStat [pds] ON [pds].[Database] = [p].[Database] AND [pds].[Cube] = [p].[Cube] AND [pds].[MeasureGroup] = [p].[MeasureGroup] AND [pds].[Partition] = [p].[Partition]
ORDER BY [Database], [Cube], [MeasureGroup], [Partition], [Dimension], [Attribute]
DROP TABLE #Partitions
DROP TABLE #PartitionDimensionStat
