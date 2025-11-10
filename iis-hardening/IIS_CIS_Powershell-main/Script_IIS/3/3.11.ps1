$result = C:\Windows\System32\inetsrv\appcmd.exe list config -section:system.webServer/httpProtocol
$result
if($result.Contains('<remove name="X-Powered-By"/>')){
    
    Write-Output '3.11 (L2) Ensure X-Powered-By Header is removed is non-compliant'
    $command = Remove-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webserver/httpProtocol/customHeaders" -name "." -AtElement @{name='XPowered-By'}
    Write-Output 'Rerun Script to view changes'

}
else{

    Write-Output '3.11 (L2) Ensure X-Powered-By Header is removed is compliant'

}






