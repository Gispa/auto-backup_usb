<#
Runs backup_matched_devices.ps1 in background process, handling exits
#>


# Not required, currently using PIDs instead of window titles as running in hidden window, file no longer created
# in backup_matched_devices.ps1 script
# =============================================================================
# $uniqueWindowTitle = "Backup Script " + (Get-Date -Format s)
# $uniqueWindowTitle > $PSScriptRoot\uniqueWindowTitle.tmp



do{
    if (-not (Test-Path $PSScriptRoot\staging)) {
    New-Item -Path $PSScriptRoot -Name "staging" -ItemType "Directory"
    }
    # Starts the detect and update script in a new process (hidden window), if that process is killed will exit the loop
    $childProcess = Start-Process -FilePath PowerShell -ArgumentList "-File $PSScriptRoot\backup_matched_devices.ps1" -Wait -WindowStyle Hidden -PassThru
    if (Get-Process -Id $childProcess.Id -ErrorAction SilentlyContinue) {
        Write-Host "Still running child with PID: '$childProcess.Id'"
        $childAlive = 1
    } else {
        Write-Host "Child no longer running, gracefully exiting..."
        $childAlive = 0
    }
} until ($childAlive -eq 0)

# I've now learned subscription does not persist through sessions, but just in case 
# (and because I put so much time into running as separate processes)
Unregister-Event -SourceIdentifier volumeChange -ErrorAction SilentlyContinue 

# Not required, currently using PIDs instead of window titles as running in hidden window, file no longer created
# in backup_matched_devices.ps1 script
# ================================================================================
# Remove-Item $PSScriptRoot\uniqueWindowTitle.tmp

Remove-Item $PSScriptRoot\staging -Force
Write-Host "Exited gracefully!"