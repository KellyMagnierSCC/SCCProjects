SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [$(DBName)];
GO
IF OBJECT_ID(N'[dbo].[vw_FileStat_Drive_Delta]', N'V') IS NOT NULL DROP VIEW [dbo].[vw_FileStat_Drive_Delta];
GO
CREATE VIEW [dbo].[vw_FileStat_Drive_Delta]
AS
SELECT
    capture_time,
    [Volume Mount Point],
    [Read Latency],
    [Write Latency],
    [Overall Latency],
    [Avg Bytes/Read],
    [Avg Bytes/Write],
    [Avg Bytes/Transfer],
    [Read Latency] - LAG([Read Latency]) OVER (PARTITION BY [Volume Mount Point] ORDER BY capture_time) AS delta_read_latency,
    [Write Latency] - LAG([Write Latency]) OVER (PARTITION BY [Volume Mount Point] ORDER BY capture_time) AS delta_write_latency,
    [Overall Latency] - LAG([Overall Latency]) OVER (PARTITION BY [Volume Mount Point] ORDER BY capture_time) AS delta_overall_latency
FROM dbo.FileStat_Drive_History;
GO