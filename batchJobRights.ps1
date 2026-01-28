# Get the SID for LAB\svc_taskscheduler
$Account = 'LAB\svc_taskscheduler'
$SID = (New-Object System.Security.Principal.NTAccount($Account)).
       Translate([System.Security.Principal.SecurityIdentifier]).Value

Write-Host "SID for $Account is $SID"

# Create a minimal INF file to grant SeBatchLogonRight
$Policy = @'
[Unicode]
Unicode=yes
[Version]
signature="$CHICAGO$"
Revision=1
[Privilege Rights]
SeBatchLogonRight = *S-1-5-32-544,*S-1-5-32-551,*S-1-5-32-559,*S-1-5-32-568,
'@ + "*$SID"

$Policy | Out-File C:\Temp\grant_batchlogon.inf -Encoding ASCII -Force

# Import & apply new policy
secedit.exe /import /db C:\Temp\grant_batchlogon.sdb /cfg C:\Temp\grant_batchlogon.inf
secedit.exe /configure /db C:\Temp\grant_batchlogon.sdb /cfg C:\Temp\grant_batchlogon.inf /areas USER_RIGHTS
