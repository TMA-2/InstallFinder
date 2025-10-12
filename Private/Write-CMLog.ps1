function Write-CMLog {
    <#
    .SYNOPSIS
        Writes log entries in Configuration Manager log format.

    .DESCRIPTION
        Creates log entries compatible with Configuration Manager's CMTrace log viewer.
        Automatically includes timestamp, component, context, thread ID, and source file information.

    .PARAMETER Text
        The main log message(s) to record.

    .PARAMETER Level
        The PSCallStack level to log. 2 = calling function/script, 1 = current function, 0 = this function.
        Defaults to 2.

    .PARAMETER Component
        The component name to log. Defaults to the process name and script filename.

    .PARAMETER Type
        The log type: 1 = Info, 2 = Warning, 3 = Error. Defaults to 1 (Info).

    .PARAMETER LogPath
        The full path to the log file. If not specified, uses the module's default log path.

    .EXAMPLE
        Write-CMLog -Text "Starting installation process"

        Writes an info message to the log.

    .EXAMPLE
        Write-CMLog -Text "Failed to connect" -Type 3

        Writes an error message to the log.

    .NOTES
        Log format matches Configuration Manager's CMTrace format for easy viewing.
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline,
            HelpMessage = "Main log message(s) to record."
        )]
        [object[]]
        $Text,

        [Parameter(
            HelpMessage = "PSCallStack level to log. 2 = calling function/script, 1 = current function, 0 = ?"
        )]
        [int]
        $Level = 2,

        [string]
        $Component = (Get-Process -Id $PID).ProcessName + "\" + (Split-Path $PSCommandPath -Leaf),

        [ValidateRange(1, 3)]
        [int]
        $Type = 1,

        [string]
        $LogPath
    )

    process {
        # Get call stack information
        $CallStack = Get-PSCallStack
        if ($CallStack.Count -gt $Level) {
            $CallerInfo = $CallStack[$Level]
            $File = ($CallerInfo.Location -replace ': line ', ':')
            $Context = $CallerInfo.Command
        }
        else {
            $File = "Unknown"
            $Context = "Unknown"
        }

        # Determine log path
        if (-not $LogPath) {
            if ($script:LogFile) {
                $LogPath = $script:LogFile
            }
            else {
                # Fallback to temp directory
                $Date = Get-Date -Format "yyyyMMdd"
                $LogPath = "$env:TEMP\InstallFinder-$Date.log"
            }
        }

        # Build log entry
        $LogStart = "<![LOG["
        $LogEnd = "]LOG]!>"

        # Set up properties
        $LogTime = (Get-Date -DisplayHint Time -Format "HH:mm:ss.fff+") + (-(Get-TimeZone).BaseUtcOffset.TotalMinutes)
        $LogDate = Get-Date -DisplayHint Date -Format "MM-dd-yyyy"

        # Build first section
        $LogText = $LogStart + $Text + $LogEnd

        # Append remaining properties
        $LogText += '<time="{0}" date="{1}" component="{2}" context="{3}" type="{4}" thread="{5}" file="{6}">' -f `
            $LogTime, $LogDate, $Component, $Context, $Type, $PID, $File

        # Append line to file
        $LogText | Out-File -FilePath $LogPath -Append -Encoding utf8
    }
}
