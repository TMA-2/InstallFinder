using namespace System.Security.Principal
using namespace System.Reflection

function ConvertTo-UserSID {
    <#
    .SYNOPSIS
    Given a username, returns the corresponding SID.
    .DESCRIPTION
    This function takes a username (samaccountname) as input and returns the corresponding SID. It uses the .NET NTAccount and SecurityIdentifier classes to perform the translation.
    .PARAMETER UserName
    The user name (with optional domain in domain\user or user@domain format) to be translated.
    Defaults to the current user.
    .EXAMPLE
    PS C:\> ConvertTo-UserSID -UserName 'doejohn'

    Direct cmdlet use with username only.
    Output: 'S-1-5-21-1234567890-1234567890-1234567890-1001'
    .EXAMPLE
    PS C:\> 'DOMAIN\doejohn' | ConvertTo-UserSID

    Pipeline support in domain\user format.
    Output: 'S-1-5-21-1234567890-1234567890-1234567890-1001'
    .EXAMPLE
    PS C:\> 'doejohn@DOMAIN' | ConvertTo-UserSID

    Pipeline support in user@domain format.
    Output: 'S-1-5-21-1234567890-1234567890-1234567890-1001'
    .LINK
    ConvertTo-UserName
    #>
    [OutputType([string])]
    [Alias('Convert-UserNameToSID','user2sid')]
    [CmdletBinding(PositionalBinding)]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline
        )]
        [string]
        $UserName = "$env:USERDOMAIN\$env:USERNAME"
    )
    begin {
        $REDomainUser = '^(?<domain>[^\\]+)\\(?<user>.+)$'
        $REUserDomain = '^(?<user>[^@]+)@(?<domain>.+)$'
    }
    process {
        # Convert from DOMAIN\username format
        if ($UserName -match $REDomainUser) {
            $UserName = $Matches.Item('user')
            $UserDomain = $Matches.Item('domain')
        }
        # Convert from FQDN format
        elseif ($UserName -match $REUserDomain) {
            $UserName = $Matches.Item('user')
            $UserDomain = $Matches.Item('domain')
        }

        try {
            if ($UserDomain) {
                $SecurityID = [NTAccount]::new($UserDomain, $UserName)
            }
            else {
                $SecurityID = [NTAccount]::new($UserName)
            }
            $UserSID = $SecurityID.Translate([SecurityIdentifier]).Value
        }
        catch {
            $Err = $_
            throw "Exception $($Err.Exception.HResult) translating $UserName to SID > $($Err.Exception.Message)"
        }

        return $UserSID
    }
} # ConvertTo-UserSID
