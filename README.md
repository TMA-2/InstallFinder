# InstallFinder

PowerShell module for finding and managing installed applications via registry search with support for remote computers and uninstallation.

## Features

- **Fast registry-based search** - Query installed applications from registry (~100ms vs seconds for WMI)
- **Remote computer support** - Search and uninstall on remote machines
- **Multiple output formats** - GridView, CSV, JSON, XML, HTML, and more
- **Smart uninstall parsing** - Automatically converts modify commands to silent uninstall commands
- **Pipeline support** - Properly streams results for efficient processing
- **Flexible filtering** - Search by name, publisher, version, or custom script blocks
- **Custom formatting** - Clean table and list views with sensible defaults

## Installation

```powershell
# Import the module
Import-Module InstallFinder

# Or copy to your PowerShell module path
Copy-Item -Path .\InstallFinder -Destination "$env:PSModulePath\InstallFinder" -Recurse
```

## Quick Start

```powershell
# Find VMware applications
Find-InstalledApplication "VMware*"

# Output displays in clean table format by default:
# Computer        Name                              Version        Publisher
# --------        ----                              -------        ---------
# WORKSTATION01   VMware Horizon Client             8.11.0.23058   VMware, Inc.

# Find and display in GridView
Find-InstalledApplication "Microsoft*" -Display

# View detailed information with Format-List
Find-InstalledApplication "PowerShell*" | Format-List
# Shows: Computer, Name, Version, Publisher, GUID, Uninstall

# Search by publisher
Find-InstalledApplication "VMware*" -Property Publisher

# Find and uninstall (with confirmation)
Find-InstalledApplication "OldApp*" -Uninstall

# Search remote computer
Find-InstalledApplication "Chrome*" -ComputerName SERVER01

# Custom filter
Find-InstalledApplication -Filter {$_.InstallDate -match '2024'}

# Export to CSV
Find-InstalledApplication "Adobe*" -Display -Output CSV

# Generate interactive HTML report with dark mode
Find-InstalledApplication "Microsoft*" -Display -Output HTML
# Creates a sortable, searchable report with theme toggle
```

### HTML Report Features
When using `-Output HTML`, you get an interactive report with:
- 🌓 **Dark/Light mode toggle** (defaults to dark mode, saves preference)
- 🔍 **Real-time search** - Filter applications instantly
- ⬆️⬇️ **Sortable columns** - Click any column header to sort
- 📊 **Statistics dashboard** - View counts and architecture breakdown
- 📱 **Responsive design** - Works on mobile and desktop
- 💾 **Saves to file** - Opens automatically in your default browser

```powershell

## Functions

### Find-InstalledApplication
Searches installed applications from the registry and optionally tries to uninstall and/or output to multiple file types.

**Alias:** `Find-Install`

### Start-Uninstall
Runs uninstall commands locally or remotely with proper error handling and exit code reporting.

## Requirements

- PowerShell 5.1 or higher
- Administrator rights for uninstall operations
- WinRM configured for remote operations
- **Recommended:** CMLogs module for Configuration Manager-formatted log file support

## License

Copyright (c) 2025 Jonathan Dunham

[See LICENSE](LICENSE)

## Authors

- Jonathan Dunham
