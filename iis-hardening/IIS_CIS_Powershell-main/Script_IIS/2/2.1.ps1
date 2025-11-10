$result = C:\Windows\system32\inetsrv\appcmd list config -section:system.webserver/security/authorization
$result
[xml]$xmlresult = $result

$xmlcheck = $xmlresult.'system.webServer'.security.authorization.add -ne $null
$xmlAdd = $xmlresult.'system.webServer'.security.authorization.add | Where-Object { $_.accessType -eq "Allow" -and $_.roles -eq "Administrators" }

if($xmlcheck -and $xmlAdd){
    Write-Output "2.1 (L1) Ensure 'global authorization rule' is set to restrict access is compliant"
}
else{

    Write-Output "2.1 (L1) Ensure 'global authorization rule' is set to restrict access is not compliant"
    $command1 = Remove-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/authorization" -name "." -AtElement @{users='*';roles='';verbs=''}
    $command2 = Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/authorization" -name "." -value @{accessType='Allow';roles='Administrators'}    


}


