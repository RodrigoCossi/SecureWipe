# SecureWipe.ps1 - A script for securely wiping disks using multiple passes and diskpart.

$disks                      = Get-Disk
$global:DISKPART_SCRIPT     = "SecureWipe_script.txt"
$global:diskIdToWipe        = "xxx"
$global:numberOfPasses
$confirmation
$diskIDs                    = [System.Collections.ArrayList]@()
$systemDrive                = $Env:Systemdrive

Function Get-UserInput() {
    Clear
    Write-Host "`n----------- Available Disks -----------`n"

    foreach ($disk in $disks) {
        Write-Host "Disk ID:        $($disk.Number)" -ForegroundColor Red
        Write-Host "Disk Name:      $($disk.FriendlyName)"
        Write-Host "Disk Size:      $($disk.Size / 1GB) GB"
        Write-Host "Partition Style:$($disk.PartitionStyle)`n"
        $diskIDs.Add($disk.Number) | Out-Null
    }

    if ($disks.Count -lt 2) {
        Write-Host "Less than 2 disks detected. Exiting to avoid wiping system/boot disk." -ForegroundColor Red
        Exit
    }

    while (-Not ($diskIDs -contains $global:diskIdToWipe)) {
        Write-Host "`nEnter the Disk ID to wipe:" -ForegroundColor Yellow
        $input = Read-Host
        $global:diskIdToWipe = if ($input -eq "") { "xxx" } else { $input }
        
        if (-Not ($diskIDs -contains $global:diskIdToWipe)) {
            Clear
            Write-Host "Invalid Disk ID. Valid options are:`n" -ForegroundColor DarkYellow
            foreach ($disk in $disks) {
                Write-Host "Disk ID:        $($disk.Number)" -ForegroundColor Red
                Write-Host "Disk Name:      $($disk.FriendlyName)"
                Write-Host "Disk Size:      $($disk.Size / 1GB) GB"
                Write-Host "Partition Style:$($disk.PartitionStyle)`n"
            }
        }
    }

    Clear
    while (-Not ([int]$global:numberOfPasses -ge 1 -and [int]$global:numberOfPasses -le 99)) {
        Write-Host "Enter number of passes (1–99, Recommended: 10):" -ForegroundColor Yellow
        $input = Read-Host
        try { $global:numberOfPasses = [int]$input } catch { $global:numberOfPasses = 0 }
        if (-Not ($global:numberOfPasses -ge 1 -and $global:numberOfPasses -le 99)) {
            Clear
            Write-Host "Invalid number. Please enter 1–99." -ForegroundColor DarkYellow
        }
    }

    Clear
    while ($confirmation -ne 'confirm') {
        Write-Host "`nYou are about to wipe Disk $($global:diskIdToWipe) with $($global:numberOfPasses) passes." -ForegroundColor Cyan
        Write-Host "WARNING: ALL DATA WILL BE DESTROYED." -ForegroundColor Red
        Write-Host "Type 'confirm' to proceed or Ctrl+C to cancel." -ForegroundColor Yellow
        $confirmation = Read-Host
        if ($confirmation -ne 'confirm') {
            Clear
            Write-Host "Confirmation required to proceed." -ForegroundColor DarkYellow
        }
    }
}

Function Build-WipeScript() {
    Remove-Item -Path "$systemDrive\$global:DISKPART_SCRIPT" -Force -ErrorAction SilentlyContinue
    @(
        "sel disk $global:diskIdToWipe",
        "clean all",
        "create partition primary",
        "format fs=ntfs quick",
        "assign letter j",
        "exit"
    ) | Out-File "$systemDrive\$global:DISKPART_SCRIPT" -Encoding ascii
}

Function Build-FinalWipeScript() {
    Remove-Item -Path "$systemDrive\$global:DISKPART_SCRIPT" -Force -ErrorAction SilentlyContinue
    @(
        "sel disk $global:diskIdToWipe",
        "clean all",
        "exit"
    ) | Out-File "$systemDrive\$global:DISKPART_SCRIPT" -Encoding ascii
}

Function Perform-WipePass() {
    Build-WipeScript
    Write-Host "`nPass $count of $global:numberOfPasses" -ForegroundColor Cyan
    Write-Progress -Activity "Wiping disk $($global:diskIdToWipe) with diskpart..."
    & diskpart.exe /s "$systemDrive\$global:DISKPART_SCRIPT"
}

Function Perform-FinalWipe() {
    Write-Progress -Activity "Final clean pass on disk $($global:diskIdToWipe)..."
    Build-FinalWipeScript
    & diskpart.exe /s "$systemDrive\$global:DISKPART_SCRIPT"
}

Function Sanitize-Disk() {
    Clear
    $count = 1
    while ($count -le $global:numberOfPasses) {
        Perform-WipePass
        $count++
        Clear
    }
    Write-Host "Disk wipe complete." -ForegroundColor Green
}

# Execution
Get-UserInput
Sanitize-Disk
Perform-FinalWipe
