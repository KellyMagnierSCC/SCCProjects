SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [$(DBName)];
GO
IF OBJECT_ID(N'[dbo].[vw_WaitStats_RollingDelta]', N'V') IS NOT NULL DROP VIEW [dbo].[vw_WaitStats_RollingDelta];
GO
CREATE VIEW [dbo].[vw_WaitStats_RollingDelta]
AS
SELECT
    capture_time,
    wait_type,
    wait_time_ms,
    signal_wait_time_ms,
    waiting_tasks_count,
    wait_time_ms - LAG(wait_time_ms) OVER (PARTITION BY wait_type ORDER BY capture_time) AS delta_wait_time_ms,
    signal_wait_time_ms - LAG(signal_wait_time_ms) OVER (PARTITION BY wait_type ORDER BY capture_time) AS delta_signal_wait_time_ms,
    waiting_tasks_count - LAG(waiting_tasks_count) OVER (PARTITION BY wait_type ORDER BY capture_time) AS delta_waiting_tasks
FROM dbo.WaitStats_History;
GO