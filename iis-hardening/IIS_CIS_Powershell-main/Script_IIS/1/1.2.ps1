$result = Get-WebBinding -Port * | Format-List bindingInformation
$bindingInfo = $result | Out-String | Select-String -Pattern "bindingInformation\s*:\s*(.*)" | ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() }


Write-Output '######################## AUDIT ########################'

$result

if($bindingInfo.Contains('*')){
    Write-Output '1.2 Ensure host headers are on all sites is non-compliant'

    ###REPLACE @name with your site name, replace <ip> with your own ip address, localhost with your FQDN
    $configureHost = Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/sites/site[@name="Default Web Site"]/bindings/binding[@protocol="http" and @bindingInformation="*:80:"]' -name 'bindingInformation' -value '192.168.1.104:80:localhost'
    Write-Output 'Rerun script to view changes'

}
else{
    Write-Output '1.2 Ensure host headers are on all sites is compliant'
}