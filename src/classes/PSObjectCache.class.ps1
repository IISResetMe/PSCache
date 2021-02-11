using namespace System.Collections

class PSObjectCache
{
    hidden [IDictionary]$LookupTable 
    hidden [scriptblock]$Fetcher

    PSObjectCache([scriptblock]$Fetcher){
        $this.Fetcher = $Fetcher
        $this.LookupTable = @{}
    }

    [psobject]Get($Key){
        if($this.LookupTable.Contains($Key)){
            return $this.LookupTable[$Key]
        }
        else{
            try{
                $copy = & $this.Fetcher $Key
                return ($this.LookupTable[$Key] = $copy)
            }
            catch{
                $this.LookupTable.Remove($Key)
                throw $_
            }
            return $null
        }
    }

    [void]AddOrUpdate($Key,$Item){
        $this.LookupTable[$Key] = $Item
    }
    
    [void]Remove($Key){
        $this.LookupTable.Remove($Key)
    }

    [void]Remove([scriptblock]$KeyPredicate){
        foreach($key in $this.LookupTable.Keys.Where($KeyPredicate)){
            $this.Remove($key)
        }
    }
    
    [void]Clear(){
        $this.LookupTable.Clear()
    }
}

class ExpiringCacheEntry
{
    [object]$Item

    [datetime]$EOL

    ExpiringCacheEntry($item, [timespan]$expireAfter)
    {
        $this.Item = $item
        $this.EOL = [datetime]::UtcNow.Add($expireAfter)
    }
}

class ExpiringCache : PSObjectCache
{
    [timespan]$MaxAge

    ExpiringCache([scriptblock]$Fetcher, [timespan]$ExpireAfter)
        : base($Fetcher)
    {
        $this.MaxAge = $ExpireAfter
    }

    [psobject]
    Get($Key)
    {
        if($this.LookupTable.Contains($Key)){
            $existingItem = $this.LookupTable[$Key]
            if($existingItem.EOL -gt [datetime]::UtcNow){
                return $this.LookupTable[$Key].Item
            }
        }
        else {
        }

        try{
            $copy = & $this.Fetcher $Key
        }
        catch{
            throw $_
            return $null
        }

        $this.AddOrUpdate($Key, [ExpiringCacheEntry]::new($copy,$this.MaxAge))

        return $copy
    }
}