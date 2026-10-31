<#
.SYNOPSIS
    Kebab-Case String Transformation Adapter
.DESCRIPTION
    Converts arbitrary titles, spaced names, or mixed-cased strings into clean lowercase kebab-case.
#>

function ConvertTo-KebabCase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }

    # 1. Trim and lowercase
    $str = $Text.Trim().ToLowerInvariant()

    # 2. Replace invalid path characters and punctuation with hyphens
    $str = $str -replace '[\s_.,:;!?/\\|`~@#$%^&*()+=\[\]{}<>"\'''']+', '-'

    # 3. Collapse multiple consecutive hyphens
    $str = $str -replace '-{2,}', '-'

    # 4. Trim leading and trailing hyphens
    $str = $str.Trim('-')

    return $str
}

Export-ModuleMember -Function ConvertTo-KebabCase
