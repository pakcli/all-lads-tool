<#
.SYNOPSIS
    Batch Markdown Target-Dir Renamer Adapter
.DESCRIPTION
    Scans a target directory, inspects Markdown YAML frontmatters,
    and performs safe batch renames based on title, kebab-case title,
    and bidirectional frontmatter synchronization.
#>

$adapterDir = $PSScriptRoot
Import-Module -Name (Join-Path $adapterDir "kebab-case-converter.psm1") -Force
Import-Module -Name (Join-Path $adapterDir "frontmatter-title-parser.psm1") -Force

function Invoke-BatchTargetDirRename {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetDir,
        [switch]$KebabCase,
        [switch]$SyncFrontmatter,
        [switch]$DryRun
    )

    if (-not (Test-Path -LiteralPath $TargetDir -PathType Container)) {
        Write-Error "[ERROR] Target directory not found: $TargetDir"
        return
    }

    $mdFiles = @(Get-ChildItem -LiteralPath $TargetDir -Filter "*.md" -File)
    if ($mdFiles.Count -eq 0) {
        Write-Host "[INFO] No markdown files (*.md) found in '$TargetDir'." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "   BATCH TARGET-DIR RENAME :: FRONTMATTER TITLE ENGINE                  " -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host " Target Directory : $TargetDir" -ForegroundColor White
    Write-Host " Total Files      : $($mdFiles.Count) markdown file(s)" -ForegroundColor White
    Write-Host " Kebab-Case Mode  : $(if ($KebabCase) { 'YES (lowercase-kebab-case)' } else { 'NO (Raw Title)' })" -ForegroundColor Cyan
    Write-Host " Sync Frontmatter : $(if ($SyncFrontmatter) { 'YES (Bidirectional Sync)' } else { 'NO' })" -ForegroundColor Cyan
    Write-Host " Execution Mode   : $(if ($DryRun) { '[DRY-RUN / PREVIEW ONLY]' } else { '[LIVE EXECUTION]' })" -ForegroundColor $(if ($DryRun) { 'Yellow' } else { 'Green' })
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""

    $actions = @()
    $renamedCount = 0

    foreach ($file in $mdFiles) {
        $title = Get-FrontmatterTitle -FilePath $file.FullName
        if ([string]::IsNullOrWhiteSpace($title)) {
            $actions += [PSCustomObject]@{
                "Current File" = $file.Name
                "Status"       = "[SKIP] No Frontmatter Title"
                "New File"     = "-"
            }
            continue
        }

        $newBase = if ($KebabCase) {
            ConvertTo-KebabCase -Text $title
        } else {
            # Sanitize illegal characters for raw title
            $clean = $title -replace '[\/\\:*?"<>|]', '-'
            $clean.Trim()
        }

        if ([string]::IsNullOrWhiteSpace($newBase)) {
            $actions += [PSCustomObject]@{
                "Current File" = $file.Name
                "Status"       = "[SKIP] Empty Target Name"
                "New File"     = "-"
            }
            continue
        }

        $newFileName = "$newBase.md"
        $newPath = Join-Path $TargetDir $newFileName

        if ($file.Name -eq $newFileName) {
            $actions += [PSCustomObject]@{
                "Current File" = $file.Name
                "Status"       = "[ALIGNED] Name Matches Title"
                "New File"     = $newFileName
            }
            continue
        }

        if (Test-Path -LiteralPath $newPath) {
            $actions += [PSCustomObject]@{
                "Current File" = $file.Name
                "Status"       = "[COLLISION] Target Exists"
                "New File"     = $newFileName
            }
            continue
        }

        $actions += [PSCustomObject]@{
            "Current File" = $file.Name
            "Status"       = "[READY TO RENAME]"
            "New File"     = $newFileName
        }

        if (-not $DryRun) {
            # Check if repo is git tracked
            $isGit = git -C $TargetDir rev-parse --is-inside-work-tree 2>$null
            if ($isGit -eq "true") {
                git -C $TargetDir mv $file.Name $newFileName 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Move-Item -LiteralPath $file.FullName -Destination $newPath -Force
                }
            } else {
                Move-Item -LiteralPath $file.FullName -Destination $newPath -Force
            }

            if ($SyncFrontmatter) {
                Set-FrontmatterTitle -FilePath $newPath -NewTitle $newBase
            }
            $renamedCount++
        }
    }

    $actions | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Gray

    if ($DryRun) {
        Write-Host "[DRY-RUN] Preview complete. Run without -DryRun to apply renames.`n" -ForegroundColor Yellow
    } else {
        Write-Host "[OK] Successfully renamed $renamedCount file(s).`n" -ForegroundColor Green
    }
}

Export-ModuleMember -Function Invoke-BatchTargetDirRename
