:setvar DBName "DBA"
USE [master];
GO
IF DB_ID('$(DBName)') IS NULL
BEGIN
    PRINT 'Creating database $(DBName)';
    EXEC('CREATE DATABASE ['+REPLACE('$(DBName)',']',']]')+']');
END
GO
PRINT 'Target database: $(DBName)';
GO