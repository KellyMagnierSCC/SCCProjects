SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [$(DBName)];
GO
IF OBJECT_ID(N'[dbo].[WaitStats_History]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[WaitStats_History](
        [capture_time] [datetime2](7) NOT NULL,
        [wait_type] [nvarchar](120) NOT NULL,
        [waiting_tasks_count] [bigint] NOT NULL,
        [wait_time_ms] [bigint] NOT NULL,
        [max_wait_time_ms] [bigint] NOT NULL,
        [signal_wait_time_ms] [bigint] NOT NULL
    ) ON [PRIMARY];
    ALTER TABLE [dbo].[WaitStats_History]
        ADD CONSTRAINT [DF_WaitStats_History_capture_time]
        DEFAULT (SYSDATETIME()) FOR [capture_time];
END
ELSE
BEGIN
    PRINT '[dbo].[WaitStats_History] already exists - skipping CREATE';
END
GO
-- Index to optimize windowing by wait_type then time and common selects
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_WaitStats_History_WaitType_Time' AND object_id = OBJECT_ID('[dbo].[WaitStats_History]'))
BEGIN
    CREATE INDEX [IX_WaitStats_History_WaitType_Time]
        ON [dbo].[WaitStats_History]([wait_type], [capture_time])
        INCLUDE([wait_time_ms],[signal_wait_time_ms],[waiting_tasks_count]);
END
GO