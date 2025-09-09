SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [$(DBName)];
GO
IF OBJECT_ID(N'[dbo].[FileStat_Drive_History]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[FileStat_Drive_History](
        [capture_time] [datetime] NOT NULL,
        [Drive] [char](2) NULL,
        [Volume Mount Point] [nvarchar](128) NULL,
        [Read Latency] [float] NULL,
        [Write Latency] [float] NULL,
        [Overall Latency] [float] NULL,
        [Avg Bytes/Read] [float] NULL,
        [Avg Bytes/Write] [float] NULL,
        [Avg Bytes/Transfer] [float] NULL
    ) ON [PRIMARY];
    ALTER TABLE [dbo].[FileStat_Drive_History]
        ADD CONSTRAINT [DF_FileStat_Drive_History_capture_time]
        DEFAULT (GETDATE()) FOR [capture_time];
END
ELSE
BEGIN
    PRINT '[dbo].[FileStat_Drive_History] already exists - skipping CREATE';
END
GO
-- Helpful index for time-series analysis by volume
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FileStat_Drive_History_Volume_Time' AND object_id = OBJECT_ID('[dbo].[FileStat_Drive_History]'))
BEGIN
    CREATE INDEX [IX_FileStat_Drive_History_Volume_Time]
        ON [dbo].[FileStat_Drive_History]([Volume Mount Point], [capture_time]);
END
GO