$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxAllowedContentLength"
$result

if($result.Value -gt 30000000){

    Write-Output '4.1 (L2) Ensure maxAllowedContentLength is configured is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxAllowedContentLength" -value 30000000
    Write-Output 'Rerun script to view changes'

}
else{
   
    Write-Output '4.1 (L2) Ensure maxAllowedContentLength is configured is compliant'
}



