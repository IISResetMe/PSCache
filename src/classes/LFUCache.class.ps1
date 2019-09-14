using namespace System.Collections.Generic

class LFUCacheEntry
{
    [object]$Key
    [object]$Item

    [int]$Hits

    LFUCacheEntry($key,$item)
    {
        $this.Key = $key
        $this.Item = $item
    }

    LFUCacheEntry($key,$item,$hits)
    {
        $this.Key = $key
        $this.Item = $item
        $this.Hits = $hits
    }

    Hit()
    {
        $this.Hits++
    }

    Tick()
    {
        if($this.Hits -gt 0){
            $this.Hits--
        }
    }
}

class LFUCache : PSObjectCache
{
    hidden [IDictionary[int,LinkedList[LFUCacheEntry]]]
    $FrequencyTable

    hidden [int]
    $gc

    [int]$Capacity
    [int]$MinHits

    LFUCache([scriptblock]$Fetcher,[int]$Capacity) : base($Fetcher)
    {
        $this.Capacity = $Capacity
        $this.FrequencyTable = [Dictionary[int,LinkedList[LFUCacheEntry]]]::new($Capacity)
    }

    hidden [void]
    Promote([LinkedListNode[LFUCacheEntry]]$Node)
    {
        $hitCount = $Node.Value.Hits
        $hitList = $this.FrequencyTable[$hitCount]
        $hitList.Remove($Node)
        if($hitList.Count -lt 1){
            [void]$this.FrequencyTable.Remove($hitCount)
            if($hitCount -eq $this.MinHits){
                $hitCount++
            }
        }
        $Node.Value.Hit()
        $newHitCount = $Node.Value.Hits
        if(-not $this.FrequencyTable.ContainsKey($newHitCount)){
            $this.FrequencyTable[$newHitCount] = [LinkedList[LFUCacheEntry]]::new()
        }
        [void]$this.FrequencyTable[$newHitCount].AddFirst($Node.Value)
    }

    [psobject]
    Get($Key){
        if($this.LookupTable.Contains($Key)){
            $CacheEntry = $this.LookupTable[$Key]
            $CacheEntry.Value.Hit()
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

            $this.Add($key,$copy)

            return $copy
        }
    }

    [void]
    Add($key, $val) {
        if($this.LookupTable.Contains($key)){
            $this.LookupTable[$key].Value = $val
            $this.Promote($this.LookupTable[$key])
        }
        else{
            while($this.LookupTable.Count -ge $this.Capacity){
                $hitList = $this.FrequencyTable[$this.MinHits]
                $lfuNode = $hitList.RemoveLast()
                if($hitList.Count -lt 1){
                    $this.FrequencyTable.Remove($this.MinHits)
                }
                $this.LookupTable.Remove($lfuNode.Value.Key)
            }

            $newEntry = [LFUCacheEntry]::new($key, $val)
            $newEntry.Hit()
            if(-not $this.FrequencyTable.ContainsKey($newEntry.Hits)){
                $this.FrequencyTable[$newEntry.Hits] = [LinkedList[LFUCacheEntry]]::new()
            }
            $newNode = $this.FrequencyTable[$newEntry.Hits].AddFirst($newEntry)
            $this.LookupTable[$key] = $newNode
        }
    }
}