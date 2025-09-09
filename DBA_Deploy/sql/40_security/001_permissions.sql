USE [$(DBName)];
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_filemonitors')
BEGIN
    CREATE ROLE [db_filemonitors] AUTHORIZATION [dbo];
END
GO
GRANT SELECT ON OBJECT::[dbo].[vw_FileStat_DB_Current] TO [db_filemonitors];
GRANT SELECT ON OBJECT::[dbo].[vw_FileStat_Drive_Current] TO [db_filemonitors];
GRANT SELECT ON OBJECT::[dbo].[vw_FileStat_DB_Delta] TO [db_filemonitors];
GRANT SELECT ON OBJECT::[dbo].[vw_FileStat_Drive_Delta] TO [db_filemonitors];
GRANT SELECT ON OBJECT::[dbo].[vw_FileStat_DB_PctChange] TO [db_filemonitors];
GRANT SELECT ON OBJECT::[dbo].[vw_FileStat_Drive_PctChange] TO [db_filemonitors];
GRANT SELECT ON OBJECT::[dbo].[vw_FileStat_DB_RollingAvg] TO [db_filemonitors];
GRANT SELECT ON OBJECT::[dbo].[vw_FileStat_Drive_RollingAvg] TO [db_filemonitors];
GRANT SELECT ON OBJECT::[dbo].[vw_FileStat_DB_Spikes] TO [db_filemonitors];
GRANT SELECT ON OBJECT::[dbo].[vw_FileStat_Drive_Spikes] TO [db_filemonitors];
GRANT SELECT ON OBJECT::[dbo].[FileStat_DB_History] TO [db_filemonitors];
GRANT SELECT ON OBJECT::[dbo].[FileStat_Drive_History] TO [db_filemonitors];
GRANT EXECUTE ON OBJECT::[dbo].[Capture_FileStats_History] TO [db_filemonitors];
GO
-- NOTE: Querying DMVs used in the views requires VIEW SERVER STATE at server scope for the caller.
-- Run on the target instance (requires sysadmin):
-- USE [master];
-- GRANT VIEW SERVER STATE TO [<login_or_server_role>];
-- (Alternatively, run the SQL Agent job under a proxy/sysadmin and grant database access to readers.)