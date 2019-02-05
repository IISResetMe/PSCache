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
