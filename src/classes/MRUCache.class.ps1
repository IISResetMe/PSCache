using namespace System.Collections.Generic

class MRUCacheEntry
{
    [object]$Key
    [object]$Item

    MRUCacheEntry($key,$item)
    {
        $this.Key = $key
        $this.Item = $item
    }
}

class MRUCache : PSObjectCache
{
    hidden [LinkedList[MRUCacheEntry]]
    $Entries

    hidden [System.Collections.IDictionary]
    $LookupTable

    [int]$Capacity

    MRUCache([scriptblock]$Fetcher,[int]$Capacity) : base($Fetcher)
    {
        $this.Capacity = $Capacity
        $this.Entries = [LinkedList[MRUCacheEntry]]::new()
    }

    hidden [void]
    Promote([LinkedListNode[MRUCacheEntry]]$Node)
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
                $this.LookupTable.Remove($this.Entries.First.Value.Key)
                $this.Entries.RemoveFirst()
            }

            $this.LookupTable[$Key] = $this.Entries.AddFirst([MRUCacheEntry]::new($key,$copy))

            return $copy
        }
    }
}
