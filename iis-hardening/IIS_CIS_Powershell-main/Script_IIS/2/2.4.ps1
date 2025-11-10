$result = C:\Windows\system32\inetsrv\appcmd list config -section:system.web/authentication$result
[xml]$xmlcheck = $result

$cookieornot = $xmlcheck.'system.web'.authentication.forms.cookieless -ne $null
$cookieornot2 = $xmlcheck.'system.web'.authentication.forms | Where-Object { $_.cookieless -eq "UseCookies" }
$cookieornot
$cookieornot2

if($cookieornot -and $cookieornot2){
    Write-Output "2.4 (L2) Ensure 'forms authentication' is set to use cookies is compliant"
}
else{

    Write-Output "2.4 (L2) Ensure 'forms authentication' is set to use cookies is non-compliant. Rerun script to view changes"
    $command = C:\Windows\system32\inetsrv\appcmd set config -section:system.web/authentication /forms.cookieless:"UseCookies"

}
