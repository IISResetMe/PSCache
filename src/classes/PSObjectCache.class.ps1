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
            return ($this.LookupTable[$Key] = try{& $this.Fetcher $Key}catch{$null})
        }
    }
    
    [void]Remove(){
        $this.LookupTable.Remove()
    }
    
    [void]Clear(){
        $this.LookupTable.Clear()
    }
}
