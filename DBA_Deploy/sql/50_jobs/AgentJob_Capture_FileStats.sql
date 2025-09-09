:setvar DBName "DBA"
:setvar JobName "Capture FileStats History"
:setvar ScheduleName "Every 15 minutes"
:setvar JobOwner "sa"

USE [msdb];
GO
DECLARE @jobId BINARY(16);

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'$(JobName)')
BEGIN
    EXEC msdb.dbo.sp_add_job @job_name=N'$(JobName)',
        @enabled=1,
        @description=N'Captures file & drive IO stats into $(DBName) history tables',
        @owner_login_name=N'$(JobOwner)',
        @notify_level_eventlog=0,
        @job_id=@jobId OUTPUT;

    EXEC msdb.dbo.sp_add_jobstep @job_name=N'$(JobName)', @step_name=N'Capture',
        @subsystem=N'TSQL',
        @command=N'EXEC ['+REPLACE('$(DBName)',']',']]')+'].[dbo].[Capture_FileStats_History];',
        @database_name=N'$(DBName)',
        @retry_attempts=3,
        @retry_interval=5;

    EXEC msdb.dbo.sp_add_schedule @schedule_name=N'$(ScheduleName)',
        @enabled=1,
        @freq_type=4, -- daily
        @freq_interval=1,
        @freq_subday_type=4, -- minutes
        @freq_subday_interval=15,
        @active_start_time=000000; -- start immediately

    EXEC msdb.dbo.sp_attach_schedule @job_name=N'$(JobName)', @schedule_name=N'$(ScheduleName)';
    EXEC msdb.dbo.sp_add_jobserver @job_name=N'$(JobName)';
END
ELSE
BEGIN
    PRINT 'Job $(JobName) already exists - skipping creation.';
END
GO