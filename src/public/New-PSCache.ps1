function New-PSCache {
    [CmdletBinding(DefaultParameterSetName = 'PSObject')]
    param (        
        [Alias('Fetcher')]
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({$_.Ast.ParamBlock.Parameters.Count -in 0..1})]
        [scriptblock]
        $ScriptBlock,

        [Parameter(ParameterSetName = 'Max')]
        [ValidateSet('LRU','MRU','LFU','SLRU')]
        [string]
        $EvictionPolicy,

        [Parameter(ParameterSetName = 'Max')]
        [Alias('MaximumSize')]
        [ValidateRange(2,2147483647)]
        [int]
        $Capacity = 1000
    )

    $AST = $ScriptBlock.Ast

    if($AST.ParamBlock.Parameters.Count -eq 0){ 
        $VariableExpressions = $AST.FindAll({
            param($SubAST)
            $SubAST -is [System.Management.Automation.Language.VariableExpressionAst]
        },$false)

        if($VariableExpressions.Where({$_.VariablePath.UserPath -in @('_','psitem')})){
            $ScriptBlock = [scriptblock]::Create($($ScriptBlock -replace "^$([regex]::Escape($AST.ParamBlock.Extent))",'param([Alias("PsItem")]$$_)'))
        }
    }

    if($PSCmdlet.ParameterSetName -eq 'Max'){
        if($EvictionPolicy -eq 'LRU'){
            $cacheType = [LRUCache]
        }
        if($EvictionPolicy -eq 'MRU'){
            $cacheType = [MRUCache]
        }
        if($EvictionPolicy -eq 'LFU'){
            $cacheType = [LFUCache]
        }
        if($EvictionPolicy -eq 'SLRU'){
            $cacheType = [SLRUCache]
        }

        return $cacheType::new($ScriptBlock, $Capacity)
    }
    return [PSObjectCache]::new($ScriptBlock)
}
