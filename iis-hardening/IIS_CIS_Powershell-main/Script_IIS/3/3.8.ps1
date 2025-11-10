$command = C:\Windows\system32\inetsrv\appcmd set config /commit:WEBROOT /section:machineKey /validation:SHA1
$command
Write-Output 'Perform 3.8 Audit to view changes'