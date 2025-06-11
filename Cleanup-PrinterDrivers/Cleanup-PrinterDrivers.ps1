<#
.SYNOPSIS
    Cleans up printer drivers and settings on Windows machines
.DESCRIPTION
    This script performs printer cleanup tasks. Some operations require administrator privileges.
.PARAMETER RemoveAllPrinters
    If specified, removes all installed printers (requires admin)
.PARAMETER Force
    Bypasses confirmation prompts
.PARAMETER UserLevelOnly
    Performs only user-level cleanup tasks
.EXAMPLE
    .\Cleanup-PrinterDrivers.ps1 -UserLevelOnly
.EXAMPLE
    .\Cleanup-PrinterDrivers.ps1 -RemoveAllPrinters -Force
#>

param(
    [switch]$RemoveAllPrinters,
    [switch]$Force,
    [switch]$UserLevelOnly
)

# Function to log messages
function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Log "Running as normal user - performing user-level cleanup only" "WARNING"
    Write-Log "For full cleanup (drivers, system settings), run as Administrator"
    $UserLevelOnly = $true
}

Write-Log "Starting printer cleanup..."

try {
    # USER LEVEL CLEANUP TASKS
    Write-Log "=== USER LEVEL CLEANUP ==="
    
    # Clear user-specific print settings and preferences
    Write-Log "Clearing user print preferences..."
    $userPrintSettings = @(
        "HKCU:\Printers\Settings",
        "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\PrinterPorts",
        "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows\Device"
    )
    
    foreach ($regPath in $userPrintSettings) {
        try {
            if (Test-Path $regPath) {
                # Backup current settings first
                $backupPath = "$env:TEMP\PrinterBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
                reg export $regPath.Replace('HKCU:', 'HKEY_CURRENT_USER') $backupPath /y | Out-Null
                Write-Log "Backed up $regPath to $backupPath"
                
                # Clear the registry key (but keep the key itself)
                Get-ChildItem $regPath -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Cleared user settings: $regPath"
            }
        }
        catch {
            Write-Log "Could not clear user setting $regPath : $($_.Exception.Message)" "WARNING"
        }
    }
    
    # Clear recent documents that might reference printers
    Write-Log "Clearing recent printer-related documents..."
    $recentPath = "$env:APPDATA\Microsoft\Windows\Recent"
    if (Test-Path $recentPath) {
        Get-ChildItem $recentPath -Filter "*.lnk" | Where-Object { 
            $_.Name -match "(print|printer)" 
        } | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    
    # Clear user temp files related to printing
    Write-Log "Clearing user temporary print files..."
    $tempPaths = @("$env:TEMP", "$env:LOCALAPPDATA\Temp")
    foreach ($tempPath in $tempPaths) {
        if (Test-Path $tempPath) {
            Get-ChildItem $tempPath -Filter "*print*" -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    if ($UserLevelOnly) {
        Write-Log "User-level cleanup completed. For system-level cleanup, run as Administrator."
        return
    }
    
    # ADMINISTRATOR LEVEL CLEANUP TASKS
    Write-Log "=== ADMINISTRATOR LEVEL CLEANUP ==="
    
    # Stop print spooler service
    Write-Log "Stopping Print Spooler service..."
    Stop-Service -Name Spooler -Force -ErrorAction Stop
    
    # Clear print queue files
    Write-Log "Clearing print queue files..."
    $spoolPath = "$env:WINDIR\System32\spool\PRINTERS"
    if (Test-Path $spoolPath) {
        Get-ChildItem -Path $spoolPath -File | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Log "Print queue files cleared"
    }
    
    # Start print spooler service
    Write-Log "Starting Print Spooler service..."
    Start-Service -Name Spooler -ErrorAction Stop
    
    # Wait for service to fully start
    Start-Sleep -Seconds 3
    
    # Get all installed printers
    $printers = Get-Printer -ErrorAction SilentlyContinue
    Write-Log "Found $($printers.Count) installed printers"
    
    if ($RemoveAllPrinters) {
        if (-not $Force) {
            $confirm = Read-Host "Are you sure you want to remove ALL printers? (Y/N)"
            if ($confirm -ne 'Y' -and $confirm -ne 'y') {
                Write-Log "Operation cancelled by user"
                exit 0
            }
        }
        
        # Remove all printers
        Write-Log "Removing all printers..."
        foreach ($printer in $printers) {
            try {
                Remove-Printer -Name $printer.Name -ErrorAction Stop
                Write-Log "Removed printer: $($printer.Name)"
            }
            catch {
                Write-Log "Failed to remove printer $($printer.Name): $($_.Exception.Message)" "WARNING"
            }
        }
    }
    
    # Get all printer drivers
    Write-Log "Scanning for printer drivers..."
    $drivers = Get-PrinterDriver -ErrorAction SilentlyContinue
    $driversInUse = @()
    
    # If printers still exist, get their drivers
    $remainingPrinters = Get-Printer -ErrorAction SilentlyContinue
    foreach ($printer in $remainingPrinters) {
        $driversInUse += $printer.DriverName
    }
    
    Write-Log "Found $($drivers.Count) total drivers, $($driversInUse.Count) in use"
    
    # Remove unused drivers
    $removedCount = 0
    foreach ($driver in $drivers) {
        if ($driver.Name -notin $driversInUse) {
            try {
                Remove-PrinterDriver -Name $driver.Name -ErrorAction Stop
                Write-Log "Removed unused driver: $($driver.Name)"
                $removedCount++
            }
            catch {
                # Try to remove with environment specified
                try {
                    Remove-PrinterDriver -Name $driver.Name -PrinterEnvironment "Windows x64" -ErrorAction Stop
                    Write-Log "Removed unused driver (x64): $($driver.Name)"
                    $removedCount++
                }
                catch {
                    Write-Log "Failed to remove driver $($driver.Name): $($_.Exception.Message)" "WARNING"
                }
            }
        }
        else {
            Write-Log "Keeping driver in use: $($driver.Name)"
        }
    }
    
    # Remove unused printer ports (optional)
    Write-Log "Checking for unused printer ports..."
    $ports = Get-PrinterPort -ErrorAction SilentlyContinue
    $portsInUse = @()
    
    foreach ($printer in $remainingPrinters) {
        $portsInUse += $printer.PortName
    }
    
    $removedPorts = 0
    foreach ($port in $ports) {
        # Only remove TCP/IP and local ports, skip standard Windows ports
        if ($port.Name -notin $portsInUse -and 
            $port.Name -notmatch "^(LPT|COM|FILE|NUL|CON).*" -and
            $port.PortMonitor -ne "Local Port") {
            try {
                Remove-PrinterPort -Name $port.Name -ErrorAction Stop
                Write-Log "Removed unused port: $($port.Name)"
                $removedPorts++
            }
            catch {
                Write-Log "Failed to remove port $($port.Name): $($_.Exception.Message)" "WARNING"
            }
        }
    }
    
    # Clean up driver store (advanced)
    Write-Log "Attempting to clean driver store..."
    try {
        $driverPackages = Get-WindowsDriver -Online | Where-Object { $_.ClassName -eq "Printer" }
        foreach ($package in $driverPackages) {
            # Only remove if not currently in use
            if ($package.Driver -notin $driversInUse) {
                try {
                    Remove-WindowsDriver -Online -Driver $package.Driver -ErrorAction Stop
                    Write-Log "Removed driver package: $($package.Driver)"
                }
                catch {
                    # This is expected for some drivers, so we'll continue silently
                }
            }
        }
    }
    catch {
        Write-Log "Driver store cleanup encountered issues (this is normal)" "WARNING"
    }
    
    Write-Log "Cleanup completed successfully!"
    Write-Log "Summary:"
    Write-Log "  - Removed $removedCount unused printer drivers"
    Write-Log "  - Removed $removedPorts unused printer ports"
    Write-Log "  - Cleared print queue files"
    
    if ($RemoveAllPrinters) {
        Write-Log "  - Removed all printers"
    }
    
    Write-Log "You may need to restart the computer for all changes to take effect."
}
catch {
    Write-Log "An error occurred: $($_.Exception.Message)" "ERROR"
    # Ensure print spooler is running
    try {
        Start-Service -Name Spooler -ErrorAction SilentlyContinue
    }
    catch {}
    exit 1
}