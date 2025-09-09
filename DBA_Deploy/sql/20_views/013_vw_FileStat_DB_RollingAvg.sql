SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [$(DBName)];
GO
IF OBJECT_ID(N'[dbo].[vw_FileStat_DB_RollingAvg]', N'V') IS NOT NULL DROP VIEW [dbo].[vw_FileStat_DB_RollingAvg];
GO
CREATE VIEW [dbo].[vw_FileStat_DB_RollingAvg]
AS
SELECT
    capture_time,
    [Database Name],
    physical_name,
    [avg_io_latency_ms],
    AVG([avg_io_latency_ms]) OVER (
        PARTITION BY [Database Name], physical_name
        ORDER BY capture_time
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS rolling_avg_io_latency
FROM dbo.FileStat_DB_History;
GO