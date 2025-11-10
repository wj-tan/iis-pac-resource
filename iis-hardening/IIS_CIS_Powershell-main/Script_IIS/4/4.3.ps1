$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxQueryString"
$result

if($result.Value -gt 2048){
    
    Write-Output '4.3 (L2) Ensure MaxQueryString request filter is configured is non-compliant'
    $command =  Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxQueryString" -value 2048
    Write-Output 'Rerun script to view changes'
}

else{

    Write-Output '4.3 (L2) Ensure MaxQueryString request filter is configured is compliant' 
    

}
