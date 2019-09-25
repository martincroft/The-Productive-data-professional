USE Master
GO
IF (
		SELECT OBJECT_ID('CPU_Usage')
		) IS NOT NULL
	DROP TABLE dbo.CPU_Usage

CREATE TABLE dbo.CPU_Usage (
	ID INT
	,ServerName NVARCHAR(128)
	,SQL_CPU_Utilization INT
	,System_Idle_Process INT
	,Other_Process_CPU_Utilization INT
	,ReportDate DATETIME
	)



DECLARE @StartDate DATETIME =GETDATE()
DECLARE @BusinessStartHours TIME ='10:00:00'
DECLARE @BusinessEndHours TIME ='16:00:00'
DECLARE @ServerProfile CHAR(4) ='LOW' --LOW, MED, HIGH



  ;WITH CTE_ROWS
  AS
  (
  SELECT 
	ROW_NUMBER() OVER (PARTITION BY (SELECT 1) ORDER BY (SELECT 1)) AS ID
	,DATEADD(minute,-ROW_NUMBER() OVER (PARTITION BY (SELECT 1) ORDER BY (SELECT 1)),@StartDate) AS ReportDate
	,CASE WHEN CAST(DATEADD(minute,-ROW_NUMBER() OVER (PARTITION BY (SELECT 1) ORDER BY (SELECT 1)),@StartDate) AS TIME) BETWEEN @BusinessStartHours AND @BusinessEndHours THEN  
	
			CASE WHEN @ServerProfile='HIGH' THEN ABS(CHECKSUM(NewId())) % 99  
				 WHEN @ServerProfile='MED' THEN ABS(CHECKSUM(NewId())) % 60 
				 WHEN @ServerProfile='LOW' THEN ABS(CHECKSUM(NewId())) % 20 +10
				 ELSE 0 
			END
			ELSE 
			ABS(CHECKSUM(NewId())) % 10 
	END AS SQL_CPU_Utilization
	,CASE WHEN CAST(DATEADD(minute,-ROW_NUMBER() OVER (PARTITION BY (SELECT 1) ORDER BY (SELECT 1)),@StartDate) AS TIME) BETWEEN @BusinessStartHours AND @BusinessEndHours THEN  
		CASE WHEN @ServerProfile='HIGH' THEN ABS(CHECKSUM(NewId())) % 20  
				 WHEN @ServerProfile='MED' THEN ABS(CHECKSUM(NewId())) % 40 
				 WHEN @ServerProfile='LOW' THEN ABS(CHECKSUM(NewId())) % 60+40 
				 ELSE 0
			END
		ELSE 
			ABS(CHECKSUM(NewId())) % 10 
	 END AS System_Idle_Process
	
FROM Master.dbo.sysobjects
CROSS JOIN sys.columns
  )


  INSERT INTO dbo.CPU_Usage
  (

  ID, ServerName, SQL_CPU_Utilization, System_Idle_Process, Other_Process_CPU_Utilization, ReportDate

)  
SELECT ID
	,@@Servername AS ServerName
	,SQL_CPU_Utilization
	,System_Idle_Process
	,CASE WHEN SQL_CPU_Utilization + System_Idle_Process > 100 THEN 0
	ELSE 100 - (System_Idle_Process+SQL_CPU_Utilization) END AS  Other_Process_CPU_Utilization 
	,DATEADD(MINUTE, DATEDIFF(MINUTE, 0, ReportDate), 0) ReportDate
	FROM CTE_ROWS
WHERE ID <= (
		SELECT 24 * 60 * 7 * 4
		)
ORDER BY ReportDate DESC


;WITH CTE_UPdate
AS
(

SELECT
ID, ABS(CHECKSUM(NewId())) % 79+20 AS [SQL_CPU_Utilization]

FROM [dbo].[CPU_Usage] U
WHERE 
		CASE WHEN @@SERVERNAME='Liverpool' THEN CAST(Reportdate AS TIME) END between '00:00:00' AND '01:00:00'
	OR
		CASE WHEN @@SERVERNAME='Leeds' THEN CAST(Reportdate AS TIME) END between '00:30:00' AND '01:30:00'
	OR
		CASE WHEN @@SERVERNAME='Manchester' THEN CAST(Reportdate AS TIME) END between '02:30:00' AND '01:30:00'
)

UPDATE U1
SET [SQL_CPU_Utilization] = C.SQL_CPU_Utilization
	,[System_Idle_Process] = 0
	,[Other_Process_CPU_Utilization] = 100 - C.SQL_CPU_Utilization
FROM CTE_UPdate C
JOIN [dbo].[CPU_Usage] U1 ON C.ID = U1.ID


SELECT * FROM [dbo].[CPU_Usage] U