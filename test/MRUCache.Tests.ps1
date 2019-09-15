[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
$SuppressImportModule = $true
. $PSScriptRoot\Shared.ps1

Describe 'New-PSCache works with MRU Policy' {
    It 'Returns a PSObjectCache object' {
        (New-PSCache -ScriptBlock {

        } -EvictionPolicy MRU).GetType().FullName |Should Be MRUCache
    }

    It 'Evicts Most-Recently Used entries' {
        $MRUCache = New-PSCache { return $_ } -EvictionPolicy MRU -Capacity 3
        1..4 |ForEach-Object {
            [void]$MRUCache.Get($_)
        }

        # One over capacity, cache should evict 3 (most recently promoted before 4)
        $MRUCache.Entries.First.Value.Key |Should Be 4
        $MRUCache.LookupTable.ContainsKey(3) |Should Be $false
    }
}