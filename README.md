# Versioned Backup Script (vbackup.ps1)

This PowerShell script provides a rolling, versioned backup for critical RPOWER transactional database files. Its primary purpose is to create frequent, short-term backups to enable recovery from data corruption, especially in cases where corrupted files might be replicated from a live file server.

> **[!!] CRITICAL WARNING**
>
> **DO NOT RUN THIS SCRIPT ON THE FILE SERVER.**
>
> This script is designed to run *only* on the **RPOWER BACKUP SERVER**.

## Overview

The script runs in a continuous loop to create a snapshot of specific data files at a regular interval. It maintains a rolling window of backups, deleting the oldest version as new ones are created.

* **Backup Frequency:** Every 5 minutes.
* **Backup Retention:** Keeps the 12 most recent versions.
* **Total Backup Window:** Provides a rolling 1-hour (12 versions * 5 minutes/version) backup history.
* **Retention Method:** First-In, Last-Out (FILO). The oldest backup is deleted once the maximum number of versions is exceeded.

## How it Works

1.  **Infinite Loop:** The script runs in a `while ($true)` loop, which means it will run continuously until manually stopped.
2.  **Backup:** Every 5 minutes, the `Perform-Backup` function is called.
    * It creates a new backup directory inside the `$backupRootDir` (default: `C:\sys\backups`).
    * The new directory is named using the current day and time (e.g., `16-08.53`).
    * It copies all files specified in the `$fileList` array from `C:\sys\rpower\data\` to the new timestamped directory.
3.  **Cleanup:** After each backup, the `Cleanup-OldVersions` function is called.
    * It gets a list of all backup directories in `$backupRootDir`, sorted by creation time (oldest first).
    * If the total number of directories is greater than `$maxVersions` (12), it deletes the oldest directory (or directories) until only 12 remain.

## Configuration

The following variables can be modified at the top of the `vbackup.ps1` script to change its behavior.

* **`$fileList`**: An array of file paths to be backed up.
* **`$backupRootDir`**: The root folder where versioned backup directories will be stored.
    * **Default:** `C:\sys\backups`
* **`$backupInterval`**: The time, in minutes, between each backup cycle.
    * **Default:** `5`
* **`$maxVersions`**: The total number of backup versions to keep.
    * **Default:** `12`
* **`$logFile`**: The full path to the log file where all actions will be recorded.
    * **Default:** `C:\sys\backup_log.txt`

## How to Run

1.  Open a PowerShell terminal.
2.  Navigate to the directory containing `vbackup.ps1`.
3.  Execute the script:

    ```powershell
    .\vbackup.ps1
    ```

The script will start and continue to run in the console, logging its actions to the specified log file. To stop the script, press `Ctrl+C` in the console.

**Note:** For production use, you may want to run this script as a persistent background process, such as a Windows Service or a Scheduled Task set to run on system startup.

## Logging

All actions are logged with a timestamp to the file specified in the `$logFile` variable (default: `C:\sys\backup_log.txt`).

This includes:
* Successful file backups.
* "File not found" errors.
* Removal of old backup versions.
* Any other errors encountered during the backup or cleanup process.
