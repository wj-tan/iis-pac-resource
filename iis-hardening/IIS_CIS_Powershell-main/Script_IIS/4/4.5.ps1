$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering" -name "allowDoubleEscaping"
$result

if($result.Value){
    
    Write-Output '4.5 (L1) Ensure Double-Encoded requests will be rejected is compliant'
 
}

else{

    Write-Output '4.5 (L1) Ensure Double-Encoded requests will be rejected is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering" -name "allowDoubleEscaping" -value "True"    Write-Output 'Rerun script to view changes'

}












