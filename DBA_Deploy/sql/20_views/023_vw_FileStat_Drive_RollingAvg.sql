SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [$(DBName)];
GO
IF OBJECT_ID(N'[dbo].[vw_FileStat_Drive_RollingAvg]', N'V') IS NOT NULL DROP VIEW [dbo].[vw_FileStat_Drive_RollingAvg];
GO
CREATE VIEW [dbo].[vw_FileStat_Drive_RollingAvg]
AS
SELECT
    capture_time,
    [Volume Mount Point],
    [Overall Latency],
    AVG([Overall Latency]) OVER (
        PARTITION BY [Volume Mount Point]
        ORDER BY capture_time
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS rolling_avg_latency
FROM dbo.FileStat_Drive_History;
GO