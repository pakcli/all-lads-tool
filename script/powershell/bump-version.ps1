<#
.SYNOPSIS
    Vintage Computing Arcade — Granular Version Bumper (v01_00 -> v01_01 -> v02_00)
.DESCRIPTION
    Increments micro version tags for atomic commits or major versions for releases.
    Synchronizes state with main.json.
#>

[CmdletBinding()]
param (
    [ValidateSet("minor", "major")]
    [string]$Type = "minor",

    [string]$Message = "",

    [switch]$GitCommit,
    [switch]$DryRun
)

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$configFile = Join-Path $repoRoot "main.json"

if (-not (Test-Path $configFile)) {
    Write-Host "❌ main.json not found in $repoRoot" -ForegroundColor Red
    exit 1
}

$rawJson = Get-Content -Path $configFile -Raw -Encoding UTF8
$config = $rawJson | ConvertFrom-Json

# Initialize versioning block if absent
if (-not $config.versioning) {
    $config | Add-Member -MemberType NoteProperty -Name "versioning" -Value ([PSCustomObject]@{
        current = "v01_00"
        major = 1
        minor = 0
        lastCommit = "v01_00: baseline master architecture"
        updatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    })
}

$currMajor = [int]$config.versioning.major
$currMinor = [int]$config.versioning.minor

if ($Type -eq "major") {
    $currMajor++
    $currMinor = 0
} else {
    $currMinor++
}

$newTag = "v{0:D2}_{1:D2}" -f $currMajor, $currMinor
$fullCommitMsg = if ($Message) { "$newTag: $Message" } else { "$newTag: bump version to $newTag" }

Write-Host "🔄 Version Bump: $($config.versioning.current) ➔ $newTag ($Type)" -ForegroundColor Cyan
Write-Host "📝 Commit Message: $fullCommitMsg" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "🔍 [DryRun] No changes written to main.json." -ForegroundColor Gray
    exit 0
}

# Update main.json
$config.versioning.current = $newTag
$config.versioning.major = $currMajor
$config.versioning.minor = $currMinor
$config.versioning.lastCommit = $fullCommitMsg
$config.versioning.updatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")

$updatedJson = $config | ConvertTo-Json -Depth 10
$updatedJson | Set-Content -Path $configFile -Encoding UTF8 -Force
Write-Host "✔ Updated main.json version to $newTag" -ForegroundColor Green

if ($GitCommit) {
    Set-Location $repoRoot
    git add -A
    git commit -m $fullCommitMsg
    Write-Host "✔ Created Git commit: $fullCommitMsg" -ForegroundColor Green
}
