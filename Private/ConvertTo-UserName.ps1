using namespace System.Security.Principal
using namespace System.Reflection

function ConvertTo-UserName {
    <#
    .SYNOPSIS
    Given a SID, returns the corresponding username.
    .DESCRIPTION
    This function takes a user SID as input and returns the corresponding username. It uses the .NET SecurityIdentifier and NTAccount classes to perform the translation.
    .PARAMETER UserSID
    The Security Identifier (SID) of the user to be translated into a username.
    .EXAMPLE
    PS C:\> ConvertTo-UserName -UserSID 'S-1-5-21-1234567890-1234567890-1234567890-1001'

    Output: 'doejohn'
    .EXAMPLE
    PS C:\> 'S-1-5-21-1234567890-1234567890-1234567890-1001' | ConvertTo-UserName

    Output: 'doejohn'
    .LINK
    ConvertTo-UserSID
    #>
    [OutputType([string])]
    [Alias('Convert-SIDToUserName','sid2user')]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string]
        $UserSID
    )

    process {
        try {
            $SecurityID = [SecurityIdentifier]::new($UserSID)
            $UserName = $SecurityID.Translate([NTAccount]).Value
        } catch {
            $Err = $_
            throw "Exception $($Err.Exception.HResult) translating $UserSID to name > $($Err.Exception.Message)"
        }

        return $UserName
    }
} # ConvertTo-UserName
