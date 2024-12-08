<#
.SYNOPSIS
Creates and manages an Arch Linux VM on Hyper-V with flexible configuration options.

.DESCRIPTION
This script automates the creation and configuration of a Hyper-V VM. It includes options for setting dynamic memory, processor count, attaching ISO files, creating additional disks, and configuring shared folders.

.PARAMETER VMName
The name of the virtual machine to create or manage.

.PARAMETER VHDPath
The path to the primary VHD file for the VM.

.PARAMETER ISOPath
The path to the Arch Linux ISO file to attach to the VM.

.PARAMETER MemoryStartupMB
The startup memory for the VM (in MB).

.PARAMETER MemoryMinimumMB
The minimum dynamic memory for the VM (in MB).

.PARAMETER MemoryMaximumMB
The maximum dynamic memory for the VM (in MB).

.PARAMETER ProcessorCount
The number of virtual processors to allocate to the VM.

.PARAMETER AdditionalDisks
The number of additional disks to create and attach to the VM.

.PARAMETER DiskSizeGB
The size of each additional disk (in GB).

.PARAMETER SharedFolder
The path to a folder on the host to share with the VM.

.EXAMPLE
.\Manage-ArchLinuxVM.ps1 -VMName "ArchLinuxVM" -ISOPath "C:\ISOs\archlinux.iso" -MemoryStartupMB 2048 -ProcessorCount 2 -AdditionalDisks 2 -DiskSizeGB 20 -SharedFolder "C:\Hyper-V\Shared"

Creates a new Arch Linux VM with the specified resources, attaches an ISO, and configures shared folders.

.NOTES
Requires Hyper-V to be enabled and running on the host system.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$VMName,

    [Parameter(Mandatory = $true)]
    [string]$VHDPath = "C:\Hyper-V\Virtual Hard Disks\$VMName.vhdx",

    [Parameter(Mandatory = $true)]
    [string]$ISOPath,

    [int]$MemoryStartupMB = 2048,
    [int]$MemoryMinimumMB = 1024,
    [int]$MemoryMaximumMB = 4096,
    [int]$ProcessorCount = 2,
    [int]$AdditionalDisks = 0,
    [int]$DiskSizeGB = 20,
    [string]$SharedFolder = "C:\Hyper-V\Shared"
)

# Ensure the script runs as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script must be run as an Administrator!"
    exit
}

# Import Hyper-V module
Import-Module Hyper-V

# Enable Enhanced Session Mode
Set-VMHost -EnableEnhancedSessionMode $true

# Create VM
if (-not (Get-VM -Name $VMName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating VM: $VMName"
    New-VM -Name $VMName -MemoryStartupBytes (${MemoryStartupMB}MB) -Generation 2 -SwitchName "Default Switch" -VHDPath $VHDPath
}

# Configure memory and processors
Write-Host "Configuring VM resources..."
Set-VM -Name $VMName -DynamicMemory -MemoryStartupBytes (${MemoryStartupMB}MB) -MemoryMinimumBytes (${MemoryMinimumMB}MB) -MemoryMaximumBytes (${MemoryMaximumMB}MB)
Set-VMProcessor -VMName $VMName -Count $ProcessorCount

# Attach ISO
Write-Host "Attaching ISO..."
if (-not (Get-VMDvdDrive -VMName $VMName -ErrorAction SilentlyContinue)) {
    Add-VMDvdDrive -VMName $VMName -Path $ISOPath
} else {
    Set-VMDvdDrive -VMName $VMName -Path $ISOPath
}

# Create and attach additional disks
if ($AdditionalDisks -gt 0) {
    for ($i = 1; $i -le $AdditionalDisks; $i++) {
        $DiskPath = "C:\Hyper-V\Virtual Hard Disks\$VMName-Disk$i.vhdx"
        Write-Host "Creating additional disk $i at $DiskPath..."
        New-VHD -Path $DiskPath -SizeBytes ($DiskSizeGB * 1GB) -Dynamic
        Add-VMHardDiskDrive -VMName $VMName -Path $DiskPath
    }
}

# Configure shared folder
if ($SharedFolder) {
    Write-Host "Configuring shared folder at $SharedFolder..."
    if (-not (Test-Path $SharedFolder)) {
        New-Item -Path $SharedFolder -ItemType Directory
    }
}

# Start VM
Write-Host "Starting VM..."
Start-VM -Name $VMName

# Output summary
Write-Host "VM '$VMName' has been created and configured with the following settings:"
Write-Host " - Memory: $MemoryStartupMB MB (Dynamic: $MemoryMinimumMB MB - $MemoryMaximumMB MB)"
Write-Host " - Processor Count: $ProcessorCount"
Write-Host " - Primary VHD: $VHDPath"
Write-Host " - ISO Path: $ISOPath"
Write-Host " - Additional Disks: $AdditionalDisks ($DiskSizeGB GB each)"
Write-Host " - Shared Folder: $SharedFolder"
