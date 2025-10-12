function Show-SaveDialog {
    <#
    .SYNOPSIS
        Displays a Windows Forms save file dialog.

    .DESCRIPTION
        Creates and displays a save file dialog with customizable file type filters.
        Returns the selected file path.

    .PARAMETER InitialDirectory
        The initial directory to display in the dialog. Defaults to the user's Desktop.

    .PARAMETER FileType
        One or more file extensions to filter by (without the dot). Defaults to all files (*).

    .EXAMPLE
        Show-SaveDialog -FileType 'csv','tsv'

        Displays a save dialog filtered to CSV and TSV files.

    .OUTPUTS
        System.String
        Returns the full path of the selected file, or empty string if canceled.
    #>
    [CmdletBinding()]
    param (
        [string]
        $InitialDirectory = "$env:USERPROFILE\Desktop",

        [string[]]
        $FileType = "*"
    )

    begin {
        [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

        # Construct filetype filter
        if ($PSBoundParameters.ContainsKey('FileType')) {
            $Extensions = $FileType -replace '(.+)', '$1 file (*.$1)|*.$1' -join '|'
        }
        else {
            $Extensions = "All Files (*.*)|*.*"
        }
    }

    process {
        $SaveFileDialog = [System.Windows.Forms.SaveFileDialog]::new()
        $SaveFileDialog.initialDirectory = $InitialDirectory
        $SaveFileDialog.Filter = $Extensions
        $SaveFileDialog.ShowDialog() | Out-Null

        Write-Verbose "Selected file: $($SaveFileDialog.FileName)"

        return $SaveFileDialog.FileName
    }

    end {
        $SaveFileDialog.Dispose()
        [gc]::Collect()
    }
}
