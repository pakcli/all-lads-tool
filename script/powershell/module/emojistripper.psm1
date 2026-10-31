<#
.SYNOPSIS
    Emoji Stripping and Text Sanitization Module.
.DESCRIPTION
    Headless PowerShell module to detect, count, and remove emojis from text and files.
    Part of all-lads-tool modular toolchain.
#>
[CmdletBinding()]
param()

# Authoritative regex pattern covering astral surrogate pairs (all modern emojis), dingbats, symbols, and variation selectors
$script:EmojiPattern = '(?:\p{Cs}{2}|\p{Cs}|[\u2600-\u27BF]|[\u2300-\u23FF]|[\u2B00-\u2BFF]|[\uFE00-\uFE0F]|\u200D|[\u20E3])'

function Test-HasEmoji {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Text
    )
    if ([string]::IsNullOrEmpty($Text)) { return $false }
    return [regex]::IsMatch($Text, $script:EmojiPattern)
}

function Remove-EmojiFromText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Text,

        [switch]$NormalizeSpaces
    )
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    $result = [regex]::Replace($Text, $script:EmojiPattern, "")
    if ($NormalizeSpaces) {
        # Collapse multiple horizontal spaces into single space without collapsing line breaks
        $result = [regex]::Replace($result, '[^\S\r\n]{2,}', ' ')
        # Clean trailing space before line breaks
        $result = [regex]::Replace($result, '[^\S\r\n]+(\r?\n)', '$1')
    }
    return $result
}

function Get-EmojiCountInText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Text
    )
    if ([string]::IsNullOrEmpty($Text)) { return 0 }
    $matches = [regex]::Matches($Text, $script:EmojiPattern)
    return $matches.Count
}

function Invoke-EmojiStripOnFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [switch]$DryRun,
        [switch]$NormalizeSpaces
    )

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        return [PSCustomObject]@{
            FilePath   = $FilePath
            Modified   = $false
            EmojiCount = 0
            Status     = "NotFound"
        }
    }

    try {
        $rawContent = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
    } catch {
        return [PSCustomObject]@{
            FilePath   = $FilePath
            Modified   = $false
            EmojiCount = 0
            Status     = "ReadError"
        }
    }

    $count = Get-EmojiCountInText -Text $rawContent
    if ($count -eq 0) {
        return [PSCustomObject]@{
            FilePath   = $FilePath
            Modified   = $false
            EmojiCount = 0
            Status     = "Clean"
        }
    }

    if (-not $DryRun) {
        $cleaned = Remove-EmojiFromText -Text $rawContent -NormalizeSpaces:$NormalizeSpaces
        [System.IO.File]::WriteAllText($FilePath, $cleaned, [System.Text.UTF8Encoding]::new($false))
        $status = "Stripped"
    } else {
        $status = "DryRun"
    }

    return [PSCustomObject]@{
        FilePath   = $FilePath
        Modified   = (-not $DryRun)
        EmojiCount = $count
        Status     = $status
    }
}

Export-ModuleMember -Function Test-HasEmoji, Remove-EmojiFromText, Get-EmojiCountInText, Invoke-EmojiStripOnFile
