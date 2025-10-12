BeforeAll {
    # Import the module
    $ModulePath = Split-Path -Parent $PSScriptRoot
    Import-Module "$ModulePath\InstallFinder.psd1" -Force
}

Describe 'InstallFinder Module' {
    Context 'Module Import' {
        It 'Should import the module successfully' {
            $Module = Get-Module -Name InstallFinder
            $Module | Should -Not -BeNullOrEmpty
        }

        It 'Should have the correct module version' {
            $Module = Get-Module -Name InstallFinder
            $Module.Version | Should -BeOfType [System.Version]
        }

        It 'Should export the expected functions' {
            $Module = Get-Module -Name InstallFinder
            $Module.ExportedFunctions.Keys | Should -Contain 'Find-InstalledApplication'
            $Module.ExportedFunctions.Keys | Should -Contain 'Start-Uninstall'
        }

        It 'Should export the Find-Install alias' {
            $Module = Get-Module -Name InstallFinder
            $Module.ExportedAliases.Keys | Should -Contain 'Find-Install'
        }

        It 'Should have module-scoped regex variables' {
            # These should be accessible to module functions
            $Module = Get-Module -Name InstallFinder
            $Module | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Module Manifest' {
        It 'Should have a valid manifest file' {
            $ManifestPath = Join-Path $ModulePath 'InstallFinder.psd1'
            Test-Path $ManifestPath | Should -Be $true
        }

        It 'Should have valid manifest data' {
            $ManifestPath = Join-Path $ModulePath 'InstallFinder.psd1'
            { Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should specify minimum PowerShell version 5.1' {
            $ManifestPath = Join-Path $ModulePath 'InstallFinder.psd1'
            $Manifest = Test-ModuleManifest -Path $ManifestPath
            $Manifest.PowerShellVersion | Should -Be '5.1'
        }
    }

    Context 'Module Structure' {
        It 'Should have Public folder' {
            Test-Path (Join-Path $ModulePath 'Public') | Should -Be $true
        }

        It 'Should have Private folder' {
            Test-Path (Join-Path $ModulePath 'Private') | Should -Be $true
        }

        It 'Should have Test folder' {
            Test-Path (Join-Path $ModulePath 'Test') | Should -Be $true
        }

        It 'Should have README.md' {
            Test-Path (Join-Path $ModulePath 'README.md') | Should -Be $true
        }

        It 'Should have CHANGELOG.md' {
            Test-Path (Join-Path $ModulePath 'CHANGELOG.md') | Should -Be $true
        }

        It 'Should have LICENSE file' {
            Test-Path (Join-Path $ModulePath 'LICENSE') | Should -Be $true
        }
    }

    Context 'Private Functions' {
        It 'Should not export private functions' {
            $Module = Get-Module -Name InstallFinder
            $Module.ExportedFunctions.Keys | Should -Not -Contain 'Show-SaveDialog'
            $Module.ExportedFunctions.Keys | Should -Not -Contain 'Write-CMLog'
            $Module.ExportedFunctions.Keys | Should -Not -Contain 'Convert-UninstallCommand'
            $Module.ExportedFunctions.Keys | Should -Not -Contain 'Write-VerboseAndLog'
        }
    }
}
