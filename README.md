# Hyper-V Arch Linux Setup

This repository contains PowerShell scripts to automate the setup and configuration of an Arch Linux virtual machine on Hyper-V.

## Scripts

### 1. Create-ArchLinuxVM.ps1

This script creates a new Arch Linux virtual machine on Hyper-V with the following configurations:
- Enables Enhanced Session Mode
- Creates an external virtual switch
- Configures VM settings (memory, processors, network adapter)
- Attaches the Arch Linux ISO
- Configures shared folders
- Starts the VM

**Usage:**
```powershell
.\Create-ArchLinuxVM.ps1
```