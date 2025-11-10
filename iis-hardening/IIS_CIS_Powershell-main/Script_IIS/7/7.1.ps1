$command1 = C:\Windows\system32\inetsrv\appcmd.exe set config -section:system.webServer/httpProtocol /+"customHeaders.[name='StrictTransport-Security',value='max-age=480; preload']"
$command2 = C:\Windows\system32\inetsrv\appcmd.exe set config -section:system.webServer/httpProtocol /+"customHeaders.[name='StrictTransport-Security',value='max-age=480; includeSubDomains; preload']"
$command3 = C:\Windows\system32\inetsrv\appcmd.exe set config "Default Web Site" -section:system.webServer/httpProtocol /+"customHeaders.[name='StrictTransport-Security',value='max-age=480; preload']"
$command4 = C:\Windows\system32\inetsrv\appcmd.exe set config "Default Web Site" -section:system.webServer/httpProtocol /+"customHeaders.[name='StrictTransport-Security',value='max-age=480; includeSubDomains; preload']"$command1$command2$command3$command4Write-Output "###########################AUDIT##########################"if($command1 -or $command2 -or $command3 -or $command4 -eq "ERROR ( hresult:c00cee2b, message:Failed to commit configuration changes.  

 )"){    Write-Output 'If you see the above commit configuration error, please perform the following steps to remediate instead:'    Write-Output "1. Open IIS Manager
2. In the Connections pane, select your server
3. In the Features View pane, double click HTTP Response Headers
4. Verify an entry exists named Strict-Transport-Security
5. Double click Strict-Transport-Security and verify the Value: box contains any value 
   greater than 0
6. Click OK"    Write-Output "7. Open IIS Manager
8. In the Connections pane, expand the tree and select Website
9. In the Features View pane, double click HTTP Response Headers
10. Verify an entry exists name Strict-Transport-Security
11. Double click Strict-Transport-Security and verify the Value: box contains any value 
    greater than 0
12. Click OK."    Write-Output "Note: Any value greater than 0 meets this recommendation. The examples below are specific to 8 
minutes but can be adjusted to meet your requirements"}