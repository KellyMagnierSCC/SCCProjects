USE [$(DBName)];
GO
-- Reuse db_filemonitors role created by earlier script
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_filemonitors')
BEGIN
    CREATE ROLE [db_filemonitors] AUTHORIZATION [dbo];
END
GO
GRANT SELECT ON OBJECT::[dbo].[WaitStats_History] TO [db_filemonitors];
GRANT SELECT ON OBJECT::[dbo].[vw_WaitStats_Current] TO [db_filemonitors];
GRANT SELECT ON OBJECT::[dbo].[vw_WaitStats_RollingDelta] TO [db_filemonitors];
GRANT EXECUTE ON OBJECT::[dbo].[Capture_WaitStats_History] TO [db_filemonitors];
GO
-- NOTE: Access to sys.dm_os_wait_stats needs VIEW SERVER STATE at server scope for the caller.