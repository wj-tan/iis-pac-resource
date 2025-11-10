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
