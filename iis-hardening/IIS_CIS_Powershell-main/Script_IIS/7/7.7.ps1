$result = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\NULL' -name 'Enabled'
$result

if($result.Enabled -eq 0){

    Write-Output "7.7 (L1) Ensure NULL Cipher Suites is Disabled is compliant"

}
else{
    
    Write-Output "7.7 (L1) Ensure NULL Cipher Suites is Disabled is non-compliant. Rerun script to view changes"
    $command = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\NULL' -Force | Out-Null
    $command1 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\NULL' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null


}
