# Phase 1 – Platform & SQL build

Build Windows servers
Create WSFC
Install SQL Server 2022
Configure:
service accounts
tempdb
max memory / MAXDOP
security baselines

➡️ No AG yet, no instance objects yet.

# Phase 2 – Availability Group scaffolding

Create AG (empty or with a dummy DB)
Validate:
replica health
failover
endpoints
Create a temporary listener name
➡️ SQL high-availability layer exists and is stable.

# Phase 3 – Instance-level pre-creation (this is where you were aiming)

This is the right place to do it.
Pre-create:
Logins (with preserved SIDs)
Server roles
Credentials
Linked servers
SQL Agent jobs (disabled)
Database Mail
Proxies / operators
Any CLR / instance config
Why this order is correct:
AG endpoints already exist
You can validate security in the final topology

Nothing depends on user databases yet
Failures here are clean and obvious
➡️ Instance now “looks like” production but with no data.

# Phase 4 – Database migration

Backup/restore from 2012
Restore to 2022 primary
Join databases to AG
Seed secondaries
Benefits:
Users auto-map (no orphan cleanup)
No job failures
Linked server references resolve immediately
DB validation is signal-rich (real errors only)

# Phase 5 – Listener cutover

Remove old listener
Recreate listener on new AG using legacy name
New IP(s)
DNS update
Phase 6 – Enablement & validation
Enable SQL Agent jobs selectively
App connectivity testing
Failover test

Confirm auth scheme (KERBEROS vs NTLM)
