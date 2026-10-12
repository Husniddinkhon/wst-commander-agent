$ErrorActionPreference = "Stop"
$Gateway = "https://commander.montag.uz"
$ZipUrl = "$Gateway/download/wst-commander-agent-win.zip"
$InstallDir = Join-Path $env:LOCALAPPDATA "WSTCommander"
$Tmp = Join-Path $env:TEMP ("wst-commander-" + [guid]::NewGuid().ToString("N"))
$Zip = "$Tmp\agent.zip"

Write-Host "WST Commander setup" -ForegroundColor Cyan
Write-Host "Downloading latest agent..."
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null
Invoke-WebRequest -UseBasicParsing -Uri $ZipUrl -OutFile $Zip

if (Test-Path $InstallDir) {
  $Backup = "$InstallDir.backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
  Move-Item $InstallDir $Backup
  Write-Host "Previous version backed up to $Backup"
}
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Expand-Archive -Path $Zip -DestinationPath $InstallDir -Force

# Normalize single nested folder archives.
$items = Get-ChildItem $InstallDir
if ($items.Count -eq 1 -and $items[0].PSIsContainer) {
  $nested = $items[0].FullName
  Get-ChildItem $nested -Force | Move-Item -Destination $InstallDir -Force
  Remove-Item $nested -Recurse -Force
}

$Node = Get-ChildItem $InstallDir -Recurse -Filter node.exe -File | Select-Object -First 1 -ExpandProperty FullName
$Client = Get-ChildItem $InstallDir -Recurse -Filter gateway-client.js -File | Select-Object -First 1 -ExpandProperty FullName
if (-not $Node) { $Node = (Get-Command node.exe -ErrorAction SilentlyContinue).Source }
if (-not $Node -or -not $Client) { throw "Agent package is incomplete (node.exe or gateway-client.js missing)." }

# Ensure gateway URL is production.
$config = Get-ChildItem $InstallDir -Recurse -Filter config.json -File | Select-Object -First 1 -ExpandProperty FullName
if ($config) {
  try {
    $j = Get-Content $config -Raw | ConvertFrom-Json
    if (-not $j.product) { $j | Add-Member -NotePropertyName product -NotePropertyValue ([pscustomobject]@{}) }
    $j.product | Add-Member -Force -NotePropertyName gatewayUrl -NotePropertyValue $Gateway
    $j | ConvertTo-Json -Depth 20 | Set-Content $config -Encoding UTF8
  } catch {}
}

# Replace stale identity so this install pairs to the current user's account.
$agentDir = Split-Path $Client -Parent
Remove-Item (Join-Path $agentDir 'device-identity.json') -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $agentDir 'pairing-request.json') -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $agentDir 'gateway-client.pid') -Force -ErrorAction SilentlyContinue

# Create pairing request.
$out = & $Node $Client pairRequest
if ($LASTEXITCODE -ne 0) { throw "Pairing request failed." }
$pair = $out | ConvertFrom-Json
$code = [string]$pair.code
Set-Clipboard -Value $code

# Autostart via Scheduled Task at user logon.
$taskName = 'WST Commander Agent'
$action = New-ScheduledTaskAction -Execute $Node -Argument ('"' + $Client + '" loop')
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 99 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

# Start once immediately.
Start-Process -FilePath $Node -ArgumentList ('"' + $Client + '" loop') -WindowStyle Hidden

$pairUrl = "$Gateway/"
Start-Process $pairUrl
Write-Host ""
Write-Host "PAIRING CODE: $code" -ForegroundColor Green
Write-Host "The code is copied to clipboard." -ForegroundColor Green
Write-Host "In the page that opened: sign in, click Approve code, paste the code." -ForegroundColor Yellow
Write-Host "After approval, the agent finishes pairing automatically within a few seconds."

# Poll and finalize pairing for up to 3 minutes.
$deadline = (Get-Date).AddMinutes(3)
do {
  Start-Sleep -Seconds 3
  try {
    $r = & $Node $Client pairComplete 2>$null
    if ($LASTEXITCODE -eq 0 -and $r) {
      $obj = $r | ConvertFrom-Json
      if ($obj.status -eq 'paired') {
        & $Node $Client heartbeat | Out-Null
        Write-Host "WST Commander is ONLINE." -ForegroundColor Green
        Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue
        exit 0
      }
    }
  } catch {}
} while ((Get-Date) -lt $deadline)

Write-Host "Pairing is still waiting. Keep this window open and approve the code in the browser." -ForegroundColor Yellow
