DECLARE @cmd VARCHAR(MAX)
SET @cmd = ''
CREATE TABLE #DimensionStat([Database] SYSNAME, [Dimension] SYSNAME, [Attribute] SYSNAME, [Count] BIGINT)
CREATE TABLE #Dimensions([ObjectParentPath] VARCHAR(MAX), [Dimension] VARCHAR(128), [Start] INT, [Finish] INT, [Database] VARCHAR(128))
INSERT INTO #Dimensions ([ObjectParentPath], [Dimension]) SELECT * FROM OPENQUERY([LinkedServerName], 'SELECT DISTINCT [OBJECT_PARENT_PATH], [OBJECT_ID] FROM [$SYSTEM].[DISCOVER_OBJECT_ACTIVITY]')
DELETE FROM #Dimensions WHERE [ObjectParentPath] NOT LIKE CHAR(37)+'.Dimensions'
UPDATE #Dimensions SET [Start] = CHARINDEX('.Databases.', [ObjectParentPath])+11
UPDATE #Dimensions SET [Finish] = CHARINDEX('.', [ObjectParentPath], [Start])
UPDATE #Dimensions SET [Database] = SUBSTRING([ObjectParentPath], [Start], [Finish]-[Start])
SELECT @cmd = @cmd + 'INSERT #DimensionStat EXEC (''SELECT * FROM OPENQUERY([LinkedServerName], ''''SELECT * FROM SYSTEMRESTRICTSCHEMA([$SYSTEM].[DISCOVER_DIMENSION_STAT],[DATABASE_NAME]='''''''''+[Database]+''''''''',[DIMENSION_NAME]='''''''''+[Dimension]+''''''''')'''')'');'
  FROM #Dimensions
EXEC (@cmd)
SELECT [d].[Database], [d].[Dimension], [ds].[Attribute], [ds].[Count]
  FROM #Dimensions [d]
LEFT JOIN #DimensionStat [ds] ON [ds].[Database] = [d].[Database] AND [ds].[Dimension] = [d].[Dimension]
ORDER BY [Database], [Dimension], [Attribute]
DROP TABLE #Dimensions
DROP TABLE #DimensionStat
