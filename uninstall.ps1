$ErrorActionPreference='SilentlyContinue'
Stop-ScheduledTask -TaskName 'WST Commander Agent'
Unregister-ScheduledTask -TaskName 'WST Commander Agent' -Confirm:$false
Get-CimInstance Win32_Process | Where-Object {$_.CommandLine -like '*gateway-client.js*loop*'} | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Remove-Item (Join-Path $env:LOCALAPPDATA 'WSTCommander') -Recurse -Force
Write-Host 'WST Commander removed.'
