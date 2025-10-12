function Convert-UninstallCommand {
    <#
    .SYNOPSIS
        Converts an uninstall string to a silent/quiet version with parsed components.

    .DESCRIPTION
        Parses various types of uninstall commands and converts them to silent execution mode.
        Handles MSI, Package Cache, script-based, and standard executable uninstallers.

    .PARAMETER String
        The original uninstall command string to parse and convert.

    .PARAMETER Pattern
        The regex pattern to use for parsing the command.

    .PARAMETER Find
        The regex pattern to find in the arguments for replacement.

    .PARAMETER Replace
        The string to replace the found pattern with (typically silent flags).

    .EXAMPLE
        Convert-UninstallCommand -String 'msiexec /i {GUID}' -Pattern $RegexMsiexec -Find '/i' -Replace '/x /qn /norestart'

        Converts an MSI install command to a silent uninstall command.

    .OUTPUTS
        PSCustomObject with Cmd, Args, and Full properties.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $String,

        [Parameter(Mandatory)]
        [string]
        $Pattern,

        [Parameter(Mandatory)]
        [string]
        $Find,

        [Parameter(Mandatory)]
        [string]
        $Replace
    )

    $RegexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    $REMatch = [regex]::Match($String, $Pattern, $RegexOptions)

    if ($REMatch.Success) {
        # Get path
        $CmdPath = $REMatch.Groups['path'].Value

        if ($REMatch.Groups['args'].Value -match $Find) {
            # Replace modify with uninstall
            $CmdArgs = $REMatch.Groups['args'].Value -replace $Find, $Replace
        }
        else {
            # Append to args
            $CmdArgs = $REMatch.Groups['args'].Value -replace '/uninstall', "/uninstall $Replace"
        }

        $Result = [PSCustomObject]@{
            Cmd  = $CmdPath
            Args = $CmdArgs
            Full = "$CmdPath $CmdArgs"
        }

        return $Result
    }
    else {
        # Fallback parsing for unrecognized formats
        $Result = [PSCustomObject]@{
            Cmd  = "$(($String -split '.exe ')[0]).exe"
            Args = ($String -split '.exe ')[1]
            Full = $String
        }

        return $Result
    }
}
