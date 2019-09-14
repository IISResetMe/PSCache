[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
$SuppressImportModule = $true
. $PSScriptRoot\Shared.ps1

Describe 'New-PSCache works with MRU Policy' {
    It 'Returns a PSObjectCache object' {
        (New-PSCache -ScriptBlock {

        } -EvictionPolicy MRU).GetType().FullName |Should Be MRUCache
    }

    It 'Evicts Most-Recently Used entries' {
        $LRUCache = New-PSCache { return $_ } -EvictionPolicy MRU -Capacity 3
        1..4 |ForEach-Object {
            [void]$LRUCache.Get($_)
        }

        # One over capacity, cache should evict 3 (most recently promoted before 4)
        $LRUCache.Entries.First.Value.Key |Should Be 4
        $LRUCache.LookupTable.ContainsKey(3) |Should Be $false
    }
}