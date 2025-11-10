$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/compilation" -name "debug" | Select-Object Name, Value$resultif($result.Value){

    Write-Output '3.2 Ensure debug is turned off is not compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/compilation" -name "debug" -value "False"
    Write-Output 'Rerun script to view changes'

}

else{

    Write-Output '3.2 Ensure debug is turned off is compliant'
    
}
