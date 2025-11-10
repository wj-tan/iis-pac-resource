$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/handlers" -name "accessPolicy"$resultif($result -eq "Read,Script"){    Write-Output '4.8 (L1) Ensure Handler is not granted Write and Script/Execute is compliant'}else{    Write-Output '4.8 (L1) Ensure Handler is not granted Write and Script/Execute is non-compliant'    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/handlers" -name "accessPolicy" -value "Read,Script"    Write-Output 'Rerun script to view changes'}














