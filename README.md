# PowerShell Scripts Collection

A repository of useful PowerShell scripts for Windows system administration and maintenance tasks.

## Overview

This repository contains a collection of PowerShell scripts designed to help system administrators and users perform various maintenance and administrative tasks on Windows systems. Each script is organized in its own folder with dedicated documentation.

## Available Scripts

### [Cleanup-PrinterDrivers](./Cleanup-PrinterDrivers)

A comprehensive tool for cleaning up printer drivers, settings, and related components on Windows machines. This script can:

- Remove unused printer drivers
- Clear print queues
- Clean up printer ports
- Remove all printers (optional)
- Perform user-level cleanup tasks
- Clean up the Windows driver store for printer drivers

See the [Cleanup-PrinterDrivers README](./Cleanup-PrinterDrivers/README.md) for detailed usage instructions.

## Requirements

- Windows operating system
- PowerShell 5.1 or higher
- Administrator privileges for full functionality of most scripts (some operations can run with standard user privileges)

## Usage

Each script is contained in its own folder with a dedicated README file that provides detailed usage instructions, parameters, and examples. Generally, you can:

1. Navigate to the script's folder
2. Review the README.md file for usage instructions
3. Run the script with appropriate parameters

Example:

```powershell
cd Cleanup-PrinterDrivers
.\Cleanup-PrinterDrivers.ps1 -UserLevelOnly
```

## Structure

```
powershell scripts/
├── README.md                  # This file
├── Cleanup-PrinterDrivers/    # Printer cleanup script
│   ├── Cleanup-PrinterDrivers.ps1
│   └── README.md              # Detailed documentation for the script
└── ... (future scripts)
```

## Contributing

Contributions to this repository are welcome. If you'd like to add a new script or improve an existing one:

1. Create a new folder for your script with a descriptive name
2. Include the PowerShell script file(s)
3. Add a comprehensive README.md file in your script's folder
4. Update the main README.md to include your script in the "Available Scripts" section

## License

These scripts are provided as-is with no warranty. Use at your own risk.
