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