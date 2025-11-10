$result = Get-WebConfiguration system.webServer/security/authentication/* -Recurse | Where-Object {$_.enabled -eq $true} | Select-Object SectionPath,PSPath,Location
$result

$anonymousCheck = $false

Write-Output '###################### AUDIT #####################
'

#if there is more than 1 result
if($result.Count -gt 1){
#IGNORE THE FIRST LINE
    foreach($value in $result[1..($result.Count-1)]){

        $path = $value.Location
        $sectionPath = $value.SectionPath
        
               
        if($sectionPath -eq '/system.webServer/security/authentication/windowsAuthentication'){
            
            if($path -gt 0){
                Write-Output 'Windows Authentication is compliant'
            }
            else{
                Write-Output 'Windows Authentication is not compliant'
                $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter 'system.webServer/security/authentication/windowsAuthentication' -name 'enabled' -value 'True'
                Write-Output 'Rerun script to view changes'
            }

            $windowsCheck = $true

        }

        if($sectionPath -eq '/system.webServer/security/authentication/anonymousAuthentication'){
            
            Write-Output 'Anonymous Authentication is not compliant'
            $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter 'system.webServer/security/authentication/anonymousAuthentication' -name 'enabled' -value 'False'
            $command1 = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter 'system.webServer/security/authentication/windowsAuthentication' -name 'enabled' -value 'True'
            Write-Output 'Rerun script to view changes'
            $anonymousCheck = $true
        }
    }
    
        
    if(-not $anonymousCheck){
        Write-Output 'Anonymous Authentication is compliant'
    }

       
}
else{
    Write-Output '2.2 Ensure access to sensitive site features is restricted to authenticated principals only is not compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter 'system.webServer/security/authentication/anonymousAuthentication' -name 'enabled' -value 'False'
    $command1 = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter 'system.webServer/security/authentication/windowsAuthentication' -name 'enabled' -value 'True'
    Write-Output 'Rerun script to view changes'
}

