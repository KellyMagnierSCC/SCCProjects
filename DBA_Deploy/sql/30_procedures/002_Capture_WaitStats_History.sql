SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [$(DBName)];
GO
CREATE OR ALTER PROCEDURE [dbo].[Capture_WaitStats_History]
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.WaitStats_History (
        capture_time,
        wait_type,
        waiting_tasks_count,
        wait_time_ms,
        max_wait_time_ms,
        signal_wait_time_ms
    )
    SELECT
        SYSDATETIME() AS capture_time,
        wait_type,
        waiting_tasks_count,
        wait_time_ms,
        max_wait_time_ms,
        signal_wait_time_ms
    FROM dbo.vw_WaitStats_Current;
END
GO