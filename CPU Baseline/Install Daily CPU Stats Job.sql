USE master
GO


IF (SELECT OBJECT_ID('CPU_Usage')) IS NOT NULL 
BEGIN
	 SELECT TOP 1 * FROM CPU_Usage 
	  RaisError ('Table exists so exiting. Review', 20, 10) WITH LOG
END



IF (SELECT OBJECT_ID('CPU_Usage')) IS NOT NULL DROP TABLE CPU_Usage

CREATE TABLE CPU_Usage (
	ID INT IDENTITY(1,1),
	ServerName nvarchar(128),
	SQL_CPU_Utilization int,
	System_Idle_Process int,
	Other_Process_CPU_Utilization int,
	ReportDate datetime)


SET QUOTED_IDENTIFIER ON
-- Get CPU Utilization History for last 256 minutes (in one minute intervals)  (Query 44) (CPU Utilization History)
DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info WITH (NOLOCK)); 


;WITH  CTE_CPUHistory
AS
(

SELECT TOP(256) @@ServerName AS ServerName,SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               CAST(CAST(DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS CHAR(19))AS DATETIME) AS [ReportDate] 
FROM (SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
			AS [SystemIdle], 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') 
			AS [SQLProcessUtilization], [timestamp] 
	  FROM (SELECT [timestamp], CONVERT(xml, record) AS [record] 
			FROM sys.dm_os_ring_buffers WITH (NOLOCK)
			WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
			AND record LIKE N'%<SystemHealth>%') AS x) AS y 
ORDER BY record_id DESC 
)


INSERT INTO CPU_Usage (
	ServerName
	,SQL_CPU_Utilization
	,System_Idle_Process
	,Other_Process_CPU_Utilization
	,ReportDate
	)

SELECT 
	 CUH.ServerName
	,CUH.[SQL Server Process CPU Utilization]
	,CUH.[System Idle Process]
	,CUH.[Other Process CPU Utilization]
	,CUH.ReportDate 
FROM 
	CTE_CPUHistory CUH
LEFT JOIN 	
	CPU_Usage CU ON CUH.ServerName =CU.ServerName AND CUH.ReportDate=CU.ReportDate 
WHERE 
	CU.ID is NUll
ORDER BY ReportDate





USE [msdb]
GO

/****** Object:  Job [DBA Capture CPU Stats]    Script Date: 27/11/2018 09:43:14 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 27/11/2018 09:43:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Capture CPU Stats', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Capture CPU]    Script Date: 27/11/2018 09:43:17 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Capture CPU', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET QUOTED_IDENTIFIER ON

-- Get CPU Utilization History for last 256 minutes (in one minute intervals) 
DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info WITH (NOLOCK)); 


;WITH  CTE_CPUHistory
AS
(

SELECT TOP(256) @@ServerName AS ServerName,SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               CAST(CAST(DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS CHAR(19))AS DATETIME) AS [ReportDate] 
FROM (SELECT record.value(''(./Record/@id)[1]'', ''int'') AS record_id, 
			record.value(''(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]'', ''int'') 
			AS [SystemIdle], 
			record.value(''(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]'', ''int'') 
			AS [SQLProcessUtilization], [timestamp] 
	  FROM (SELECT [timestamp], CONVERT(xml, record) AS [record] 
			FROM sys.dm_os_ring_buffers WITH (NOLOCK)
			WHERE ring_buffer_type = N''RING_BUFFER_SCHEDULER_MONITOR'' 
			AND record LIKE N''%<SystemHealth>%'') AS x) AS y 
ORDER BY record_id DESC 
)


INSERT INTO CPU_Usage (
	ServerName
	,SQL_CPU_Utilization
	,System_Idle_Process
	,Other_Process_CPU_Utilization
	,ReportDate
	)

SELECT 
	 CUH.ServerName
	,CUH.[SQL Server Process CPU Utilization]
	,CUH.[System Idle Process]
	,CUH.[Other Process CPU Utilization]
	,CUH.ReportDate 
FROM 
	CTE_CPUHistory CUH
LEFT JOIN 	
	CPU_Usage CU ON CUH.ServerName =CU.ServerName AND CUH.ReportDate=CU.ReportDate 
WHERE 
	CU.ID is NUll

ORDER BY ReportDate
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 1 hour', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20181121, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'0cf83fa4-d006-4be0-a7c7-abe9ace359dc'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

SELECT @@Servername AS Servername