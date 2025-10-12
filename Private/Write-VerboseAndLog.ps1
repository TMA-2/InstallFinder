function Write-VerboseAndLog {
    <#
    .SYNOPSIS
        Writes messages to both verbose stream and CM log file.

    .DESCRIPTION
        Helper function that conditionally outputs to Write-Verbose and/or CMLogs module's Write-CMLog
        based on preferences and the -Silent switch. Requires the CMLogs module to be available.

    .PARAMETER Message
        The message(s) to write.

    .PARAMETER Scope
        The PSCallStack level to pass to Write-CMLog. Defaults to 2.

    .PARAMETER Silent
        If specified, suppresses verbose output but still logs to file if logging is enabled.

    .EXAMPLE
        Write-VerboseAndLog "Processing item 1"

        Writes to verbose stream and log file if logging is enabled.

    .EXAMPLE
        Write-VerboseAndLog "Background operation" -Silent

        Only writes to log file, suppresses verbose output.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]
        $Message,

        [int]
        $Scope = 2,

        [Alias('q', 's', 'quiet')]
        [switch]
        $Silent
    )

    $CombinedMessage = $Message -join ''

    if (-not $Silent) {
        Write-Verbose $CombinedMessage
    }

    if ($script:Log) {
        # Use CMLogs module if available
        if (Get-Command Write-CMLog -ErrorAction SilentlyContinue) {
            Write-CMLog -Message $CombinedMessage -Scope $Scope
        }
        else {
            Write-Warning "CMLogs module not available. Install it for CM-formatted logging support."
        }
    }
}
