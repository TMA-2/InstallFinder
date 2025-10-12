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
        $Applications = [System.Collections.Generic.List[PSCustomObject]]::new()
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
        
        $Template = Get-Content $TemplatePath -Raw
        
        # Prepare replacement values
        $DefaultTheme = if ($DarkMode) { 'dark' } else { 'light' }
        $GeneratedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $TotalCount = $Applications.Count
        $X64Count = ($Applications | Where-Object InstallArch -eq 'x64' | Measure-Object).Count
        $X86Count = ($Applications | Where-Object InstallArch -eq 'x86' | Measure-Object).Count
        
        # Build table rows
        $TableRows = foreach ($App in $Applications) {
            @"
                <tr>
                    <td>$($App.Computer)</td>
                    <td>$($App.Name)</td>
                    <td>$($App.Version)</td>
                    <td>$($App.Publisher)</td>
                    <td>$($App.InstallDate)</td>
                    <td>$($App.GUID)</td>
                    <td class="size-cell">$($App.Size)</td>
                    <td>$($App.InstallArch)</td>
                    <td class="path-cell">$($App.Location)</td>
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
            Replace('{{TABLE_ROWS}}', $TableRowsHtml)
        
        return $HtmlContent
    }
}
