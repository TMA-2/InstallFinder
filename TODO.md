# TODO

## General
- [ ] Add support for searching all user hives (not just current logged-on user)
- [ ] Add AppX package search support
- [ ] Implement version targeting improvements (better range comparisons)
- [ ] Add support for parallel job processing for faster remote queries
- [x] Replace Write-CMLog with CMLogs module dependency
- [x] Add custom Types.ps1xml and Format.ps1xml for better default display
- [x] Improve HTML report output with dark/light mode and sortable tables

## Find-InstalledApplication
- [ ] Add confirmation dialog integration when -Confirm and -Display are both used (possibly MessageBox)
- [ ] Improve InstallDate parsing for edge cases
- [ ] Add calculated Size property based on InstallLocation when EstimatedSize is missing
- [ ] Better handling of uninstall strings with complex argument structures (e.g., Edge with multiple flags)
- [ ] Add filtering after initial search for version ranges (currently done during query)

## Start-Uninstall
- [ ] Add support for different uninstall modes (Silent, Passive, Attended/Normal) as parameter set
- [ ] Improve error reporting with more detailed exit code explanations
- [ ] Add retry logic for failed uninstalls

## Testing
- [ ] Add integration tests for remote computer scenarios
- [ ] Add mock tests for registry queries
- [ ] Add tests for all output format types

## Documentation
- [ ] Generate PlatyPS markdown documentation
- [ ] Create MAML help files for Get-Help support
- [ ] Add more usage examples to README
- [ ] Document common exit codes and their meanings
