
IF EXISTS (SELECT 1 FROM MSDB.dbo.sysjobs WHERE name =N'DBA Logging Monitoring Job')
BEGIN
	EXEC msdb.dbo.sp_delete_job @job_name=N'DBA Logging Monitoring Job'
END 
GO

DROP TABLE IF EXISTS Master.dbo.DBALoginMonitoring