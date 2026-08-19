# Deploy clash-ext.yaml to the S-UI hub over SSH. Does not restart sing-box.
param(
    [string]$HostName = $(if ($env:SUI_HOST) { $env:SUI_HOST } else { "13.196.71.52" }),
    [string]$User = $(if ($env:SUI_USER) { $env:SUI_USER } else { "ubuntu" }),
    [string]$IdentityFile = $env:SUI_SSH_KEY
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Yaml = Join-Path $Root "clash-ext.yaml"
$Py = Join-Path $Root "scripts\sync_subclash.py"

if (-not (Test-Path $Yaml)) { throw "missing $Yaml" }
if (-not (Test-Path $Py)) { throw "missing $Py" }

$SshTarget = "${User}@${HostName}"
$SshOpts = @("-o", "BatchMode=yes", "-o", "ConnectTimeout=15")
if ($IdentityFile) { $SshOpts += @("-i", $IdentityFile) }

& scp @SshOpts $Yaml $Py "${SshTarget}:/tmp/"
if ($LASTEXITCODE -ne 0) { throw "scp failed" }

& ssh @SshOpts $SshTarget "sudo python3 /tmp/sync_subclash.py --file /tmp/clash-ext.yaml --verify"
if ($LASTEXITCODE -ne 0) { throw "remote sync failed" }
