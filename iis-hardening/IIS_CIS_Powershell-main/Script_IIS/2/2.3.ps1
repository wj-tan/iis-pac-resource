$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter 'system.web/authentication/forms' -name 'requireSSL' | Select-Object Name,Value
$result

Write-Output '####################### AUDIT #######################
'

foreach($result in $result){
    
    if(-not $result.Value){
    
        Write-Output '2.3 Ensure forms authentication require SSL is not compliant'
        $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter 'system.web/authentication/forms' -name 'requireSSL' -value 'True'
        Write-Output 'Rerun script to view changes'
    }
    else{
    
        Write-Output '2.3 Ensure forms authentication require SSL is compliant'

    }

}