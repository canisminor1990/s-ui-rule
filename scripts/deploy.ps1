# Deploy clash-ext.yaml to the S-UI hub over SSH. Does not restart sing-box.
param(
    [string]$HostName = $env:SUI_HOST,
    [string]$User = $env:SUI_USER,
    [string]$IdentityFile = $env:SUI_SSH_KEY
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Yaml = Join-Path $Root "clash-ext.yaml"
$Py = Join-Path $Root "scripts\sync_subclash.py"

function Read-DeployConfig {
    $cfgPath = Join-Path $Root ".deploy\config"
    $map = @{}
    if (-not (Test-Path $cfgPath)) { return $map }
    Get-Content -LiteralPath $cfgPath | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith("#")) { return }
        $eq = $line.IndexOf("=")
        if ($eq -lt 1) { return }
        $key = $line.Substring(0, $eq).Trim()
        $val = $line.Substring($eq + 1).Trim().Trim('"').Trim("'")
        $map[$key] = $val
    }
    $map
}

$cfg = Read-DeployConfig
if (-not $HostName) { $HostName = $cfg["SUI_HOST"] }
if (-not $User) { $User = $cfg["SUI_USER"] }
if (-not $IdentityFile) { $IdentityFile = $cfg["SUI_SSH_KEY"] }
if (-not $IdentityFile) {
    $defaultKey = Join-Path $Root ".deploy\id_ed25519"
    if (Test-Path $defaultKey) { $IdentityFile = $defaultKey }
}

if (-not $HostName -or -not $User) {
    throw "Set SUI_HOST and SUI_USER via env, -HostName/-User, or .deploy/config. See scripts/deploy.env.example"
}

if (-not (Test-Path $Yaml)) { throw "missing $Yaml" }
if (-not (Test-Path $Py)) { throw "missing $Py" }

$SshTarget = "${User}@${HostName}"
$SshOpts = @("-o", "BatchMode=yes", "-o", "ConnectTimeout=15")
if ($IdentityFile) { $SshOpts += @("-i", $IdentityFile) }

& scp @SshOpts $Yaml $Py "${SshTarget}:/tmp/"
if ($LASTEXITCODE -ne 0) { throw "scp failed" }

& ssh @SshOpts $SshTarget "sudo python3 /tmp/sync_subclash.py --file /tmp/clash-ext.yaml --verify"
if ($LASTEXITCODE -ne 0) { throw "remote sync failed" }
