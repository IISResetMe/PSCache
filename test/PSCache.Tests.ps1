[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
$SuppressImportModule = $false
. $PSScriptRoot\Shared.ps1

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        $ModuleManifestName = 'PSCache.psd1'
        $ModuleManifestPath = "$PSScriptRoot\..\src\$ModuleManifestName"
        Test-ModuleManifest -Path $ModuleManifestPath
        $? | Should -BeTrue
    }
}

Describe 'New-PSCache works' {
    It 'Returns a PSObjectCache object' {
        (New-PSCache -ScriptBlock {

        }).GetType().FullName |Should -Be PSObjectCache
    }

    It 'Accepts fetchers with 1 parameter' {
        {
            New-PSCache -ScriptBlock {
                param($a)
            }
        } |Should -Not -Throw
    } 

    It 'Rejects fetchers with multiple params' {
        {
            New-PSCache -ScriptBlock {
                param($a,$b)
            }
        } |Should -Throw
    }

    It 'Supports $_' {
        $MirrorCache = New-PSCache -ScriptBlock {
            return $_
        }
        $MirrorCache.Get(1) |Should -Be 1
    }
}

Describe 'New-PSCache supports timed expiration' {
    It 'Evicts after expiration elapses' {
        $ExpiringCache = New-PSCache -ScriptBlock {
            return Get-Date
        } -ExpireAfter (New-TimeSpan -Seconds 5)

        $first = $ExpiringCache.Get(1)
        $second = $ExpiringCache.Get(1)

        $first -eq $second |Should -BeTrue

        Start-Sleep -Seconds 5
        $third = $ExpiringCache.Get(1)
        $second -eq $third |Should -BeFalse
    }
}