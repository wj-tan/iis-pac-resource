$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/customErrors" -name "mode"
$result

if($result -eq 'RemoteOnly'){

    Write-Output '3.3 Ensure custom error messages are not off is compliant'

}
else{

    Write-Output '3.3 Ensure custom error messages are not off is not compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/customErrors" -name "mode" -value "RemoteOnly"
    Write-Output 'Rerun script to view changes'

}