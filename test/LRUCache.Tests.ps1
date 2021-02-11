[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
$SuppressImportModule = $false
. $PSScriptRoot\Shared.ps1

Describe 'New-PSCache works with LRU Policy' {
    It 'Returns a PSObjectCache object' {
        (New-PSCache -ScriptBlock {

        } -EvictionPolicy LRU).GetType().FullName |Should -Be LRUCache
    }

    It 'Evicts Least-Recently Used entries' {
        $LRUCache = New-PSCache { return $_ } -EvictionPolicy LRU -Capacity 3
        1..4 |ForEach-Object {
            [void]$LRUCache.Get($_)
        }

        # One over capacity, cache should evict 1 (least recently promoted)
        $LRUCache.Entries.First.Value.Key |Should -Be 4
        $LRUCache.LookupTable.ContainsKey(1) |Should -BeFalse
    }
}