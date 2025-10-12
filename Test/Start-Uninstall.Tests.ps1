BeforeAll {
    # Import the module
    $ModulePath = Split-Path -Parent $PSScriptRoot
    Import-Module "$ModulePath\InstallFinder.psd1" -Force
}

Describe 'Start-Uninstall' {
    Context 'Module and Function Existence' {
        It 'Should have the Start-Uninstall function available' {
            Get-Command -Name Start-Uninstall -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export the function from the module' {
            (Get-Module InstallFinder).ExportedFunctions.Keys | Should -Contain 'Start-Uninstall'
        }
    }

    Context 'Parameter Validation' {
        It 'Should have Uninstall parameter (Full parameter set)' {
            $Params = (Get-Command Start-Uninstall).Parameters
            $Params['Uninstall'] | Should -Not -BeNullOrEmpty
        }

        It 'Should have Path and Arguments parameters (Args parameter set)' {
            $Params = (Get-Command Start-Uninstall).Parameters
            $Params['Path'] | Should -Not -BeNullOrEmpty
            $Params['Arguments'] | Should -Not -BeNullOrEmpty
        }

        It 'Should have ComputerName parameter with default value' {
            $Params = (Get-Command Start-Uninstall).Parameters
            $Params['ComputerName'] | Should -Not -BeNullOrEmpty
        }

        It 'Should support ShouldProcess (WhatIf/Confirm)' {
            $Cmd = Get-Command Start-Uninstall
            $Cmd.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $Cmd.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Return Values' {
        It 'Should return an integer exit code' {
            # Test with a simple command that exits cleanly
            $Result = Start-Uninstall -Path 'cmd.exe' -Arguments '/c', 'exit 0' -ErrorAction SilentlyContinue
            $Result | Should -BeOfType [int]
        }

        It 'Should return 0 for successful execution' {
            $Result = Start-Uninstall -Path 'cmd.exe' -Arguments '/c', 'exit 0' -ErrorAction SilentlyContinue
            $Result | Should -Be 0
        }

        It 'Should return non-zero for failed execution' {
            $Result = Start-Uninstall -Path 'cmd.exe' -Arguments '/c', 'exit 1' -ErrorAction SilentlyContinue
            $Result | Should -Not -Be 0
        }
    }

    Context 'WhatIf Support' {
        It 'Should not execute when -WhatIf is specified' {
            # This should not actually run the command
            { Start-Uninstall -Path 'cmd.exe' -Arguments '/c', 'echo test' -WhatIf } | Should -Not -Throw
        }

        It 'Should not execute Full parameter set when -WhatIf is specified' {
            { Start-Uninstall -Uninstall 'cmd.exe /c echo test' -WhatIf } | Should -Not -Throw
        }
    }

    Context 'Error Handling' {
        It 'Should handle invalid executable gracefully' {
            { Start-Uninstall -Path 'nonexistent.exe' -Arguments 'test' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Parameter Sets' {
        It 'Should accept Full parameter set with Uninstall string' {
            { Start-Uninstall -Uninstall 'cmd.exe /c exit 0' -WhatIf } | Should -Not -Throw
        }

        It 'Should accept Args parameter set with Path and Arguments' {
            { Start-Uninstall -Path 'cmd.exe' -Arguments '/c', 'exit 0' -WhatIf } | Should -Not -Throw
        }
    }

    Context 'Pipeline Support' {
        It 'Should accept Uninstall from pipeline' {
            $UninstallString = 'cmd.exe /c exit 0'
            { $UninstallString | Start-Uninstall -WhatIf } | Should -Not -Throw
        }

        It 'Should accept objects with UninstallCmd and UninstallArg properties' {
            $App = [PSCustomObject]@{
                UninstallCmd = 'cmd.exe'
                UninstallArg = '/c', 'exit 0'
            }
            { $App | Start-Uninstall -Path $App.UninstallCmd -Arguments $App.UninstallArg -WhatIf } | Should -Not -Throw
        }
    }
}
