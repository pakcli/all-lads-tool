<#
.SYNOPSIS
    Universal Path Normalizer and Drag-and-Drop Sanitizer (Context: common)
.DESCRIPTION
    Conforms strictly to Brief v01-04-00 and Brief v01-04-01.
    Sanitizes raw filesystem paths from Windows Explorer drag-and-drop,
    terminal quotes, escaped trailing backslashes, and resolves canonical paths.
#>

function Convert-ToCanonicalPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$RawPath,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path
    )

    if ([string]::IsNullOrWhiteSpace($RawPath)) {
        return ""
    }

    # Step 1: Strip leading and trailing whitespace
    $clean = $RawPath.Trim()

    # Step 2: Strip outer matching double or single quotes
    while (($clean.StartsWith('"') -and $clean.EndsWith('"')) -or ($clean.StartsWith("'") -and $clean.EndsWith("'"))) {
        if ($clean.Length -le 1) { break }
        $clean = $clean.Substring(1, $clean.Length - 2).Trim()
    }

    # Step 3: Handle escaped quote artifacts resulting from trailing backslash on Windows
    # (e.g. "path\to\dir\" in cmd/powershell drag-and-drop produces trailing quote)
    if ($clean.EndsWith('"') -or $clean.EndsWith("'")) {
        $clean = $clean.Substring(0, $clean.Length - 1).Trim()
    }

    # Step 4: Remove trailing slashes and backslashes for non-root paths
    if ($clean.Length -gt 3) {
        $clean = $clean.TrimEnd('\').TrimEnd('/')
    }

    # Step 5: Convert forward slashes to system directory separator
    $clean = $clean.Replace('/', [System.IO.Path]::DirectorySeparatorChar)

    # Step 6: Resolve relative or rooted paths
    try {
        if ([System.IO.Path]::IsPathRooted($clean)) {
            if (Test-Path -LiteralPath $clean) {
                return (Resolve-Path -LiteralPath $clean).Path
            }
            return [System.IO.Path]::GetFullPath($clean)
        } else {
            $combined = [System.IO.Path]::Combine($BasePath, $clean)
            if (Test-Path -LiteralPath $combined) {
                return (Resolve-Path -LiteralPath $combined).Path
            }
            return [System.IO.Path]::GetFullPath($combined)
        }
    } catch {
        return $clean
    }
}

function Test-ValidDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $canonical = Convert-ToCanonicalPath -RawPath $Path
    if ([string]::IsNullOrWhiteSpace($canonical)) { return $false }
    return (Test-Path -LiteralPath $canonical -PathType Container)
}

function Test-ValidFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $canonical = Convert-ToCanonicalPath -RawPath $Path
    if ([string]::IsNullOrWhiteSpace($canonical)) { return $false }
    return (Test-Path -LiteralPath $canonical -PathType Leaf)
}

function Get-PathSignature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath
    )

    $canonical = Convert-ToCanonicalPath -RawPath $DirectoryPath
    if (-not (Test-ValidDirectory -Path $canonical)) {
        return [PSCustomObject]@{
            IsValid        = $false
            CanonicalPath  = $canonical
            DetectedContext= "unknown"
            IsGitRepo      = $false
            IsNodeProject  = $false
            IsMarkdownDir  = $false
            IsBlenderAsset = $false
            IsUnityProject = $false
            ItemCount      = 0
        }
    }

    $gitPath = Join-Path $canonical ".git"
    $pkgPath = Join-Path $canonical "package.json"
    $unityPath = Join-Path $canonical "Assets"

    $isGit = Test-Path -LiteralPath $gitPath
    $isNode = Test-Path -LiteralPath $pkgPath
    $isUnity = Test-Path -LiteralPath $unityPath

    $blendFiles = @(Get-ChildItem -LiteralPath $canonical -Filter "*.blend" -File -ErrorAction SilentlyContinue)
    $isBlender = ($blendFiles.Count -gt 0)

    $mdFiles = @(Get-ChildItem -LiteralPath $canonical -Filter "*.md" -File -ErrorAction SilentlyContinue)
    $isMarkdown = ($mdFiles.Count -gt 0 -and -not $isGit -and -not $isNode)

    $detected = "file"
    if ($isGit) { $detected = "repo" }
    elseif ($isNode) { $detected = "website" }
    elseif ($isBlender) { $detected = "blender" }
    elseif ($isUnity) { $detected = "unity" }
    elseif ($isMarkdown) { $detected = "file" }

    $childItems = @(Get-ChildItem -LiteralPath $canonical -ErrorAction SilentlyContinue)

    return [PSCustomObject]@{
        IsValid        = $true
        CanonicalPath  = $canonical
        DetectedContext= $detected
        IsGitRepo      = $isGit
        IsNodeProject  = $isNode
        IsMarkdownDir  = $isMarkdown
        IsBlenderAsset = $isBlender
        IsUnityProject = $isUnity
        ItemCount      = $childItems.Count
    }
}

Export-ModuleMember -Function @(
    "Convert-ToCanonicalPath",
    "Test-ValidDirectory",
    "Test-ValidFile",
    "Get-PathSignature"
)
