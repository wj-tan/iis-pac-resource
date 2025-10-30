# ====================== CONFIGURATION ===========================
$PACFiles          = @("proxy_sg.pac", "proxy_my.pac", "proxy_vn.pac") # List of PAC files
$SourceFolder      = "C:\inetpub\wwwroot"
$ArchiveFolder     = "C:\PAC_Archive"
$SecondaryServers  = @("server02", "server03")
$TargetPath        = "C$\inetpub\wwwroot"
$LogFile           = "C:\PAC_Sync\SyncLog_$(Get-Date -Format 'yyyyMMdd').log"

# ====================== INITIAL SETUP ===========================

# Check if archieve folder exists on the primary iis server
try {
    if (!(Test-Path $ArchiveFolder)) { New-Item -ItemType Directory -Path $ArchiveFolder -Force | Out-Null }
    if (!(Test-Path (Split-Path $LogFile))) { New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null }
} catch {
    Write-Host "CRITICAL: Failed to create required directories. Error: $($_.Exception.Message)"
    exit 1
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$Timestamp [$Level] $Message"
    $logEntry | Out-File -FilePath $LogFile -Append
    Write-Host $logEntry
}

# ====================== PROCESS PAC FILES ===========================
$FilesToSync = @()

foreach ($PACFile in $PACFiles) {
    $SourceFile = Join-Path $SourceFolder $PACFile
    $ArchivePattern = "$($PACFile -replace '\.pac$', '_*.pac')"
    $ArchiveFileName = "$($PACFile -replace '\.pac$', "_$(Get-Date -Format 'yyyyMMdd_HHmmss').pac")"
    $ArchiveFilePath = Join-Path $ArchiveFolder $ArchiveFileName

    try { # Check if PAC file exist
        if (!(Test-Path -Path $SourceFile)) {
            Write-Log "WARNING: PAC file not found: $SourceFile" "WARN"
            continue
        }

        # Retrieves the last modified timestamp of the PAC file
        $LastModified = (Get-Item $SourceFile).LastWriteTime 
        Write-Log "PAC file '$PACFile' found. Last modified: $LastModified"

        # Searches the archive folder for the latest archived version of this PAC file.
        $LatestArchive = Get-ChildItem -Path $ArchiveFolder -Filter $ArchivePattern -ErrorAction SilentlyContinue |
                         Sort-Object LastWriteTime -Descending |
                         Select-Object -First 1

        $ShouldArchive = $true
        if ($LatestArchive) {
            $ArchivedTime = $LatestArchive.LastWriteTime
            Write-Log "Latest archive for '$PACFile': $($LatestArchive.Name) (Archived at: $ArchivedTime)"

            # If the PAC file hasn’t changed since the last archive, it skips archiving by setting $ShouldArchive to false.
            if ($LastModified -le $ArchivedTime) {
                Write-Log "No change detected for '$PACFile'. Skipping archive."
                $ShouldArchive = $false
            }
        } else {
            Write-Log "No previous archive found for '$PACFile'. Proceeding to archive."
        }

        # If the PAC file has changed ($ShouldArchive = true), it creates a new archive and adds the file to $FilesToSync.
        if ($ShouldArchive) {
            Copy-Item -Path $SourceFile -Destination $ArchiveFilePath -Force -ErrorAction Stop
            Write-Log "Archived '$PACFile' as $ArchiveFilePath"
            $FilesToSync += $PACFile
        }

    } catch {
        Write-Log "ERROR processing '$PACFile': $($_.Exception.Message)" "ERROR"
    }
}

# ====================== COPY TO SECONDARY SERVERS ===========================
if ($FilesToSync.Count -gt 0) {
    Write-Log "Changes detected in PAC files: $($FilesToSync -join ', '). Proceeding to sync."

    foreach ($Server in $SecondaryServers) {
        try {
            if (-not (Test-Connection -ComputerName $Server -Count 2 -Quiet)) {
                throw "Server $Server is not reachable."
            }

            $UNCPathArchive = "\\$Server\C$\PAC_Archive"
            if (!(Test-Path $UNCPathArchive)) {
                New-Item -ItemType Directory -Path $UNCPathArchive -Force -ErrorAction Stop | Out-Null
                Write-Log "Archive folder created on $Server"
            }

            foreach ($PACFile in $FilesToSync) {
                $SourceFile = Join-Path $SourceFolder $PACFile
                $UNCPathFile = "\\$Server\$TargetPath\$PACFile"

                Copy-Item -Path $SourceFile -Destination $UNCPathFile -Force -ErrorAction Stop
                Write-Log "Copied '$PACFile' to $UNCPathFile"
            }

            # Sync all archive files
            $ArchiveFiles = Get-ChildItem -Path $ArchiveFolder -Filter "*.pac" -File
            foreach ($File in $ArchiveFiles) {
                Copy-Item -Path $File.FullName -Destination $UNCPathArchive -Force -ErrorAction Stop
                Write-Log "Copied archive file '$($File.Name)' to $UNCPathArchive"
            }

        } catch {
            Write-Log "ERROR syncing to $Server: $($_.Exception.Message)" "ERROR"
        }
    }
} else {
    Write-Log "No PAC file changes detected. Skipping sync to secondary servers."
}

Write-Log "Script execution finished."
exit 0