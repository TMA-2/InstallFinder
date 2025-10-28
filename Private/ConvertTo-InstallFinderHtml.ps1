using namespace System.Collections.Generic

function ConvertTo-InstallFinderHtml {
    <#
    .SYNOPSIS
        Converts application data to a styled, interactive HTML report.

    .DESCRIPTION
        Creates an HTML report with dark/light mode toggle, sortable columns,
        and responsive design for installed application data.

    .PARAMETER Data
        Collection of application objects to convert to HTML.

    .PARAMETER Title
        The title for the HTML report. Defaults to "Installed Applications Report".

    .PARAMETER DarkMode
        If specified, the report will default to dark mode. Otherwise defaults to light mode.

    .EXAMPLE
        $Apps | ConvertTo-InstallFinderHtml -Title "VMware Applications" -DarkMode

    .OUTPUTS
        System.String
        Returns HTML content as a string.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject[]]
        $Data,

        [string]
        $Title = "Installed Applications Report",

        [switch]
        $DarkMode
    )

    begin {
        $Applications = [List[PSCustomObject]]::new()
    }

    process {
        foreach ($Item in $Data) {
            $Applications.Add($Item)
        }
    }

    end {
        # Load the HTML template
        $TemplatePath = Join-Path $PSScriptRoot '..\Resources\ReportTemplate.html'

        if (-not (Test-Path $TemplatePath)) {
            throw "HTML template not found at: $TemplatePath"
        }

        # Read template with UTF-8 encoding to preserve emojis
        $Template = Get-Content $TemplatePath -Raw -Encoding UTF8

        # Define column metadata (order matches table structure)
        $ColumnMetadata = @(
            @{ index = 0; name = 'Computer'; required = $true; property = 'Computer' }
            @{ index = 1; name = 'Name'; required = $true; property = 'Name' }
            @{ index = 2; name = 'Version'; required = $false; property = 'Version' }
            @{ index = 3; name = 'Publisher'; required = $false; property = 'Publisher' }
            @{ index = 4; name = 'Install Date'; required = $false; property = 'InstallDate' }
            @{ index = 5; name = 'Windows Installer'; required = $false; property = 'MSI' }
            @{ index = 6; name = 'GUID'; required = $false; property = 'GUID' }
            @{ index = 7; name = 'Size (MB)'; required = $false; property = 'Size' }
            @{ index = 8; name = 'Architecture (Install)'; required = $false; property = 'InstallArch' }
            @{ index = 9; name = 'Architecture (App)'; required = $false; property = 'AppArch' }
            @{ index = 10; name = 'Uninstall Cmd'; required = $false; property = 'UninstallCmd' }
            @{ index = 11; name = 'Uninstall Args'; required = $false; property = 'UninstallArg' }
            @{ index = 12; name = 'Location'; required = $false; property = 'Location' }
            @{ index = 13; name = 'Source'; required = $false; property = 'Source' }
            @{ index = 14; name = 'MSI Cache'; required = $false; property = 'MSICache' }
            @{ index = 15; name = 'Registry Path'; required = $false; property = 'Key' }
            @{ index = 16; name = 'User'; required = $false; property = 'User' }
            @{ index = 17; name = 'Hive'; required = $false; property = 'Hive' }
        )

        # Default visible columns (Computer, Name, Version, Publisher)
        $DefaultVisibleColumns = @(0, 1, 2, 3)

        # Convert metadata to JSON for injection into template
        $ColumnMetadataJson = $ColumnMetadata | ConvertTo-Json -Compress
        $DefaultVisibleColumnsJson = $DefaultVisibleColumns | ConvertTo-Json -Compress

        # Build table headers dynamically
        $TableHeaders = foreach ($Col in $ColumnMetadata) {
            "                        <th class=`"sortable`" data-column=`"$($Col.index)`">$($Col.name)</th>"
        }
        $TableHeadersHtml = $TableHeaders -join "`n"

        # Prepare replacement values
        $DefaultTheme = if ($DarkMode) { 'dark' } else { 'light' }
        $GeneratedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $TotalCount = $Applications.Count
        $X64Count = ($Applications | Where-Object InstallArch -eq 'x64' | Measure-Object).Count
        $X86Count = ($Applications | Where-Object InstallArch -eq 'x86' | Measure-Object).Count
        $MSICount = ($Applications | Where-Object MSI -eq $true | Measure-Object).Count

        # Build table rows
        $TableRows = foreach ($App in $Applications) {
            @"
                <tr>
                    <td>$($App.Computer)</td>
                    <td>$($App.Name)</td>
                    <td>$($App.Version)</td>
                    <td>$($App.Publisher)</td>
                    <td>$($App.InstallDate)</td>
                    <td>$($App.MSI)</td>
                    <td>$($App.GUID)</td>
                    <td class="size-cell">$($App.Size)</td>
                    <td>$($App.InstallArch)</td>
                    <td>$($App.AppArch)</td>
                    <td class="path-cell">$($App.UninstallCmd)</td>
                    <td>$($App.UninstallArg)</td>
                    <td class="path-cell">$($App.Location)</td>
                    <td class="path-cell">$($App.Source)</td>
                    <td class="path-cell">$($App.MSICache)</td>
                    <td class="path-cell">$($App.Key)</td>
                    <td>$($App.User)</td>
                    <td>$($App.Hive)</td>
                </tr>
"@
        }

        $TableRowsHtml = $TableRows -join "`n"

        # Replace placeholders in template
        $HtmlContent = $Template.
        Replace('{{TITLE}}', $Title).
        Replace('{{DEFAULT_THEME}}', $DefaultTheme).
        Replace('{{GENERATED_DATE}}', $GeneratedDate).
        Replace('{{TOTAL_COUNT}}', $TotalCount).
        Replace('{{VISIBLE_COUNT}}', $TotalCount).
        Replace('{{X64_COUNT}}', $X64Count).
        Replace('{{X86_COUNT}}', $X86Count).
        Replace('{{MSI_COUNT}}', $MSICount).
        Replace('{{COLUMN_METADATA}}', $ColumnMetadataJson).
        Replace('{{DEFAULT_VISIBLE_COLUMNS}}', $DefaultVisibleColumnsJson).
        Replace('{{TABLE_HEADERS}}', $TableHeadersHtml).
        Replace('{{TABLE_ROWS}}', $TableRowsHtml)

        return $HtmlContent
    }
}
