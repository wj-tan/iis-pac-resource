# ====================== CONFIGURATION ===========================
$RepositoryFolder = "D:\Repository" 
$SourceFolder = "D:\inetpub\wwwroot"
$ArchiveFolder = "D:\Archive"
$SecondaryServers = @("server01", "server02")
$SMBWebRootShare = "wwwroot"
$SMBArchiveShare = "Archive"
$LogFile = "D:\Scripts\SyncLog_$(Get-Date -Format 'yyyyMMdd').log"
$FirstRunFlag = "D:\Scripts\first_run.flag"
$MinFileSizeBytes = 5120  # 5KB minimum file size threshold

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
}
catch {
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
    $RepoFileSizeBytes = $FileObject.Length
    $RepoFileSizeKB = [math]::Round($RepoFileSizeBytes / 1KB, 2)
    $CountryName = $PACFile -replace '\.pac$', ''
    
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

        # ====================== FILE SIZE CHECK ======================
        if ($RepoFileSizeBytes -le $MinFileSizeBytes) {
            Write-Log "WARNING: '$PACFile' has a file size of ${RepoFileSizeKB}KB which is at or below the minimum threshold of 5KB. Deploy blocked." "WARN"
            continue
        }

        $LatestArchive = Get-ChildItem -Path $PACArchiveDir -Filter $ArchivePattern -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

        $ShouldArchiveAndDeploy = $true
        $IsNewFile = (-not $LatestArchive -and -not $IsFirstRun)

        if ($LatestArchive -and -not $IsFirstRun) {
            $RepoHash = (Get-FileHash -Path $RepoFile -Algorithm SHA256).Hash
            $ArchiveHash = (Get-FileHash -Path $LatestArchive.FullName -Algorithm SHA256).Hash

            if ($RepoHash -eq $ArchiveHash) {
                Write-Log "No change detected for '$PACFile' (hash match). Skipping."
                $ShouldArchiveAndDeploy = $false
            }
            else {
                Write-Log "Change detected for '$PACFile' (file size: ${RepoFileSizeKB}KB). Proceeding with deploy." "INFO"
            }
        }
        elseif ($IsNewFile) {
            Write-Log "New file '$PACFile' detected with no archive copy (file size: ${RepoFileSizeKB}KB). Proceeding with deploy." "INFO"
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

            if ($IsNewFile) {
                Write-Log "New file '$PACFile' successfully deployed and archived (file size: ${RepoFileSizeKB}KB)." "INFO"
            }
            else {
                Write-Log "File '$PACFile' updated and deployed successfully (file size: ${RepoFileSizeKB}KB)." "INFO"
            }
        }

    }
    catch {
        Write-Log "ERROR processing '$PACFile': $($_.Exception.Message)" "ERROR"
    }
}

# ====================== COPY TO SECONDARY SERVERS ===========================
if ($FilesToSync.Count -gt 0 -or $IsFirstRun) {
    foreach ($Server in $SecondaryServers) {
        try {
            if (-not (Test-NetConnection -ComputerName $Server -port 445 -InformationLevel Quiet -WarningAction SilentlyContinue)) {
                throw "Server $Server is not reachable."
            }

            foreach ($PACFile in $FilesToSync) {
                $CountryName = $PACFile -replace '\.pac$', ''

                $RemoteLiveDir = "\\$Server\$SMBWebRootShare\$CountryName"
                $UNCPathFile = Join-Path $RemoteLiveDir $PACFile
                $RemoteArchiveDir = "\\$Server\$SMBArchiveShare\$CountryName"
                $SourceFileToCopy = Join-Path $SourceFolder "$CountryName\$PACFile"

                if (!(Test-Path $RemoteLiveDir)) {
                    New-Item -ItemType Directory -Path $RemoteLiveDir -Force | Out-Null
                }
                if (!(Test-Path $RemoteArchiveDir)) {
                    New-Item -ItemType Directory -Path $RemoteArchiveDir -Force | Out-Null
                }

                Copy-Item -Path $SourceFileToCopy -Destination $UNCPathFile -Force -ErrorAction Stop
                Write-Log "Successfully copied '$PACFile' to $Server web root." "INFO"

                $ArchiveFilesToCopy = if ($IsFirstRun) {
                    Get-ChildItem -Path (Join-Path $ArchiveFolder $CountryName) -Filter "$($PACFile -replace '\.pac$', '_*.pac')" -File
                }
                else {
                    @(Get-Item $NewArchives[$PACFile])
                }

                foreach ($File in $ArchiveFilesToCopy) {
                    Copy-Item -Path $File.FullName -Destination $RemoteArchiveDir -Force -ErrorAction Stop
                }
                Write-Log "Successfully copied '$PACFile' archive to $Server." "INFO"
            }

            Write-Log "Successfully synced all files to $Server." "INFO"

        }
        catch {
            Write-Log "ERROR copying to $Server : $($_.Exception.Message)" "ERROR"
        }
    }

    if ($IsFirstRun) {
        New-Item -Path $FirstRunFlag -ItemType File -Force | Out-Null
    }
}

Write-Log "Script execution finished."
