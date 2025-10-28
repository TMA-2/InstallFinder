# TODO

## General
- [ ] Add AppX package search support
- [ ] Implement version targeting improvements (better range comparisons)
- [ ] Add support for parallel job processing for faster remote queries
- [x] Add support for searching all user hives (not just current logged-on user)
- [x] Replace Write-CMLog with CMLogs module dependency
- [x] Add custom Types.ps1xml and Format.ps1xml for better default display
- [x] Improve HTML report output with dark/light mode and sortable tables

## Ideas
- [ ] Add PODE web server and convert HTML report to a live application
- [ ] ...Try PSU integration?

## Functions

### Find-InstalledApplication
- [x] Un-qualify Path (PSPath) to a regular local registry key
- [x] Add `-OutputPath` parameter to specify where to save files
- [ ] Refactor to start a single session/runspace per machine to pass commands to
- [ ] Add parallel processing of multiple devices (runspaces?)
- [ ] Fix duplicate HKCU\HKU entries
- [ ] Integrate `WinResources\Get-RemoteRegistry` to query registry keys
- [ ] Use automatic property selection via TypeData or changing the output to an actual class.
- [ ] Add confirmation dialog integration when `-Confirm` and `-Display` are both used (possibly MessageBox)
- [ ] Integrate calculated Size property based on InstallLocation when EstimatedSize is missing *only for local search*, unless parallel processing has been implemented
  - [ ] Use a fast directory size calculator like `WinResources\Measure-PathSize`
- [ ] Integrate `Get-ApplicationType` on uninstall command *only for non-MSI local search*
- [ ] Integrate icon display in HTML using the **ExportIcon** module, *only for local search*
- [x] Integrate a local MSI source field using *Convert-UUIDSquished* from **GUIDEx**
- [ ] Better handling of uninstall strings with complex argument structures (e.g., Edge with multiple flags)
- [ ] (?) Add filtering after initial search for version ranges (currently done during query)
- [x] Improve InstallDate parsing for edge cases

### Start-Uninstall
- [ ] Add support for different uninstall modes (Silent, Passive, Attended/Normal) as parameter set *only if running locally*
- [ ] Improve error reporting with more detailed exit code explanations, possibly using the ErrorEx module
- [ ] Add retry logic for failed uninstalls

### ConvertTo-InstallFinderHtml
- [x] Add MSI count card

### ReportTemplate.html
- [ ] Add MSI and MSICache columns
- [ ] Fix live-update InstallArch x64, x32, and MSI counts on filter

## Testing
- [ ] Add integration tests for remote computer scenarios
- [ ] Add mock tests for registry queries
- [ ] Add mock tests for `Find-InstalledApplication -Remove`
- [ ] Add tests for all output format types

## Documentation
- [ ] Generate PlatyPS markdown documentation
- [ ] Create MAML help files for Get-Help support
- [ ] Add more usage examples to README
- [ ] Document common exit codes and their meanings
