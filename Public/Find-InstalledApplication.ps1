function Find-InstalledApplication {
    <#
    .SYNOPSIS
        Finds installed applications from the registry and optionally tries to uninstall and/or output to multiple file types.

    .DESCRIPTION
        Searches Uninstall keys in HKLM and the currently logged-on user registry, returning multiple useful properties,
        as well as parsed Uninstall and QuietUninstall strings. By default it searches the DisplayName field using a
        simple wildcard match, excluding SystemComponents, but can match with RegEx if specified.

        Results are streamed to the pipeline as they are discovered for efficient processing.

    .PARAMETER Search
        One or more application names to search for. Supports wildcards. Defaults to "*" (all applications).

    .PARAMETER Property
        The property to search against. Defaults to 'DisplayName'. Other options include Publisher, InstallLocation, etc.

    .PARAMETER RegEx
        Use regex pattern matching instead of wildcard matching for the search.

    .PARAMETER MinimumVersion
        Filter to only include applications with a version greater than or equal to this value.

    .PARAMETER MaximumVersion
        Filter to only include applications with a version less than or equal to this value.

    .PARAMETER Filter
        (Advanced) Manually specify a conditional script block for filtering,
        e.g. {$_.InstallDate -match '2024'} or {$_.Publisher -like 'Microsoft*'}

    .PARAMETER System
        Include items marked as system components. These are excluded by default.

    .PARAMETER ComputerName
        One or more computer names to search. Defaults to 'localhost'.

    .PARAMETER Display
        Display the results in a gridview or export to a file format.

    .PARAMETER Output
        Specifies the output format when -Display is used. Options: Gridview, Table, HTML, CSV, Excel, CLIXML, XML, JSON.
        Defaults to 'Gridview'.

    .PARAMETER IncludeAppX
        (EXPERIMENTAL) Include AppX packages in the search. Not yet implemented.

    .PARAMETER Uninstall
        (EXPERIMENTAL) Run uninstall on the found applications. Use with caution.

    .PARAMETER Silent
        When used with -Uninstall, attempts to run uninstalls silently without user interaction.

    .PARAMETER Log
        Log results to a Configuration Manager-formatted log file.

    .EXAMPLE
        Find-InstalledApplication "VMware Horizon*"

        Finds all installed applications with names starting with "VMware Horizon".

    .EXAMPLE
        Find-InstalledApplication "VMware*" -System -Display

        Finds VMware applications including system components and displays results in a grid view.

    .EXAMPLE
        Find-InstalledApplication -Filter {$_.InstallDate -match '2024(0[2-8])'} -Display

        Finds all applications installed between February and August 2024.

    .EXAMPLE
        Find-InstalledApplication "VMware*" -Property "Publisher"

        Searches for "VMware*" in the Publisher field instead of DisplayName.

    .EXAMPLE
        Find-InstalledApplication "OldApp*" -ComputerName SERVER01,SERVER02 -Uninstall -Silent

        Finds and silently uninstalls applications matching "OldApp*" on remote servers.

    .OUTPUTS
        PSCustomObject with the following properties:
        - Computer: Target host name
        - Name: DisplayName
        - Version: DisplayVersion (as System.Version object)
        - InstallDate: InstallDate (as datetime)
        - GUID: Key Name (registry key name)
        - InstallArch: x64 | x86 (based on registry path)
        - AppArch: x64 | x86 (based on install location)
        - Publisher: Publisher name
        - Location: InstallLocation
        - Source: InstallSource
        - Size: EstimatedSize (in MB)
        - UninstallCmd: Parsed command
        - UninstallArg: Parsed arguments
        - Uninstall: Original UninstallString
        - QuietUninstall: Modified silent uninstall string
        - Modify: ModifyPath
        - Repair: RepairPath
        - System: SystemComponent flag
        - Path: Full registry key path
        - User: Logged-on username
        - Hive: Registry hive name
        - ExitCode: Uninstall exit code (if -Uninstall was used)

    .NOTES
        Author: Texas Health Resources - End User Computing
        Searching the registry is significantly faster (~100ms) compared to Get-Package or Win32_Product.

    .LINK
        Start-Uninstall
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Search",
        SupportsShouldProcess
    )]
    [Alias('Find-Install')]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ParameterSetName = "Search",
            HelpMessage = "Enter software name(s) to find."
        )]
        [Parameter(
            Position = 0,
            ParameterSetName = "Remove"
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("Name", "DisplayName")]
        [String[]]
        $Search = "*",

        [Parameter(
            Position = 2,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Search",
            HelpMessage = "Specify the property to search."
        )]
        [Parameter(
            Position = 1,
            ParameterSetName = "Remove"
        )]
        [string]
        $Property = 'DisplayName',

        [Parameter(
            ParameterSetName = "Search",
            HelpMessage = "Use regex filter instead of wildcard."
        )]
        [switch]
        $RegEx,

        [Parameter(
            ParameterSetName = "Search"
        )]
        [string]
        $MinimumVersion,

        [Parameter(
            ParameterSetName = "Search"
        )]
        [string]
        $MaximumVersion,

        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ParameterSetName = "Filter",
            HelpMessage = "(Advanced) Manually specify a conditional script block, e.g. {`$_.Property -eq 'Value'}"
        )]
        [Parameter(
            ParameterSetName = "Remove"
        )]
        [object]
        $Filter,

        [Parameter(
            HelpMessage = "Include items marked as system components. Excluded by default."
        )]
        [Switch]
        $System,

        [Parameter(
            Position = 3,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Enter hostname(s) to run the cmdlet against."
        )]
        [Alias("PSComputerName", "Hostname")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ComputerName = 'localhost',

        [Parameter(
            HelpMessage = "Display the results in a gridview."
        )]
        [switch]
        $Display,

        [Parameter(
            ParameterSetName = 'Search'
        )]
        [ValidateSet('Gridview', 'Table', 'HTML', 'CSV', 'Excel', 'CLIXML', 'XML', 'JSON')]
        [string]
        $Output = 'Gridview',

        [Parameter(
            ParameterSetName = "Search",
            DontShow,
            HelpMessage = "(EXPERIMENTAL) Specifies whether to include AppX."
        )]
        [Parameter(
            ParameterSetName = "Remove"
        )]
        [Alias('appx')]
        [switch]
        $IncludeAppX,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Remove',
            HelpMessage = "(EXPERIMENTAL) Run uninstall on the results."
        )]
        [Parameter(
            ParameterSetName = "Search"
        )]
        [switch]
        $Uninstall,

        [Parameter(
            ParameterSetName = 'Remove',
            HelpMessage = "Run uninstalls silently."
        )]
        [Parameter(
            ParameterSetName = 'Search'
        )]
        [Alias("Quiet", "s", "q")]
        [switch]
        $Silent,

        [Parameter(
            HelpMessage = "Log results to a CM-formatted log."
        )]
        [switch]
        $Log
    )

    begin {
        # Set module-level logging flag
        $script:Log = $Log

        # Initialize variables
        $Date = Get-Date -Format "yyyyMMdd" -DisplayHint Date
        $IllegalCharsRE = '[<>:"\/\\|?*]'
        $SearchCleaned = $Search -replace $IllegalCharsRE, '' -join ';'

        # Log output path
        $script:LogFile = "$env:TEMP\FindInstall-$Date-$SearchCleaned.log"

        $ParamSet = $PSCmdlet.ParameterSetName

        Write-VerboseAndLog -Message "> Searching $($ComputerName -join ', ') for $($Search -join ', ')"

        # Check online status
        Write-VerboseAndLog -Message "Checking online status for $($ComputerName.count) machines" -Silent

        $OnlineStatus = @(Test-Connection $ComputerName -Count 1 -ErrorAction SilentlyContinue)

        # Filter successful results by PS version
        if ($PSVersionTable.PSEdition -eq 'Core') {
            $OnlineStatus = $OnlineStatus | Where-Object Status -eq "Success" | Select-Object -ExpandProperty Destination
        }
        else {
            $OnlineStatus = $OnlineStatus | Where-Object StatusCode -eq 0 | Select-Object -ExpandProperty Address
        }

        # If no machines were contactable
        if ($OnlineStatus.count -eq 0) {
            Write-Warning "Couldn't contact any given hostnames."
            return
        }

        Write-VerboseAndLog -Message "$($OnlineStatus.Count)/$($ComputerName.Count) machines online: $($OnlineStatus -join ', ')"

        # Registry uninstall paths to search
        $RegKeys = @(
            $script:RegLMUninstall,
            $script:RegLMUninstall32,
            $script:RegCUUninstall,
            $script:RegCUUninstall32
        )

        # Default filter for system components
        $SystemFilter = { $_.SystemComponent -ne 1 }

        # Build search filter based on parameter set
        switch ($ParamSet) {
            'Search' {
                # Build base search string
                if (-not $System) {
                    $SearchBase = "`$null -ne `$_.DisplayName -and $SystemFilter -and "
                }
                else {
                    $SearchBase = "`$null -ne `$_.DisplayName -and "
                }

                # Add version filtering if specified
                if ($MinimumVersion -and $MaximumVersion) {
                    $SearchBase += "[version]'$MinimumVersion' -le [version]`$_.DisplayVersion -and [version]'$MaximumVersion' -ge [version]`$_.DisplayVersion -and ("
                }
                elseif ($MinimumVersion -and -not $MaximumVersion) {
                    $SearchBase += "[version]'$MinimumVersion' -le [version]`$_.DisplayVersion -and ("
                }
                elseif (-not $MinimumVersion -and $MaximumVersion) {
                    $SearchBase += "[version]'$MaximumVersion' -ge [version]`$_.DisplayVersion -and ("
                }
                else {
                    $SearchBase += "("
                }

                # Set search operator
                $SearchOperator = if ($RegEx) { '-match' } else { '-like' }

                # Build search string
                if ($PSVersionTable.PSEdition -eq 'Core') {
                    $SearchString = $Search | Join-String -Separator ' -or ' -OutputPrefix $SearchBase -OutputSuffix ')' -FormatString "`$_.$Property $SearchOperator '{0}'"
                }
                else {
                    $SearchString = $SearchBase + (($Search | ForEach-Object { "`$_.$Property $SearchOperator '$_'" }) -join ' -or ') + ")"
                }

                $SearchFilter = [scriptblock]::Create($SearchString)
                Write-VerboseAndLog -Message "Search: Created search filter $SearchString from terms: $($Search -join ', ')"
            }
            'Filter' {
                if (-not $System) {
                    $SearchFilter = [scriptblock]::Create("$Filter -and $SystemFilter")
                }
                else {
                    $SearchFilter = [scriptblock]::Create($Filter)
                }
                Write-VerboseAndLog -Message "FILTER: Created search filter: $SearchFilter from $Filter"
            }
        }

        # Collection for display/output processing (only when needed)
        if ($Display -or $Uninstall) {
            $ResultCollection = [System.Collections.Generic.List[PSCustomObject]]::new()
        }
    }

    process {
        Write-VerboseAndLog -Message "Searching machines for $SearchCleaned using filter: $($SearchFilter.ToString())..."

        try {
            # Get logged-on user SID for HKEY_USERS search
            $UserSID = Get-CimInstance -ClassName Win32_UserProfile -Filter 'NOT LocalPath LIKE "%pickyprocess" AND Loaded = True AND Special = False' -ComputerName $OnlineStatus -ErrorAction SilentlyContinue | Select-Object LocalPath, SID

            if ($UserSID) {
                $Username = $UserSID.LocalPath.Split('\')[-1]
                Write-VerboseAndLog -Message "Found user SIDs for $Username"

                # Add HKU keys to reg search collection
                $RegKeys += "Microsoft.PowerShell.Core\Registry::HKEY_USERS\$($UserSID[0].SID)\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "Microsoft.PowerShell.Core\Registry::HKEY_USERS\$($UserSID[0].SID)\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
            }

            # Execute registry search
            if ($ComputerName -match "(localhost|$env:COMPUTERNAME|\.)") {
                $Result = @(Invoke-Command -ScriptBlock { Get-ItemProperty -Path $RegKeys -ErrorAction SilentlyContinue } | Where-Object -FilterScript $SearchFilter)
            }
            else {
                $Result = @(Invoke-Command -ComputerName $OnlineStatus { Get-ItemProperty -Path $Using:RegKeys -ErrorAction SilentlyContinue } | Where-Object -FilterScript $SearchFilter)
            }
        }
        catch {
            $Err = $_
            Write-Error "Error $($Err.Exception.HResult) invoking command on machines: $($Err.Exception.Message)"
            return
        }

        # No results
        if ($Result.Count -eq 0) {
            Write-VerboseAndLog -Message "No results for $Search"
            return
        }
        else {
            Write-VerboseAndLog -Message "Found $($Result.count) results for $Search"
        }

        # Process each result and emit to pipeline
        foreach ($Item in $Result) {
            # Format InstallDate
            if ($Item.InstallDate) {
                try {
                    if ($Item.InstallDate.Contains('/')) {
                        $FormattedDate = $Item.InstallDate -replace '^(\d{4})/(\d{2})/(\d{2})$', '$2 $3 $1'
                    }
                    else {
                        $FormattedDate = $Item.InstallDate -replace '^(\d{4})(\d{2})(\d{2})$', '$2 $3 $1'
                    }
                    $InstallDate = Get-Date $FormattedDate -Format 'yyyy/MM/dd' -ErrorAction Stop
                }
                catch {
                    Write-VerboseAndLog "Error parsing InstallDate $($Item.InstallDate) for $($Item.DisplayName)" -Silent
                }
            }
            else {
                $InstallDate = "N/A"
            }

            # Format Version
            if ($Item.DisplayVersion -match '^[\d\.]+$') {
                $Version = [Version]::Parse($Item.DisplayVersion)
            }
            else {
                $Version = $Item.DisplayVersion
            }

            # Format uninstall strings
            $UninstallStr = if ($Item.QuietUninstallString) {
                Write-VerboseAndLog -Message "QuietUninstallString found:", $Item.QuietUninstallString -Silent
                [PSCustomObject]@{
                    Cmd  = $Item.QuietUninstallString -replace '^(.+\.exe"?) ?(.*)','$1'
                    Args = ($Item.QuietUninstallString -split '\.exe"? ')[1]
                    Full = $Item.QuietUninstallString
                }
            }
            else {
                switch -Regex ($Item.UninstallString) {
                    # MSIExec
                    $script:RegexMsiexec {
                        Write-VerboseAndLog -Message "MSI uninstall found: ", $Item.UninstallString -Silent
                        [PSCustomObject]@{
                            Cmd  = "msiexec"
                            Args = $Item.UninstallString -replace $script:RegexMsiexec, '/qn /norestart /x "${guid}"'
                            Full = $Item.UninstallString -replace $script:RegexMsiexec, 'msiexec /qn /norestart /x "${guid}"'
                        }
                        break
                    }
                    # Package Cache
                    $script:RegexPackageCache {
                        Write-VerboseAndLog -Message "Package Cache uninstall found: ", $Item.UninstallString -Silent
                        Convert-UninstallCommand -String $Item.UninstallString -Pattern $script:RegexPackageCache -Find '([-/]*)(modify|uninstall)' -Replace '$1uninstall $1quiet $1norestart '
                        break
                    }
                    # Script uninstall
                    $script:ScriptUninstall {
                        Write-VerboseAndLog -Message "Script uninstaller found: ", $Item.UninstallString -Silent
                        Convert-UninstallCommand -String $Item.UninstallString -Pattern $script:ScriptUninstall -Find '([-/]+)(modify|uninstall)' -Replace '$1uninstall $1quiet $1norestart '
                        break
                    }
                    # Other uninstaller
                    $script:RegexUninstall {
                        Write-VerboseAndLog -Message "Other uninstaller found:", $Item.UninstallString -Silent
                        Convert-UninstallCommand -String $Item.UninstallString -Pattern $script:RegexUninstall -Find '([-/]*)(modify|uninstall)' -Replace '$1uninstall $1quiet $1norestart '
                        break
                    }
                    Default {
                        [pscustomobject]@{
                            Cmd  = $Item.UninstallString -replace '^(.+\.exe"?) ?(.*)','$1'
                            Args = ($Item.UninstallString -split '\.exe"? ')[1]
                            Full = $Item.UninstallString
                        }
                    }
                }
            }

            # Build application object
            $AppInfo = [PSCustomObject]@{
                PSTypeName     = 'InstallFinder.Application'
                Computer       = if ($ComputerName -eq 'localhost') { $env:COMPUTERNAME } else { $Item.PSComputerName }
                Name           = $Item.DisplayName
                Version        = $Version
                InstallDate    = $InstallDate
                GUID           = $Item.PSChildName
                InstallArch    = if ($Item.PSParentPath -ilike '*\wow6432node\*') { 'x86' } else { 'x64' }
                AppArch        = if ($Item.InstallLocation -ilike '*\Program Files\*') { 'x64' } elseif ($Item.InstallLocation -ilike '*\Program Files (x86)\*') { 'x86' } else { 'Unknown' }
                Publisher      = $Item.Publisher
                Location       = $Item.InstallLocation
                Source         = $Item.InstallSource
                Size           = if ($Item.EstimatedSize) { [math]::Round($Item.EstimatedSize * 1KB / 1MB, 2) } else { 0 }
                Modify         = $Item.ModifyPath
                Repair         = $Item.RepairPath
                Uninstall      = $Item.UninstallString
                QuietUninstall = $UninstallStr.Full
                UninstallCmd   = $UninstallStr.Cmd
                UninstallArg   = $UninstallStr.Args
                System         = $Item.SystemComponent
                Path           = $Item.PSPath
                User           = $Username
                Hive           = $Item.PSDrive
                ExitCode       = $null
            }

            # If Display or Uninstall is specified, collect results; otherwise stream to pipeline
            if ($Display -or $Uninstall) {
                $ResultCollection.Add($AppInfo)
            }
            else {
                Write-Output $AppInfo
            }
        }
    }

    end {
        # Process display/output/uninstall operations
        if ($Display -or $Uninstall) {
            $Selection = $ResultCollection

            # Handle display
            if ($Display) {
                $ListComp = $OnlineStatus -join ', '
                $ListSearch = $Search -join ', '
                $DisplayTitle = "$($ResultCollection.count) reg keys found on $ListComp for $ListSearch"

                Write-VerboseAndLog -Message "Output $Output used!"
                $FilePathDefault = "$env:temp\Find-Install-$SearchCleaned"

                try {
                    switch ($Output) {
                        'Gridview' {
                            $Selection = $ResultCollection | Out-GridView -Title $DisplayTitle -OutputMode Multiple
                        }
                        'Table' {
                            $ResultCollection | Format-Table -AutoSize -GroupBy Computer
                        }
                        'HTML' {
                            $HtmlTitle = "$ListSearch on $ListComp - $($ResultCollection.count) applications found"
                            $HTMLOut = $ResultCollection | ConvertTo-InstallFinderHtml -Title $HtmlTitle -DarkMode

                            if ($Silent) {
                                $FilePath = "$FilePathDefault.$($Output.ToLower())"
                                $HTMLOut | Out-File -FilePath $FilePath -Encoding utf8
                                Write-Verbose "Wrote apps to $FilePath"
                            }
                            else {
                                $FilePath = Show-SaveDialog -FileType $Output
                                if ($FilePath) {
                                    $HTMLOut | Out-File -FilePath $FilePath -Force -Encoding utf8
                                    Write-Host "Wrote apps to $FilePath"
                                }
                            }
                        }
                        'CSV' {
                            if (-not $Silent) {
                                $FilePath = Show-SaveDialog -FileType 'tsv', 'csv'
                                $FileExt = (Split-Path $FilePath -Leaf).Split('.') | Select-Object -Last 1
                            }
                            else {
                                $FileExt = 'csv'
                                $FilePathDefault += ".$FileExt"
                            }

                            $CSVSplat = @{
                                InputObject       = $ResultCollection
                                Path              = if ($Silent) { $FilePathDefault } else { $FilePath }
                                Delimiter         = if ($FileExt -eq 'tsv') { "`t" } else { "," }
                                NoTypeInformation = $true
                            }

                            Export-Csv @CSVSplat
                        }
                        'JSON' {
                            if ($Silent) {
                                $ResultCollection | ConvertTo-Json | Out-File -FilePath "$FilePathDefault.$($Output.ToLower())"
                            }
                            else {
                                $FilePath = Show-SaveDialog -FileType $Output
                                $ResultCollection | ConvertTo-Json | Out-File -FilePath $FilePath
                            }
                        }
                        'XML' {
                            if ($Silent) {
                                $ResultCollection | ConvertTo-Xml -As Document | Out-File -FilePath "$FilePathDefault.$($Output.ToLower())"
                            }
                            else {
                                $FilePath = Show-SaveDialog -FileType $Output
                                $ResultCollection | ConvertTo-Xml -As Document | Out-File -FilePath $FilePath
                            }
                        }
                        'CLIXML' {
                            if ($Silent) {
                                $ResultCollection | Export-Clixml -Path "$FilePathDefault.$($Output.ToLower())"
                            }
                            else {
                                $FilePath = Show-SaveDialog -FileType $Output
                                $ResultCollection | Export-Clixml -Path $FilePath
                            }
                        }
                    }
                }
                catch {
                    $Err = $_
                    Write-Error "Error $($Err.Exception.HResult) writing file > $($Err.Exception.Message)"
                }
                finally {
                    if ($Output -ne 'GridView' -and $Output -ne 'Table') {
                        $Selection = $ResultCollection
                    }
                    Write-VerboseAndLog -Message "Selected $($Selection.count) apps of $($ResultCollection.Count) total from $Output display."
                }
            }

            # Handle uninstall
            if ($Selection.Count -gt 0 -and $Uninstall) {
                Write-VerboseAndLog -Message "Uninstall specified!"

                foreach ($App in $Selection) {
                    if ($PSCmdlet.ShouldProcess("$($App.Uninstall) -ComputerName $($app.Computer)", "Start-Uninstall")) {
                        if ($Silent) {
                            $App.ExitCode = Start-Uninstall -Path $App.UninstallCmd -Arguments $App.UninstallArg -ComputerName $App.Computer
                        }
                        else {
                            $App.ExitCode = Start-Uninstall -Uninstall $App.Uninstall -ComputerName $App.Computer
                        }
                        Write-VerboseAndLog -Message "Uninstall for $($App.Name) $($App.Version) on $($App.Computer): return code: $($App.ExitCode)" -Silent
                    }
                }

                $SuccessfulUninstalls = $Selection | Where-Object ExitCode -eq 0

                # Show results in gridview if used
                if ($Display -and $Output -eq 'GridView') {
                    $Selection | Out-GridView -Title "$($SuccessfulUninstalls.Count) successfully removed of $($Selection.Count) total" -OutputMode Multiple
                }
            }

            # Display file if created
            if ($Display -and $FilePath) {
                Write-VerboseAndLog -Message "Running file $FilePath"
                if ($Output -match '^((CLI)?X|HT)ML|JSON') {
                    Start-Process msedge -ArgumentList "$FilePath" -WindowStyle Normal
                }
                elseif ($Output -match 'CSV') {
                    Start-Process $FilePath
                }
            }

            # Return results
            Write-VerboseAndLog -Message "Total count: $($ResultCollection.Count). Selected count: $($Selection.Count)"
            Write-Output $Selection
        }

        # Cleanup
        [gc]::Collect()
    }
}
