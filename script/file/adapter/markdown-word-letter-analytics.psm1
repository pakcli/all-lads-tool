<#
.SYNOPSIS
    Markdown Word & Letter Analytics Adapter (Context: File)
.DESCRIPTION
    Analyzes filenames, frontmatter titles, and aliases for word counts,
    reduplications (e.g. 'paru paru' = 1 word vs 'saudi arabia' = 2 words),
    letter min/max lengths, and starting/usage popularity with negative ranking (4=-1, 5=-2, 6=-3).
    Strictly sanitizes paths to prevent leaking sensitive drive letters (D:, C:) or usernames.
#>

function Get-SanitizedFolderName {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "root" }
    $leaf = Split-Path -Path $Path -Leaf
    if ([string]::IsNullOrWhiteSpace($leaf) -or $leaf -match '^[A-Za-z]:\\?$') {
        $leaf = "workspace-root"
    }
    # Sanitize: strip drive colons, user names, illegal chars
    $safe = $leaf -replace '^[A-Za-z]:', '' -replace '[\\/:*?"<>|]', '-' -replace '-{2,}', '-'
    return $safe.Trim('-').ToLower()
}

function Split-IntoLexicalWords {
    <#
    .SYNOPSIS
        Splits text into words taking into account Indonesian reduplication rules:
        - "paru paru" or "paru-paru" -> 1 word (identical consecutive words)
        - "saudi arabia" -> 2 words (distinct words)
    #>
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }

    # Clean punctuation, keep alphanumeric, spaces, and hyphens
    $clean = $Text -replace '[^\p{L}\p{Nd}\s-]', ' '
    $rawTokens = @($clean -split '[\s_-]+' | Where-Object { $_.Trim().Length -gt 0 })

    if ($rawTokens.Count -eq 0) { return @() }

    $words = [System.Collections.ArrayList]@()
    $i = 0
    while ($i -lt $rawTokens.Count) {
        $curr = $rawTokens[$i].Trim()
        if ($i + 1 -lt $rawTokens.Count) {
            $next = $rawTokens[$i + 1].Trim()
            # Reduplication check: word[i] == word[i+1] (e.g. paru paru, anak anak, jalan jalan)
            if ($curr.ToLowerInvariant() -eq $next.ToLowerInvariant()) {
                $words.Add("$curr-$next") | Out-Null
                $i += 2
                continue
            }
        }
        $words.Add($curr) | Out-Null
        $i++
    }

    return @($words)
}

function Get-FrontmatterMetadata {
    param([string]$FilePath)

    $meta = [PSCustomObject]@{
        Title   = ""
        Aliases = @()
    }

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) { return $meta }

    $lines = Get-Content -LiteralPath $FilePath -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $lines -or $lines.Count -lt 2 -or $lines[0].Trim() -ne '---') { return $meta }

    $inAliases = $false
    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $trimmed = $line.Trim()
        if ($trimmed -eq '---') { break }

        # Title
        if ($trimmed -match '^title\s*:\s*(.*)$') {
            $raw = $matches[1].Trim().Trim('"').Trim("'")
            $meta.Title = $raw
            $inAliases = $false
            continue
        }

        # Single-line Alias / Aliases
        if ($trimmed -match '^(alias|aliases)\s*:\s*\[(.*)\]$') {
            $rawList = $matches[2]
            $items = $rawList -split ',' | ForEach-Object { $_.Trim().Trim('"').Trim("'") } | Where-Object { $_ }
            $meta.Aliases += $items
            $inAliases = $false
            continue
        }
        if ($trimmed -match '^(alias|aliases)\s*:\s*(.+)$') {
            $rawVal = $matches[2].Trim().Trim('"').Trim("'")
            if ($rawVal) { $meta.Aliases += $rawVal }
            $inAliases = $false
            continue
        }
        if ($trimmed -match '^(alias|aliases)\s*:\s*$') {
            $inAliases = $true
            continue
        }

        # Multi-line alias list
        if ($inAliases) {
            if ($trimmed -match '^-\s*(.*)$') {
                $item = $matches[1].Trim().Trim('"').Trim("'")
                if ($item) { $meta.Aliases += $item }
            } elseif ($trimmed -match '^[A-Za-z0-9_-]+\s*:') {
                $inAliases = $false
            }
        }
    }

    return $meta
}

function Analyze-InstanceText {
    param(
        [string]$TypeInstance,
        [string]$RawText
    )

    $words = Split-IntoLexicalWords -Text $RawText
    $wordsCount = $words.Count

    # Identify single words vs multi words
    # A single-word instance has wordsCount == 1
    $singleWordCount = if ($wordsCount -eq 1) { 1 } else { 0 }

    # Letter count statistics for single words
    $singleWordMinMax = if ($wordsCount -eq 1) {
        $len = ($words[0] -replace '[^A-Za-z0-9]', '').Length
        "min:${len}-max:${len}"
    } else {
        "min:0-max:0"
    }

    # Letter count statistics across all individual words in this instance
    $wordLengths = @($words | ForEach-Object { ($_ -replace '[^A-Za-z0-9]', '').Length } | Where-Object { $_ -gt 0 })
    $wordsMinMax = if ($wordLengths.Count -gt 0) {
        $min = ($wordLengths | Measure-Object -Minimum).Minimum
        $max = ($wordLengths | Measure-Object -Maximum).Maximum
        "min:${min}-max:${max}"
    } else {
        "min:0-max:0"
    }

    return [PSCustomObject]@{
        "type-instance"                    = $TypeInstance
        "word-single-count"                = $singleWordCount
        "words-count"                      = $wordsCount
        "single-word-letter-min-max-count" = $singleWordMinMax
        "words-letter-min-max-count"       = $wordsMinMax
        "ExtractedWords"                   = $words
    }
}

function Get-PopularityRanks {
    param(
        [hashtable]$FrequencyMap
    )

    # Sort descending
    $sorted = @($FrequencyMap.GetEnumerator() | Sort-Object Value -Descending)
    $total = $sorted.Count

    $result = [ordered]@{}
    if ($total -eq 0) { return $result }

    # Top 3 (1, 2, 3)
    $result["1 (Top #1)"] = if ($total -ge 1) { "$($sorted[0].Key) ($($sorted[0].Value)x)" } else { "N/A" }
    $result["2 (Top #2)"] = if ($total -ge 2) { "$($sorted[1].Key) ($($sorted[1].Value)x)" } else { "N/A" }
    $result["3 (Top #3)"] = if ($total -ge 3) { "$($sorted[2].Key) ($($sorted[2].Value)x)" } else { "N/A" }

    # Bottom 3 with negative indexing: 4 = -1, 5 = -2, 6 = -3
    $result["4 (Rank -1: Least #1)"] = if ($total -ge 1) { "$($sorted[$total - 1].Key) ($($sorted[$total - 1].Value)x)" } else { "N/A" }
    $result["5 (Rank -2: Least #2)"] = if ($total -ge 2) { "$($sorted[$total - 2].Key) ($($sorted[$total - 2].Value)x)" } else { "N/A" }
    $result["6 (Rank -3: Least #3)"] = if ($total -ge 3) { "$($sorted[$total - 3].Key) ($($sorted[$total - 3].Value)x)" } else { "N/A" }

    return $result
}

function Invoke-MarkdownWordLetterAnalytics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetDir,
        [string]$OutputDir = $TargetDir
    )

    if (-not (Test-Path -LiteralPath $TargetDir -PathType Container)) {
        Write-Error "[ERROR] Target directory not found: $TargetDir"
        return
    }

    $folderSlug = Get-SanitizedFolderName -Path $TargetDir
    $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
    $fileNamePrefix = "${timestamp}_${folderSlug}"

    $mdFiles = @(Get-ChildItem -LiteralPath $TargetDir -Filter "*.md" -Recurse -File)
    if ($mdFiles.Count -eq 0) {
        Write-Host "[INFO] No markdown files found in '$folderSlug'." -ForegroundColor Yellow
        return
    }

    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "   MARKDOWN METADATA & WORD ANALYTICS                                   " -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host " Target Folder : $folderSlug (Path sanitized - zero drive/user leak)" -ForegroundColor White
    Write-Host " Output Prefix : $fileNamePrefix" -ForegroundColor Cyan
    Write-Host " Total Files   : $($mdFiles.Count) markdown files" -ForegroundColor White
    Write-Host "========================================================================`n" -ForegroundColor Cyan

    $table1Rows = [System.Collections.ArrayList]@()
    $startLetterFreq = @{}
    $letterUsageFreq = @{}
    $folderWordFreq  = @{}

    foreach ($file in $mdFiles) {
        # Relative sanitized folder path
        $relDir = $file.DirectoryName.Substring($TargetDir.Length).TrimStart('\', '/')
        if (-not $relDir) { $relDir = "root" }
        $safeRelDir = $relDir -replace '^[A-Za-z]:', '' -replace '[\\/]', '/'

        # 1. Filename instance
        $fileBase = $file.BaseName
        $rowFile = Analyze-InstanceText -TypeInstance "filename: $fileBase" -RawText $fileBase
        $table1Rows.Add($rowFile) | Out-Null

        # Frontmatter
        $meta = Get-FrontmatterMetadata -FilePath $file.FullName

        # 2. Title instance
        if ($meta.Title) {
            $rowTitle = Analyze-InstanceText -TypeInstance "title: $($meta.Title)" -RawText $meta.Title
            $table1Rows.Add($rowTitle) | Out-Null
        }

        # 3. Alias instances
        foreach ($alias in $meta.Aliases) {
            if ($alias) {
                $rowAlias = Analyze-InstanceText -TypeInstance "alias: $alias" -RawText $alias
                $table1Rows.Add($rowAlias) | Out-Null
            }
        }
    }

    # Aggregate popularity frequencies
    foreach ($row in $table1Rows) {
        $words = $row.ExtractedWords
        foreach ($w in $words) {
            $cleanWord = $w -replace '[^A-Za-z0-9]', ''
            if (-not $cleanWord) { continue }

            # 1. Word Starting Letter
            $firstLetter = $cleanWord.Substring(0, 1).ToLowerInvariant()
            if ($firstLetter -match '[a-z]') {
                $startLetterFreq[$firstLetter] = 1 + [int]$startLetterFreq[$firstLetter]
            }

            # 2. Letter Usage in Word
            foreach ($ch in $cleanWord.ToLowerInvariant().ToCharArray()) {
                if ("$ch" -match '[a-z]') {
                    $letterUsageFreq["$ch"] = 1 + [int]$letterUsageFreq["$ch"]
                }
            }
        }
    }

    # 3. Folder words instance count
    foreach ($file in $mdFiles) {
        $relDir = $file.DirectoryName.Substring($TargetDir.Length).TrimStart('\', '/')
        if (-not $relDir) { $relDir = "root" }
        $folderWordFreq[$relDir] = 1 + [int]$folderWordFreq[$relDir]
    }

    # Output Table 1: Instance Table CSV
    $table1CsvPath = Join-Path $OutputDir "${fileNamePrefix}_instances.csv"
    $exportRows = $table1Rows | Select-Object "type-instance", "word-single-count", "words-count", "single-word-letter-min-max-count", "words-letter-min-max-count"
    $exportRows | Export-Csv -LiteralPath $table1CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "[TABLE 1 EXPORTED] $table1CsvPath" -ForegroundColor Green

    # Output Table 2: Popularity Table CSV
    $popStartLetter = Get-PopularityRanks -FrequencyMap $startLetterFreq
    $popLetterUsage = Get-PopularityRanks -FrequencyMap $letterUsageFreq
    $popFolderWords = Get-PopularityRanks -FrequencyMap $folderWordFreq

    $table2Rows = @(
        [PSCustomObject]@{
            "Rank / Index"                           = "1 (Top #1)"
            "1. Most Frequent Word Starting Letter" = $popStartLetter["1 (Top #1)"]
            "2. Most Frequent Letter Usage in Words" = $popLetterUsage["1 (Top #1)"]
            "3. Folder with Most Word Instances"    = $popFolderWords["1 (Top #1)"]
        },
        [PSCustomObject]@{
            "Rank / Index"                           = "2 (Top #2)"
            "1. Most Frequent Word Starting Letter" = $popStartLetter["2 (Top #2)"]
            "2. Most Frequent Letter Usage in Words" = $popLetterUsage["2 (Top #2)"]
            "3. Folder with Most Word Instances"    = $popFolderWords["2 (Top #2)"]
        },
        [PSCustomObject]@{
            "Rank / Index"                           = "3 (Top #3)"
            "1. Most Frequent Word Starting Letter" = $popStartLetter["3 (Top #3)"]
            "2. Most Frequent Letter Usage in Words" = $popLetterUsage["3 (Top #3)"]
            "3. Folder with Most Word Instances"    = $popFolderWords["3 (Top #3)"]
        },
        [PSCustomObject]@{
            "Rank / Index"                           = "4 = -1 (Least #1)"
            "1. Most Frequent Word Starting Letter" = $popStartLetter["4 (Rank -1: Least #1)"]
            "2. Most Frequent Letter Usage in Words" = $popLetterUsage["4 (Rank -1: Least #1)"]
            "3. Folder with Most Word Instances"    = $popFolderWords["4 (Rank -1: Least #1)"]
        },
        [PSCustomObject]@{
            "Rank / Index"                           = "5 = -2 (Least #2)"
            "1. Most Frequent Word Starting Letter" = $popStartLetter["5 (Rank -2: Least #2)"]
            "2. Most Frequent Letter Usage in Words" = $popLetterUsage["5 (Rank -2: Least #2)"]
            "3. Folder with Most Word Instances"    = $popFolderWords["5 (Rank -2: Least #2)"]
        },
        [PSCustomObject]@{
            "Rank / Index"                           = "6 = -3 (Least #3)"
            "1. Most Frequent Word Starting Letter" = $popStartLetter["6 (Rank -3: Least #3)"]
            "2. Most Frequent Letter Usage in Words" = $popLetterUsage["6 (Rank -3: Least #3)"]
            "3. Folder with Most Word Instances"    = $popFolderWords["6 (Rank -3: Least #3)"]
        }
    )

    $table2CsvPath = Join-Path $OutputDir "${fileNamePrefix}_popularity.csv"
    $table2Rows | Export-Csv -LiteralPath $table2CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "[TABLE 2 EXPORTED] $table2CsvPath`n" -ForegroundColor Green

    # Terminal ASCII Printouts
    Write-Host "--- TABLE 1: INSTANCES SAMPLE (First 10 of $($exportRows.Count)) ---" -ForegroundColor Yellow
    $exportRows | Select-Object -First 10 | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor White

    Write-Host "--- TABLE 2: POPULARITY & NEGATIVE INDEX RANKING (4=-1, 5=-2, 6=-3) ---" -ForegroundColor Yellow
    $table2Rows | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Cyan

    return [PSCustomObject]@{
        Table1Path = $table1CsvPath
        Table2Path = $table2CsvPath
        TotalRows  = $exportRows.Count
    }
}

Export-ModuleMember -Function Get-SanitizedFolderName, Split-IntoLexicalWords, Get-FrontmatterMetadata, Analyze-InstanceText, Get-PopularityRanks, Invoke-MarkdownWordLetterAnalytics
