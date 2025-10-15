# Changelog

All notable changes to the InstallFinder module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2025-10-14

### Fixed
- Corrected the ambiguous Remove parameter set so -Filter works properly
- Added a try/catch around InstallDate verification to catch stupid things like Discord's "2023 43 06" 
- HTML column sort and search

## [0.2.0] - 2025-10-12

### Added
- Column visibility dropdown menu in HTML reports
- Show/hide individual table columns with checkboxes
- "All" button to show all columns
- "Reset" button to restore default column visibility
- Required columns (Computer, Name) cannot be hidden
- Column visibility preferences saved in browser LocalStorage
- Responsive controls layout with flex-wrap for mobile
- Template-driven column management with dynamic metadata injection
- Column customization documentation in `Notes/COLUMN_CUSTOMIZATION.md`

### Changed
- Refactored `ConvertTo-InstallFinderHtml` to use external template file
- Moved HTML/CSS/JS content from embedded string to `Resources/ReportTemplate.html`
- Implemented simple `{{PLACEHOLDER}}` replacement pattern for template values
- Reduced `ConvertTo-InstallFinderHtml.ps1` from ~500 lines to ~50 lines
- Updated controls layout to accommodate column visibility dropdown
- Implemented template-driven approach for column definitions (single source of truth)
- Column metadata now defined in PowerShell and injected as JSON into HTML template
- Table headers dynamically generated from column metadata
- JavaScript column definitions now populated from PowerShell metadata

### Fixed
- Column visibility controls now work for all 16 columns (previously only 9 were functional)
- Column indices properly synchronized between table headers, data cells, and JavaScript

## [0.1.0] - 2025-10-11

### Added
- Initial release of InstallFinder module
- `Find-InstalledApplication` function for searching installed applications via registry
- `Start-Uninstall` function for running uninstall commands locally or remotely
- Support for remote computer queries
- Multiple output formats (GridView, CSV, JSON, XML, HTML)
- Automatic parsing of uninstall strings for silent execution
- Alias `Find-Install` for backward compatibility
- Custom type definition with PSTypeName 'InstallFinder.Application'
- Default display property set showing Computer, Name, Version, Publisher
- Custom table format for clean output display
- Custom list format showing Computer, Name, Version, Publisher, GUID, and UninstallString
- Interactive HTML reports with dark/light mode toggle (dark mode by default)
- Sortable HTML table columns with visual indicators
- Real-time search filtering in HTML reports
- Responsive HTML design for mobile and desktop viewing
- Application statistics dashboard in HTML reports

### Changed
- Refactored from monolithic script to proper PowerShell module structure
- Improved pipeline support to emit objects as they are processed
- Separated helper functions into Private folder
- Updated logging to use CMLogs module instead of custom Write-CMLog function

[Unreleased]: https://github.com/tma-2/powershell-modules/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/tma-2/powershell-modules/releases/tag/v0.1.0
