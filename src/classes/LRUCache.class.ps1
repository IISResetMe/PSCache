using namespace System.Collections.Generic

class LRUCacheEntry
{
    [object]$Key
    [object]$Item

    LRUCacheEntry($key,$item)
    {
        $this.Key = $key
        $this.Item = $item
    }
}

class LRUCache : PSObjectCache
{
    hidden [LinkedList[LRUCacheEntry]]
    $Entries

    hidden [System.Collections.IDictionary]
    $LookupTable

    [int]$Capacity

    LRUCache([scriptblock]$Fetcher,[int]$Capacity) : base($Fetcher)
    {
        $this.Capacity = $Capacity
        $this.Entries = [LinkedList[LRUCacheEntry]]::new()
    }

    hidden [void]
    Promote([LinkedListNode[LRUCacheEntry]]$Node)
    {
        if($Node -eq $Node.List.First){
            return
        }

        $Item = $Node.Value
        $Node.List.Remove($Node)
        $this.LookupTable[$Item.Key] = $this.Entries.AddFirst($Item)
        return
    }

    [psobject]
    Get($Key){
        if($this.LookupTable.Contains($Key)){
            $CacheEntry = $this.LookupTable[$Key]
            $this.Promote($CacheEntry)
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

            while($this.Entries.Count -ge $this.Capacity)
            {
                $this.LookupTable.Remove($this.Entries.Last.Value.Key)
                $this.Entries.RemoveLast()
            }

            $this.LookupTable[$Key] = $this.Entries.AddFirst([LRUCacheEntry]::new($key,$copy))

            return $copy
        }
    }
}