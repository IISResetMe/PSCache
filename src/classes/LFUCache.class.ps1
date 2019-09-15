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
        $this.Hits = 1
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
        $list = $this.FrequencyTable[$Node.Value.Hits]
        $list.Remove($Node)
        if($list.Count -lt 1){
            $this.FrequencyTable.Remove($Node.Value.Hits)
        }

        if($this.MinHits -eq $Node.Value.Hits){
            $this.MinHits++
        }

        $Node.Value.Hit()
        if(-not $this.FrequencyTable.ContainsKey($Node.Value.Hits)){
            $this.FrequencyTable[$Node.Value.Hits] = [LinkedList[LFUCacheEntry]]::new()
        }

        $this.FrequencyTable[$Node.Value.Hits].AddFirst($Node)
    }

    [psobject]
    Get($Key){
        if($this.LookupTable.Contains($Key)){
            $this.Promote($this.LookupTable[$Key])
            return $this.LookupTable[$Key].Value.Item
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
        }
        else{
            while($this.LookupTable.Count -ge $this.Capacity){
                $hitList = $this.FrequencyTable[$this.MinHits]
                $lfuNode = $hitList.Last
                $hitList.RemoveLast()
                if($hitList.Count -lt 1){
                    $this.FrequencyTable.Remove($this.MinHits)
                }
                $this.LookupTable.Remove($lfuNode.Value.Key)
            }

            $newEntry = [LFUCacheEntry]::new($key, $val)
            $this.MinHits = $newEntry.Hits
            if(-not $this.FrequencyTable.ContainsKey($newEntry.Hits)){
                $this.FrequencyTable[$newEntry.Hits] = [LinkedList[LFUCacheEntry]]::new()
            }
            $newNode = $this.FrequencyTable[$newEntry.Hits].AddFirst($newEntry)
            $this.LookupTable[$key] = $newNode
        }
    }
}