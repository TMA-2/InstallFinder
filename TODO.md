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

## Find-InstalledApplication
- [ ] Add confirmation dialog integration when -Confirm and -Display are both used (possibly MessageBox)
- [ ] Add calculated Size property based on InstallLocation when EstimatedSize is missing *only for local search*, unless parallel processing has been implemented
  - [ ] Use a fast directory size calculator
- [ ] Integrate icon display in HTML using the **ExportIcon** module, *only for local search*
- [ ] Integrate a local MSI source field using *Convert-UUIDSquished* from **GUIDEx**
- [ ] Better handling of uninstall strings with complex argument structures (e.g., Edge with multiple flags)
- [ ] Add filtering after initial search for version ranges (currently done during query)
- [x] Improve InstallDate parsing for edge cases

## Start-Uninstall
- [ ] Add support for different uninstall modes (Silent, Passive, Attended/Normal) as parameter set *only if running locally*
- [ ] Improve error reporting with more detailed exit code explanations, possibly using the ErrorEx module
- [ ] Add retry logic for failed uninstalls

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
