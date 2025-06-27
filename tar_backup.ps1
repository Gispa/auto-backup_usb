<# 
Creates a tarball of target file and places in a staging directory
#>


$target = "" # name of directory you want to back up, e.g. "My_projects"
$targetParent = "$env:USERPROFILE\Documents" # Path of parent directory
$dateTime = Get-Date -Format "yyyy_MM_dd-HH.mm"
$backupName = "$target`_$dateTime.tar.gz"

if ((Test-Path $targetParent) -and (Test-Path $targetParent\$target)) {
    Set-Location $targetParent
    $backupName > $PSScriptRoot\staging\backup_name.tmp
    tar -czvf "$PSScriptRoot\staging\$backupName" $target
} else {
    Write-Host "`"$target`" not found, check `"$targetParent\$target`" exists"
}
exit