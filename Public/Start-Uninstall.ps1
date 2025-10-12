function Start-Uninstall {
    <#
    .SYNOPSIS
        Executes an uninstall command locally or on remote computers.

    .DESCRIPTION
        Starts an uninstall process either by providing a full uninstall string or by
        specifying the path and arguments separately. Supports both local and remote execution
        via Invoke-Command. Returns the exit code of the uninstall process.

    .PARAMETER Uninstall
        The full uninstall string to execute (e.g., "msiexec /x {GUID} /qn").
        This parameter is used with the 'Full' parameter set.

    .PARAMETER Path
        The executable path to run for the uninstall (e.g., "msiexec.exe" or "C:\path\to\uninstaller.exe").
        This parameter is used with the 'Args' parameter set.

    .PARAMETER Arguments
        The arguments to pass to the executable specified in the Path parameter.
        This parameter is used with the 'Args' parameter set.

    .PARAMETER ComputerName
        The name of the computer on which to run the uninstall. Defaults to the local computer.

    .EXAMPLE
        Start-Uninstall -Uninstall 'msiexec /x {12345678-1234-1234-1234-123456789012} /qn'

        Runs the MSI uninstall string on the local computer.

    .EXAMPLE
        Start-Uninstall -Path 'msiexec' -Arguments '/x','{GUID}','/qn' -ComputerName 'SERVER01'

        Runs msiexec with the specified arguments on SERVER01.

    .EXAMPLE
        $App | Start-Uninstall -Verbose

        Pipes an application object with UninstallCmd and UninstallArg properties to start the uninstall.

    .OUTPUTS
        System.Int32
        Returns the exit code of the uninstall process. Returns 0 if successful.

    .NOTES
        Requires WinRM to be configured for remote execution.
        Supports ShouldProcess for -WhatIf and -Confirm.
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Full",
        SupportsShouldProcess
    )]
    param(
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Full",
            HelpMessage = "The (full) uninstall strings to run."
        )]
        [Alias("UninstallQuiet")]
        [string]
        $Uninstall,

        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Args",
            HelpMessage = "The process to run."
        )]
        [object]
        $Path,

        [Parameter(
            Position = 1,
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Args",
            HelpMessage = "The arguments to pass to the command."
        )]
        [string[]]
        $Arguments,

        [Parameter(
            Position = 2,
            ValueFromPipeline,
            HelpMessage = "Hostname to run uninstall on."
        )]
        [Alias('Computer', 'Comp', 'Hostname')]
        [string]
        $ComputerName = $env:COMPUTERNAME
    )

    process {
        $ParameterSet = $PSCmdlet.ParameterSetName
        $IsLocal = $ComputerName -eq $env:COMPUTERNAME

        try {
            $Process = @{
                HasExited = $true
                ExitCode = 0
            }

            switch ($ParameterSet) {
                'Full' {
                    $Uninstall = "/C", $Uninstall
                    $ProcessBlock = { Start-Process -FilePath $env:ComSpec -ArgumentList $Using:Uninstall -Wait -PassThru }

                    Write-Verbose "Starting $env:ComSpec /C on $ComputerName to run $($ProcessBlock.ToString())"

                    if ($IsLocal) {
                        if ($PSCmdlet.ShouldProcess("$env:ComSpec $Uninstall", "Start-Process")) {
                            $Process = Start-Process -FilePath $env:ComSpec -ArgumentList $Uninstall -Wait -PassThru
                        }
                    }
                    else {
                        if ($PSCmdlet.ShouldProcess($ProcessBlock.ToString(), "Invoke-Command")) {
                            $Process = Invoke-Command -ScriptBlock $ProcessBlock -ComputerName $ComputerName
                        }
                    }
                }
                'Args' {
                    $ProcessBlock = { Start-Process -FilePath $Using:Path -ArgumentList $Using:Arguments -Wait -PassThru }

                    Write-Verbose "Starting $Path, $Arguments on $ComputerName"

                    if ($IsLocal) {
                        if ($PSCmdlet.ShouldProcess("$Path $Arguments", "Start-Process")) {
                            $Process = Start-Process -FilePath $Path -ArgumentList $Arguments -Wait -PassThru
                        }
                    }
                    else {
                        if ($PSCmdlet.ShouldProcess($ProcessBlock.ToString(), "Invoke-Command")) {
                            $Process = Invoke-Command -ScriptBlock $ProcessBlock -ComputerName $ComputerName
                        }
                    }
                }
            }
        }
        catch {
            $Err = $_
            Write-Error "Error $($Err.Exception.HResult) starting process > $($Err.Exception.Message)"
            Write-Output -1
            return
        }

        if ($Process.HasExited) {
            Write-Output $Process.ExitCode
        }
        else {
            Write-Output $Process
        }
    }
}
