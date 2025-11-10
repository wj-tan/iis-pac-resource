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

