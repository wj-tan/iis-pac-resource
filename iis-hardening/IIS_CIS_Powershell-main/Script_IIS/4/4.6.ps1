$result = C:\Windows\system32\inetsrv\appcmd list config /section:requestfiltering
$result
[xml]$xmlresult = $result

$addexist = $xmlresult.'system.webServer'.security.requestFiltering.verbs.add -ne $null
$tracefalse = $xmlresult.'system.webServer'.security.requestFiltering.verbs.add | Where-Object { $_.verb -eq "TRACE" -and $_.allowed -eq "false" }


$addexist
$tracefalse


if($addexist -and $tracefalse){

    Write-Output "4.6 (L1) Ensure 'HTTP Trace Method' is disabled is compliant"

}
else{

    Write-Output "4.6 (L1) Ensure 'HTTP Trace Method' is disabled is non-compliant. Rerun script to view changes"
    $command = Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/verbs" -name "." -value @{verb='TRACE';allowed='False'}

}



