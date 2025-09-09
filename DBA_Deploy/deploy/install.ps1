param(
  [Parameter(Mandatory=$true)][string]$ServerName,
  [string]$DatabaseName = 'DBA',
  [ValidateSet('Windows','Sql')][string]$Auth = 'Windows',
  [string]$SqlUser,
  [string]$SqlPassword,
  [string]$JobOwner = 'sa'
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here

function Invoke-TsqlFile {
  param([string]$Path, [hashtable]$SqlCmdVars)

  if (Get-Module -ListAvailable -Name SqlServer) {
    Import-Module SqlServer -ErrorAction SilentlyContinue | Out-Null
    $params = @{ ServerInstance = $ServerName; InputFile = $Path; Variable = $SqlCmdVars }
    if ($Auth -eq 'Sql') { $params['Username']=$SqlUser; $params['Password']=$SqlPassword }
    Invoke-Sqlcmd @params
  } else {
    # Fallback to sqlcmd
    $vars = @()
    foreach ($k in $SqlCmdVars.Keys) { $vars += @('-v', "$k=$($SqlCmdVars[$k])") }
    $auth = @()
    if ($Auth -eq 'Sql') { $auth = @('-U', $SqlUser, '-P', $SqlPassword) } else { $auth = @('-E') }
    & sqlcmd -S $ServerName @auth -b -i $Path @vars
  }
}

$sqlVars = @{ DBName = $DatabaseName; JobName='Capture FileStats History'; ScheduleName='Every 15 minutes'; JobOwner=$JobOwner }

$order = @(
  'sql/00_prechecks',
  'sql/10_tables',
  'sql/20_views',
  'sql/30_procedures',
  'sql/40_security',
  'sql/50_jobs',
  'sql/99_postchecks'
)

foreach ($folder in $order) {
  Get-ChildItem -Path (Join-Path $root $folder) -Filter *.sql | Sort-Object Name | ForEach-Object {
    Write-Host "Running $($_.FullName) ..." -ForegroundColor Cyan
    Invoke-TsqlFile -Path $_.FullName -SqlCmdVars $sqlVars
  }
}

Write-Host 'Deployment complete.' -ForegroundColor Green