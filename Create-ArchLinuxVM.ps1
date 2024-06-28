# Ensure you are running the script as an Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You need to run this script as an Administrator!"
    exit
}

# Import the Hyper-V module
Import-Module Hyper-V

# Variables
$vmName = "ArchLinuxVM"
$vhdPath = "C:\Hyper-V\Virtual Hard Disks\ArchLinuxVM.vhdx"
$memoryStartup = 2048MB
$memoryMinimum = 1024MB
$memoryMaximum = 4096MB
$processorCount = 2
$switchName = "ExternalSwitch"
$networkAdapterName = "Network Adapter"
$isoPath = "C:\path\to\archlinux.iso"  # Update with the correct path to your Arch Linux ISO

# Enable Enhanced Session Mode
Set-VMHost -EnableEnhancedSessionMode $true

# Create an external virtual switch if it doesn't exist
if (-not (Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue))
{
    New-VMSwitch -Name $switchName -NetAdapterName (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1).Name -AllowManagementOS $true
}

# Create a new VM
New-VM -Name $vmName -MemoryStartupBytes $memoryStartup -VHDPath $vhdPath -Generation 2

# Configure VM settings
Set-VM -Name $vmName -DynamicMemory -MemoryMinimumBytes $memoryMinimum -MemoryMaximumBytes $memoryMaximum
Set-VMProcessor -VMName $vmName -Count $processorCount
Add-VMNetworkAdapter -VMName $vmName -SwitchName $switchName -Name $networkAdapterName

# Attach the Arch Linux ISO to the VM
Add-VMDvdDrive -VMName $vmName -Path $isoPath

# Configure Shared Folders (Host to VM)
# For this example, we're sharing the "C:\Hyper-V\Shared" folder
$sharedFolder = "C:\Hyper-V\Shared"
if (-not (Test-Path $sharedFolder))
{
    New-Item -Path $sharedFolder -ItemType Directory
}

Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $sharedFolder

# Start the VM
Start-VM -Name $vmName

# Output the configuration summary
Write-Host "VM '$vmName' has been created and started with the following configuration:"
Write-Host " - Memory: $memoryStartup (Dynamic Memory: $memoryMinimum - $memoryMaximum)"
Write-Host " - Processor Count: $processorCount"
Write-Host " - Network Adapter: Connected to '$switchName'"
Write-Host " - ISO Path: $isoPath"
Write-Host " - Shared Folder: $sharedFolder"
