# Standalone interactive CSV -> YAML frontmatter converter (single file, zero dependencies).
# Asks for TARGET DIR and TARGET CSV. Implements: all-lads-tool/skill/csv-to-frontmatter-compatible-parser.md
param(
    [string]$TargetDir,
    [string]$TargetCsv
)

$ErrorActionPreference = 'Stop'

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
    <# Converts one CSV row (PSCustomObject) into a YAML frontmatter string. #>
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
    <# Writes one .md per CSV row into OutputDir. File name comes from NameColumn (default: first column). #>
    param(
        [Parameter(Mandatory)][string]$CsvPath,
        [Parameter(Mandatory)][string]$OutputDir,
        [string]$NameColumn
    )
    if (-not (Test-Path -LiteralPath $CsvPath -PathType Leaf)) { throw "CSV not found: $CsvPath" }
    if (-not (Test-Path -LiteralPath $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }

    $rows = @(Import-Csv -LiteralPath $CsvPath -Encoding UTF8)
    if ($rows.Count -eq 0) { Write-Warning 'CSV has no data rows.'; return 0 }
    if (-not $NameColumn) { $NameColumn = $rows[0].PSObject.Properties[0].Name }

    $invalid = [IO.Path]::GetInvalidFileNameChars()
    $count = 0
    foreach ($row in $rows) {
        $name = ([string]$row.$NameColumn).Trim()
        if (-not $name) { $name = 'row-' + ($count + 1) }
        foreach ($c in $invalid) { $name = $name.Replace([string]$c, '-') }
        $target = Join-Path $OutputDir "$name.md"
        [IO.File]::WriteAllText($target, (ConvertTo-FrontmatterBlock -Row $row), (New-Object Text.UTF8Encoding $false))
        $count++
    }
    return $count
}

if (-not $TargetDir) { $TargetDir = Read-Host 'TARGET DIR (output folder for .md files)' }
if (-not $TargetCsv) { $TargetCsv = Read-Host 'TARGET CSV (path to CSV file)' }
$TargetDir = $TargetDir.Trim('"').Trim()
$TargetCsv = $TargetCsv.Trim('"').Trim()

$count = Export-CsvToMarkdownFiles -CsvPath $TargetCsv -OutputDir $TargetDir
Write-Host "Done: $count file(s) written to $TargetDir"
