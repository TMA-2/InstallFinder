@{
    RootModule        = 'InstallFinder.psm1'
    ModuleVersion     = '0.5.5'
    GUID              = '7f3e8c9a-4b2d-4e5f-9a1c-3d7e8f9a2b4c'
    Author            = 'Jon Dunham'
    CompanyName       = 'TMA-2'
    Copyright         = '(c) 2025 TMA-2. All rights reserved.'
    Description       = 'PowerShell module for finding and managing installed applications via registry search with support for remote computers and uninstallation.'
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{
            ModuleName    = 'GUIDEx'
            ModuleVersion = '2.6.2'
        }
        # @{
        #     ModuleName    = 'WinResources'
        #     ModuleVersion = '0.10.15'
        # }
    )

    # Recommended modules for enhanced logging functionality
    # Note: CMLogs module is optional but recommended for CM-formatted log file support
    # If not available, logging will still work but without CM log formatting

    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @('InstallFinder.Types.ps1xml')

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @('InstallFinder.Format.ps1xml')

    # Functions to export from this module
    FunctionsToExport = @(
        'Find-InstalledApplication',
        'Start-Uninstall'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @(
        'Find-Install'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData       = @{
        PSData = @{
            Tags         = @('Inventory', 'Software', 'Uninstall', 'Registry')
            # LicenseUri   = 'https://github.com/tma-2/installfinder/blob/main/LICENSE'
            # ProjectUri   = 'https://github.com/tma-2/installfinder'
            ReleaseNotes = 'See CHANGELOG.md'
        }
    }
}
