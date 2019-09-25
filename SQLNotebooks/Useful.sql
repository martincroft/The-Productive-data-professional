
--#1 SQL Server Installation Date
--#1b SQL Server Installation Date (works on SQL 2000)
--#2 top 10 tables with tablename entire db
--#3 Page life expectancy
--#4 SQL Memory
--#5 Versions from Product version
--#6 Split out servername from INstance name
--#7 Simple Data Dictionary extednded properties for all columns on  table
--#8 Check if Enterprise features being used

--#101 MAX CPU

-- Server level queries ***


-- SQL and OS Version information for current instance (Query 1) (Version Info)
SELECT @@SERVERNAME AS [Server Name], @@VERSION AS [SQL Server and OS Version Info];
------


-- Date SQL was installed ![Installation](file:///C://SQLServerSolutions/Installation.jpg) (Query 2) (SQL Server Installation Date)
SELECT create_date
FROM sys.server_principals
WHERE sid = 0x010100000000000512000000;
------


-- Date SQL was installed for different SQL versions (Query 3) (SQL Server Versions Installation Date)
DECLARE @SQLServerInstanceVersion INT
SELECT  @SQLServerInstanceVersion=FLOOR(SUBSTRING(CAST(SERVERPROPERTY('ProductVersion')AS VARCHAR(10)),1,4)) 

SELECT @SQLServerInstanceVersion

IF @SQLServerInstanceVersion < 10 
BEGIN 
	SELECT  @@servername AS servername,CONVERT(DATETIME, createdate, 103) AS create_date FROM syslogins 
	WHERE   name = 'sa'
END
ELSE
BEGIN
	SELECT  @@ServerName as ServerName,CONVERT(DATETIME, create_date, 103) AS create_date FROM sys.server_principals WHERE sid = 0x010100000000000512000000
END;
------


-- List top 10 rows from all tables with tablename (Query 4) (Top Ten tables with tablename entireDB)
EXEC sp_msforeachtable "SELECT top 10 * FROM ?; SELECT '?'";
------


-- Page Life Expectanct ![Installation](file:///C://SQLServerSolutions/memory.jpg) (Query 5) (PLE)
SELECT [object_name],
[counter_name],
[cntr_value] FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Manager%'
AND [counter_name] = 'Page life expectancy';
------


-- Memory queries (Query 6) (Find Production version code)
GO
DECLARE @SQLServerInstanceVersion INT
SELECT  @SQLServerInstanceVersion=FLOOR(SUBSTRING(CAST(SERVERPROPERTY('ProductVersion')AS VARCHAR(10)),1,4)) 

SELECT CASE
			WHEN @SQLServerInstanceVersion ='14' THEN 'SQL Server 2017' 
			WHEN @SQLServerInstanceVersion ='13' THEN 'SQL Server 2016'  
			WHEN @SQLServerInstanceVersion ='12' THEN 'SQL Server 2014'  
			WHEN @SQLServerInstanceVersion ='11' THEN 'SQL Server 2012'  
			WHEN @SQLServerInstanceVersion ='10' THEN 'SQL Server 2008 R2'  
			WHEN @SQLServerInstanceVersion ='10' THEN 'SQL Server 2008'   
			WHEN @SQLServerInstanceVersion ='9' THEN 'SQL Server 2005'   
			WHEN @SQLServerInstanceVersion ='8' THEN 'SQL Server 2000'   
		END AS Version;
------

-- Check if Enterprise features in use (Query 7) (Enterprise Features)

SELECT feature_name FROM sys.dm_db_persisted_sku_features;  

EXEC sp_MSForeachDB 'USE [?] SELECT db_name() AS dbname, feature_name FROM sys.dm_db_persisted_sku_features;  '
------

-- Date SQL was installed (Query 8) (Split out Server / Instance Name)
SELECT 
	CASE 
		WHEN CHARINDEX('\', SQLServerInstance) = 0 THEN SQLServerInstance
		ELSE SUBSTRING(SQLServerInstance, 0, CHARINDEX('\', SQLServerInstance))
	END AS ServerName;

------

-- Date SQL was started ![calendar](file:///C://SQLServerSolutions/calendar.jpg)  (Query 9) (SQL Server Start Date)
select login_time from master.dbo.sysprocesses
where spid =1
------
