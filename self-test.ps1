$ErrorActionPreference='SilentlyContinue'
$InstallDir=Join-Path $env:LOCALAPPDATA 'WSTCommander'
$rows=@()
$rows += [pscustomobject]@{Check='Install folder';Status=$(if(Test-Path $InstallDir){'PASS'}else{'FAIL'})}
foreach($p in 4318,4319){
  $ok=!!(Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue)
  $rows += [pscustomobject]@{Check=('Port '+$p);Status=$(if($ok){'PASS'}else{'FAIL'})}
}
foreach($n in 'WST Commander MCP','WST Commander Chat','WST Commander Agent','WST Commander Watchdog'){
  $t=Get-ScheduledTask -TaskName $n -ErrorAction SilentlyContinue
  $rows += [pscustomobject]@{Check=$n;Status=$(if($t){'PASS'}else{'FAIL'})}
}
$rows | Format-Table -Auto
$failed=@($rows|Where-Object Status -eq 'FAIL').Count
if($failed -eq 0){Write-Host 'WST Commander self-test: PASS' -ForegroundColor Green;exit 0}
Write-Host ('WST Commander self-test: FAIL ('+$failed+' checks)') -ForegroundColor Red
exit 1
