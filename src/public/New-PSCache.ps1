function New-PSCache {
    [CmdletBinding()]
    param (        
        [Alias('Fetcher')]
        [Parameter(Mandatory)]
        [ValidateScript({$_.Ast.ParamBlock.Parameters.Count -in 0..1})]
        [scriptblock]$ScriptBlock
    )

    $AST = $ScriptBlock.Ast

    if($AST.ParamBlock.Parameters.Count -eq 0){ 
        $VariableExpressions = $AST.FindAll({
            param($SubAST)
            $SubAST -is [System.Management.Automation.Language.VariableExpressionAst]
        },$false)

        if($VariableExpressions.Where({$_.VariablePath.UserPath -eq '_'})){
            $ScriptBlock = [scriptblock]::Create($($ScriptBlock -replace "^$([regex]::Escape($AST.ParamBlock.Extent))",'param([Alias("PsItem")]$$_)'))
        }
    }

    return [PSObjectCache]::new($ScriptBlock)
}