USE [DBA];
GO

/*=========================================================
  1. History Tables
=========================================================*/

IF OBJECT_ID('dbo.RCSI_ActiveTransactions_History') IS NOT NULL
    DROP TABLE dbo.RCSI_ActiveTransactions_History;
GO
CREATE TABLE dbo.RCSI_ActiveTransactions_History
(
    capture_time DATETIME2 NOT NULL DEFAULT getdate(),
    transaction_id BIGINT,
    session_id INT,
    is_snapshot BIT,
    elapsed_time_seconds BIGINT,
    login_name SYSNAME,
    host_name SYSNAME,
    program_name NVARCHAR(256),
    status NVARCHAR(30),
    database_name SYSNAME
);
GO

IF OBJECT_ID('dbo.RCSI_VersionStoreUsage_History') IS NOT NULL
    DROP TABLE dbo.RCSI_VersionStoreUsage_History;
GO
CREATE TABLE dbo.RCSI_VersionStoreUsage_History
(
    capture_time DATETIME2 NOT NULL DEFAULT getdate(),
    database_name SYSNAME,
    version_store_mb DECIMAL(18,2)
);
GO

IF OBJECT_ID('dbo.RCSI_TempdbUsage_History') IS NOT NULL
    DROP TABLE dbo.RCSI_TempdbUsage_History;
GO
CREATE TABLE dbo.RCSI_TempdbUsage_History
(
    capture_time DATETIME2 NOT NULL DEFAULT getdate(),
    mb_user_objects DECIMAL(18,2),
    mb_internal DECIMAL(18,2),
    mb_version_store DECIMAL(18,2),
    mb_free DECIMAL(18,2)
);
GO

/*=========================================================
  2. Stored Procedure: Capture Snapshot
=========================================================*/

IF OBJECT_ID('dbo.Capture_RCSI_Snapshot') IS NOT NULL
    DROP PROCEDURE dbo.Capture_RCSI_Snapshot;
GO

CREATE PROCEDURE dbo.Capture_RCSI_Snapshot
AS
BEGIN
    SET NOCOUNT ON;

    -- Active transactions
    INSERT INTO dbo.RCSI_ActiveTransactions_History
    (
        transaction_id, session_id, is_snapshot, elapsed_time_seconds,
        login_name, host_name, program_name, status, database_name
    )
    SELECT
        at.transaction_id,
        at.session_id,
        at.is_snapshot,
        at.elapsed_time_seconds,
        es.login_name,
        es.host_name,
        es.program_name,
        es.status,
        DB_NAME(dt.database_id)
    FROM sys.dm_tran_active_snapshot_database_transactions AS at
    JOIN sys.dm_exec_sessions AS es
        ON at.session_id = es.session_id
    JOIN sys.dm_tran_database_transactions AS dt
        ON at.transaction_id = dt.transaction_id;

    -- Version store usage
    INSERT INTO dbo.RCSI_VersionStoreUsage_History (database_name, version_store_mb)
    SELECT
        DB_NAME(database_id),
        reserved_page_count * 8 / 1024.0
    FROM sys.dm_tran_version_store_space_usage;

    -- Tempdb usage
    INSERT INTO dbo.RCSI_TempdbUsage_History (mb_user_objects, mb_internal, mb_version_store, mb_free)
    SELECT
        SUM(user_object_reserved_page_count) * 8 / 1024.0,
        SUM(internal_object_reserved_page_count) * 8 / 1024.0,
        SUM(version_store_reserved_page_count) * 8 / 1024.0,
        SUM(unallocated_extent_page_count) * 8 / 1024.0
    FROM tempdb.sys.dm_db_file_space_usage;
END;
GO

/*=========================================================
  3. SQL Agent Job (runs every 10 mins)
=========================================================*/
USE [msdb];
GO

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'DBA_Capture RCSI Snapshot')
BEGIN
    EXEC sp_add_job
        @job_name = N'DBA_Capture RCSI Snapshot',
        @enabled = 1,
        @description = N'Collects RCSI and TempDB metrics into DBA history tables.';

    EXEC sp_add_jobstep
        @job_name = N'DBA_Capture RCSI Snapshot',
        @step_name = N'Run Capture',
        @subsystem = N'TSQL',
        @database_name = N'DBA',
        @command = N'EXEC dbo.Capture_RCSI_Snapshot;',
        @on_success_action = 1;

    EXEC sp_add_schedule
        @schedule_name = N'Every 10 minutes',
        @freq_type = 4,               -- daily
        @freq_interval = 1,
        @freq_subday_type = 4,        -- minutes
        @freq_subday_interval = 10,   -- every 10 minutes
        @active_start_time = 0;       -- midnight

    EXEC sp_attach_schedule
        @job_name = N'DBA_Capture RCSI Snapshot',
        @schedule_name = N'Every 10 minutes';

    EXEC sp_add_jobserver
        @job_name = N'DBA_Capture RCSI Snapshot';
END;
GO



