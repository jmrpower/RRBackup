# SUMMARY
#
# Meant to be run on the RPOWER BACKUP SERVER
#######
#######
####### DO NOT RUN ON THE FILE SERVER #######
#######
#######
# Backup daily transactional files in to a versioned backup
# Keeps previous 1 hour of data in a rolling FILO every 5 minutes
# 
# This helps us recover from a network/drive disaster where all 
# data is corrupt in a transaction file and copied to the backup server

# Define the array of files to backup
$fileList = @(
    "C:\sys\rpower\data\GPT.dbf",
    "C:\sys\rpower\data\RSV.dbf",
    "C:\sys\rpower\data\ACD.dbf",
    "C:\sys\rpower\data\TKT.dbf",
    "C:\sys\rpower\data\TKS.dbf",
    "C:\sys\rpower\data\TKP.dbf",
    "C:\sys\rpower\data\TKM.dbf",
    "C:\sys\rpower\data\TKR.dbf",
    "C:\sys\rpower\data\TKN.dbf",
    "C:\sys\rpower\data\TKL.dbf",
    "C:\sys\rpower\data\RSD.dbf",
    "C:\sys\rpower\data\FPL.dbf",
    "C:\sys\rpower\data\PHI.dbf",
    "C:\sys\rpower\data\VIL.dbf",
    "C:\sys\rpower\data\SIN.dbf"
)

# Set the destination backup root directory
$backupRootDir = "C:\sys\backups"

# Create the backup root directory if it doesn't exist
if (!(Test-Path -Path $backupRootDir)) {
    New-Item -ItemType Directory -Path $backupRootDir
}

# Define the backup interval (in minutes) and the number of versions to keep
$backupInterval = 5
$maxVersions = 12

# Define log file path
$logFile = "C:\sys\backup_log.txt"

# Function to write to log
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logEntry
}

# Function to perform the backup
function Perform-Backup {
    try {
        # Get the current date and time for the folder name
        $currentDate = Get-Date
        $formattedDate = $currentDate.ToString("dd-HH.mm")
        
        # Create the backup directory for the current version
        $backupDir = Join-Path -Path $backupRootDir -ChildPath $formattedDate
        New-Item -ItemType Directory -Path $backupDir -Force
        
        # Iterate over each file in the list and copy it to the backup directory
        foreach ($filePath in $fileList) {
            if (Test-Path -Path $filePath) {
                $fileName = [System.IO.Path]::GetFileName($filePath)
                Copy-Item -Path $filePath -Destination (Join-Path -Path $backupDir -ChildPath $fileName) -Force
                Write-Log "Backup successful: $fileName"
            } else {
                Write-Log "File not found: $filePath"
            }
        }
        
        # Clean up old versions
        Cleanup-OldVersions
    } catch {
        Write-Log "Error during backup: $_"
    }
}

# Function to clean up old versions
function Cleanup-OldVersions {
    try {
        # Get a list of all backup directories sorted by creation time (oldest to newest)
        $backupDirs = Get-ChildItem -Path $backupRootDir | Sort-Object LastWriteTime
        
        # Check if there are more versions than needed
        if ($backupDirs.Count -gt $maxVersions) {
            # Calculate the number of directories to remove
            $dirsToRemove = $backupDirs.Count - $maxVersions
            
            # Remove the oldest directories
            for ($i = 0; $i -lt $dirsToRemove; $i++) {
                Remove-Item -Path $backupDirs[$i].FullName -Recurse -Force
                Write-Log "Old backup removed: $($backupDirs[$i].Name)"
            }
        }
    } catch {
        Write-Log "Error during cleanup: $_"
    }
}

# Schedule the backup task
while ($true) {
    Perform-Backup
    Start-Sleep -Seconds ($backupInterval * 60)
}
