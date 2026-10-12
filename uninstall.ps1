$ErrorActionPreference='SilentlyContinue'
foreach($n in 'WST Commander Agent','WST Commander MCP','WST Commander Chat'){ Stop-ScheduledTask -TaskName $n -ErrorAction SilentlyContinue; Unregister-ScheduledTask -TaskName $n -Confirm:$false -ErrorAction SilentlyContinue }
Get-CimInstance Win32_Process | Where-Object {$_.CommandLine -like '*gateway-client.js*loop*'} | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Remove-Item (Join-Path $env:LOCALAPPDATA 'WSTCommander') -Recurse -Force
Write-Host 'WST Commander removed.'

