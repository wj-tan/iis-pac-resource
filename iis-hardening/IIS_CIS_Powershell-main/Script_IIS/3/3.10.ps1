$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT' -filter "system.web/trust" -name "level"
$result
if($result.Value -eq 'Medium'){
    
    Write-Output '3.10 (L1) Ensure global .NET trust level is configured is compliant'

}

else{

    Write-Output '3.10 (L1) Ensure global .NET trust level is configured is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT' -filter "system.web/trust" -name "level" -value "Medium"
    Write-Output 'Rerun script to view changes'

}










