$result = Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 128/128' -name 'Enabled'$resultif($result.Enabled -eq 0){    Write-Output "7.10 (L1) Ensure AES 128/128 Cipher Suite is Disabled is compliant"

}
else{
    
    Write-Output "7.10 (L1) Ensure AES 128/128 Cipher Suite is Disabled is non-compliant. Rerun script to view changes"
    $command1 = (Get-Item 'HKLM:\').OpenSubKey('SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers', $true).CreateSubKey('AES 128/128')
    $command2 = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 128/128' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null

}