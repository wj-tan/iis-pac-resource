$taskName  = "Sync PAC File"
$taskPath  = "\PAC Sync"
$script    = "C:\Scripts\sync-pacFile.ps1"
$username  = "LAB\Administrator"
$password  = "P@ssw0rd"

# Define the Action
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoLogo -ExecutionPolicy Bypass -NoProfile -NonInteractive -File `"$script`""

# Define the Trigger (every 1 minute)
$trigger = New-ScheduledTaskTrigger -Once -At ([DateTime]::Now.AddMinutes(1)) -RepetitionInterval ([TimeSpan]::FromMinutes(1))

# Define the Principal (runs even when logged off)
$principal = New-ScheduledTaskPrincipal -UserId $username -LogonType Password -RunLevel Highest

# Combine into Task
$task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Description "Sync PAC file every minute."

# Register the Task
Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -InputObject $task -User $username -Password $password
