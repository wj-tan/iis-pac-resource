$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT' -filter "system.web/machineKey" -name "validation"

if($result -eq 'AES'){

    Write-Output '3.9 (L1) Ensure MachineKey validation method - .Net 4.5 is configured is compliant'

}

else{

    Write-Output '3.9 (L1) Ensure MachineKey validation method - .Net 4.5 is configured is non-compliant'
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT' -filter "system.web/machineKey" -name "validation" -value "AES"    Write-Output 'Rerun script to view changes'

}








