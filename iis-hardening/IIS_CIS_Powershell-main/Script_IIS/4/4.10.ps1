$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/isapiCgiRestriction" -name "notListedCgisAllowed"
$result

if($result.Value){

    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/isapiCgiRestriction" -name "notListedCgisAllowed" -value "False"
    Write-Output "4.10 (L1) Ensure 'notListedCgisAllowed' is set to false is non-compliant. Rerun script to view changes"

}

else{

    Write-Output "4.10 (L1) Ensure 'notListedCgisAllowed' is set to false is compliant"

}

















