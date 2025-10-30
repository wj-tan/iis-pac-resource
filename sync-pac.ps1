# ====================== CONFIGURATION ===========================
$PACFiles          = @("proxy_sg.pac", "proxy_my.pac", "proxy_vn.pac")
$SourceFolder      = "C:\inetpub\wwwroot"
$ArchiveFolder     = "C:\PAC_Archive"
$SecondaryServers  = @("server02", "server03")
$TargetPath        = "C$\inetpub\wwwroot"
$LogFile           = "C:\PAC_Sync\SyncLog_$(Get-Date -Format 'yyyyMMdd').log"
$FirstRunFlag      = "C:\PAC_Sync\first_run.flag"

# ====================== INITIAL SETUP ===========================
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

$IsFirstRun = -not (Test-Path $FirstRunFlag)

# ====================== PROCESS PAC FILES ===========================
$FilesToSync = @()
$NewArchives = @{}

foreach ($PACFile in $PACFiles) {
    $SourceFile = Join-Path $SourceFolder $PACFile
    $ArchivePattern = "$($PACFile -replace '\.pac$', '_*.pac')"
    $ArchiveFileName = "$($PACFile -replace '\.pac$', "_$(Get-Date -Format 'yyyyMMdd_HHmmss').pac")"
    $ArchiveFilePath = Join-Path $ArchiveFolder $ArchiveFileName

    try {
        if (!(Test-Path -Path $SourceFile)) {
            Write-Log "WARNING: PAC file not found: $SourceFile" "WARN"
            continue
        }

        $LastModified = (Get-Item $SourceFile).LastWriteTime
        Write-Log "PAC file '$PACFile' found. Last modified: $LastModified"

        $LatestArchive = Get-ChildItem -Path $ArchiveFolder -Filter $ArchivePattern -ErrorAction SilentlyContinue |
                         Sort-Object LastWriteTime -Descending |
                         Select-Object -First 1

        $ShouldArchive = $true
        if ($LatestArchive -and -not $IsFirstRun) {
            $ArchivedTime = $LatestArchive.LastWriteTime
            Write-Log "Latest archive for '$PACFile': $($LatestArchive.Name) (Archived at: $ArchivedTime)"
            if ($LastModified -le $ArchivedTime) {
                Write-Log "No change detected for '$PACFile'. Skipping archive."
                $ShouldArchive = $false
            }
        } else {
            Write-Log "No previous archive found or first run. Proceeding to archive."
        }

        if ($ShouldArchive) {
            Copy-Item -Path $SourceFile -Destination $ArchiveFilePath -Force -ErrorAction Stop
            Write-Log "Archived '$PACFile' as $ArchiveFilePath"
            $FilesToSync += $PACFile
            $NewArchives[$PACFile] = $ArchiveFilePath
        }

    } catch {
        Write-Log "ERROR processing '$PACFile': $($_.Exception.Message)" "ERROR"
    }
}

# ====================== COPY TO SECONDARY SERVERS ===========================
if ($FilesToSync.Count -gt 0 -or $IsFirstRun) {
    Write-Log "Syncing PAC files to secondary servers..."

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

                # Copy updated PAC file
                Copy-Item -Path $SourceFile -Destination $UNCPathFile -Force -ErrorAction Stop
                Write-Log "Copied '$PACFile' to $UNCPathFile"

                # Copy archive file
                if ($IsFirstRun -or $NewArchives.ContainsKey($PACFile)) {
                    $ArchiveFilesToCopy = @()
                    if ($IsFirstRun) {
                        $ArchiveFilesToCopy = Get-ChildItem -Path $ArchiveFolder -Filter "$($PACFile -replace '\.pac$', '_*.pac')" -File
                    } else {
                        $ArchiveFilesToCopy = @(Get-Item $NewArchives[$PACFile])
                    }

                    foreach ($File in $ArchiveFilesToCopy) {
                        Copy-Item -Path $File.FullName -Destination $UNCPathArchive -Force -ErrorAction Stop
                        Write-Log "Copied archive file '$($File.Name)' to $UNCPathArchive"
                    }
                }
            }

        } catch {
            Write-Log "ERROR copying to $Server : $($_.Exception.Message)" "ERROR"
        }
    }

    # Mark first run complete
    if ($IsFirstRun) {
        New-Item -Path $FirstRunFlag -ItemType File -Force | Out-Null
        Write-Log "First run completed. Flag file created."
    }
} else {
    Write-Log "No PAC file changes detected. Skipping copying to secondary servers."
}

Write-Log "Script execution finished."
exit 0