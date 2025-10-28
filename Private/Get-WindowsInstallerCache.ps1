function Get-WindowsInstallerCache {
    <#
    .SYNOPSIS
        Retrieves the Windows Installer cache directory path from the registry.
    .DESCRIPTION
        This function accesses the Windows registry to find the path of the Windows Installer cache directory.
        The cache is used by the Windows Installer service to store installation files for applications.
    .EXAMPLE
        PS C:\> Get-WindowsInstallerCache
        Returns the path of the Windows Installer cache directory.
    .NOTES
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [guid]$GUID,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Alias('PSComputerName')]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        $InstallerBase = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products'
    }

    process {
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            throw "${FunctionName}: Cannot connect to computer: $ComputerName"
        }

        $ProductCode = Convert-UUIDSquished $GUID -Format n
        $InstallerKey = "$InstallerBase\$ProductCode\InstallProperties"

        try {
            $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName, 'Registry64')
            $RegistryKey = $Registry.OpenSubKey($InstallerKey)
            if (-not $RegistryKey) {
                throw "${FunctionName}: Installer registry key not found for product $GUID on computer $ComputerName."
            }
            $RegistryValue = $RegistryKey.GetValue('LocalPackage')
        }
        catch {
            $Err = $_
            throw "${FunctionName}: Exception $($Err.Exception.HResult) retrieving remote registry key > $($Err.Exception.Message)"
        }
        finally {
            $Registry.Close()
            if ($RegistryKey) {
                $RegistryKey.Close()
            }
        }

        # local machine case
        <# try {
            if (-not (Test-Path $InstallerKey)) {
                throw "Product with GUID $GUID not found."
            }
            $CachePath = Get-ItemPropertyValue -Path $InstallerKey -Name 'LocalPackage' -ea SilentlyContinue
        }
        catch {
            $Err = $_
            throw "Exception $($Err.Exception.HResult) getting LocalPackage from the Installer registry key > $($Err.Exception.Message)"
        } #>

        $RegistryValue
    }
}
