
--=====================================================
--#8 Check if Enterprise features being used
--=====================================================
SELECT feature_name FROM sys.dm_db_persisted_sku_features;  

EXEC sp_MSForeachDB 'USE [?] SELECT db_name() AS dbname, feature_name FROM sys.dm_db_persisted_sku_features;  '

--or 
DROP TABLE IF EXISTS #Results
CREATE TABLE #Results(DbName VARCHAR(60),Feature_name VARCHAR(100)); 
EXEC sp_MSForeachDB 'USE [?] INSERT INTO #Results (dbname,Feature_name) SELECT db_name() AS dbname, feature_name FROM sys.dm_db_persisted_sku_features;  '
SELECT * FROM #Results


