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

If your windows version supports it, search for "Run" in the search bar and open it. Type in optionalFeatures. The window that pops up will contain Hyper-V if your version supports it. Make sure to check the boxes.

#>

<#
.Example 

PowerShell Profile setup

# Check if profile directory exists, create it if not
if (-not (Test-Path -Path (Split-Path -Parent $PROFILE))) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $PROFILE) -Force
}

# Begin profile configuration
"Starting PowerShell Profile Configuration..."


.NOTES Configuring PowerShellGet and NuGet

.# 1. Set up PowerShellGet and NuGet
if (-not (Get-Command Install-PackageProvider -ErrorAction SilentlyContinue)) {
    Write-Host "Installing PowerShellGet and NuGet..."
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
    Install-Module -Name PowerShellGet -Force -Scope CurrentUser
}



# 2. Register PSGallery as trusted repository
if (-not (Get-PSRepository | Where-Object { $_.Name -eq 'PSGallery' })) {
    Write-Host "Registering PSGallery..."
    Register-PSRepository -Name PSGallery -SourceLocation https://www.powershellgallery.com/api/v2 -InstallationPolicy Trusted
}

# 3. Install and configure Az module for Azure development
if (-not (Get-Module -ListAvailable -Name Az)) {
    Write-Host "Installing Az module for Azure..."
    Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
}

# 4. Import Hyper-V module if available
if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
    if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V).State -eq "Enabled") {
        Write-Host "Hyper-V is already enabled."
        Import-Module -Name Hyper-V
    } else {
        Write-Host "Enabling Hyper-V feature..."
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
    }
}

# 5. Set up PackageManagement for module installation
if (-not (Get-Command Install-Module -ErrorAction SilentlyContinue)) {
    Write-Host "Installing PackageManagement module..."
    Install-Module -Name PackageManagement -Force -Scope CurrentUser
}

# 6. Other development tools
Write-Host "Installing useful development modules..."
$devModules = @('Pester', 'Plaster', 'PSReadLine', 'PSWriteColor')
foreach ($module in $devModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Install-Module -Name $module -Force -Scope CurrentUser
    }
}

# 7. Configure PSReadLine for better shell usability
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -Colors @{
    InlinePrediction = [ConsoleColor]::DarkGray
}

# 8. Enable command aliases for common Unix-like commands
Write-Host "Adding Unix-like command aliases..."
Set-Alias ll Get-ChildItem
Set-Alias la "Get-ChildItem -Force"
Set-Alias .. Set-Location ..

# 9. Automatically import Az and Hyper-V on startup
Write-Host "Adding Az and Hyper-V modules to auto-import..."
if (Get-Module -ListAvailable -Name Az) {
    Import-Module -Name Az
}
if (Get-Module -ListAvailable -Name Hyper-V) {
    Import-Module -Name Hyper-V
}

# Completion message
Write-Host "PowerShell Profile Configuration Complete!"

# Optional: Open a new PowerShell window to apply changes
Write-Host "Restart your PowerShell session to fully apply changes."


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
