#1.1
$website = Get-Website | Format-List Name, PhysicalPath
$physicalPath = $website | Out-String | Select-String -Pattern "PhysicalPath\s*:\s*(.*)" | ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() }
Write-Output '######################## AUDIT ########################'
if($physicalPath -eq "C:\inetpub\wwwroot"){
    Write-Output "1.1 Ensure web content is on non-system partition is non-compliant" 
    Write-Output "REMEDIATION: 
        1. Browse to web content in C:\inetpub\wwwroot\
        2. Copy or cut content onto a dedicated and restricted web folder on a non-system 
        drive such as D:\webroot\
        3. Change mappings for any applications or Virtual Directories to reflect the new 
        location

        To change the mapping for the application named app1 which resides under the Default 
        Web Site, open IIS Manager:
        1. Expand the server node
        2. Expand Sites
        3. Expand Default Web Site
        4. Click on app1
        5. In the Actions pane, select Basic Settings
        6. In the Physical path text box, put the new location of the application, 
        D:\wwwroot\app1 in the example above"  
}
else{
    Write-Output "1.1 Ensure web content is on non-system partition is compliant"
}


#1.2
$result = Get-WebBinding -Port * | Format-List bindingInformation
$bindingInfo = $result | Out-String | Select-String -Pattern "bindingInformation\s*:\s*(.*)" | ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() }
Write-Output '######################## AUDIT ########################'
$result
if($bindingInfo.Contains('*')){
    Write-Output '1.2 Ensure host headers are on all sites is non-compliant'

    ###REPLACE @name with your site name, replace <ip> with your own ip address, localhost with your FQDN
    $configureHost = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/sites/site[@name="Default Web Site"]/bindings/binding[@protocol="http" and @bindingInformation="*:80:"]' -name 'bindingInformation' -value '<ip>:80<port>:FQDN'
    Write-Output 'Rerun script to view changes'
}
else{
    Write-Output '1.2 Ensure host headers are on all sites is compliant'
}


#1.3
$result = Get-WebConfigurationProperty -Filter system.webserver/directorybrowse -PSPath iis:\ -Name Enabled | select Value
#$bindingInfo = $result | Out-String | Select-String -Pattern "bindingInformation\s*:\s*(.*)" | ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() }
Write-Output '######################## AUDIT ########################'
$result
if($result.Value -eq "False"){
    Write-Output "1.3 Ensure 'directory browsing' is set to disabled is non-compliant"
    $result = Set-WebConfigurationProperty -Filter system.webserver/directorybrowse -PSPath iis:\ -Name Enabled -Value False
    Write-Output 'Rerun script to view changes'
}
else{
    Write-Output "1.3 Ensure 'directory browsing' is set to disabled is compliant"
}


#1.4
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


#1.5
$result = Get-Website | Select-Object Name, applicationPool
Write-Output '######################## AUDIT ########################'
$result
if($result.applicationPool.Length -gt 0){
    Write-Output "1.5 Ensure 'unique application pools' is set for sites is compliant"
}
else{
    Write-Output "1.5 Ensure 'unique application pools' is set for sites is non-compliant"
    $result = Set-ItemProperty -Path 'IIS:\Sites\Default Web Site' -Name applicationPool -Value DefaultAppPool
    Write-Output "Rerun script to view changes"
}


#1.6
$result = Get-WebConfiguration system.webServer/security/authentication/anonymousAuthentication -Recurse | where {$_.enabled -eq $true} | Select-Object location
$result
if($result.Location -eq ""){
    Write-Output "1.6 (L1) Ensure 'application pool identity' is configured for anonymous user identity is compliant"
}
else{
    Write-Output "1.6 (L1) Ensure 'application pool identity' is configured for anonymous user identity is non-compliant. Rerun script to view changes"
    $command1 = C:\Windows\system32\inetsrv\appcmd set config -section:anonymousAuthentication /username:"" --password
}


#1.7
$result = Get-WindowsFeature Web-DAV-PublishingWrite-Output '##################### AUDIT ####################'$resultif($result.InstallState -eq 'Available'){    Write-Output '1.7 Ensure WebDav feature is disabled is compliant'}else{    Write-Output '1.7 (L1) Ensure WebDav feature is disabled is non-compliant'    $result = Remove-WindowsFeature Web-DAV-Publishing    Write-Output 'Rerun script to see changes'}


#2.1
$result = C:\Windows\system32\inetsrv\appcmd list config -section:system.webserver/security/authorization
$result
[xml]$xmlresult = $result
$xmlcheck = $xmlresult.'system.webServer'.security.authorization.add -ne $null
$xmlAdd = $xmlresult.'system.webServer'.security.authorization.add | Where-Object { $_.accessType -eq "Allow" -and $_.roles -eq "Administrators" }
$xmlAdd
$xmlcheck
if($xmlcheck -and $xmlAdd){
    Write-Output "2.1 (L1) Ensure 'global authorization rule' is set to restrict access is compliant"
}
else{
    Write-Output "2.1 (L1) Ensure 'global authorization rule' is set to restrict access is not compliant"
    $command1 = Remove-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/authorization" -name "." -AtElement @{users='*';roles='';verbs=''}
    $command2 = Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/authorization" -name "." -value @{accessType='Allow';roles='Administrators'}
}


#2.2
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



#2.3
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter 'system.web/authentication/forms' -name 'requireSSL' | Select-Object Name,Value
$result

Write-Output '####################### AUDIT #######################
'

foreach($result in $result){
    if(-not $result.Value){
        Write-Output '2.3 Ensure forms authentication require SSL is not compliant'
        $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter 'system.web/authentication/forms' -name 'requireSSL' -value 'True'
        Write-Output 'Rerun script to view changes'
    }
    else{    
        Write-Output '2.3 Ensure forms authentication require SSL is compliant'
    }

}


#2.4
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


#2.5
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter 'system.web/authentication/forms' -name 'protection'
$result
Write-Output '#################### AUDIT ######################
'
if($result -eq 'All'){
    Write-Output '2.5 Ensure cookie protection mode is configured for forms authentication is compliant'
}
else{
    Write-Output '2.5 Ensure cookie protection mode is configured for forms authentication is not compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter 'system.web/authentication/forms' -name 'protection' -value 'All'
    Write-Output 'Rerun script to view changes'
}


#2.6
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter 'system.webServer/security/access' -name 'sslFlags'
$result
if($result -eq 'Ssl'){
    Write-Output "2.6 Ensure transport layer security for 'basic authentication' is configured is COMPLIANT"
}
else{
    Write-Output "2.6 Ensure transport layer security for 'basic authentication' is configured is not COMPLIANT"
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter 'system.webServer/security/access' -name 'sslFlags' -value 'Ssl'
    Write-Output 'Rerun script to view changes'
}



#2.7
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter 'system.web/authentication/forms/credentials' -name 'passwordFormat'if($result -eq 'Clear'){     #there are other encryption method based on remediation manual they say make sure not 'Clear'    Write-Output '2.7 Ensure passwordFormat is not set to clear is not compliant'    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter 'system.web/authentication/forms/credentials' -name 'passwordFormat' -value 'SHA1'     Write-Output 'Rerun script to view changes'}else{    Write-Output '2.7 Ensure passwordFormat is not set to clear is compliant'}


#3.2
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/compilation" -name "debug" | Select-Object Name, Value$resultif($result.Value){
    Write-Output '3.2 Ensure debug is turned off is not compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/compilation" -name "debug" -value "False"
    Write-Output 'Rerun script to view changes'
}
else{
    Write-Output '3.2 Ensure debug is turned off is compliant'   
}


#3.3
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/customErrors" -name "mode"
$result
if($result -eq 'RemoteOnly'){
    Write-Output '3.3 Ensure custom error messages are not off is compliant'
}
else{
    Write-Output '3.3 Ensure custom error messages are not off is not compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/customErrors" -name "mode" -value "RemoteOnly"
    Write-Output 'Rerun script to view changes'
}


#3.4
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


#3.5
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/trace" -name "enabled" | Select-Object Name,Value
$result
if(-not $result.Value){
    Write-Output '3.5 (L2) Ensure ASP.NET stack tracing is not enabled is compliant'
}
else{
    Write-Output '3.5 (L2) Ensure ASP.NET stack tracing is not enabled is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/trace" -name "enabled" -value "False"
    Write-Output 'Rerun script to view changes'
}


#3.6
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/sessionState" -name "mode"
if($result -eq 'StateServer'){
    Write-Output "3.6 Ensure 'httpcookie' mode is configured for session state is compliant"
}
else{
    Write-Output "3.6 Ensure 'httpcookie' mode is configured for session state is non-compliant"
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.web/sessionState" -name "mode" -value "StateServer"
    Write-Output 'Rerun script to view changes'
}


#3.9
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT' -filter "system.web/machineKey" -name "validation"
if($result -eq 'AES'){
    Write-Output '3.9 (L1) Ensure MachineKey validation method - .Net 4.5 is configured is compliant'
}
else{
    Write-Output '3.9 (L1) Ensure MachineKey validation method - .Net 4.5 is configured is non-compliant'
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT' -filter "system.web/machineKey" -name "validation" -value "AES"    Write-Output 'Rerun script to view changes'
}


#3.10
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT' -filter "system.web/trust" -name "level"
$result
if($result.Value -eq 'Medium'){ 
    Write-Output '3.10 (L1) Ensure global .NET trust level is configured is compliant'
}
else{
    Write-Output '3.10 (L1) Ensure global .NET trust level is configured is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT' -filter "system.web/trust" -name "level" -value "Medium"
    Write-Output 'Rerun script to view changes'
}

#3.11
$result = C:\Windows\System32\inetsrv\appcmd.exe list config -section:system.webServer/httpProtocol
$result
if($result.Contains('<remove name="X-Powered-By"/>')){
    Write-Output '3.11 (L2) Ensure X-Powered-By Header is removed is non-compliant'
    $command = Remove-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webserver/httpProtocol/customHeaders" -name "." -AtElement @{name='XPowered-By'}
    Write-Output 'Rerun Script to view changes'
}
else{
    Write-Output '3.11 (L2) Ensure X-Powered-By Header is removed is compliant'
}


#3.12
$result = Get-WebConfigurationProperty -pspath machine/webroot/apphost -filter 'system.webserver/security/requestfiltering' -name 'removeServerHeader' | Select-Object Value
$result
if($result.Value){
    Write-Output '3.12 (L2) Ensure Server Header is removed is compliant'
}
else{
    Write-Output '3.12 (L2) Ensure Server Header is removed is non-compliant'
    $command = C:\Windows\system32\inetsrv\appcmd.exe set config -section:system.webServer/security/requestFiltering /removeServerHeader:"True" /commit:apphost    Write-Output 'Rerun script to view changes'
}


#4.1
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxAllowedContentLength"
$result
if($result.Value -gt 30000000){
    Write-Output '4.1 (L2) Ensure maxAllowedContentLength is configured is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxAllowedContentLength" -value 30000000
    Write-Output 'Rerun script to view changes'
}
else{
    Write-Output '4.1 (L2) Ensure maxAllowedContentLength is configured is compliant'
}


#4.2
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxUrl"
$result
if($result.Value -gt 4096){
    Write-Output '4.2 (L2) Ensure maxURL request filter is configured is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxUrl" -value 4096
    Write-Output 'Rerun script to view changes'
}
else{
    Write-Output '4.2 (L2) Ensure maxURL request filter is configured is compliant' 
}



#4.3
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxQueryString"
$result
if($result.Value -gt 2048){
    Write-Output '4.3 (L2) Ensure MaxQueryString request filter is configured is non-compliant'
    $command =  Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxQueryString" -value 2048
    Write-Output 'Rerun script to view changes'
}
else{
    Write-Output '4.3 (L2) Ensure MaxQueryString request filter is configured is compliant' 
}



#4.4
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.webServer/security/requestFiltering' -name 'allowHighBitCharacters'
$result
if($result.Value){
    Write-Output '4.4 (L2) Ensure non-ASCII characters in URLs are not allowed is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering" -name "allowHighBitCharacters" -value "False"
    Write-Output 'Rerun script to view changes'
}
else{
    Write-Output '4.4 (L2) Ensure non-ASCII characters in URLs are not allowed is compliant'
}



#4.5
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering" -name "allowDoubleEscaping"
$result
if($result.Value){ 
    Write-Output '4.5 (L1) Ensure Double-Encoded requests will be rejected is compliant'
}
else{
    Write-Output '4.5 (L1) Ensure Double-Encoded requests will be rejected is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering" -name "allowDoubleEscaping" -value "True"    Write-Output 'Rerun script to view changes'
}


#4.6
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


#4.7
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/fileExtensions" -name "allowUnlisted"
$result
if($result.Value){
    Write-Output '4.7 (L1) Ensure Unlisted File Extensions are not allowed is non-compliant'
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/fileExtensions" -name "allowUnlisted" -value "False"    Write-Output 'Rerun the script to view changes'
}
else{
    Write-Output '4.7 (L1) Ensure Unlisted File Extensions are not allowed is compliant'
}


#4.8
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/handlers" -name "accessPolicy"$resultif($result -eq "Read,Script"){    Write-Output '4.8 (L1) Ensure Handler is not granted Write and Script/Execute is compliant'}else{    Write-Output '4.8 (L1) Ensure Handler is not granted Write and Script/Execute is non-compliant'    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/handlers" -name "accessPolicy" -value "Read,Script"    Write-Output 'Rerun script to view changes'}


#4.9
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/isapiCgiRestriction" -name "notListedIsapisAllowed"
$result
if($result.Value){
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/isapiCgiRestriction" -name "notListedIsapisAllowed" -value "False"    Write-Output "4.9 (L1) Ensure 'notListedIsapisAllowed' is set to false is non-compliant. Rerun to view changes"
}
else{
    Write-Output "4.9 (L1) Ensure 'notListedIsapisAllowed' is set to false is compliant"
}


#4.10
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/isapiCgiRestriction" -name "notListedCgisAllowed"
$result
if($result.Value){
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/isapiCgiRestriction" -name "notListedCgisAllowed" -value "False"
    Write-Output "4.10 (L1) Ensure 'notListedCgisAllowed' is set to false is non-compliant. Rerun script to view changes"
}
else{
    Write-Output "4.10 (L1) Ensure 'notListedCgisAllowed' is set to false is compliant"
}


$4.11
$result1 = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/dynamicIpSecurity/denyByConcurrentRequests" -name "enabled"
$result1
$result2 = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/dynamicIpSecurity/denyByConcurrentRequests" -name "maxConcurrentRequests"
$result2
if($result1.Value){  
    Write-Output "4.11 (L1) Ensure 'Dynamic IP Address Restrictions' is enabled is compliant"
}else{  
    $command1 = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/dynamicIpSecurity/denyByConcurrentRequests" -name "enabled" -value "True"    $command2 = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/dynamicIpSecurity/denyByConcurrentRequests" -name "maxConcurrentRequests" -value 20
    Write-Output "4.11 (L1) Ensure 'Dynamic IP Address Restrictions' is enabled is non-compliant. Rerun script to view changes"
}


#5.1
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/siteDefaults/logFile" -name "directory"
$result
if($result -eq "%SystemDrive%\inetpub\logs\LogFiles"){   
    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/siteDefaults/logFile" -name "directory" -value <DIRECTORY_TO_STORE_LOG_FILES>
    Write-Output "5.1 (L1) Ensure Default IIS web log location is moved is non-compliant. Rerun script to view changes"
}
else{
    Write-Output "5.1 (L1) Ensure Default IIS web log location is moved is compliant"
}


#6.1
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


#6.2
$result = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.ftpServer/security/authentication/denyByFailure" -name "enabled"$resultif($result.Value){    Write-Output "6.2 (L1) Ensure FTP Logon attempt restrictions is enabled is compliant"}else{    $command = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.ftpServer/security/authentication/denyByFailure" -name "enabled" -value "True"    Write-Output "6.2 (L1) Ensure FTP Logon attempt restrictions is enabled is non-compliant. Rerun script to view changes"}

#7.2
$result1 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -name 'Enabled' | Select-Object Enabled
$result2 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -name 'Enabled' | Select-Object Enabled
$result3 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -name 'DisabledByDefault' | Select-Object DisabledByDefault
$result4 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -name 'DisabledByDefault' | Select-Object DisabledByDefault
$result1.Enabled
$result2.Enabled
$result3.DisabledByDefault
$result4.DisabledByDefault
if($result1.Enabled -eq 0 -and $result2.Enabled -eq 0 -and $result3.DisabledByDefault -eq 1 -and $result4.DisabledByDefault -eq 1){
    Write-Output "7.2 (L1) Ensure SSLv2 is Disabled is compliant"
}
else{
    Write-Output "7.2 (L1) Ensure SSLv2 is Disabled is non-compliant. Rerun script to view changes"
    $command1 = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -Force | Out-Null
    $command2 = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -Force | Out-Null
    $command3 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
    $command4 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
    $command5 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -name 'DisabledByDefault' -value '1' -PropertyType 'DWord' -Force | Out-Null
    $command6 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -name 'DisabledByDefault' -value '1' -PropertyType 'DWord' -Force | Out-Null
}


#7.3
$result1 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server' -name 'Enabled' | Select-Object Enabled
$result2 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client' -name 'Enabled' | Select-Object Enabled
$result3 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server' -name 'DisabledByDefault' | Select-Object DisabledByDefault
$result4 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client' -name 'DisabledByDefault' | Select-Object DisabledByDefault
$result1.Enabled
$result2.Enabled
$result3.DisabledByDefault
$result4.DisabledByDefault
if($result1.Enabled -eq 0 -and $result2.Enabled -eq 0 -and $result3.DisabledByDefault -eq 1 -and $result4.DisabledByDefault -eq 1){    
    Write-Output "7.3 (L1) Ensure SSLv3 is Disabled is compliant"
}
else{    
    Write-Output "7.3 (L1) Ensure SSLv3 is Disabled is non-compliant. Rerun script to view changes"
    $command1 = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server' -Force | Out-Null
    $command2 = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client' -Force | Out-Null
    $command3 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
    $command4 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
    $command5 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server' -name 'DisabledByDefault' -value '1' -PropertyType 'DWord' -Force | Out-Null
    $command6 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client' -name 'DisabledByDefault' -value '1' -PropertyType 'DWord' -Force | Out-Null
}


#7.4
$result1 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -name 'Enabled' | Select-Object Enabled
$result2 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -name 'Enabled' | Select-Object Enabled
$result3 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -name 'DisabledByDefault' | Select-Object DisabledByDefault
$result4 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -name 'DisabledByDefault' | Select-Object DisabledByDefault
$result1.Enabled
$result2.Enabled
$result3.DisabledByDefault
$result4.DisabledByDefault
if($result1.Enabled -eq 0 -and $result2.Enabled -eq 0 -and $result3.DisabledByDefault -eq 1 -and $result4.DisabledByDefault -eq 1){
    Write-Output "7.4 (L1) Ensure TLS 1.0 is Disabled is compliant"
}
else{
    Write-Output "7.4 (L1) Ensure TLS 1.0 is Disabled is non-compliant. Rerun script to view changes"
    $command1 = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -Force | Out-Null
    $command2 = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -Force | Out-Null
    $command3 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
    $command4 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
    $command5 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -name 'DisabledByDefault' -value '1' -PropertyType 'DWord' -Force | Out-Null
    $command6 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -name 'DisabledByDefault' -value '1' -PropertyType 'DWord' -Force | Out-Null
}


#7.5
$result1 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -name 'Enabled' | Select-Object Enabled
$result2 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -name 'Enabled' | Select-Object Enabled
$result3 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -name 'DisabledByDefault' | Select-Object DisabledByDefault
$result4 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -name 'DisabledByDefault' | Select-Object DisabledByDefault
$result1.Enabled
$result2.Enabled
$result3.DisabledByDefault
$result4.DisabledByDefault
if($result1.Enabled -eq 0 -and $result2.Enabled -eq 0 -and $result3.DisabledByDefault -eq 1 -and $result4.DisabledByDefault -eq 1){
    Write-Output "7.5 (L1) Ensure TLS 1.1 is Disabled is compliant"
}
else{
    Write-Output "7.5 (L1) Ensure TLS 1.1 is Disabled is non-compliant. Rerun script to view changes"
    $command1 = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -Force | Out-Null
    $command2 = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -Force | Out-Null
    $command3 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
    $command4 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
    $command5 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -name 'DisabledByDefault' -value '1' -PropertyType 'DWord' -Force | Out-Null
    $command6 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -name 'DisabledByDefault' -value '1' -PropertyType 'DWord' -Force | Out-Null
}


#7.6
$result1 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'Enabled'
$result2 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'DisabledByDefault'
$result1.Enabled
$result2.DisabledByDefault
if($result1.Enabled -eq 1 -and $result2.DisabledByDefault -eq 0){
    Write-Output "7.6 (L1) Ensure TLS 1.2 is Enabled is compliant"
}
else{  
    Write-Output "7.6 (L1) Ensure TLS 1.2 is Enabled is non-compliant. Rerun script to view changes"
    $command1 = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Force | Out-Null
    $command2 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null
    $command3 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'DisabledByDefault' -value '0' -PropertyType 'DWord' -Force | Out-Null
}


#7.7
$result = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\NULL' -name 'Enabled'
$result
if($result.Enabled -eq 0){
    Write-Output "7.7 (L1) Ensure NULL Cipher Suites is Disabled is compliant"
}
else{
    Write-Output "7.7 (L1) Ensure NULL Cipher Suites is Disabled is non-compliant. Rerun script to view changes"
    $command = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\NULL' -Force | Out-Null
    $command1 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\NULL' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null}


#7.8
$result = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\DES 56/56' -name 'Enabled'
$result
if($result.Enabled -eq 0){
    Write-Output "7.8 (L1) Ensure DES Cipher Suites is Disabled is compliant"
}
else{
    Write-Output "7.8 (L1) Ensure DES Cipher Suites is Disabled is non-compliant. Rerun script to view changes"
    $command1 = (Get-Item 'HKLM:\').OpenSubKey('SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers', $true).CreateSubKey('DES 56/56')
    $command2 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\DES 56/56' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
}


#7.9
$result1 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 40/128' -name 'Enabled'
$result2 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 56/128' -name 'Enabled'
$result3 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 64/128' -name 'Enabled'
$result4 = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 128/128' -name 'Enabled'
$result1
$result2
$result3
$result4
if($result1.Enabled -eq 0 -and $result2.Enabled -eq 0 -and $result3.Enabled -eq 0 -and $result4.Enabled -eq 0){
    Write-Output "7.9 (L1) Ensure RC4 Cipher Suites is Disabled is compliant"
}
else{
    Write-Output "7.9 (L1) Ensure RC4 Cipher Suites is Disabled is non-compliant. Rerun script to view changes"
    $command1 = (Get-Item 'HKLM:\').OpenSubKey('SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers', $true).CreateSubKey('RC4 40/128')
    $command2 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 40/128' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
    $command3 = (Get-Item 'HKLM:\').OpenSubKey('SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers', $true).CreateSubKey('RC4 56/128')
    $command4 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 56/128' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
    $command5 = (Get-Item 'HKLM:\').OpenSubKey('SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers', $true).CreateSubKey('RC4 64/128')
    $command6 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 64/128' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
    $command7 = (Get-Item 'HKLM:\').OpenSubKey('SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers', $true).CreateSubKey('RC4 128/128')
    $command8 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 128/128' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
}


#7.10
$result = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 128/128' -name 'Enabled'$resultif($result.Enabled -eq 0){    Write-Output "7.10 (L1) Ensure AES 128/128 Cipher Suite is Disabled is compliant"
}
else{
    Write-Output "7.10 (L1) Ensure AES 128/128 Cipher Suite is Disabled is non-compliant. Rerun script to view changes"
    $command1 = (Get-Item 'HKLM:\').OpenSubKey('SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers', $true).CreateSubKey('AES 128/128')
    $command2 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 128/128' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
}


#7.11
$result = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 256/256' -name 'Enabled'$resultif($result.Enabled -eq 1){    Write-Output "7.11 (L1) Ensure AES 256/256 Cipher Suite is Enabled is compliant"
}
else{
    Write-Output "7.11 (L1) Ensure AES 256/256 Cipher Suite is Enabled is non-compliant. Rerun script to view changes"
    $command1 = (Get-Item 'HKLM:\').OpenSubKey('SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers', $true).CreateSubKey('AES 256/256')
    $command2 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 256/256' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null
}


#7.12
$result = Get-ItemProperty -path 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -name 'Functions'$resultif($result.Functions -eq "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"){    Write-Output "7.12 (L2) Ensure TLS Cipher Suite ordering is Configured is compliant"}else{    Write-Output "7.12 (L2) Ensure TLS Cipher Suite ordering is Configured is non-compliant. Rerun script to view changes"    $command1 = New-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -Force | Out-Null
    $command2 = New-ItemProperty -path 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -name 'Functions' -value 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256' -PropertyType 'MultiString' -Force | Out-Null}