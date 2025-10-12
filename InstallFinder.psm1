#Requires -Version 5.1

# Module-scoped regex patterns for parsing uninstall strings
$script:RegexMsiexec = '^(?<path>msiexec(?:\.exe)?) (?<args>(?:/[a-z]+ ?)*) ?(?<guid>{[0-9A-F-]+})$'
$script:RegexPackageCache = '^"?(?<path>C:\\ProgramData\\Package Cache\\(?<guid>{[0-9A-F-]+}.*)\\(?<file>[^\\]+\.\w+))"? *(?<args>(?:[-/]*.+)*)$'
$script:RegexUninstall = '^"?(?<path>[a-z]:\\[\w\\ \.\-(){}]+\\(?<file>[^\\]+\.exe))"? *(?<args>(?:[-/]*.+)*)'
$script:ScriptUninstall = '^(?<path>[wcj]script(\.exe)?) (?<file>.+\.(?:vbs|js)) (?<args>.+)'

# Module-scoped registry paths for uninstall key search
$script:RegLMUninstall = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$script:RegLMUninstall32 = "HKLM:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$script:RegCUUninstall = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$script:RegCUUninstall32 = "HKCU:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

# Get public and private function definition files
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($Import in @($Public + $Private)) {
    try {
        . $Import.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName -Alias 'Find-Install'
