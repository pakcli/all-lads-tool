<#
.SYNOPSIS
    CSV to YAML Frontmatter Transformation Adapter
.DESCRIPTION
    Converts tabular CSV rows into clean Obsidian Markdown notes with YAML frontmatter.
    Single-responsibility adapter for CSV -> Frontmatter.
#>

function ConvertFrom-CoordinateString {
    param([string]$Text)
    $result = [ordered]@{}
    foreach ($part in ($Text -split '\|')) {
        $idx = $part.IndexOf(':')
        if ($idx -lt 1) { continue }
        $result[$part.Substring(0, $idx).Trim()] = $part.Substring($idx + 1).Trim()
    }
    return $result
}

function ConvertTo-YamlScalar {
    param([string]$Value)
    $v = $Value.Replace('\', '/')
    if ($v -match ': |#|[{}]') { return '"' + $v.Replace('"', "'") + '"' }
    return $v
}

function ConvertTo-FrontmatterBlock {
    param([Parameter(Mandatory)]$Row)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('---')
    foreach ($prop in $Row.PSObject.Properties) {
        $key = $prop.Name
        $val = ([string]$prop.Value).Trim().Trim('"')
        if ([string]::IsNullOrWhiteSpace($val)) { continue }

        if ($val.Contains(':') -and $val.Contains('|') -and -not $val.Contains('[[')) {
            [void]$sb.AppendLine("${key}:")
            $coords = ConvertFrom-CoordinateString -Text $val
            foreach ($k in $coords.Keys) { [void]$sb.AppendLine("  ${k}: $($coords[$k])") }
        }
        elseif ($val.Contains('|')) {
            [void]$sb.AppendLine("${key}:")
            foreach ($item in ($val -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
                if ($item.StartsWith('[[') -and $item.EndsWith(']]')) { [void]$sb.AppendLine("  - `"$item`"") }
                else { [void]$sb.AppendLine("  - $(ConvertTo-YamlScalar $item)") }
            }
        }
        else {
            [void]$sb.AppendLine("${key}: $(ConvertTo-YamlScalar $val)")
        }
    }
    [void]$sb.AppendLine('---')
    return $sb.ToString()
}

function Export-CsvToMarkdownFiles {
    param(
        [Parameter(Mandatory)][string]$CsvPath,
        [Parameter(Mandatory)][string]$OutputDir,
        [string]$NameColumn
    )
    if (-not (Test-Path -LiteralPath $CsvPath -PathType Leaf)) { throw "CSV not found: $CsvPath" }
    if (-not (Test-Path -LiteralPath $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

    $rows = @(Import-Csv -LiteralPath $CsvPath -Encoding UTF8)
    if ($rows.Count -eq 0) { Write-Warning 'CSV has no data rows.'; return 0 }
    if (-not $NameColumn) { $NameColumn = $rows[0].PSObject.Properties[0].Name }

    $invalid = [System.IO.Path]::GetInvalidFileNameChars()
    $count = 0
    foreach ($row in $rows) {
        $name = ([string]$row.$NameColumn).Trim()
        if (-not $name) { $name = 'row-' + ($count + 1) }
        foreach ($c in $invalid) { $name = $name.Replace([string]$c, '-') }
        $target = Join-Path $OutputDir "$name.md"
        [System.IO.File]::WriteAllText($target, (ConvertTo-FrontmatterBlock -Row $row), (New-Object System.Text.UTF8Encoding $false))
        $count++
    }
    return $count
}

Export-ModuleMember -Function ConvertFrom-CoordinateString, ConvertTo-YamlScalar, ConvertTo-FrontmatterBlock, Export-CsvToMarkdownFiles
