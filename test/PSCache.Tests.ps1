[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
$SuppressImportModule = $true
. $PSScriptRoot\Shared.ps1

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $ModuleManifestPath
        $? | Should Be $true
    }
}

Describe 'New-PSCache works' {
    It 'Returns a PSObjectCache object' {
        (New-PSCache -ScriptBlock {

        }).GetType().FullName |Should Be PSObjectCache
    }

    It 'Accepts fetchers with 1 parameter' {
        {
            New-PSCache -ScriptBlock {
                param($a)
            }
        } |Should Not Throw
    } 

    It 'Rejects fetchers with multiple params' {
        {
            New-PSCache -ScriptBlock {
                param($a,$b)
            }
        } |Should Throw
    }

    It 'Supports $_' {
        $MirrorCache = New-PSCache -ScriptBlock {
            return $_
        }
        $MirrorCache.Get(1) |Should Be 1
    }
}