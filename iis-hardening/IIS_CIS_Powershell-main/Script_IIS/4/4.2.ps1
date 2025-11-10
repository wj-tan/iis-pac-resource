$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxUrl"
$result

if($result.Value -gt 4096){
    
    Write-Output '4.2 (L2) Ensure maxURL request filter is configured is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxUrl" -value 4096
    Write-Output 'Rerun script to view changes'
}

else{

    Write-Output '4.2 (L2) Ensure maxURL request filter is configured is compliant' 
    

}
