USE [DBA];
GO

--------------------------------------------------------------------------------
-- 1. View: Active Snapshot Transactions
-- Shows which sessions are running under RCSI/Snapshot, their elapsed time,
-- and which database they are working in.
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.vw_RCSI_ActiveTransactions') IS NOT NULL
    DROP VIEW dbo.vw_RCSI_ActiveTransactions;
GO

CREATE VIEW dbo.vw_RCSI_ActiveTransactions
AS
SELECT
    at.transaction_id,
    at.session_id,
    at.is_snapshot,
    at.elapsed_time_seconds,
    es.login_name,
    es.host_name,
    es.program_name,
    es.status,
    DB_NAME(dt.database_id) AS database_name
FROM sys.dm_tran_active_snapshot_database_transactions AS at
JOIN sys.dm_exec_sessions AS es
    ON at.session_id = es.session_id
JOIN sys.dm_tran_database_transactions AS dt
    ON at.transaction_id = dt.transaction_id;
GO

--------------------------------------------------------------------------------
-- 2. View: Version Store Usage by Database
-- Reports how much tempdb space (MB) each database is consuming for row versions.
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.vw_RCSI_VersionStoreUsage') IS NOT NULL
    DROP VIEW dbo.vw_RCSI_VersionStoreUsage;
GO

CREATE VIEW dbo.vw_RCSI_VersionStoreUsage
AS
SELECT
    DB_NAME(database_id) AS database_name,
    reserved_page_count * 8 / 1024.0 AS version_store_mb
FROM sys.dm_tran_version_store_space_usage;
GO

--------------------------------------------------------------------------------
-- 3. View: TempDB Space Breakdown
-- Summarises how tempdb is being used (user, internal, version store, free).
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.vw_RCSI_TempdbUsage') IS NOT NULL
    DROP VIEW dbo.vw_RCSI_TempdbUsage;
GO

CREATE VIEW dbo.vw_RCSI_TempdbUsage
AS
SELECT
    SUM(user_object_reserved_page_count) * 8 / 1024.0 AS mb_user_objects,
    SUM(internal_object_reserved_page_count) * 8 / 1024.0 AS mb_internal,
    SUM(version_store_reserved_page_count) * 8 / 1024.0 AS mb_version_store,
    SUM(unallocated_extent_page_count) * 8 / 1024.0 AS mb_free
FROM tempdb.sys.dm_db_file_space_usage;
GO
