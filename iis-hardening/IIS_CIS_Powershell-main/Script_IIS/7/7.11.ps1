$result = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 256/256' -name 'Enabled'
$result

if($result.Enabled -eq 1){

    Write-Output "7.11 (L1) Ensure AES 256/256 Cipher Suite is Enabled is compliant"

}
else{
    
    Write-Output "7.11 (L1) Ensure AES 256/256 Cipher Suite is Enabled is non-compliant. Rerun script to view changes"
    $command1 = (Get-Item 'HKLM:\').OpenSubKey('SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers', $true).CreateSubKey('AES 256/256')
    $command2 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 256/256' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null
}
