# InstallFinder HTML Column Customization Guide

## Overview
The HTML report generation now uses a **template-driven approach** where column definitions are managed in one place (PowerShell) and dynamically injected into the HTML template.

## Architecture

### Single Source of Truth
All column definitions are maintained in `Private/ConvertTo-InstallFinderHtml.ps1`:

```powershell
$ColumnMetadata = @(
    @{ index = 0; name = 'Computer'; required = $true; property = 'Computer' }
    @{ index = 1; name = 'Name'; required = $true; property = 'Name' }
    @{ index = 2; name = 'Version'; required = $false; property = 'Version' }
    # ... etc for all 16 columns
)
```

### What Gets Injected

1. **Column Metadata** (`{{COLUMN_METADATA}}`): Complete JSON array of column definitions
2. **Default Visible Columns** (`{{DEFAULT_VISIBLE_COLUMNS}}`): Array of column indices to show by default
3. **Table Headers** (`{{TABLE_HEADERS}}`): Dynamically generated `<th>` elements

## How to Add/Remove/Modify Columns

### Adding a New Column

1. **Add to PowerShell metadata** in `ConvertTo-InstallFinderHtml.ps1`:
   ```powershell
   $ColumnMetadata = @(
       # ... existing columns ...
       @{ index = 16; name = 'New Column'; required = $false; property = 'NewProperty' }
   )
   ```

2. **Add to table row generation** in the same file:
   ```powershell
   $TableRows = foreach ($App in $Applications) {
       @"
           <tr>
               <!-- ... existing columns ... -->
               <td>$($App.NewProperty)</td>
           </tr>
   "@
   }
   ```

That's it! The HTML template will automatically:
- Generate the header
- Add it to the column visibility menu
- Handle sorting/filtering

### Removing a Column

1. Remove from `$ColumnMetadata` array
2. Remove corresponding `<td>` from table row generation
3. Update indices of subsequent columns

### Changing Column Order

1. Reorder entries in `$ColumnMetadata` (update `index` values)
2. Reorder corresponding `<td>` elements in table rows

### Changing Default Visible Columns

Modify the `$DefaultVisibleColumns` array:
```powershell
$DefaultVisibleColumns = @(0, 1, 2, 3, 5, 7)  # Computer, Name, Version, Publisher, GUID, Arch
```

### Making a Column Required

Set `required = $true` in the metadata:
```powershell
@{ index = 2; name = 'Version'; required = $true; property = 'Version' }
```

Required columns cannot be hidden via the UI.

## Current Column Structure

| Index | Name | Property | Required | Description |
|-------|------|----------|----------|-------------|
| 0 | Computer | Computer | ✓ | Target host name |
| 1 | Name | Name | ✓ | Application display name |
| 2 | Version | Version | | Application version |
| 3 | Publisher | Publisher | | Software publisher |
| 4 | Install Date | InstallDate | | Installation date |
| 5 | GUID | GUID | | Registry key GUID |
| 6 | Size (MB) | Size | | Installation size |
| 7 | Architecture (Install) | InstallArch | | x64/x86 registry location |
| 8 | Architecture (App) | AppArch | | x64/x86 app binary |
| 9 | Uninstall Cmd | UninstallCmd | | Parsed uninstall command |
| 10 | Uninstall Args | UninstallArg | | Parsed uninstall arguments |
| 11 | Location | Location | | Install location path |
| 12 | Source | Source | | Install source path |
| 13 | Registry Path | Path | | Full registry key path |
| 14 | User | User | | User context |
| 15 | Hive | Hive | | Registry hive (HKLM/HKCU) |

## Benefits of This Approach

✅ **Single source of truth**: Column definitions in one place  
✅ **Type safety**: PowerShell handles JSON serialization  
✅ **Maintainability**: Add/remove columns without touching HTML/JavaScript  
✅ **Consistency**: Headers and visibility menu auto-sync  
✅ **Flexibility**: Easy to customize per report if needed  

## Future Enhancements

Potential improvements:
- Accept `$ColumnMetadata` as a parameter to `ConvertTo-InstallFinderHtml`
- Support column-specific CSS classes via metadata
- Add column grouping/categorization
- Support custom formatters per column type
- Add column width hints

## Testing

To test column changes:

```powershell
# Dot-source the function
. .\Private\ConvertTo-InstallFinderHtml.ps1

# Create test data
$TestData = Find-InstalledApplication "TestApp*" | Select-Object -First 1

# Generate HTML
$Html = $TestData | ConvertTo-InstallFinderHtml -Title "Test Report"

# Save and view
$Html | Out-File "$env:TEMP\test.html"
Start-Process "$env:TEMP\test.html"
```
