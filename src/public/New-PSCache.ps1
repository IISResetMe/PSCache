function New-PSCache {
    [CmdletBinding(DefaultParameterSetName = 'PSObject')]
    param (        
        [Alias('Fetcher')]
        [Parameter(Mandatory)]
        [ValidateScript({$_.Ast.ParamBlock.Parameters.Count -in 0..1})]
        [scriptblock]
        $ScriptBlock,

        [Parameter(ParameterSetName = 'Max')]
        [ValidateSet('LRU')]
        [string]
        $EvictionPolicy,

        [Parameter(Mandatory = $true, ParameterSetName = 'Max')]
        [Alias('MaximumSize')]
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

    if($EvictionPolicy -eq 'LRU')
    {
        return [LRUCache]::new($ScriptBlock, $Max)
    }
    return [PSObjectCache]::new($ScriptBlock)
}
