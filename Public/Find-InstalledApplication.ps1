using namespace System.Collections.Generic
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

    .PARAMETER OutputPath
        Specifies the output path for the results specified with -Output.
        Defaults to $env:temp\Find-Install-<SearchTerm>.<OutputFormat>

    .PARAMETER IncludeAppX
        (EXPERIMENTAL) Include AppX packages in the search. Not yet implemented.

    .PARAMETER Uninstall
        (EXPERIMENTAL) Run uninstall on the found applications. Use with caution.

    .PARAMETER Silent
        When used with -Uninstall, attempts to run uninstalls silently without user interaction.
        When used with -Output, saves the output to a temporary path instead of asking.

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
        - Key: Full registry key path
        - User: Logged-on username
        - Hive: Registry hive name
        - ExitCode: Uninstall exit code (if -Uninstall was used)

    .NOTES
        Author: Jonathan Dunham
        Searching the registry is significantly faster (~100ms) compared to Get-Package or Win32_Product.

    .LINK
        Start-Uninstall
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Search",
        SupportsShouldProcess,
        ConfirmImpact = 'High'
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
        # Place inside a param() block before a parameter.
        # Help: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_argument_completion?view=powershell-5.1#argumentcompleter-attribute
        [ArgumentCompleter({
            [OutputType([CompletionResult])]
            param($CommandName,$ParameterName,$wordToComplete,$CommandAst,$fakeBoundParameters)
            # get common registry values
            $UninstallProperties = @{
                DisplayName          = 'The name of the application as shown in Programs and Features.'
                DisplayVersion       = 'The version of the application.'
                Publisher            = 'The publisher of the application.'
                InstallLocation      = 'The installation directory of the application.'
                InstallSource        = 'The source location from which the application was installed.'
                InstallDate          = 'The date the application was installed.'
                EstimatedSize        = 'The estimated size of the application in KB.'
                UninstallString      = 'The command used to uninstall the application.'
                QuietUninstallString = 'The command used to silently uninstall the application.'
                ModifyPath           = 'The command used to modify the installation.'
                RepairPath           = 'The command used to repair the installation.'
                SystemComponent      = 'Indicates if the application is a system component.'
                WindowsInstaller     = 'Indicates if the application was installed using Windows Installer (MSI).'
                URLInfoAbout         = 'URL for more information about the application.'
                URLUpdateInfo        = 'URL for updating the application.'
                HelpLink             = 'URL for help regarding the application.'
                Comments             = 'Additional comments about the application.'
                NoRemove             = 'Indicates if the application can be removed via the Programs UI (0/1).'
                NoModify             = 'Indicates if the application can be modified via the Programs UI (0/1).'
                NoRepair             = 'Indicates if the application can be repaired via the Programs UI (0/1).'
            }
            $UninstallProperties.GetEnumerator() |
                Where-Object Key -like "$wordToComplete*" |
                ForEach-Object {
                    [CompletionResult]::new($PSItem.Key, $PSItem.Key, 'ParameterValue', $PSItem.Value)
                }
        })]
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
        [scriptblock]
        $Filter,

        [Parameter(
            HelpMessage = "Include items marked as system components. Excluded by default."
        )]
        [Switch]
        $System,

        [Parameter(
            Position = 3,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Enter hostname(s) to run the cmdlet against."
        )]
        [Alias("PSComputerName", "Hostname")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ComputerName = $env:COMPUTERNAME,

        [Parameter(
            HelpMessage = "Display the results in the format specified by -Output."
        )]
        [switch]
        $Display,

        [Parameter(
            HelpMessage = "Specify the output format to write and/or display the results in."
        )]
        [ValidateSet('Gridview', 'Table', 'HTML', 'CSV', 'Excel', 'CLIXML', 'XML', 'JSON')]
        [string]
        $Output = 'Gridview',

        [Parameter(
            HelpMessage = "Specify the file path for the -Output format."
        )]
        [string]
        $OutputPath,

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
            HelpMessage = "Run uninstalls silently. Don't ask where to save files with -Output."
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
        $PSDefaultParameterValues['Get-CimInstance:Verbose'] = $false

        Write-VerboseAndLog -Message "> Searching $($ComputerName -join ', ') for $($Search -join ', ')"

        # Registry uninstall paths to search
        $RegKeys = @(
            $script:RegLMUninstall,
            $script:RegLMUninstall32,
            $script:RegCUUninstall,
            $script:RegCUUninstall32
        )

        # Collection for display/output processing (only when needed)
        if ($Display -or $Uninstall -or $OutputPath -or $PSBoundParameters.ContainsKey('Output')) {
            $ResultCollection = [List[PSObject]]::new()
        }
    }

    process {
        # Check online status
        Write-VerboseAndLog -Message "Checking online status for $($ComputerName.count) machines" -Silent

        $Ping = [System.Net.NetworkInformation.Ping]::new()
        $OnlineStatus = $ComputerName | % {
            $Reply = $Ping.Send($_, 2000)
            $Reply | Add-Member -MemberType NoteProperty -Name Name -Value $_ -PassThru
        }
        # $OnlineStatus = @(Test-Connection $ComputerName -Count 1 -TimeoutSeconds 2 -ErrorAction SilentlyContinue)
        # if ($PSVersionTable.PSEdition -eq 'Core') {
        #     $OnlineComputers = $OnlineStatus | Where-Object Status -eq "Success" | Select-Object -ExpandProperty Destination
        # }
        # else {
        #     $OnlineComputers = $OnlineStatus | Where-Object StatusCode -eq 0 | Select-Object -ExpandProperty Address
        # }

        $OnlineComputers = $OnlineStatus | Where-Object Status -EQ "Success" | Select-Object -ExpandProperty Name

        # If no machines were contactable
        if ($OnlineComputers.count -eq 0) {
            Write-Warning "Couldn't contact any given hostnames."
            return
        }
        else {
            Write-VerboseAndLog -Message "$($OnlineComputers.Count)/$($ComputerName.Count) machines online"
        }

        # SECTION: Build filter
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
                Write-Debug "Search: Created search filter $SearchString from terms: $($Search -join ', ')"
            }
            'Filter' {
                if (-not $System) {
                    $SearchFilter = [scriptblock]::Create("$Filter -and $SystemFilter")
                }
                else {
                    $SearchFilter = [scriptblock]::Create($Filter)
                }
                Write-Debug "FILTER: Created search filter: $SearchFilter from $Filter"
            }
        }

        # SECTION: create session
        <# try {
            $PSSession = New-PSSession -ComputerName $OnlineComputers -Name "InstallFinder" -ea SilentlyContinue
            if (-not $PSSession) {
                throw [PSRemotingTransportException]::new("Uncaught exception creating sessions.")
            }
        }
        catch {
            $Err = $_
            Write-Error "Exception $($Err.Exception.HResult) creating a session on $OnlineComputers > $($Err.Exception.Message)"
            continue
        } #>

        Write-VerboseAndLog -Message "Searching machines for $SearchCleaned using filter: $($SearchFilter.ToString())..."

        try {
            # Get logged-on user SID for HKEY_USERS search
            $UserSID = Get-CimInstance -ClassName Win32_UserProfile -Filter 'NOT LocalPath LIKE "%pickyprocess" AND Loaded = True AND Special = False' -ComputerName $OnlineComputers -ea SilentlyContinue

            foreach($SID in $UserSID) {
                $Username = ConvertTo-UserName -UserSID $SID.SID
                Write-VerboseAndLog -Message "Translated user SID to $Username"

                if ($SID.PSComputerName -ieq $env:COMPUTERNAME -and $Username -ieq "$env:USERDOMAIN\$env:USERNAME") {
                    Write-VerboseAndLog -Message "Skipping current user $Username for HKEY_USERS search"
                    continue
                }

                # Add HKU keys to reg search collection
                $RegKeys += "Microsoft.PowerShell.Core\Registry::HKEY_USERS\$($SID.SID)\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "Microsoft.PowerShell.Core\Registry::HKEY_USERS\$($SID.SID)\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
            }

            # Execute registry search
            if ($ComputerName.Count -eq 1 -and $ComputerName -match "(localhost|$env:COMPUTERNAME|\.)") {
                $Result = @(Invoke-Command -ScriptBlock { Get-ItemProperty -Path $RegKeys -ErrorAction SilentlyContinue } | Where-Object -FilterScript $SearchFilter) | ForEach-Object {
                    $_ | Add-Member -MemberType NoteProperty -Name User -Value $env:USERNAME
                    $_ | Add-Member -MemberType NoteProperty -Name PSComputerName -Value $ComputerName[0] -PassThru
                }
                Write-VerboseAndLog -Message "Found $($Result.Count) results on local machine."
            }
            else {
                $Result = @(Invoke-Command -ComputerName $OnlineComputers { Get-ItemProperty -Path $Using:RegKeys -ErrorAction SilentlyContinue } | Where-Object -FilterScript $SearchFilter) | % {
                    $CompName = $_.PSComputerName
                    $User = $UserSID | Where-Object {$_.PSComputerName -ieq $CompName} | % {
                        ConvertTo-UserName -UserSID $PSItem.SID
                    }
                    $_ | Add-Member -MemberType NoteProperty -Name User -Value $User -PassThru
                }
                Write-VerboseAndLog -Message "Found $($Result.Count) results on remote machines."
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
            try {
                if ($Item.DisplayVersion -match '^\d\.\d(\.\d){1,2}$') {
                    $Version = [Version]::Parse($Item.DisplayVersion)
                }
                else {
                    $Version = $Item.DisplayVersion
                }
            }
            catch {
                $Err = $_
                Write-Error "Couldn't parse version $($Item.DisplayVersion): $($Err.Exception.Message)"
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

            # if ($PSBoundParameters['ComputerName']) {
            #     $Comp = $Item.PSComputerName
            # }
            # else {
            #     $Comp = $ComputerName -as [string]
            # }

            try {
                # get windows installer cache
                $MSICache = ''
                if ($Item.WindowsInstaller -eq 1) {
                    $MSICache = Get-WindowsInstallerCache -GUID $Item.PSChildName -ComputerName $Item.PSComputerName
                }
            }
            catch {
                $Err = $_
                Write-Error "Error retrieving Windows Installer cache > $($Err.Exception.Message)"
            }

            # Build application object
            $AppInfo = [PSCustomObject]@{
                PSTypeName     = 'InstallFinder.Application'
                Computer       = $Item.PSComputerName
                Name           = $Item.DisplayName
                Version        = $Version
                InstallDate    = $InstallDate
                MSI            = if ($Item.WindowsInstaller -eq 1) { $true } else { $false }
                GUID           = $Item.PSChildName
                InstallArch    = if ($Item.PSParentPath -imatch '\\wow6432node\\') { 'x86' } else { 'x64' }
                AppArch        = if ($Item.InstallLocation -imatch '\\Program Files\\') { 'x64' } elseif ($Item.InstallLocation -imatch '\\Program Files (x86)\\') { 'x86' } else { 'Unknown' }
                Publisher      = $Item.Publisher
                Location       = $Item.InstallLocation
                Source         = $Item.InstallSource
                MSICache       = $MSICache
                Size           = if ($Item.EstimatedSize) { [math]::Round($Item.EstimatedSize * 1KB / 1MB, 2) } else { 0 }
                Modify         = $Item.ModifyPath
                Repair         = $Item.RepairPath
                Uninstall      = $Item.UninstallString
                QuietUninstall = $UninstallStr.Full
                UninstallCmd   = $UninstallStr.Cmd
                UninstallArg   = $UninstallStr.Args
                System         = if ($Item.SystemComponent -eq 1) { $true } else { $false }
                User           = $Item.User
                Key            = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Item.PSPath)
                Hive           = $Item.PSDrive
                ExitCode       = $null
            }

            # If Display or Uninstall is specified, collect results; otherwise stream to pipeline
            if ($Display -or $Uninstall -or $PSBoundParameters['Output'] -or $OutputPath) {
                [void]$ResultCollection.Add($AppInfo)
            }
            else {
                $AppInfo
            }
        }
    }

    end {
        # Process display/output/uninstall operations
        if ($Display -or $Uninstall -or $PSBoundParameters['Output'] -or $OutputPath) {
            $Selection = $ResultCollection

            # Handle display
            if ($Display -or $PSBoundParameters['Output'] -or $OutputPath) {
                $ListComp = $OnlineComputers -join ', '
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

                            if (-not $OutputPath) {
                                if ($Silent) {
                                    $OutputPath = "$FilePathDefault.$($Output.ToLower())"
                                }
                                else {
                                    $OutputPath = Show-SaveDialog -FileType $Output
                                }
                            }
                            if ($OutputPath) {
                                # Write as UTF-8 with BOM to ensure proper emoji rendering in Edge
                                [System.IO.File]::WriteAllText($OutputPath, $HTMLOut, [System.Text.UTF8Encoding]::new($true))
                                Write-Verbose "Wrote HTML report to $OutputPath"
                            }
                        }
                        'CSV' {
                            if ($OutputPath) {
                                $FileExt = (Split-Path $OutputPath -Leaf).Split('.')[-1]
                            }
                            else {
                                if ($Silent) {
                                    $FileExt = 'csv'
                                    $FilePathDefault += ".$FileExt"
                                    $OutputPath = $FilePathDefault
                                }
                                else {
                                    $OutputPath = Show-SaveDialog -FileType 'tsv', 'csv'
                                    $FileExt = (Split-Path $OutputPath -Leaf).Split('.')[-1]
                                }
                            }

                            $CSVSplat = @{
                                InputObject       = $ResultCollection
                                Path              = $OutputPath
                                Delimiter         = if ($FileExt -eq 'tsv') { "`t" } else { "," }
                                NoTypeInformation = $true
                            }

                            Export-Csv @CSVSplat
                        }
                        'JSON' {
                            if (-not $OutputPath) {
                                if ($Silent) {
                                    $OutputPath = "$FilePathDefault.$($Output.ToLower())"
                                }
                                else {
                                    $OutputPath = Show-SaveDialog -FileType $Output
                                }
                            }
                            $ResultCollection | ConvertTo-Json | Out-File -FilePath $OutputPath
                        }
                        'XML' {
                            if (-not $OutputPath) {
                                if ($Silent) {
                                    $OutputPath = "$FilePathDefault.$($Output.ToLower())"
                                }
                                else {
                                    $OutputPath = Show-SaveDialog -FileType $Output
                                }
                                $ResultCollection | ConvertTo-Xml -As Document | Out-File -FilePath $OutputPath
                            }
                        }
                        'CLIXML' {
                            if (-not $OutputPath) {
                                if ($Silent) {
                                    $OutputPath = "$FilePathDefault.$($Output.ToLower())"
                                }
                                else {
                                    $OutputPath = Show-SaveDialog -FileType $Output
                                }
                            }
                            $ResultCollection | Export-Clixml -Path $OutputPath
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
            if ($Display -and $OutputPath) {
                Write-VerboseAndLog -Message "Running file $OutputPath"
                if ($Output -match '^((CLI)?X|HT)ML|JSON') {
                    Start-Process msedge -ArgumentList "$OutputPath" -WindowStyle Normal
                }
                elseif ($Output -match 'CSV') {
                    Start-Process $OutputPath
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
