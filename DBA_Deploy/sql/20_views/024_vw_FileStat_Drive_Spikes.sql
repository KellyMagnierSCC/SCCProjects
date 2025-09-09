SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [$(DBName)];
GO
IF OBJECT_ID(N'[dbo].[vw_FileStat_Drive_Spikes]', N'V') IS NOT NULL DROP VIEW [dbo].[vw_FileStat_Drive_Spikes];
GO
CREATE VIEW [dbo].[vw_FileStat_Drive_Spikes]
AS
SELECT TOP 100 PERCENT
    capture_time,
    [Volume Mount Point],
    [Overall Latency],
    [Overall Latency] - LAG([Overall Latency]) OVER (PARTITION BY [Volume Mount Point] ORDER BY capture_time) AS delta_latency
FROM dbo.FileStat_Drive_History
ORDER BY delta_latency DESC;
GO