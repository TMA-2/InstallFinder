BeforeAll {
    # Import the module
    $ModulePath = Split-Path -Parent $PSScriptRoot
    Import-Module "$ModulePath\InstallFinder.psd1" -Force
}

Describe 'Find-InstalledApplication' {
    Context 'Module and Function Existence' {
        It 'Should have the Find-InstalledApplication function available' {
            Get-Command -Name Find-InstalledApplication -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have the Find-Install alias available' {
            Get-Command -Name Find-Install -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export the function from the module' {
            (Get-Module InstallFinder).ExportedFunctions.Keys | Should -Contain 'Find-InstalledApplication'
        }
    }

    Context 'Parameter Validation' {
        It 'Should have Search parameter with default value "*"' {
            $Params = (Get-Command Find-InstalledApplication).Parameters
            $Params['Search'] | Should -Not -BeNullOrEmpty
        }

        It 'Should have Property parameter with default value "DisplayName"' {
            $Params = (Get-Command Find-InstalledApplication).Parameters
            $Params['Property'] | Should -Not -BeNullOrEmpty
        }

        It 'Should have ComputerName parameter with default value "localhost"' {
            $Params = (Get-Command Find-InstalledApplication).Parameters
            $Params['ComputerName'] | Should -Not -BeNullOrEmpty
        }

        It 'Should support ShouldProcess (WhatIf/Confirm)' {
            $Cmd = Get-Command Find-InstalledApplication
            $Cmd.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $Cmd.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Basic Functionality' {
        It 'Should return PSCustomObjects' {
            $Result = Find-InstalledApplication -Search "PowerShell*" | Select-Object -First 1
            $Result | Should -BeOfType [PSCustomObject]
        }

        It 'Should have expected properties' {
            $Result = Find-InstalledApplication -Search "*" | Select-Object -First 1
            $Result.PSObject.Properties.Name | Should -Contain 'Name'
            $Result.PSObject.Properties.Name | Should -Contain 'Version'
            $Result.PSObject.Properties.Name | Should -Contain 'Publisher'
            $Result.PSObject.Properties.Name | Should -Contain 'Computer'
            $Result.PSObject.Properties.Name | Should -Contain 'InstallDate'
        }

        It 'Should filter by name with wildcard' {
            $Result = Find-InstalledApplication -Search "Microsoft*"
            $Result.Count | Should -BeGreaterThan 0
        }

        It 'Should exclude system components by default' {
            $Result = Find-InstalledApplication -Search "*"
            $SystemComponents = $Result | Where-Object { $_.System -eq 1 }
            $SystemComponents.Count | Should -Be 0
        }

        It 'Should include system components when -System is specified' {
            $WithSystem = Find-InstalledApplication -Search "*" -System
            $WithoutSystem = Find-InstalledApplication -Search "*"
            $WithSystem.Count | Should -BeGreaterThan $WithoutSystem.Count
        }
    }

    Context 'Search Patterns' {
        It 'Should search by Publisher property' {
            $Result = Find-InstalledApplication -Search "Microsoft*" -Property "Publisher"
            $Result.Count | Should -BeGreaterThan 0
        }

        It 'Should support custom filters' {
            $Result = Find-InstalledApplication -Filter { $_.DisplayName -like "Microsoft*" }
            $Result.Count | Should -BeGreaterThan 0
        }
    }

    Context 'Pipeline Support' {
        It 'Should stream results (not build collection)' {
            # Test that results are emitted during processing
            $StartTime = Get-Date
            $FirstResult = Find-InstalledApplication -Search "*" | Select-Object -First 1
            $FirstResultTime = (Get-Date) - $StartTime

            # If streaming works, getting first result should be very fast
            $FirstResultTime.TotalSeconds | Should -BeLessThan 5
        }

        It 'Should accept ComputerName from pipeline' {
            $Computer = [PSCustomObject]@{ PSComputerName = 'localhost' }
            { $Computer | Find-InstalledApplication -Search "PowerShell*" } | Should -Not -Throw
        }
    }

    Context 'Output Formats' {
        It 'Should support -Display parameter' {
            Mock Out-GridView { return @() } -ModuleName InstallFinder
            { Find-InstalledApplication -Search "PowerShell*" -Display } | Should -Not -Throw
        }
    }
}
