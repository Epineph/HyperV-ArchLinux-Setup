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

# Function to set VM resources
function Set-VMResources {
    param (
        [string]$VMName,
        [int]$ProcessorCount,
        [int]$MemoryStartupMB,
        [int]$MemoryMinimumMB,
        [int]$MemoryMaximumMB
    )
    
    # Check if VM exists
    if (-not (Get-VM -Name $VMName -ErrorAction SilentlyContinue)) {
        Write-Error "VM '$VMName' does not exist."
        return
    }
    
    # Set processor count
    Set-VMProcessor -VMName $VMName -Count $ProcessorCount
    
    # Set memory configuration
    Set-VM -Name $VMName -DynamicMemory -MemoryStartupBytes (${MemoryStartupMB}MB) -MemoryMinimumBytes (${MemoryMinimumMB}MB) -MemoryMaximumBytes (${MemoryMaximumMB}MB)
    
    Write-Host "VM '$VMName' resources have been updated:"
    Write-Host " - Processor Count: $ProcessorCount"
    Write-Host " - Memory: $MemoryStartupMB MB (Dynamic Memory: $MemoryMinimumMB MB - $MemoryMaximumMB MB)"
}

# Prompt for user input
$processorCount = Read-Host "Enter the number of processors to allocate"
$memoryStartupMB = Read-Host "Enter the startup memory (MB)"
$memoryMinimumMB = Read-Host "Enter the minimum memory (MB)"
$memoryMaximumMB = Read-Host "Enter the maximum memory (MB)"

# Validate input
if ($processorCount -lt 1) {
    Write-Error "Processor count must be at least 1."
    exit
}

if ($memoryStartupMB -lt 512) {
    Write-Error "Startup memory must be at least 512 MB."
    exit
}

if ($memoryMinimumMB -lt 512) {
    Write-Error "Minimum memory must be at least 512 MB."
    exit
}

if ($memoryMaximumMB -lt $memoryStartupMB) {
    Write-Error "Maximum memory must be greater than or equal to startup memory."
    exit
}

# Set VM resources
Set-VMResources -VMName $vmName -ProcessorCount $processorCount -MemoryStartupMB $memoryStartupMB -MemoryMinimumMB $memoryMinimumMB -MemoryMaximumMB $memoryMaximumMB
