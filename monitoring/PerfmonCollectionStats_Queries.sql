CREATE OR ALTER PROCEDURE dbo.usp_PivotPerfmonStats_XML
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cols NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);

    -- 1. Build column list dynamically using FOR XML PATH (safe for >8000 chars)
    SELECT @cols = STUFF((
        SELECT DISTINCT ',' + QUOTENAME(CounterPath)
        FROM dbo.PerfmonStats
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 1, '');

    -- Defensive check
    IF @cols IS NULL OR LEN(@cols) = 0
    BEGIN
        RAISERROR('No counters found in dbo.PerfmonStats', 16, 1);
        RETURN;
    END

    -- 2. Build dynamic SQL
    SET @sql = N'
    SELECT Capture_Time, ' + @cols + '
    FROM (
        SELECT 
            Capture_Time,
            CounterPath,
            CounterValue
        FROM dbo.PerfmonStats
    ) AS src
    PIVOT (
        MAX(CounterValue)
        FOR CounterPath IN (' + @cols + ')
    ) AS p
    ORDER BY Capture_Time;';

    -- 3. Execute dynamic pivot
    EXEC sp_executesql @sql;
END
GO
