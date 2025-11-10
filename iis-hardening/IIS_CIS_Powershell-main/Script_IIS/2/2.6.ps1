$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter 'system.webServer/security/access' -name 'sslFlags'
$result
if($result -eq 'Ssl'){
    Write-Output "2.6 Ensure transport layer security for 'basic authentication' is configured is COMPLIANT"
}
else{
    Write-Output "2.6 Ensure transport layer security for 'basic authentication' is configured is not COMPLIANT"
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter 'system.webServer/security/access' -name 'sslFlags' -value 'Ssl'
    Write-Output 'Rerun script to view changes'
}