$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter 'system.web/authentication/forms' -name 'protection'
$result

Write-Output '#################### AUDIT ######################
'

if($result -eq 'All'){

    Write-Output '2.5 Ensure cookie protection mode is configured for forms authentication is compliant'

}

else{

    Write-Output '2.5 Ensure cookie protection mode is configured for forms authentication is not compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter 'system.web/authentication/forms' -name 'protection' -value 'All'
    Write-Output 'Rerun script to view changes'

}


