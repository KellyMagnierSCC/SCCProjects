# File Stats (SQL Server) – DBA utility

Version-controlled scripts to capture and analyse per-file and per-volume IO latency using SQL Server DMVs. Includes tables, views, a capture procedure, and an optional SQL Agent job.

## Repo layout

```
sql/
  00_prechecks/           # create $(DBName) if missing
  10_tables/              # history tables + indexes
  20_views/               # current/derived views over DMVs and history
  30_procedures/          # Capture_FileStats_History
  40_security/            # role + grants (server VIEW SERVER STATE note)
  50_jobs/                # optional SQL Agent job (15 min)
  99_postchecks/          # smoke tests
deploy/
  install.ps1             # runs all .sql files in the right order
```

## Prereqs & permissions

* The views that read DMVs require **VIEW SERVER STATE** on the target instance for the caller (or run the Agent job under a sysadmin context).
* PowerShell: either the `SqlServer` module (Invoke-Sqlcmd) **or** `sqlcmd` in PATH.

## Quick start

1. Clone this repo or download the zip.
2. Open PowerShell in the repo root and run:

   ```powershell
   ./deploy/install.ps1 -ServerName "<server>" -DatabaseName "DBA" -Auth Windows
   # or for SQL Auth
   ./deploy/install.ps1 -ServerName "<server>" -DatabaseName "DBA" -Auth Sql -SqlUser "sa" -SqlPassword "<pwd>"
   ```

3. (Optional) Change the job frequency by editing `sql/50_jobs/AgentJob_Capture_FileStats.sql` (15-minute default).

## Retention (optional)

For busy systems you may want to purge older history. Example:

```sql
DELETE FROM dbo.FileStat_DB_History WHERE capture_time < DATEADD(day, -90, SYSDATETIME());
DELETE FROM dbo.FileStat_Drive_History WHERE capture_time < DATEADD(day, -90, SYSDATETIME());
```

Schedule that as a separate Agent job if needed.

## Tested on

* SQL Server 2016 SP1+ and Azure SQL Managed Instance. On earlier versions, replace `CREATE OR ALTER PROCEDURE` with DROP/CREATE.



## Wait Stats module

Captures cumulative waits from `sys.dm_os_wait_stats` into `dbo.WaitStats_History`, with a delta view to spot changes over time.

### Objects
- Table: `dbo.WaitStats_History` (with default `SYSDATETIME()` and index on `(wait_type, capture_time)`)
- Views: `dbo.vw_WaitStats_Current`, `dbo.vw_WaitStats_RollingDelta`
- Proc: `dbo.Capture_WaitStats_History`
- Agent Job: **Capture WaitStats History** (15 min, shares the same schedule if present)

> Note: `sys.dm_os_wait_stats` is cumulative since the last service restart or `DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR)`. The rolling delta view computes per-capture increments so you can trend spikes. Access requires `VIEW SERVER STATE`.
