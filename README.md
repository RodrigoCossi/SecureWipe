# 🔒 SecureWipe - Military Grade Disk Sanitizer

**SecureWipe** is a PowerShell-based utility designed to securely wipe physical disks. It uses a 3-pass method based on the US Department of Defense 5220.22-M standard.

---

# ✅ Purpose
- Prevent data recovery using tools that can read residual magnetic traces.
- Ensure secure decommissioning of drives in military, corporate, or sensitive environments.


## 🚀 Features
- Interactive disk selection
- Diskpart automation for cleanup and reformatting
- Protects USB execution with RAM drive fallback
- Guardrails in place to avoid wiping the system drive or USB accidentally.
- Final wipe after pass loop (clears disk filesystem)

---

## 💡 How It Works

SecureWipe allows you to:
- View all disks connected to the system
- Select the correct one by ID
- Run a secure, scripted wipe using the `diskpart` utility

Description of each pass:
- First pass: Overwrites the disk with 0x00
- Second pass: Overwrites with 0xFF
- Third pass: Overwrites with random data

---

## 📋 Example Execution

```
PS> .\SecureWipe.ps1
```

```
----------------------------------- Disk Information -----------------------------------
Disk ID:        1
Disk Name:      Samsung SSD
Disk Size:      512 GB
Disk Partition: GPT
----------------------------------------------------------------------------------------

Enter the Disk ID you want to securely wipe: 1

Enter the file system format to use (ntfs, fat32, exfat, ext4, apfs) [default: ntfs]: ntfs

You are about to wipe Disk ID 1 with DoD 5220.22-M method.
Type 'confirm' to proceed or Ctrl+C to abort: confirm

Pass 1: Overwriting with pattern zeros ...
Pass 2: Overwriting with pattern ones ...
Pass 3: Overwriting with pattern random ...

Secure wipe complete!
```

> ⚠️ **WARNING**: This will irreversibly erase all data on the selected disk.

---

## 🧠 RAM Drive Protection (If Running From USB)

If you’re running SecureWipe from a **USB stick**, it will copy itself and required files to a **RAM drive (system memory)** and relaunch from there.

**Why?**
- Reduces wear on USB flash drives
- Prevents accidental self-deletion (e.g., wiping the USB itself)
- Increases execution speed and safety

---

## 🛠 Prerequisites

- Windows system with PowerShell
- Admin privileges
- Diskpart must be available (standard on Windows)

---

## 📂 File Overview

- `SecureWipe.ps1` – Main script
- `diskpart_script.txt` – Temporary file used to send commands to `diskpart`
- `SecureWipe.bat` and `SecureWipe.ps1` – Auto-copied to RAM if launched from USB

---

## 🔐 Important Notes

- This script **does not** secure-wipe individual files or partitions — it wipes entire physical disks.
- Make absolutely sure you're selecting the correct disk. You **cannot undo** this process.

---

## 📣 Disclaimer

Use SecureWipe **at your own risk**. This script is powerful and destructive by design.
