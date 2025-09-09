SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [$(DBName)];
GO
IF OBJECT_ID(N'[dbo].[vw_FileStat_DB_Spikes]', N'V') IS NOT NULL DROP VIEW [dbo].[vw_FileStat_DB_Spikes];
GO
CREATE VIEW [dbo].[vw_FileStat_DB_Spikes]
AS
SELECT TOP 100 PERCENT
    capture_time,
    [Database Name],
    physical_name,
    [avg_io_latency_ms],
    [avg_io_latency_ms] - LAG([avg_io_latency_ms]) OVER (PARTITION BY [Database Name], physical_name ORDER BY capture_time) AS delta_latency
FROM dbo.FileStat_DB_History
ORDER BY delta_latency DESC;
GO