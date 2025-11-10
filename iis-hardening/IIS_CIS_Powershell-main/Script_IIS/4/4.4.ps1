$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.webServer/security/requestFiltering' -name 'allowHighBitCharacters'
$result

if($result.Value){
    
    Write-Output '4.4 (L2) Ensure non-ASCII characters in URLs are not allowed is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering" -name "allowHighBitCharacters" -value "False"
    Write-Output 'Rerun script to view changes'
}

else{

    Write-Output '4.4 (L2) Ensure non-ASCII characters in URLs are not allowed is compliant'

}
