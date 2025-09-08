# This code will; for a set of folders give MODIFT permissions to the service account running the SQL Server Service.
# This can be used on existing sql instance builds to set new permissions.
param (
    [string]$ComputerName = 'odcx-sql-d-59',              # Remote SQL Server
    [string]$SqlInstance = "DEV"  # Default instance unless named
)

Invoke-Command -ComputerName $ComputerName -ScriptBlock {
    param($SqlInstance)

    # --- Get SQL Server service account ---
    if ($SqlInstance -eq "MSSQLSERVER") {
        $svcName = "MSSQLSERVER"
    } else {
        $svcName = "MSSQL$" + $SqlInstance
    }

    $service = Get-CimInstance Win32_Service -Filter "Name='$svcName'"
    $serviceAccount = $service.StartName
    Write-Output "SQL Service account: $serviceAccount"
   
    # --- Get SQL default paths ---
    $regPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.$SqlInstance\MSSQLServer"
    $dataPath   = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).DefaultData
    $logPath    = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).DefaultLog
    $backupPath = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).BackupDirectory

    $paths = @($dataPath, $logPath, $backupPath) | Where-Object { $_ -ne $null }
    Write-Output "PAths: $paths"
 
    # --- Add mount patterns ---
    $mountPatterns = @(
        "E:\MOUNT\Databases\Data\Data*",
        "E:\MOUNT\Databases\Logs\Log*",
        "E:\MOUNT\Databases\TempDB\Temp*"
    )
        Write-Output "mountPatterns: $mountPatterns"


    foreach ($pattern in $mountPatterns) {
        $mountPaths = Get-ChildItem -Path $pattern -Directory -ErrorAction SilentlyContinue | 
                      Select-Object -ExpandProperty FullName
        $paths += $mountPaths
    }

    Write-output "`nChecking these paths:" 
    $paths | Sort-Object -Unique | ForEach-Object { Write-Host " - $_" }

#} -ArgumentList $SqlInstance

    # --- Function to grant permissions ---
    function Ensure-Permissions {
        param ($Path, $Account)

        try {
            $acl = Get-Acl $Path
            $hasPerm = $acl.Access | Where-Object {
                $_.IdentityReference -eq $Account -and $_.FileSystemRights -match "Modify"
            }

            if ($hasPerm) {
                Write-Host "✔ $Account already has Modify rights on $Path"
            }
            else {
                Write-Host "⚠ $Account missing rights on $Path — granting Modify..."
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    $Account, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
                )
                $acl.AddAccessRule($rule)
                Set-Acl -Path $Path -AclObject $acl
                Write-Host "✔ Granted Modify rights to $Account on $Path"
            }
        }
        catch {
            Write-Host "❌ Error accessing $Path : $_"
        }
    }

    # --- Apply to all paths ---
    foreach ($path in ($paths | Sort-Object -Unique)) {
        Ensure-Permissions -Path $path -Account $serviceAccount
    }

} -ArgumentList $SqlInstance
