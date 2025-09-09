SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [$(DBName)];
GO
IF OBJECT_ID(N'[dbo].[vw_FileStat_Drive_PctChange]', N'V') IS NOT NULL DROP VIEW [dbo].[vw_FileStat_Drive_PctChange];
GO
CREATE VIEW [dbo].[vw_FileStat_Drive_PctChange]
AS
SELECT
    capture_time,
    [Volume Mount Point],
    [Overall Latency],
    100.0 * ([Overall Latency] - LAG([Overall Latency]) OVER (PARTITION BY [Volume Mount Point] ORDER BY capture_time))
      / NULLIF(LAG([Overall Latency]) OVER (PARTITION BY [Volume Mount Point] ORDER BY capture_time), 0) AS pct_change_latency
FROM dbo.FileStat_Drive_History;
GO