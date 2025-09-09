SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [$(DBName)];
GO
IF OBJECT_ID(N'[dbo].[vw_FileStat_DB_PctChange]', N'V') IS NOT NULL DROP VIEW [dbo].[vw_FileStat_DB_PctChange];
GO
CREATE VIEW [dbo].[vw_FileStat_DB_PctChange]
AS
SELECT
    capture_time,
    [Database Name],
    physical_name,
    [avg_io_latency_ms],
    100.0 * ([avg_io_latency_ms] - LAG([avg_io_latency_ms]) OVER (PARTITION BY [Database Name], physical_name ORDER BY capture_time))
      / NULLIF(LAG([avg_io_latency_ms]) OVER (PARTITION BY [Database Name], physical_name ORDER BY capture_time), 0) AS pct_change_latency
FROM dbo.FileStat_DB_History;
GO