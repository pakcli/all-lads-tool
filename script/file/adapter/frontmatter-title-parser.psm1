<#
.SYNOPSIS
    Markdown Frontmatter Title Parser & Synchronizer Adapter
.DESCRIPTION
    Extracts, inspects, and modifies YAML frontmatter titles in Markdown files.
#>

function Get-FrontmatterTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) { return $null }

    $lines = Get-Content -LiteralPath $FilePath -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $lines -or $lines.Count -lt 2) { return $null }
    if ($lines[0].Trim() -ne '---') { return $null }

    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        if ($line -eq '---') { break }

        if ($line -match '^title\s*:\s*(.*)$') {
            $rawTitle = $matches[1].Trim()
            # Strip wrapping single or double quotes
            if (($rawTitle.StartsWith('"') -and $rawTitle.EndsWith('"')) -or
                ($rawTitle.StartsWith("'") -and $rawTitle.EndsWith("'"))) {
                $rawTitle = $rawTitle.Substring(1, $rawTitle.Length - 2).Trim()
            }
            return $rawTitle
        }
    }

    return $null
}

function Set-FrontmatterTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string]$NewTitle
    )

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) { return $false }

    $lines = [System.Collections.ArrayList]@(Get-Content -LiteralPath $FilePath -Encoding UTF8)
    if (-not $lines -or $lines.Count -lt 2 -or $lines[0].Trim() -ne '---') {
        # Prepend new frontmatter if none exists
        $newContent = "---`ntitle: $NewTitle`n---`n" + ($lines -join "`n")
        [System.IO.File]::WriteAllText($FilePath, $newContent, (New-Object System.Text.UTF8Encoding $false))
        return $true
    }

    $titleIndex = -1
    $closingIndex = -1

    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        if ($line -eq '---') {
            $closingIndex = $i
            break
        }
        if ($line -match '^title\s*:') {
            $titleIndex = $i
        }
    }

    if ($titleIndex -ge 0) {
        $lines[$titleIndex] = "title: $NewTitle"
    } elseif ($closingIndex -ge 0) {
        $lines.Insert($closingIndex, "title: $NewTitle")
    }

    $finalText = ($lines -join "`n") + "`n"
    [System.IO.File]::WriteAllText($FilePath, $finalText, (New-Object System.Text.UTF8Encoding $false))
    return $true
}

Export-ModuleMember -Function Get-FrontmatterTitle, Set-FrontmatterTitle
