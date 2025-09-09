:setvar DBName "DBA"
:setvar JobName "Capture WaitStats History"
:setvar ScheduleName "Every 15 minutes"
:setvar JobOwner "sa"

USE [msdb];
GO

DECLARE @schedId INT;
SELECT @schedId = schedule_id FROM msdb.dbo.sysschedules WHERE name = N'$(ScheduleName)';

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'$(JobName)')
BEGIN
    DECLARE @jobId BINARY(16);
    EXEC msdb.dbo.sp_add_job @job_name=N'$(JobName)',
        @enabled=1,
        @description=N'Captures sys.dm_os_wait_stats into $(DBName).dbo.WaitStats_History',
        @owner_login_name=N'$(JobOwner)',
        @job_id=@jobId OUTPUT;

    EXEC msdb.dbo.sp_add_jobstep @job_name=N'$(JobName)', @step_name=N'Capture WaitStats',
        @subsystem=N'TSQL',
        @command=N'EXEC ['+REPLACE('$(DBName)',']',']]')+'].[dbo].[Capture_WaitStats_History];',
        @database_name=N'$(DBName)',
        @retry_attempts=3,
        @retry_interval=5;

    IF @schedId IS NULL
    BEGIN
        EXEC msdb.dbo.sp_add_schedule @schedule_name=N'$(ScheduleName)',
            @enabled=1,
            @freq_type=4, -- daily
            @freq_interval=1,
            @freq_subday_type=4, -- minutes
            @freq_subday_interval=15,
            @active_start_time=000000; -- start immediately
        SELECT @schedId = schedule_id FROM msdb.dbo.sysschedules WHERE name = N'$(ScheduleName)';
    END

    EXEC msdb.dbo.sp_attach_schedule @job_name=N'$(JobName)', @schedule_id=@schedId;
    EXEC msdb.dbo.sp_add_jobserver @job_name=N'$(JobName)';
END
ELSE
BEGIN
    PRINT 'Job $(JobName) already exists - skipping creation.';
END
GO