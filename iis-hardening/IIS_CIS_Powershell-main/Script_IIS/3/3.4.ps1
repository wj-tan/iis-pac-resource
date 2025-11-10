$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.webServer/httpErrors" -name "errorMode"

$result

if($result -eq 'DetailedLocalOnly'){

    Write-Output '3.4 Ensure IIS HTTP detailed errors are hidden from displaying remotely is compliant'

}


else{

    Write-Output '3.4 Ensure IIS HTTP detailed errors are hidden from displaying remotely is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.webServer/httpErrors" -name "errorMode" -value "DetailedLocalOnly"
    Write-Output 'Rerun script to view changes'
    

}

