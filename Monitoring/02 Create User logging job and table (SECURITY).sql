
IF NOT EXISTS (SELECT name from Master.dbo.sysobjects where name ='DBALoginMonitoring')
BEGIN
	CREATE TABLE Master.dbo.DBALoginMonitoring
	(
		ID INT IDENTITY(1,1),
		LoginName SYSNAME,
		HostName SYSNAME,
		ReportDate DATETIME,
		FailedLogin BIT DEFAULT(0)
	)
END 
ELSE
--Enhance to capture failed logins
IF (SELECT 1 FROM syscolumns WHERE ID =OBJECT_ID('DBALoginMonitoring') AND Name ='FailedLogin') IS NULL
BEGIN
	ALTER TABLE Master.dbo.DBALoginMonitoring ADD FailedLogin BIT DEFAULT(0) WITH VALUES
END


USE [msdb]
GO

IF EXISTS (SELECT 1 FROM sysjobs WHERE name =N'DBA Logging Monitoring Job')
BEGIN
	EXEC msdb.dbo.sp_delete_job @job_name=N'DBA Logging Monitoring Job'
END 
GO

/****** Object:  Job [DBA Logging Monitoring Job]    Script Date: 18/03/2019 10:19:29 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 18/03/2019 10:19:29 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Logging Monitoring Job', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Job to capture logins from blackbox trace for users loggining for analysis of SQL 2008 R2 upgrades/Decommissioning', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Capture logins]    Script Date: 18/03/2019 10:19:30 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Capture logins', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--==========================================================================
--Check blackbox / other SQL trace
--==========================================================================



DECLARE @TraceIDToReview int
DECLARE @path varchar(255)

SET @TraceIDToReview = 1
--this is the trace you want to review!
SELECT @path = path
from sys.traces
WHERE id = @TraceIDToReview


;WITH
    CTE_Blackbox
    AS
    (
        SELECT DISTINCT
        T.LoginName, COALESCE(T.HostName,''UNKNOWN'') AS HostName
		,EventClass
		,Starttime AS ReportDate
        FROM ::fn_trace_gettable(@path, default) T
            LEFT OUTER JOIN sys.trace_events TE ON T.EventClass = TE.trace_event_id
            LEFT OUTER JOIN sys.trace_subclass_values V
            ON T.EventClass = V.trace_event_id AND T.EventSubClass = V.subclass_value
        WHERE T.loginName iS NOT NULL
    )

INSERT INTO Master.dbo.DBALoginMonitoring
   (
       LoginName,
       HostName,
       ReportDate,
	   FailedLogin
   )

SELECT distinct
    b.LoginName,
    COALESCE(b.HostName,@@ServerName) AS HostName,
    GETDATE() AS ReportDate,
	0 AS FailedLogin

FROM CTE_blackbox b
    LEFT JOIN dbo.DBALoginMonitoring l ON b.loginname =l.loginname and  b.hostname =l.hostname
WHERE 
     l.loginname IS NULL AND l.hostname IS NULL AND EventClass!=20 

UNION 


SELECT distinct
    b.LoginName,
    COALESCE(b.HostName,@@ServerName) AS HostName,
    b.ReportDate,
	1  AS FailedLogin
	
FROM CTE_blackbox b
    LEFT JOIN dbo.DBALoginMonitoring l ON b.loginname =l.loginname and  b.hostname =l.hostname and b.ReportDate = l.ReportDate
WHERE 1=1
AND Eventclass =20

  AND  (l.reportdate IS NULL or b.loginname IS NULL) ', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily Hourly Scheduled', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20190318, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'89d9b3e4-b417-4ea6-bc4c-7152a99b96ec'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


EXEC MSDB.dbo.sp_start_job 'DBA Logging Monitoring Job'

GO




