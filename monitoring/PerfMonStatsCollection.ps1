function Start-PerfMonStatsCollection {
    <#
    .SYNOPSIS
        Collects PerfMon counters from Windows and SQL Server, and logs results into a SQL Server table.

    .DESCRIPTION
        This function gathers performance counter values (Windows + SQL Server) using Get-Counter, 
        then inserts the results into a target SQL Server database table (dbo.PerfMonStats).
        If the table does not already exist, it will be created automatically.

    .PARAMETER SqlServer
        The SQL Server host name.

    .PARAMETER InstanceName
        The SQL Server instance name (without MSSQL$ prefix).

    .PARAMETER Database
        The database where the dbo.PerfMonStats table should be created and written to. Default is "dba".

    .PARAMETER IntervalSeconds
        Number of seconds to wait between counter collections. Default is 5.

    .PARAMETER Iterations
        Number of times to collect performance counters. Default is 1.

    .PARAMETER Databases
        An array of SQL Server database names to collect database-specific counters for.

    .PARAMETER CounterGroups
        Which groups of counters to collect. 
        Options: Processor, PhysicalDisk, Memory, System, Locks, SQLStats, Transactions, Network, Databases, All.
        Default is All.

    .EXAMPLE
        Start-PerfMonStatsCollection -SqlServer "MyServer" -InstanceName "DEV" -Iterations 10 -IntervalSeconds 30

        Collects all counters every 30 seconds for 10 iterations and inserts into dbo.PerfMonStats.

    .NOTES
        Author: Kelly (improved with documentation and formatting)
        Requires: SqlServer PowerShell module
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SqlServer,

        [Parameter(Mandatory = $true)]
        [string]$InstanceName,

        [string]$Database = "dba",

        [int]$IntervalSeconds = 5,

        [int]$Iterations = 1,

        [string[]]$Databases = @(),

        [ValidateSet("Processor", "PhysicalDisk", "Memory", "System", "Locks", "SQLStats", "Transactions", "Network", "Databases", "All")]
        [string[]]$CounterGroups = @("All")
    )

    begin {
        # Load SqlServer module
        if (-not (Get-Module -ListAvailable -Name SqlServer)) {
            throw "SqlServer PowerShell module is not installed. Run: Install-Module SqlServer"
        }
        Import-Module SqlServer -ErrorAction Stop

        $servername  = $SqlServer
        $SQLInstance = "MSSQL`$$InstanceName"

        # --------------------------
        # Counter Definitions (unchanged from your script)
        # --------------------------
        $ProcessorCounters   = @(
            "\\$servername\Processor(_Total)\% Processor Time",
            "\\$servername\Processor(_Total)\% Privileged Time",
            "\\$servername\Processor(_Total)\% User Time"
        )
        $PhysicalDiskCounters = @(
            "\\$servername\PhysicalDisk(_Total)\Disk Reads/sec",
            "\\$servername\PhysicalDisk(_Total)\Avg. Disk sec/Read",
            "\\$servername\PhysicalDisk(_Total)\Disk Read Bytes/sec",
            "\\$servername\PhysicalDisk(*)\Current Disk Queue Length",
            "\\$servername\PhysicalDisk(*)\Avg. Disk Queue Length",
            "\\$servername\PhysicalDisk(*)\Avg. Disk Write Queue Length",
            "\\$servername\PhysicalDisk(*)\Avg. Disk Read Queue Length",
            "\\$servername\PhysicalDisk(*)\% Disk Time",
            "\\$servername\PhysicalDisk(_Total)\Disk Writes/sec",
            "\\$servername\PhysicalDisk(_Total)\Avg. Disk sec/Write",
            "\\$servername\PhysicalDisk(_Total)\Disk Write Bytes/sec"
        )
        $MemoryCounters = @(
            "\\$servername\Memory\Available MBytes",
            "\\$servername\Memory\Pages/sec",
            ("\\$servername\" + $SQLInstance + ":Memory Manager\Total Server Memory (KB)"),
            ("\\$servername\" + $SQLInstance + ":Memory Manager\Target Server Memory (KB)")
        )
        $SystemCounters = @(
            "\\$servername\System\Processor Queue Length"
        )
        $LocksCounters = @(
            ("\\$servername\" + $SQLInstance + ":Locks(_Total)\Lock Waits/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(_Total)\Number of Deadlocks/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(_Total)\Lock Timeouts/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(_Total)\Average Wait Time (ms)"),
            ("\\$servername\" + $SQLInstance + ":Locks(Database)\Lock Waits/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(Database)\Number of Deadlocks/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(Database)\Lock Timeouts/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(Database)\Average Wait Time (ms)"),
            ("\\$servername\" + $SQLInstance + ":Locks(Object)\Lock Waits/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(Object)\Number of Deadlocks/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(Object)\Lock Timeouts/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(Object)\Average Wait Time (ms)"),
            ("\\$servername\" + $SQLInstance + ":Locks(Page)\Lock Waits/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(Page)\Number of Deadlocks/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(Page)\Lock Timeouts/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(Page)\Average Wait Time (ms)"),
            ("\\$servername\" + $SQLInstance + ":Locks(Key)\Lock Waits/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(Key)\Number of Deadlocks/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(Key)\Lock Timeouts/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(Key)\Average Wait Time (ms)"),
            ("\\$servername\" + $SQLInstance + ":Locks(RID)\Lock Waits/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(RID)\Number of Deadlocks/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(RID)\Lock Timeouts/sec"),
            ("\\$servername\" + $SQLInstance + ":Locks(RID)\Average Wait Time (ms)")
        )
        $SQLStatsCounters = @(
            ("\\$servername\" + $SQLInstance + ":SQL Statistics\Batch Requests/sec"),
            ("\\$servername\" + $SQLInstance + ":SQL Statistics\SQL Compilations/sec"),
            ("\\$servername\" + $SQLInstance + ":SQL Statistics\SQL Re-Compilations/sec")
        )
        $TransactionsCounters = @(
            ("\\$servername\" + $SQLInstance + ":Transactions\Version Generation Rate (KB/s)"),
            ("\\$servername\" + $SQLInstance + ":Transactions\Version Cleanup rate (KB/s)"),
            ("\\$servername\" + $SQLInstance + ":Transactions\Version Store Size (KB)"),
            ("\\$servername\" + $SQLInstance + ":Transactions\Version Store unit count"),
            ("\\$servername\" + $SQLInstance + ":Transactions\Longest Transaction Running Time"),
            ("\\$servername\" + $SQLInstance + ":Transactions\Free Space in tempdb (KB)")
        )
        $NetworkCounters = @(
            "\\$servername\Network Interface(*)\Bytes Sent/sec",
            "\\$servername\Network Interface(*)\Bytes received/sec",
            "\\$servername\Network Interface(*)\Output Queue Length",
            "\\$servername\TCPv4\Segments Retransmitted/sec"
        )
        $DatabasesCounters = @(
            ("\\$servername\" + $SQLInstance + ":Buffer Manager\Page reads/sec"),
            ("\\$servername\" + $SQLInstance + ":Databases(_Total)\Backup/Restore Throughput/sec")
        )

        # --------------------------
        # Build Final Counter List
        # --------------------------
        $counters = @()
        if ("All" -in $CounterGroups) {
            $counters += $ProcessorCounters + $PhysicalDiskCounters + $MemoryCounters + $SystemCounters + `
                         $LocksCounters + $SQLStatsCounters + $TransactionsCounters + $NetworkCounters + $DatabasesCounters
        } else {
            if ("Processor"     -in $CounterGroups) { $counters += $ProcessorCounters }
            if ("PhysicalDisk"  -in $CounterGroups) { $counters += $PhysicalDiskCounters }
            if ("Memory"        -in $CounterGroups) { $counters += $MemoryCounters }
            if ("System"        -in $CounterGroups) { $counters += $SystemCounters }
            if ("Locks"         -in $CounterGroups) { $counters += $LocksCounters }
            if ("SQLStats"      -in $CounterGroups) { $counters += $SQLStatsCounters }
            if ("Transactions"  -in $CounterGroups) { $counters += $TransactionsCounters }
            if ("Network"       -in $CounterGroups) { $counters += $NetworkCounters }
            if ("Databases"     -in $CounterGroups) { $counters += $DatabasesCounters }
        }

        # Database-specific counters
        foreach ($db in $Databases) {
            if ("All" -in $CounterGroups -or "Databases" -in $CounterGroups) {
                $counters += @(
                    ("\\$servername\" + $SQLInstance + ":Databases($db)\Transactions/sec"),
                    ("\\$servername\" + $SQLInstance + ":Databases($db)\Log Bytes Flushed/sec"),
                    ("\\$servername\" + $SQLInstance + ":Databases($db)\Log Flushes/sec"),
                    ("\\$servername\" + $SQLInstance + ":Databases($db)\Data File(s) Size (KB)"),
                    ("\\$servername\" + $SQLInstance + ":Databases($db)\Active Transactions"),
                    ("\\$servername\" + $SQLInstance + ":Databases($db)\Write Transactions/sec"),
                    ("\\$servername\" + $SQLInstance + ":Databases($db)\Log Growths"),
                    ("\\$servername\" + $SQLInstance + ":Databases($db)\Log Truncations")
                )
            }
        }
    }

    process {
        Write-Verbose "Starting PerfMon baseline collection for $Iterations iterations every $IntervalSeconds seconds..."

        # Ensure target table exists
        $serverInstance = "$SqlServer\$InstanceName"
        $tableCheckSql = @"
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'PerfMonStats' AND s.name = 'dbo'
)
BEGIN
    CREATE TABLE dbo.PerfMonStats (
        Capture_Time DATETIME2 NOT NULL,
        CounterPath  NVARCHAR(4000) NOT NULL,
        CounterValue FLOAT NOT NULL
    );
END
"@
        Invoke-Sqlcmd -ServerInstance $serverInstance -Database $Database -Query $tableCheckSql -ErrorAction Stop

        # Collection loop
        for ($i = 1; $i -le $Iterations; $i++) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            try {
                $pm = Get-Counter -Counter $counters -ErrorAction Stop

                $values = ($pm.CounterSamples | ForEach-Object {
                    "('$timestamp', N'$($_.Path.Replace("'", "''"))', $($_.CookedValue))"
                }) -join ","

                $sql = @"
INSERT INTO dbo.PerfMonStats (Capture_Time, CounterPath, CounterValue)
VALUES $values;
"@
                Invoke-Sqlcmd -ServerInstance $serverInstance -Database $Database -Query $sql -ErrorAction Stop

                Write-Verbose "[$timestamp] Inserted $($pm.CounterSamples.Count) rows (iteration $i/$Iterations)"
                Write-Host    "[$timestamp] Inserted $($pm.CounterSamples.Count) rows (iteration $i/$Iterations)"
            }
            catch {
                Write-Warning "Error during iteration $i : $_"
            }

            Start-Sleep -Seconds $IntervalSeconds
        }

        Write-Verbose "Collection finished. Data saved to [$Database].[dbo].[PerfMonStats] on $SqlServer"
        Write-Host    "Collection finished. Data saved to [$Database].[dbo].[PerfMonStats] on $SqlServer"
    }
}


Start-PerfMonStatsCollection -SqlServer "odcx-sql-d-13" -InstanceName "dev" -IntervalSeconds 20 -Iterations 15 ## -CounterGroups Locks,SQLStats -Verbose
