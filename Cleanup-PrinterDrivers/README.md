# Cleanup-PrinterDrivers

A PowerShell script for cleaning up printer drivers, settings, and related components on Windows machines.

## Overview

`Cleanup-PrinterDrivers.ps1` is a comprehensive tool designed to help system administrators and users clean up printer-related components on Windows systems. It can perform both user-level and administrator-level cleanup tasks, making it versatile for different scenarios.

## Requirements

- Windows operating system
- PowerShell 5.1 or higher
- Administrator privileges for full functionality (some operations can run with standard user privileges)

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-RemoveAllPrinters` | Switch | If specified, removes all installed printers (requires administrator privileges) |
| `-Force` | Switch | Bypasses confirmation prompts when removing all printers |
| `-UserLevelOnly` | Switch | Performs only user-level cleanup tasks, even when run as administrator |

## Usage Examples

### Perform User-Level Cleanup Only

```powershell
.\Cleanup-PrinterDrivers.ps1 -UserLevelOnly
```

This will clean up user-specific print settings and preferences, clear recent printer-related documents, and remove temporary print files in the user's profile.

### Remove All Printers and Perform Full Cleanup

```powershell
.\Cleanup-PrinterDrivers.ps1 -RemoveAllPrinters -Force
```

This will perform a complete cleanup including removing all printers, unused printer drivers, and printer ports without confirmation prompts.

### Standard Cleanup (Administrator)

```powershell
.\Cleanup-PrinterDrivers.ps1
```

When run as administrator without parameters, the script will perform a standard cleanup that includes:
- User-level cleanup tasks
- Stopping and restarting the print spooler service
- Clearing print queue files
- Removing unused printer drivers and ports
- Cleaning up the driver store

## Functionality Details

### User-Level Cleanup Tasks

These tasks can be performed without administrator privileges:

- Clears user-specific print settings and preferences from the registry
- Backs up registry settings before clearing them
- Removes printer-related shortcuts from the Recent Items folder
- Clears temporary print files from user temp directories

### Administrator-Level Cleanup Tasks

These tasks require administrator privileges:

- Stops and restarts the Print Spooler service
- Clears print queue files from the spooler directory
- Optionally removes all installed printers
- Identifies and removes unused printer drivers
- Cleans up unused printer ports (excluding standard Windows ports)
- Attempts to clean up the Windows driver store for printer drivers

## Notes and Warnings

- **Registry Backups**: The script creates backups of registry settings before clearing them. These are stored in the user's temp directory with filenames like `PrinterBackup_YYYYMMDD_HHMMSS.reg`.
- **Service Restart**: The script stops and restarts the Print Spooler service, which may temporarily interrupt printing services.
- **System Restart**: In some cases, a system restart may be required for all changes to take effect, especially after removing printer drivers.
- **Running as Standard User**: When run without administrator privileges, the script automatically switches to user-level cleanup only and displays a warning.

## Logging

The script provides detailed logging to the console, including:
- Timestamp for each operation
- Clear section headers for different cleanup phases
- Summary of actions performed
- Warnings and error messages when operations fail

## Troubleshooting

If you encounter issues:

1. Ensure you're running with the appropriate privileges for your intended cleanup level
2. Check for error messages in the script output
3. Try running with the `-UserLevelOnly` switch first to see if user-level cleanup completes successfully
4. For driver removal issues, you may need to manually uninstall printer software using Windows Settings or Control Panel

## License

This script is provided as-is with no warranty. Use at your own risk.
