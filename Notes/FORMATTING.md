# Custom Type and Format Implementation

## Overview
Added custom PowerShell type definition and formatting views to the InstallFinder module for better default display behavior.

## Files Created

### 1. InstallFinder.Types.ps1xml
Defines a custom type `InstallFinder.Application` with a default display property set.

**Default Display Properties:**
- Computer
- Name
- Version
- Publisher

This means when you run `Find-InstalledApplication`, you'll only see these four columns by default, making the output much cleaner and easier to read.

### 2. InstallFinder.Format.ps1xml
Provides custom formatting views for both table and list display modes.

**Table View (Default):**
- Computer (15 chars)
- Name (35 chars)
- Version (15 chars)
- Publisher (remaining width)

**List View (Format-List):**
- Computer
- Name
- Version
- Publisher
- GUID
- Uninstall

## Implementation Details

### Manifest Updates
Updated `InstallFinder.psd1` to include:
```powershell
TypesToProcess = @('InstallFinder.Types.ps1xml')
FormatsToProcess = @('InstallFinder.Format.ps1xml')
```

### Function Updates
Modified `Find-InstalledApplication.ps1` to add PSTypeName to output objects:
```powershell
$AppInfo = [PSCustomObject]@{
    PSTypeName = 'InstallFinder.Application'
    Computer   = ...
    Name       = ...
    # ... other properties
}
```

## Usage Examples

### Default Table Output
```powershell
PS> Find-InstalledApplication "PowerShell*"

Computer        Name                              Version        Publisher
--------        ----                              -------        ---------
WORKSTATION01   PowerShell 7-x64                  7.4.5.0       Microsoft Corporation
WORKSTATION01   PowerShell 7-preview-x64          7.5.0.4       Microsoft Corporation
```

### List Output (More Details)
```powershell
PS> Find-InstalledApplication "PowerShell*" | Format-List

Computer  : WORKSTATION01
Name      : PowerShell 7-x64
Version   : 7.4.5.0
Publisher : Microsoft Corporation
GUID      : {B0F5A7A7-1C3E-4B7F-9F3E-1D2C3B4A5E6F}
Uninstall : "C:\Program Files\PowerShell\7\pwsh.exe" -Command Uninstall-PSResource PowerShell
```

### Access All Properties
All properties are still accessible; they're just not displayed by default:
```powershell
PS> $App = Find-InstalledApplication "PowerShell*" | Select-Object -First 1
PS> $App | Select-Object * | Format-List

# Shows all properties: Computer, Name, Version, Publisher, GUID, InstallArch, 
# AppArch, Location, Source, Size, Modify, Repair, Uninstall, QuietUninstall,
# UninstallCmd, UninstallArg, System, Path, User, Hive, ExitCode
```

## Benefits

1. **Cleaner Output**: Users see only the most relevant information by default
2. **Better Usability**: No need to pipe to `Select-Object` for common scenarios
3. **Consistent Experience**: Follows PowerShell conventions for custom types
4. **Flexibility**: Full data still accessible when needed via `Select-Object *` or `Format-List`
5. **Professional Appearance**: Fixed-width columns in table view for aligned output

## Testing

After importing the module, verify the formatting works:
```powershell
Import-Module InstallFinder -Force

# Test default table format
Find-InstalledApplication "Microsoft*" | Select-Object -First 5

# Test list format
Find-InstalledApplication "PowerShell*" | Format-List

# Verify type name
$App = Find-InstalledApplication "*" | Select-Object -First 1
$App.PSTypeNames[0]  # Should return: InstallFinder.Application
```

## Version
Added in v0.1.0 (2025-10-11)
