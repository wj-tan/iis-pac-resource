# ==============================

# Configuration

# ==============================

$SourceFile = "D:\TaskSchedulerTest\test.pac"

$Destination1 = "\\192.168.14.12\D$\TaskSchedulerTest\test.pac"
$Destination2 = "\\Server2\D$\TaskSchedulerTest\test.pac"

$LogFile = "D:\TaskSchedulerTest\pac_copy_test.log"

# ==============================

# Logging Function

# ==============================

function Write-Log {
    param ([string]$Message)


    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "$Timestamp - $Message"
    Add-Content -Path $LogFile -Value $Entry


}

Write-Log "===== Script Started ====="
Write-Log "Running as user: $env:USERDOMAIN\$env:USERNAME"
Write-Log "Running on machine: $env:COMPUTERNAME"

# ==============================

# Check Source File

# ==============================

if (!(Test-Path $SourceFile)) {
    Write-Log "ERROR: Source file not found: $SourceFile"
    exit 1
}

Write-Log "Source file located successfully."

# ==============================

# Copy to Server1

# ==============================

try {
    Copy-Item $SourceFile -Destination $Destination1 -Force -ErrorAction Stop
    Write-Log "SUCCESS: Copied to $Destination1"
}
catch {
    Write-Log "ERROR copying to Server1: $($_.Exception.Message)"
}

# ==============================

# Copy to Server2

# ==============================

try {
    Copy-Item $SourceFile -Destination $Destination2 -Force -ErrorAction Stop
    Write-Log "SUCCESS: Copied to $Destination2"
}
catch {
    Write-Log "ERROR copying to Server2: $($_.Exception.Message)"
}

Write-Log "===== Script Finished ====="
