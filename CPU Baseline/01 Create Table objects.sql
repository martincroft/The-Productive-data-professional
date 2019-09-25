USE Reports
GO

IF (
		SELECT Object_ID('MasterServerDetails')
		) IS NOT NULL
	DROP TABLE MasterServerDetails

CREATE TABLE MasterServerDetails (
	ID INT IDENTITY(1, 1)
	,SQLServerInstanceName VARCHAR(30)
	,CPULoggingInstalled BIT DEFAULT(0)
	,LoggingInstalled BIT DEFAULT(0)
	)
GO

INSERT INTO MasterServerDetails (
	SQLServerInstanceName
	,CPULoggingInstalled
	,LoggingInstalled
)
VALUES (
	'Glasgow'
	,1
	,1

	)

INSERT INTO MasterServerDetails (
	SQLServerInstanceName
	,CPULoggingInstalled
	,LoggingInstalled

	)
VALUES (
	'Edinburgh'
	,1
	,1

	)

INSERT INTO MasterServerDetails (
	SQLServerInstanceName
	,CPULoggingInstalled
	,LoggingInstalled

	)
VALUES (
	'Manchester'
	,1
	,1
	)
GO

IF (
		SELECT NAME
		FROM Sys.schemas
		WHERE NAME = 'Staging'
		) IS NULL
	EXEC ('CREATE Schema Staging')
GO

IF (
		SELECT OBJECT_ID('Staging.CPU_Usage')
		) IS NOT NULL
	DROP TABLE Staging.CPU_Usage

CREATE TABLE [Staging].[CPU_Usage](
	[ServerName] [nvarchar](128) NULL,
	[SQL_CPU_Utilization] [int] NULL,
	[System_Idle_Process] [int] NULL,
	[Other_Process_CPU_Utilization] [int] NULL,
	[ReportDate] VARCHAR(30) NULL
) ON [PRIMARY]
GO
GO

IF (
		SELECT OBJECT_ID('CPU_Usage')
		) IS NOT NULL
	DROP TABLE dbo.CPU_Usage

CREATE TABLE dbo.CPU_Usage (
	ID INT IDENTITY(1, 1)
	,ServerName NVARCHAR(128)
	,SQL_CPU_Utilization INT
	,System_Idle_Process INT
	,Other_Process_CPU_Utilization INT
	,ReportDate DATETIME
	)
GO



SELECT * FROM MasterServerDetails
EXEC sp_tables

SELECT *
FROM staging.CPU_Usage

SELECT *
FROM dbo.CPU_Usage