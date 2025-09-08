# Action Log

| Action | Date | Method | Additional Info |
| ------ | --------- | ------ | ------------ |
| Request to Dave Wilson regaridng config of gMSA testing. | 30-07-2025 | Email | [Proposal_for_DEV_gMSA](./gmSA/Proposal_for_DEV_gMSAs.md) |
| Dave Wingrave completed parts 1 and 2 of request (see Proposal for Dev gMSA doc | 11-08-2025 | Email | See image |
| Dave Wilsonn - "Created a new GPO called SQL Server GMSA Policy and applied it to the SQL OU." | 11-08-2025 | Email | |  
| SQL Server patching highlighted that the GPO was applied to all SQL Servers in the OU to add these gMSA as "Log oon as a Service". Overwriting the existing SQL Server service accounts.  This caused all of the DEV Servers to not restart after patching. | 13-08-2025 | | Caused by action above |
| Dave Wingrave - So the GPO applied to all Servers in that OU, which caused Kelly a headache this morning. I removed the OU from the GPO and, after a gpupdate /force command, the servers were back to ‘normal’. So I have now applied the GPO to the SQL_Dev_servers group only (only ODCX-SQL-D-59 is a member) | 13-08-2025 | Email | Need to add another Server into this group and see if I can set the gMSA. |
