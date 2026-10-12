$ErrorActionPreference='SilentlyContinue'
$InstallDir=Join-Path $env:LOCALAPPDATA 'WSTCommander'
$Log=Join-Path $InstallDir 'watchdog.log'
function Log($m){Add-Content -Path $Log -Value ((Get-Date -Format s)+' '+$m) -Encoding UTF8}
function NodePath(){
  $n=Get-ChildItem $InstallDir -Recurse -Filter node.exe -File | Select-Object -First 1 -ExpandProperty FullName
  if(-not $n){$c=Get-Command node.exe -ErrorAction SilentlyContinue;if($c){$n=$c.Source}}
  return $n
}
function Ensure-Port($port,$script,$args=''){
  if(Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue){return}
  $node=NodePath
  if(-not $node -or -not (Test-Path $script)){Log ('missing runtime for '+$port);return}
  Start-Process -FilePath $node -ArgumentList ('"'+$script+'" '+$args) -WindowStyle Hidden
  Start-Sleep -Seconds 2
  if(Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue){Log ('recovered '+$port)}else{Log ('failed '+$port)}
}
while($true){
  try{
    $mcp=Join-Path $InstallDir 'src\server.js'
    $chat=Join-Path $InstallDir 'dashboard\server.js'
    $client=Join-Path $InstallDir 'agent\gateway-client.js'
    Ensure-Port 4318 $mcp '--http'
    Ensure-Port 4319 $chat ''
    $a=Get-CimInstance Win32_Process | Where-Object {$_.CommandLine -like '*gateway-client.js*loop*'} | Select-Object -First 1
    if(-not $a){$node=NodePath;if($node -and (Test-Path $client)){Start-Process -FilePath $node -ArgumentList ('"'+$client+'" loop') -WindowStyle Hidden;Log 'recovered agent'}}
  }catch{Log $_.Exception.Message}
  Start-Sleep -Seconds 30
}
