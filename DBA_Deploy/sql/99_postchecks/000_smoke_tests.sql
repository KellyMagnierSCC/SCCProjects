USE [$(DBName)];
GO
-- Smoke tests
SELECT TOP (5) * FROM [dbo].[vw_FileStat_DB_Current] ORDER BY [Database Name];
SELECT TOP (5) * FROM [dbo].[vw_FileStat_Drive_Current] ORDER BY [Volume Mount Point];
GO