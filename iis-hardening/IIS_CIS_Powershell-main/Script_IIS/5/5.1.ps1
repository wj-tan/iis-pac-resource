$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/siteDefaults/logFile" -name "directory"
$result

if($result -eq "%SystemDrive%\inetpub\logs\LogFiles"){
    
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/siteDefaults/logFile" -name "directory" -value <any_directory_that_isnt_default>
    Write-Output "5.1 (L1) Ensure Default IIS web log location is moved is non-compliant. Rerun script to view changes"
}
else{

    Write-Output "5.1 (L1) Ensure Default IIS web log location is moved is compliant"

}