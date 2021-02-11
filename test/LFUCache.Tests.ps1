[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
$SuppressImportModule = $false
. $PSScriptRoot\Shared.ps1

Describe 'New-PSCache works with LRU Policy' {
    It 'Returns a PSObjectCache object' {
        (New-PSCache -ScriptBlock {

        } -EvictionPolicy LFU).GetType().FullName |Should -Be LFUCache
    }

    It 'Evicts Least-Frequently Used entries' {
        $LFUCache = New-PSCache { return $_ } -EvictionPolicy LFU -Capacity 3
        1,1,1,2,3,4,5 |ForEach-Object {
            [void]$LFUCache.Get($_)
        }

        # Two over capacity, cache should evict 2, then 3 (least recently promoted among the least frequently hit (2,3,4))
        $EntryKeys = $LFUCache.LookupTable.get_Values().Value.Key  |Sort-Object 
        $EntryKeys[0] |Should -Be 1
        $EntryKeys[1] |Should -Be 4
        $EntryKeys[2] |Should -Be 5
        $LFUCache.LookupTable.ContainsKey(2) |Should -BeFalse
        $LFUCache.LookupTable.ContainsKey(3) |Should -BeFalse
    }
}