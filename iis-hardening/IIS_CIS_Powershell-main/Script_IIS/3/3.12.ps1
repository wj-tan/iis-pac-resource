$result = Get-WebConfigurationProperty -pspath machine/webroot/apphost -filter 'system.webserver/security/requestfiltering' -name 'removeServerHeader' | Select-Object Value
$result

if($result.Value){
    
    Write-Output '3.12 (L2) Ensure Server Header is removed is compliant'

}
else{
    Write-Output '3.12 (L2) Ensure Server Header is removed is non-compliant'
    $command = C:\Windows\system32\inetsrv\appcmd.exe set config -section:system.webServer/security/requestFiltering /removeServerHeader:"True" /commit:apphost    Write-Output 'Rerun script to view changes'
}





