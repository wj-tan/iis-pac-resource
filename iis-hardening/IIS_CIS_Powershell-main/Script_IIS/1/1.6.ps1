$result = Get-WebConfiguration system.webServer/security/authentication/anonymousAuthentication -Recurse | where {$_.enabled -eq $true} | Select-Object location
$result

if($result.Location -eq ""){
    
    Write-Output "1.6 (L1) Ensure 'application pool identity' is configured for anonymous user identity is compliant"
    
}
else{

    Write-Output "1.6 (L1) Ensure 'application pool identity' is configured for anonymous user identity is non-compliant. Rerun script to view changes"
    $command1 = C:\Windows\system32\inetsrv\appcmd set config -section:anonymousAuthentication /username:"" --password

}