# Project for Transitioning from windows domain accounts to group managed service accounts for SQL Server Services.

## Methodology

Test on single instance of dev server. 

Initial development to Development servers as part of move from Enterprise Edition to Developer Edition. 

On successful deployment to DEV implement onexisting production instances.  
[! Note] Production servers as not being built will need to have permissions changed on all drives to use gmsa accounts.
