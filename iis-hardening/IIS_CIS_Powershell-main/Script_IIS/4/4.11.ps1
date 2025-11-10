$result1 = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/dynamicIpSecurity/denyByConcurrentRequests" -name "enabled"
$result1

$result2 = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/dynamicIpSecurity/denyByConcurrentRequests" -name "maxConcurrentRequests"
$result2

if($result1.Value){
    
    Write-Output "4.11 (L1) Ensure 'Dynamic IP Address Restrictions' is enabled is compliant"

}else{
    
    $command1 = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/dynamicIpSecurity/denyByConcurrentRequests" -name "enabled" -value "True"    $command2 = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/dynamicIpSecurity/denyByConcurrentRequests" -name "maxConcurrentRequests" -value <number of requests>
    Write-Output "4.11 (L1) Ensure 'Dynamic IP Address Restrictions' is enabled is non-compliant. Rerun script to view changes"

}

