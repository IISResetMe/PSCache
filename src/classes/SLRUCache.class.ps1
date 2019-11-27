using namespace System.Collections.Generic

class SLRUCacheEntry
{
    [object]$Key
    [object]$Item

    SLRUCacheEntry($key,$item)
    {
        $this.Key = $key
        $this.Item = $item
    }
}

class SLRUCache : PSObjectCache
{
    hidden [LinkedList[SLRUCacheEntry]]
    $ProtectedEntries

    hidden [LinkedList[SLRUCacheEntry]]
    $ProbationaryEntries

    hidden [System.Collections.IDictionary]
    $LookupTable

    [int]$Capacity

    SLRUCache([scriptblock]$Fetcher,[int]$Capacity) : base($Fetcher)
    {
        $this.Capacity = $Capacity
        $this.ProtectedEntries = [LinkedList[SLRUCacheEntry]]::new()
        $this.ProbationaryEntries = [LinkedList[SLRUCacheEntry]]::new()
    }

    hidden [void]
    Protect([LinkedListNode[SLRUCacheEntry]]$Node)
    {
        # Remove from current position
        if($Node.List.Count){
            $Node.List.Remove($Node)
        }

        # Make room in protected segment
        while($this.ProtectedEntries.Count -ge $this.Capacity){
            $tmpNode = $this.ProtectedEntries.Last
            $this.ProtectedEntries.RemoveLast()
            $this.ProbationaryEntries.AddFirst($tmpNode)
        }

        # Add target node as the MRU protected entry
        $this.ProtectedEntries.AddFirst($Node)

        # Prune probationary segment
        while($this.ProbationaryEntries.Count -gt $this.Capacity){
            $evictee = $this.ProbationaryEntries.Last
            $this.LookupTable.Remove($evictee.Value.Key)
            $this.ProbationaryEntries.RemoveLast()
        }
    }

    [psobject]
    Get($Key){
        if($this.LookupTable.Contains($Key)){
            $CacheEntry = $this.LookupTable[$Key]
            $this.Protect($CacheEntry)
            return $CacheEntry.Value.Item
        }
        else{
            try{
                $copy = & $this.Fetcher $Key
            }
            catch{
                throw $_
                return $null
            }

            $this.LookupTable[$Key] = $this.ProbationaryEntries.AddFirst([SLRUCacheEntry]::new($key,$copy))
            
            while($this.ProbationaryEntries.Count -ge $this.Capacity){
                $evictee = $this.ProbationaryEntries.Last
                $this.LookupTable.Remove($evictee.Value)
                $this.ProbationaryEntries.RemoveLast()
            }

            return $copy
        }
    }
}