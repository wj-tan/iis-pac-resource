$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/isapiCgiRestriction" -name "notListedIsapisAllowed"
$result

if($result.Value){

    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/isapiCgiRestriction" -name "notListedIsapisAllowed" -value "False"    Write-Output "4.9 (L1) Ensure 'notListedIsapisAllowed' is set to false is non-compliant. Rerun to view changes"

}
else{

    Write-Output "4.9 (L1) Ensure 'notListedIsapisAllowed' is set to false is compliant"

}










