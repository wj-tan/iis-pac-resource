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