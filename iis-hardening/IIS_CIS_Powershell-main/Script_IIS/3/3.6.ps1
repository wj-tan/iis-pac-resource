$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/sessionState" -name "mode"

if($result -eq 'StateServer'){

    Write-Output "3.6 Ensure 'httpcookie' mode is configured for session state is compliant"

}
else{

    Write-Output "3.6 Ensure 'httpcookie' mode is configured for session state is non-compliant"
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/sessionState" -name "mode" -value "StateServer"
    Write-Output 'Rerun script to view changes'


}
