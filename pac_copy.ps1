# ====================== CONFIGURATION ===========================
# Staging/repository folder where admins upload new PAC files
$RepositoryFolder  = "C:\Repository" 
# Local base source folder (C:\inetpub\wwwroot) - this is the LIVE location
$SourceFolder      = "C:\inetpub\wwwroot"
# Local base folder where timestamped copies (archives) of the PAC files are stored
$ArchiveFolder     = "C:\Archive"
# List of secondary server names to copy files to
$SecondaryServers  = @("server02", "server03")
# Target base folder path on the secondary servers (C$\inetpub\wwwroot)
$TargetPath        = "C$\inetpub\wwwroot"
# Log file path, named daily, now stored in the C:\Scripts directory
$LogFile           = "C:\Scripts\SyncLog_$(Get-Date -Format 'yyyyMMdd').log"
# Flag file to determine if this is the first execution, now stored in C:\Scripts
$FirstRunFlag      = "C:\Scripts\first_run.flag"

# ====================== INITIAL SETUP ===========================
try {
    # Create local archive, repository, and script directories if they don't exist
    if (!(Test-Path $ArchiveFolder)) { New-Item -ItemType Directory -Path $ArchiveFolder -Force | Out-Null }
    if (!(Test-Path $RepositoryFolder)) { New-Item -ItemType Directory -Path $RepositoryFolder -Force | Out-Null }
    if (!(Test-Path (Split-Path $LogFile))) { New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null }
} catch {
    Write-Log "CRITICAL: Failed to create required directories. Error: $($_.Exception.Message)" "CRIT"
    exit 1
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$Timestamp [$Level] $Message"
    $logEntry | Out-File -FilePath $LogFile -Append
    Write-Host $logEntry
}

# ----------------- DYNAMIC PAC FILE DISCOVERY --------------------
# List of PAC files to monitor and synchronize. This is now dynamically generated
# by checking all .pac files in the repository folder.
$PACFiles = @(Get-ChildItem -Path $RepositoryFolder -Filter "*.pac" -File | Select-Object -ExpandProperty Name)

if ($PACFiles.Count -eq 0) {
    Write-Log "ERROR: No PAC files found in the repository folder: $RepositoryFolder. Exiting script." "ERROR"
    exit 1
}
Write-Log "Discovered PAC files to process: $($PACFiles -join ', ')"
# -----------------------------------------------------------------

# Determine if this is the initial run (used to force sync all files and archives)
$IsFirstRun = -not (Test-Path $FirstRunFlag)

# ====================== PROCESS PAC FILES ===========================
$FilesToSync = @() # List of PAC filenames that need syncing (i.e., they were modified)
$NewArchives = @{} # Map of PAC filename to the path of the newly created archive file

foreach ($PACFile in $PACFiles) {
    # The CountryName is derived from the PAC file name, enabling dynamic folder creation
    $CountryName = $PACFile -replace '\.pac$',''
    
    # --- File Paths ---
    # The new file source for checking changes
    $RepoFile = Join-Path $RepositoryFolder $PACFile 
    # The live file path on the primary server (deployment destination and archive source)
    $LiveFile = Join-Path $SourceFolder "AsiaSAE\$CountryName\$PACFile" 
    $LiveDir = Split-Path $LiveFile # Directory for the live file
    
    # --- Local Archive Path ---
    $PACArchiveDir = Join-Path $ArchiveFolder "AsiaSAE\$CountryName"
    $ArchivePattern = "$($PACFile -replace '\.pac$', '_*.pac')"
    $ArchiveFileName = "$($PACFile -replace '\.pac$', "_$(Get-Date -Format 'yyyyMMdd_HHmmss').pac")"
    $ArchiveFilePath = Join-Path $PACArchiveDir $ArchiveFileName

    try {
        # 1. Check if the file exists in the repository
        if (!(Test-Path -Path $RepoFile)) {
            Write-Log "WARNING: Repository file not found: $RepoFile. Skipping check." "WARN"
            continue
        }
        
        # 2. Ensure the nested local archive directory exists (e.g., C:\Archive\AsiaSAE\Indonesia)
        if (!(Test-Path $PACArchiveDir)) { 
            New-Item -ItemType Directory -Path $PACArchiveDir -Force | Out-Null
            Write-Log "Created new local archive directory: $PACArchiveDir"
        }

        $RepoLastModified = (Get-Item $RepoFile).LastWriteTime
        Write-Log "PAC file '$PACFile' found in Repository. Last modified: $RepoLastModified"

        # Find the most recently created archive file for comparison
        $LatestArchive = Get-ChildItem -Path $PACArchiveDir -Filter $ArchivePattern -ErrorAction SilentlyContinue |
                             Sort-Object LastWriteTime -Descending |
                             Select-Object -First 1

        $ShouldArchiveAndDeploy = $true
        if ($LatestArchive -and -not $IsFirstRun) {
            $ArchivedTime = $LatestArchive.LastWriteTime
            Write-Log "Latest archive for '$PACFile': $($LatestArchive.Name) (Archived at: $ArchivedTime)"
            # Compare repository file's modification time to the latest archive's modification time
            if ($RepoLastModified -le $ArchivedTime) {
                Write-Log "No change detected for '$PACFile' in repository compared to latest archive. Skipping deployment and archive."
                $ShouldArchiveAndDeploy = $false
            }
        } else {
            Write-Log "No previous archive found or first run. Proceeding to deploy and archive."
        }

        if ($ShouldArchiveAndDeploy) {
            # Step A: DEPLOY TO PRIMARY LIVE FOLDER
            # This logic creates the new country's live folder (e.g., C:\inetpub\wwwroot\AsiaSAE\Indonesia)
            if (!(Test-Path $LiveDir)) {
                New-Item -ItemType Directory -Path $LiveDir -Force | Out-Null
                Write-Log "Created new primary live directory: $LiveDir"
            }
            Copy-Item -Path $RepoFile -Destination $LiveFile -Force -ErrorAction Stop
            Write-Log "Deployed new '$PACFile' from $RepositoryFolder to primary live folder: $LiveFile"

            # Step B: PERFORM ARCHIVE (Archiving the newly deployed LIVE file)
            Copy-Item -Path $LiveFile -Destination $ArchiveFilePath -Force -ErrorAction Stop
            Write-Log "Archived deployed '$PACFile' as $ArchiveFilePath"
            
            # Flag for secondary sync
            $FilesToSync += $PACFile
            $NewArchives[$PACFile] = $ArchiveFilePath
        }

    } catch {
        Write-Log "ERROR processing '$PACFile' from repository $RepoFile : $($_.Exception.Message)" "ERROR"
    }
}

# ====================== COPY TO SECONDARY SERVERS ===========================
if ($FilesToSync.Count -gt 0 -or $IsFirstRun) {
    Write-Log "Syncing PAC files to secondary servers..."

    foreach ($Server in $SecondaryServers) {
        try {
            # 1. Test server connectivity
            if (-not (Test-Connection -ComputerName $Server -Count 2 -Quiet)) {
                throw "Server $Server is not reachable."
            }

            foreach ($PACFile in $FilesToSync) {
                $CountryName = $PACFile -replace '\.pac$',''
                
                # --- Source and Destination Paths ---
                # Local nested source path (the deployed LIVE file on primary server)
                $SourceFileToCopy = Join-Path $SourceFolder "AsiaSAE\$CountryName\$PACFile"
                
                # Remote target directory for the LIVE PAC file (e.g., \\server02\C$\inetpub\wwwroot\AsiaSAE\Indonesia)
                $RemoteLiveDir = "\\$Server\$TargetPath\AsiaSAE\$CountryName"
                # Remote target path for the LIVE PAC file 
                $UNCPathFile = Join-Path $RemoteLiveDir $PACFile

                # Remote target path for the ARCHIVE files (nested structure)
                $RemotePACArchiveDir = "\\$Server\C$\Archive\AsiaSAE\$CountryName"

                # 2. Ensure the nested LIVE file directory exists on the remote server
                if (!(Test-Path $RemoteLiveDir)) {
                    New-Item -ItemType Directory -Path $RemoteLiveDir -Force -ErrorAction Stop | Out-Null
                    Write-Log "Target web root folder created on $Server : $RemoteLiveDir"
                }

                # 3. Ensure the nested archive directory exists on the remote server
                if (!(Test-Path $RemotePACArchiveDir)) {
                    New-Item -ItemType Directory -Path $RemotePACArchiveDir -Force -ErrorAction Stop | Out-Null
                    Write-Log "Archive folder created on $Server : $RemotePACArchiveDir"
                }

                # 4. Copy updated LIVE PAC file to the target web root
                Copy-Item -Path $SourceFileToCopy -Destination $UNCPathFile -Force -ErrorAction Stop
                Write-Log "Copied LIVE '$PACFile' to $UNCPathFile (Source: $SourceFileToCopy)"

                # 5. Copy archive file(s) to the nested remote archive folder
                if ($IsFirstRun -or $NewArchives.ContainsKey($PACFile)) {
                    $ArchiveFilesToCopy = @()
                    if ($IsFirstRun) {
                        # Copy all archives for a file during first run (from local nested folder)
                        $LocalPACArchiveDir = Join-Path $ArchiveFolder "AsiaSAE\$CountryName"
                        $ArchiveFilesToCopy = Get-ChildItem -Path $LocalPACArchiveDir -Filter "$($PACFile -replace '\.pac$', '_*.pac')" -File
                    } else {
                        # Only copy the single new archive file
                        $ArchiveFilesToCopy = @(Get-Item $NewArchives[$PACFile])
                    }

                    foreach ($File in $ArchiveFilesToCopy) {
                        Copy-Item -Path $File.FullName -Destination $RemotePACArchiveDir -Force -ErrorAction Stop
                        Write-Log "Copied archive file '$($File.Name)' to $RemotePACArchiveDir"
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
