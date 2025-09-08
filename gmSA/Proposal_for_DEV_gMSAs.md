## Proposal for DEV gMSAs

Initially, we plan to use separate gMSAs for the Database Engine and Agent services. Once this setup is proven in DEV, we'll adopt the same model for production.

The proposed gMSA accounts for DEV are:
•	gMSA_SQL_Dev_Engine – for the SQL Server Database Engine
•	gMSA_SQL_Dev_Agent – for the SQL Server Agent

Key Requests
To facilitate this, we have a few requests:
1.	Create gMSA Accounts: Please create the two gMSA accounts listed above in Active Directory.
2.	Group-Based Access: We'd prefer to manage access via a dedicated AD group. Could you please assign a group like SQL_Dev_Servers to the PrincipalsAllowedToRetrieveManagedPassword property for both gMSAs?  This will allow any servers added to this group to automatically retrieve the credentials.
3.	"Log on as a service" Rights: Please grant "Log on as a service" rights to both gMSAs via Group Policy.
4.	SPN Registration Delegation: We request that our AG-SQL-Admin group be granted delegated rights to register SPNs. This will allow us to automate SPN registration during our DSC-based SQL build process, eliminating the need for manual domain admin involvement for each new deployment.

Context for SPN Registration
For your awareness, we are deploying named instances (e.g., DEV) of SQL Server Developer Edition (2019/2022) on port 55201.  An example server is ODCX-SQL-D-59.surreycc.local. Ideally, SPN setup would be done early in the build process to ensure Kerberos works out-of-the-box.
