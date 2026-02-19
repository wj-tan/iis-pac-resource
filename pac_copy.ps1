# ====================== CONFIGURATION ===========================
$RepositoryFolder  = "C:\Repository" 
$SourceFolder      = "C:\inetpub\wwwroot"
$ArchiveFolder     = "C:\Archive"
$SecondaryServers  = @("server02", "server03")
$TargetPath        = "C$\inetpub\wwwroot"
$LogFile           = "C:\Scripts\SyncLog_$(Get-Date -Format 'yyyyMMdd').log"
$FirstRunFlag      = "C:\Scripts\first_run.flag"
$MaxCharDiffThreshold = 20

# ====================== FUNCTIONS ===========================
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$Timestamp [$Level] $Message"
    $logEntry | Out-File -FilePath $LogFile -Append
    Write-Host $logEntry
}

# ====================== INITIAL SETUP ===========================
try {
    if (!(Test-Path $ArchiveFolder)) { New-Item -ItemType Directory -Path $ArchiveFolder -Force | Out-Null }
    if (!(Test-Path $RepositoryFolder)) { New-Item -ItemType Directory -Path $RepositoryFolder -Force | Out-Null }
    if (!(Test-Path (Split-Path $LogFile))) { New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null }
} catch {
    Write-Log "CRITICAL: Failed to create required directories. Error: $($_.Exception.Message)" "CRIT"
    exit 1
}

$PACFileObjects = @(Get-ChildItem -Path $RepositoryFolder -Filter "*.pac" -File -Recurse)

if ($PACFileObjects.Count -eq 0) {
    Write-Log "ERROR: No PAC files found in the repository folder: $RepositoryFolder. Exiting." "ERROR"
    exit 1
}

$IsFirstRun = -not (Test-Path $FirstRunFlag)

# ====================== PROCESS PAC FILES ===========================
$FilesToSync = @() 
$NewArchives = @{} 

foreach ($FileObject in $PACFileObjects) {
    $PACFile = $FileObject.Name
    $RepoFile = $FileObject.FullName 
    $RepoLastModified = $FileObject.LastWriteTime
    $CountryName = $PACFile -replace '\.pac$',''
    
    # --- Updated Paths (Removed AsiaSAE) ---
    $LiveFile = Join-Path $SourceFolder "$CountryName\$PACFile" 
    $LiveDir = Split-Path $LiveFile
    
    $PACArchiveDir = Join-Path $ArchiveFolder $CountryName
    $ArchivePattern = "$($PACFile -replace '\.pac$', '_*.pac')"
    $ArchiveFileName = "$($PACFile -replace '\.pac$', "_$(Get-Date -Format 'yyyyMMdd_HHmmss').pac")"
    $ArchiveFilePath = Join-Path $PACArchiveDir $ArchiveFileName

    try {
        if (!(Test-Path $PACArchiveDir)) { 
            New-Item -ItemType Directory -Path $PACArchiveDir -Force | Out-Null
        }

        $LatestArchive = Get-ChildItem -Path $PACArchiveDir -Filter $ArchivePattern -ErrorAction SilentlyContinue |
                            Sort-Object LastWriteTime -Descending |
                            Select-Object -First 1

        #$ShouldArchiveAndDeploy = $true
        #if ($LatestArchive -and -not $IsFirstRun) {
        #    if ($RepoLastModified -le $LatestArchive.LastWriteTime) {
        #        Write-Log "No change detected for '$PACFile'. Skipping."
        #        $ShouldArchiveAndDeploy = $false
        #    }
        #}

        #$ShouldArchiveAndDeploy = $true
        #if ($LatestArchive -and -not $IsFirstRun) {
        #    $RepoHash    = (Get-FileHash -Path $RepoFile    -Algorithm SHA256).Hash
        #    $ArchiveHash = (Get-FileHash -Path $LatestArchive.FullName -Algorithm SHA256).Hash
        #
        #    if ($RepoHash -eq $ArchiveHash) {
        #        Write-Log "No change detected for '$PACFile' (hash match). Skipping."
        #        $ShouldArchiveAndDeploy = $false
        #    } else {
        #        Write-Log "Change detected for '$PACFile' (hash mismatch). Proceeding with deploy." "INFO"
        #    }
        #}

        $ShouldArchiveAndDeploy = $true
        if ($LatestArchive -and -not $IsFirstRun) {
            $RepoHash    = (Get-FileHash -Path $RepoFile -Algorithm SHA256).Hash
            $ArchiveHash = (Get-FileHash -Path $LatestArchive.FullName -Algorithm SHA256).Hash

            if ($RepoHash -eq $ArchiveHash) {
                Write-Log "No change detected for '$PACFile' (hash match). Skipping."
                $ShouldArchiveAndDeploy = $false
            } else {
                # Hash mismatch — measure extent of content change by character count difference
                $RepoCharCount    = (Get-Content -Path $RepoFile -Raw).Length
                $ArchiveCharCount = (Get-Content -Path $LatestArchive.FullName -Raw).Length
                $CharDiff         = [math]::Abs($RepoCharCount - $ArchiveCharCount)

                if ($CharDiff -gt $MaxCharDiffThreshold) {
                    Write-Log "WARNING: '$PACFile' has a character count difference of $CharDiff which exceeds the $MaxCharDiffThreshold character threshold. Deploy aborted for this file." "WARN"
                    $ShouldArchiveAndDeploy = $false
                } else {
                    Write-Log "Change detected for '$PACFile' (character difference: $CharDiff). Proceeding with deploy." "INFO"
                }
            }
        }

        if ($ShouldArchiveAndDeploy) {
            # Step A: DEPLOY TO PRIMARY
            if (!(Test-Path $LiveDir)) {
                New-Item -ItemType Directory -Path $LiveDir -Force | Out-Null
            }
            Copy-Item -Path $RepoFile -Destination $LiveFile -Force -ErrorAction Stop
            
            # Step B: ARCHIVE
            Copy-Item -Path $LiveFile -Destination $ArchiveFilePath -Force -ErrorAction Stop
            
            $FilesToSync += $PACFile
            $NewArchives[$PACFile] = $ArchiveFilePath
        }
    } catch {
        Write-Log "ERROR processing '$PACFile': $($_.Exception.Message)" "ERROR"
    }
}

# ====================== COPY TO SECONDARY SERVERS ===========================
if ($FilesToSync.Count -gt 0 -or $IsFirstRun) {
    foreach ($Server in $SecondaryServers) {
        try {
            if (-not (Test-Connection -ComputerName $Server -Count 1 -Quiet)) {
                throw "Server $Server is not reachable."
            }

            foreach ($PACFile in $FilesToSync) {
                $CountryName = $PACFile -replace '\.pac$',''
                
                # --- Updated Remote Paths (Removed AsiaSAE) ---
                $SourceFileToCopy = Join-Path $SourceFolder "$CountryName\$PACFile"
                $RemoteLiveDir    = "\\$Server\$TargetPath\$CountryName"
                $UNCPathFile      = Join-Path $RemoteLiveDir $PACFile
                $RemoteArchiveDir = "\\$Server\C$\Archive\$CountryName"

                if (!(Test-Path $RemoteLiveDir)) {
                    New-Item -ItemType Directory -Path $RemoteLiveDir -Force | Out-Null
                }
                if (!(Test-Path $RemoteArchiveDir)) {
                    New-Item -ItemType Directory -Path $RemoteArchiveDir -Force | Out-Null
                }

                Copy-Item -Path $SourceFileToCopy -Destination $UNCPathFile -Force -ErrorAction Stop
                
                # Copy Archive Files
                $ArchiveFilesToCopy = if ($IsFirstRun) {
                    Get-ChildItem -Path (Join-Path $ArchiveFolder $CountryName) -Filter "$($PACFile -replace '\.pac$', '_*.pac')" -File
                } else {
                    @(Get-Item $NewArchives[$PACFile])
                }

                foreach ($File in $ArchiveFilesToCopy) {
                    Copy-Item -Path $File.FullName -Destination $RemoteArchiveDir -Force -ErrorAction Stop
                }
            }
        } catch {
            Write-Log "ERROR copying to $Server : $($_.Exception.Message)" "ERROR"
        }
    }

    if ($IsFirstRun) {
        New-Item -Path $FirstRunFlag -ItemType File -Force | Out-Null
    }
}

Write-Log "Script execution finished."
