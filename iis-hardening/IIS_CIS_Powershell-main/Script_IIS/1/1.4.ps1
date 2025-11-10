$result = Get-ChildItem -Path IIS:\AppPools\ | Select-Object name, state, <#@{e={$_.processModel.password};l="password"}, #> @{e={$_.processModel.identityType};l="identityType"}


Write-Output '######################## AUDIT ########################'

$result

if($result.identityType -eq 'ApplicationPoolIdentity'){
    Write-Output "1.4 Ensure 'application pool identity' is configured for all application pools is compliant"
}
else{
    Write-Output "
1.4 Ensure 'application pool identity' is configured for all application pools is non-compliant"

    $result = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/applicationPools/add[@name="DefaultAppPool"]/processModel' -name 'identityType' -value 'ApplicationPoolIdentity'
    Write-Output "Rerun script to view changes"

}