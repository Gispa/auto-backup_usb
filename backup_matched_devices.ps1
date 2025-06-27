<#
Detects when a USB device has been plugged in, checks if the label of USB
matches, calls tar_backup.ps1 (tarballs a folder) and moves it to device if label matches
#>

# not required currently, using passthru PID instead as running in a hidden window means no window name
# =========================================================================================
# Give PowerShell window unique name (used for main.ps1)
# $specialWindowTitle = (Get-Content $PSScriptRoot\uniqueWindowTitle.tmp -Raw)
# $host.ui.RawUI.WindowTitle = $specialWindowTitle
# write-host $specialWindowTitle

function Get-EventType($eventType) {
    # This function uses the eventType property from win32_volumeChangeEvent to give each
    # eventType code a name (based on VolumeChangeEvent Documentation). Think of it as a
    # series of if statements: if eventType == 1 then output "Configuration Changed"
    switch ($eventType) {
        1 {"Configuration Changed"}
        2 {"Device Arrival"}
        3 {"Device Removal"}
        4 {"Docking"}
    }
}
function Start-BackupDialogue {
    # put this in if statement for matching drivelabel here for tar command
    # Creates popup yes/no/cancel dialogue, yes returns 6, no returns 7, cancel returns 2, null returns -1
    # runs backup if yes
    
    $msg1 = "Do you want to backup to USB `"$driveLabel`"?" 
    $msg2 = "Press `"Yes`" to backup now, `"No`" to backup another time, or `"Cancel`" to kill this program."
    # $PID gets pid of current process (this script)
    $msg3 = "This program's process ID (PID) is '$PID' if you want to kill with task manager"
    
    $dialogueTime = Get-Date -Format "HH:mm"
    
    # Create Dialogue
    $wshell = New-Object -ComObject Wscript.Shell
    $answer = $wshell.popup("$msg1`n$msg2`n$msg3", 0,"$dialogueTime Auto-Backup to `"$driveLabel`"",32+3) 
    Write-Output $answer
    if ($answer -eq 6) {
        $tarProcess = Start-Process -FilePath PowerShell -ArgumentList "-File $PSScriptRoot\tar_backup.ps1" -WindowStyle Minimized -PassThru
        do {
            if (Get-Process -Id $tarProcess.Id -ErrorAction SilentlyContinue) {
                    Write-Host "Still running child with PID: $tarProcess.Id"
                    Start-Sleep -Seconds 5 
                    $tarChildAlive = 1
                } else {
                    if ((Test-Path $driveBackupPath) -and (Test-Path $PSScriptRoot\staging\$backupFile)) {
                        $backupFile = (Get-Content $PSScriptRoot\staging\backup_name.tmp)
                        Write-Host "Moving file $backupFile, please wait..."
                        Move-Item -Path $PSScriptRoot\staging\$backupFile -Destination $driveBackupPath
                        Remove-Item -Path $PSScriptRoot\staging\backup_name.tmp
                        Write-Host "Tar process complete, continuing..."
                        $success = New-Object -ComObject Wscript.Shell
                        $success.popup("Backup complete!!",0,"Completed Successfully",64+0)
                        $tarChildAlive = 0
                    } else {
                        New-Item -Path $driveLetter -Name "AutoBackups" -ItemType "Directory"
                    }
                }
        } while ($tarChildAlive -eq 1)
    } elseif ($answer -eq 7) {
        <# does nothing #>
    } elseif ($answer -eq 2) {
        exit
    } else {exit}
}


Write-Host (Get-Date -Format s) "Beginning script..."

if (-not (Test-Path $PSScriptRoot\staging)) {
    New-Item -Path $PSScriptRoot -Name "staging" -ItemType "Directory"
}
# Subscribe to Cim event win32_volumeChangeEvent and use the name "volumeChange" to refer to subscription
Register-CimIndicationEvent -ClassName Win32_VolumeChangeEvent -SourceIdentifier volumeChange -ErrorAction SilentlyContinue

$driveTrigger = "-ab"
do {
    # Wait until a volume change event occurs
    $newEvent = Wait-Event -SourceIdentifier volumeChange
    $eventTypeName = $(Get-EventType -eventType $newEvent.SourceEventArgs.NewEvent.EventType)

    Write-Host (Get-Date -Format s) "Event detected: " $eventTypeName
    if ($eventTypeName -eq "Device Arrival") {
        # if the volume change event is 2 ("Device Arrival"), get the drive letter 
        $driveLetter = $newEvent.SourceEventArgs.NewEvent.DriveName # DriveName here refers to its letter
    
        # Use drive letter to display just that drive's details
        $driveDetails = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$driveLetter'"
        Write-Host $driveDetails
        # Display drive label only
        $driveLabel = $driveDetails.VolumeName
        Write-Host $driveLabel
        $driveBackupPath = "$driveLetter\AutoBackups"
        
        if ($driveLabel -like "*$driveTrigger") {
            Start-BackupDialogue
        }
    }
    Remove-Event -SourceIdentifier volumeChange -ErrorAction SilentlyContinue
} while (1 -eq 1)
