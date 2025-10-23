<#
.SYNOPSIS
    Sync PAC file from Primary IIS Server (DCA) to Secondary IIS Servers
.DESCRIPTION
    1. Detects the last modified timestamp of the PAC file.
    2. Creates a timestamped backup in the Archive folder.
    3. Copies PAC file and Archive folder to secondary IIS servers.
    4. Logs the status and emails the result.
#>

# ====================== CONFIGURATION ===========================
$SourceFile       = "C:\inetpub\wwwroot\proxy.pac"              # PAC file path on primary server
$ArchiveFolder    = "C:\PAC_Archive"                            # Archive folder
$SecondaryServers = @("server02", "server03")                 # Target IIS servers
$TargetPath       = "C$\inetpub\wwwroot"                        # Target path on secondary servers

$LogFile          = "C:\PAC_Sync\SyncLog_$(Get-Date -Format 'yyyyMMdd').log" # Log file of the operation
#$SmtpServer       = "mail.yourdomain.com"
#$MailFrom         = "PACSync@yourdomain.com"
#$MailTo           = "NetOps@yourdomain.com"
#$SubjectSuccess   = "PAC File Sync - SUCCESS"
#$SubjectFailure   = "PAC File Sync - FAILURE"
# ================================================================

# Ensure required folders exist
try {
    if (!(Test-Path $ArchiveFolder)) { New-Item -ItemType Directory -Path $ArchiveFolder -Force | Out-Null }
    if (!(Test-Path (Split-Path $LogFile))) { New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null }
} catch {
    Write-Host "CRITICAL: Failed to create required directories. Error: $($_.Exception.Message)"
    exit 1
}

# Function to log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$Timestamp [$Level] $Message"
    $logEntry | Out-File -FilePath $LogFile -Append
    Write-Host $logEntry
}

# ====================== STEP 1: CHECK TIMESTAMP ===========================
try {
    if (!(Test-Path -Path $SourceFile)) {
        throw "PAC file not found at $SourceFile"
    }

    $LastModified = (Get-Item $SourceFile -ErrorAction Stop).LastWriteTime
    Write-Log "PAC file found. Last modified: $LastModified"

} catch {
    $err = $_.Exception.Message
    Write-Log "ERROR: $err" "ERROR"
    Send-MailMessage -SmtpServer $SmtpServer -From $MailFrom -To $MailTo -Subject $SubjectFailure `
        -Body "PAC file sync failed. Reason: $err" -BodyAsHtml
    exit 1
}

# ====================== STEP 1.5: CHECK IF PAC FILE CHANGED ===========================
try {
    # Get latest archived file
    $LatestArchive = Get-ChildItem -Path $ArchiveFolder -Filter "proxy_*.pac" -ErrorAction SilentlyContinue |
                     Sort-Object LastWriteTime -Descending |
                     Select-Object -First 1

    if ($null -ne $LatestArchive) {
        $ArchivedTime = $LatestArchive.LastWriteTime
        Write-Log "Latest archived PAC file: $($LatestArchive.Name) (Archived at: $ArchivedTime)"

        # Compare timestamps
        if ($LastModified -le $ArchivedTime) {
            Write-Log "No change detected to PAC file since last archive."
            $SkipArchive = $true
        } else {
            Write-Log "PAC file updated after last archive. Proceeding to create new archive."
            $SkipArchive = $false
        }
    } else {
        Write-Log "No previous archive found. Proceeding to create first archive."
        $SkipArchive = $false
    }
} catch {
    $err = $_.Exception.Message
    Write-Log "WARNING: Failed to check existing archives. Proceeding to create archive. $err" "WARN"
    $SkipArchive = $false
}

if (-not $SkipArchive) {
    # ====================== STEP 2: ARCHIVE COPY ===========================
    $ArchiveFile = Join-Path $ArchiveFolder ("proxy_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".pac")
    try {
        Copy-Item -Path $SourceFile -Destination $ArchiveFile -Force -ErrorAction Stop
        Write-Log "PAC file archived successfully as $ArchiveFile"
    } catch {
        $err = $_.Exception.Message
        Write-Log "ERROR: Failed to archive PAC file. $err" "ERROR"
        Send-MailMessage -SmtpServer $SmtpServer -From $MailFrom -To $MailTo -Subject $SubjectFailure `
            -Body "PAC file sync failed while archiving.<br>Error: $err" -BodyAsHtml
        exit 1
    }


} else {
    Write-Log "Skipping archive."
}

# ====================== STEP 3: COPY TO SECONDARY SERVERS ===========================
$SuccessCount = 0
foreach ($Server in $SecondaryServers) {
    try {
        $UNCPathFile    = "\\$Server\$TargetPath\proxy.pac"
        $UNCPathArchive = "\\$Server\C$\PAC_Archive"

        # Check server connectivity before copy
        if (-not (Test-Connection -ComputerName $Server -Count 2 -Quiet)) {
            throw "Server $Server is not reachable."
        }

        # Ensure archive folder exists on remote server
        if (!(Test-Path $UNCPathArchive)) {
            New-Item -ItemType Directory -Path $UNCPathArchive -Force -ErrorAction Stop | Out-Null
            Write-Log "Archive folder created on $Server"
        }

        # Copy main PAC file
        Copy-Item -Path $SourceFile -Destination $UNCPathFile -Force -ErrorAction Stop
        Write-Log "PAC file copied successfully to $UNCPathFile"

        # Copy all files in archive folder
        $ArchiveFiles = Get-ChildItem -Path $ArchiveFolder -Filter "*.pac" -File
        if ($ArchiveFiles.Count -gt 0) {
            foreach ($File in $ArchiveFiles) {
                Copy-Item -Path $File.FullName -Destination $UNCPathArchive -Force -ErrorAction Stop
                Write-Log "Archive file ($($File.Name)) copied successfully to $UNCPathArchive"
            }
        } else {
            Write-Log "No archive files found to copy — skipping archive sync." "WARN"
        }

        $SuccessCount++
    } catch {
        $err = $_.Exception.Message
        Write-Log "ERROR: Failed to copy to $Server. $err" "ERROR"
        # Optional: Continue to next server without breaking entire script
    }
}

<# ====================== STEP 4: LOG AND EMAIL ===========================
try {
    if ($SuccessCount -eq $SecondaryServers.Count) {
        $Body = @"
PAC File Sync Completed Successfully

Source: $SourceFile
Last Modified: $LastModified
Archive: $ArchiveFile
Targets: $($SecondaryServers -join ", ")

See log for details: $LogFile
"@
        Write-Log "Sync completed successfully on all servers."
        Send-MailMessage -SmtpServer $SmtpServer -From $MailFrom -To $MailTo -Subject $SubjectSuccess -Body $Body
    } else {
        $Body = @"
PAC File Sync Completed with Errors

Source: $SourceFile
Last Modified: $LastModified
Archive: $ArchiveFile
Targets: $($SecondaryServers -join ", ")
Successful: $SuccessCount
Failed: $($SecondaryServers.Count - $SuccessCount)

Please check log: $LogFile
"@
        Write-Log "Sync completed with errors."
        Send-MailMessage -SmtpServer $SmtpServer -From $MailFrom -To $MailTo -Subject $SubjectFailure -Body $Body
    }
} catch {
    $err = $_.Exception.Message
    Write-Log "CRITICAL: Failed to send email notification. $err" "ERROR"
}

# ====================== STEP 5: EXIT CLEANLY ===========================
Write-Log "Script execution finished."
exit 0
#>