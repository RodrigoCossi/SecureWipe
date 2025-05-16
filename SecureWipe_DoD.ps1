# SecureWipe - DoD 5220.22-M Version

$disks = Get-Disk
$disk_IDs = @()
$global:FileSystemType = "ntfs"  # default value

function Copy-Files-To-Ram-Drive() {
    if (-Not ((Test-Path "$($SYSTEM_DRIVE)\SecureWipe.bat") -And (Test-Path "$($SYSTEM_DRIVE)\SecureWipe.ps1"))) {
        Write-Host ""
        Write-Host "RAM Drive missing SecureWipe files. Copying files necessary to be able to remove USB..." -ForegroundColor Green
        $JUNK | Out-File .\_._
        Copy-Item -Path .\_._ -Destination "$($SYSTEM_DRIVE)\_._"
        Copy-Item -Path .\SecureWipe.bat -Destination "$($SYSTEM_DRIVE)\SecureWipe.bat"
        Copy-Item -Path .\SecureWipe.ps1 -Destination "$($SYSTEM_DRIVE)\SecureWipe.ps1"
    }
    else {
        return # Files already exist, do exit function
    }
    Set-Location $ENV:SystemDrive
    Write-Host "Relaunching SecureWipe from Ram Drive." -ForegroundColor Green
    Start-Sleep -Seconds 3
    Powershell.exe -File .\SecureWipe.ps1
    Exit
}

function Show-Disk-Info {
    Clear-Host
    Write-Host "----------------------------------- Disk Information -----------------------------------`n"
    foreach ($disk in $disks) {
        Write-Host "Disk ID:        $($disk.Number)" -ForegroundColor Red
        Write-Host "Disk Name:      $($disk.FriendlyName)"
        Write-Host "Disk Size:      $([math]::Round($disk.Size / 1GB, 2)) GB"
        Write-Host "Disk Partition: $($disk.PartitionStyle)"
        Write-Host
        $disk_IDs += $disk.Number
    }
    Write-Host "----------------------------------------------------------------------------------------"
}

function Get-User-Input {
    Show-Disk-Info

    do {
        $diskID = Read-Host "`nEnter the Disk ID you want to securely wipe"
    } until ($disk_IDs -contains [int]$diskID)

    $global:SelectedDisk = $diskID

    do {
        $fs = Read-Host "Enter the file system format to use (ntfs, fat32, exfat, ext4, apfs) [default: ntfs]"
        if ([string]::IsNullOrWhiteSpace($fs)) {
            $fs = "ntfs"
        }
    } until ($fs -in @("ntfs", "fat32", "exfat", "ext4", "apfs"))
    
    $global:FileSystemType = $fs

    
    $global:FileSystemType = $fs


    Clear-Host
    Write-Host "You are about to wipe Disk ID $SelectedDisk with DoD 5220.22-M method." -ForegroundColor Yellow
    Write-Host "Type 'confirm' to proceed or Ctrl+C to abort."
    $confirmation = Read-Host
    if ($confirmation -ne "confirm") {
        Write-Host "Sanitization cancelled." -ForegroundColor Red
        Exit
    }
}

function Overwrite-Disk([string]$pattern, [int]$passNumber) {
    Write-Host "`nPass $passNumber: Overwriting with pattern $pattern ..." -ForegroundColor Cyan
    $script = @"
select disk $SelectedDisk
clean all
create partition primary
format fs=$FileSystemType quick
assign letter=Z
exit
"@

    $script | Out-File "$env:TEMP\diskpart_script.txt" -Encoding ASCII
    diskpart /s "$env:TEMP\diskpart_script.txt" | Out-Null

    $disk = Get-Volume -FileSystemLabel "New Volume" -ErrorAction SilentlyContinue
    if (-not $disk) {
        $disk = Get-Volume -DriveLetter Z
    }
    
    if ($disk) {
        $sizeInBytes = ($disk.SizeRemaining - 10MB) # Leave some space
        $buffer = switch ($pattern) {
            "zeros" { [byte]0x00 }
            "ones"  { [byte]0xFF }
            "random" { Get-Random -Minimum 0 -Maximum 256 }
        }

        $filePath = "$($disk.DriveLetter):\wipe.tmp"
        $stream = [System.IO.File]::Create($filePath)

        try {
            $chunk = New-Object byte[] (1MB)
            for ($i = 0; $i -lt $chunk.Length; $i++) {
                $chunk[$i] = if ($pattern -eq "random") { Get-Random -Minimum 0 -Maximum 256 } else { $buffer }
            }
            $written = 0
            while ($written -lt $sizeInBytes) {
                $stream.Write($chunk, 0, $chunk.Length)
                $written += $chunk.Length
            }
        } finally {
            $stream.Close()
        }

        Remove-Item $filePath -Force
    }
}

function Secure-Wipe {
    Overwrite-Disk "zeros" 1
    Overwrite-Disk "ones" 2
    Overwrite-Disk "random" 3

    Clear-Host
    Write-Host "`nSecure wipe complete!" -ForegroundColor Green
}

# Main
Copy-Files-To-Ram-Drive()
Get-User-Input
Secure-Wipe
