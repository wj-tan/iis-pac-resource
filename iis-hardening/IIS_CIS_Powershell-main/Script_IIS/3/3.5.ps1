$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/trace" -name "enabled" | Select-Object Name,Value
$result

if(-not $result.Value){

    Write-Output '3.5 (L2) Ensure ASP.NET stack tracing is not enabled is compliant'

}
else{

    Write-Output '3.5 (L2) Ensure ASP.NET stack tracing is not enabled is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/trace" -name "enabled" -value "False"
    Write-Output 'Rerun script to view changes'

}

