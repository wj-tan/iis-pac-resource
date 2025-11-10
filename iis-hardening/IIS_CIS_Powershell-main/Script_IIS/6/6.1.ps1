$command1 = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/siteDefaults/ftpServer/security/ssl" -name "controlChannelPolicy"
$command2 = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/siteDefaults/ftpServer/security/ssl" -name "dataChannelPolicy"

$command1
$command2


if($command1 -ne 'SslRequire' -or $command2 -ne 'SslRequire'){

    Write-Output "6.1 (L1) Ensure FTP requests are encrypted is non-compliant. Rerun script to view changes"
    $command = C:\Windows\system32\inetsrv\appcmd.exe set config -section:system.applicationHost/sites /siteDefaults.ftpServer.security.ssl.controlChannelPolicy:"SslRequire" /siteDefaults.ftpServer.security.ssl.dataChannelPolicy:"SslRequire" /commit:apphost

}
else{

    Write-Output "6.1 (L1) Ensure FTP requests are encrypted is compliant"

}
