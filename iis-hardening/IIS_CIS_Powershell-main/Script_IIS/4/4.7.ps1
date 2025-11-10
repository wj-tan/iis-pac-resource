$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/fileExtensions" -name "allowUnlisted"
$result

if($result.Value){

    Write-Output '4.7 (L1) Ensure Unlisted File Extensions are not allowed is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/fileExtensions" -name "allowUnlisted" -value "False"    Write-Output 'Rerun the script to view changes'

}

else{

    Write-Output '4.7 (L1) Ensure Unlisted File Extensions are not allowed is compliant'

}