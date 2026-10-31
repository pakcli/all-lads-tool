<#
.SYNOPSIS
    Modular Compaction & Audit Engine (CompactorEngine.ps1)
.DESCRIPTION
    Generic, zero-hardcode JavaScript (Terser + Regex Fallback), CSS, and HTML
    compaction functions plus payload size audit table reporting.
#>

function Record-AuditEntry {
    param (
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[PSCustomObject]]$AuditList,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Src = "",
        [Parameter(Mandatory = $true)][long]$BeforeBytes,
        [Parameter(Mandatory = $true)][long]$AfterBytes,
        [bool]$IsMerged = $false
    )
    $savedBytes = $BeforeBytes - $AfterBytes
    $pct = if ($BeforeBytes -gt 0) { [math]::Round(($savedBytes / $BeforeBytes) * 100, 1) } else { 0 }
    $bKb = [math]::Round($BeforeBytes / 1024, 2)
    $aKb = [math]::Round($AfterBytes / 1024, 2)
    $compactedText = if ($IsMerged) { "merged" } else { "$aKb KB" }

    # Extract clean source mode/type label if present (e.g. bundle, combine, catalog, slides, redirect, CSR)
    $mode = ""
    if ($Src -match "(?i)\b(bundle|combine|catalog|slides|redirect|CSR)\b") {
        $mode = $Matches[1].ToLower()
    } elseif ($Src -match "\(([^)]+)\)") {
        $mode = $Matches[1]
    }
    $srcDisplay = if ($mode) { "$bKb KB ($mode)" } else { "$bKb KB" }

    $AuditList.Add([PSCustomObject]@{
        FileName      = $Name
        Src           = $Src
        SrcKb         = $bKb
        SrcDisplay    = $srcDisplay
        BeforeKb      = $bKb
        AfterKb       = $aKb
        CompiledText  = "$bKb KB"
        CompactedText = $compactedText
        Reduction     = "-$pct%"
        SavedKb       = [math]::Round($savedBytes / 1024, 2)
        IsMerged      = $IsMerged
    })
}

function Invoke-JsCompactor {
    param (
        [Parameter(Mandatory = $true)][string]$RawJs,
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][string]$Label,
        [string]$Src = "",
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[PSCustomObject]]$AuditList,
        [bool]$Minify = $true,
        [bool]$IsMerged = $false
    )
    $origBytes = [System.Text.Encoding]::UTF8.GetByteCount($RawJs)

    if (-not $Minify) {
        [System.IO.File]::WriteAllText($TargetPath, $RawJs, [System.Text.Encoding]::UTF8)
        $finalBytes = (Get-Item $TargetPath).Length
        Record-AuditEntry -AuditList $AuditList -Name $Label -Src $Src -BeforeBytes $origBytes -AfterBytes $finalBytes -IsMerged $IsMerged
        return
    }

    $tempFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempFile, $RawJs, [System.Text.Encoding]::UTF8)

    $terserSuccess = $false
    if (Get-Command npx -ErrorAction SilentlyContinue) {
        try {
            & npx --yes terser $tempFile -o $TargetPath --compress passes=2 2>$null
            if ($LASTEXITCODE -eq 0 -and (Test-Path $TargetPath) -and ((Get-Item $TargetPath).Length -gt 0)) {
                $terserSuccess = $true
            }
        } catch {}
    }

    if (-not $terserSuccess) {
        $compacted = $RawJs -replace "(?ms)/\*.*?\*/", "" `
                            -replace "(?m)^\s*//.*$", "" `
                            -replace "\r?\n\s*\r?\n", "`n"
        [System.IO.File]::WriteAllText($TargetPath, $compacted, [System.Text.Encoding]::UTF8)
    }

    if (Test-Path $tempFile) { Remove-Item -Path $tempFile -Force }

    $finalBytes = (Get-Item $TargetPath).Length
    Record-AuditEntry -AuditList $AuditList -Name $Label -Src $Src -BeforeBytes $origBytes -AfterBytes $finalBytes -IsMerged $IsMerged
}

function Invoke-CssCompactor {
    param (
        [Parameter(Mandatory = $true)][string]$RawCss,
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][string]$Label,
        [string]$Src = "",
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[PSCustomObject]]$AuditList,
        [bool]$IsMerged = $false
    )
    $origBytes = [System.Text.Encoding]::UTF8.GetByteCount($RawCss)
    $compacted = $RawCss -replace "(?ms)/\*.*?\*/", "" `
                         -replace "\s*([{};:,])\s*", '$1' `
                         -replace ";\}", "}" `
                         -replace "\s+", " "
    $trimmed = $compacted.Trim()
    [System.IO.File]::WriteAllText($TargetPath, $trimmed, [System.Text.Encoding]::UTF8)

    $finalBytes = (Get-Item $TargetPath).Length
    Record-AuditEntry -AuditList $AuditList -Name $Label -Src $Src -BeforeBytes $origBytes -AfterBytes $finalBytes -IsMerged $IsMerged
}

function Invoke-HtmlMinifier {
    param (
        [Parameter(Mandatory = $true)][string]$RawHtml,
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][string]$Label,
        [string]$Src = "",
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[PSCustomObject]]$AuditList,
        [bool]$IsMerged = $false
    )
    $origBytes = [System.Text.Encoding]::UTF8.GetByteCount($RawHtml)
    $minified = $RawHtml -replace "(?s)<!--.*?-->", "" `
                         -replace "(?m)^[ \t]+", "" `
                         -replace "(?m)[ \t]+$", "" `
                         -replace "[ \t]{2,}", " " `
                         -replace "(\r?\n){2,}", "`n"
    $trimmed = $minified.Trim()
    [System.IO.File]::WriteAllText($TargetPath, $trimmed, [System.Text.Encoding]::UTF8)

    $finalBytes = (Get-Item $TargetPath).Length
    Record-AuditEntry -AuditList $AuditList -Name $Label -Src $Src -BeforeBytes $origBytes -AfterBytes $finalBytes -IsMerged $IsMerged
}

function Show-AuditReportTable {
    param (
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[PSCustomObject]]$AuditList,
        [Parameter(Mandatory = $false)][PSCustomObject]$Context = $null
    )
    $headerFmt = "  {0,-46} | {1,-24} | {2,-12} | {3,-22}"
    $divLine   = "  {0,-46}-+-{1,-24}-+-{2,-12}-+-{3,-22}" -f ("-" * 46), ("-" * 24), ("-" * 12), ("-" * 22)
    $bannerDiv = "=" * 111

    Write-Host "`n$bannerDiv" -ForegroundColor Green
    Write-Host "  PRODUCTION BUILD & COMPACTION AUDIT REPORT" -ForegroundColor Green
    Write-Host $bannerDiv -ForegroundColor Green
    Write-Host ($headerFmt -f "file name", "src", "compiled", "compiled (Compacted)") -ForegroundColor Yellow
    Write-Host $divLine -ForegroundColor DarkGray

    $totalSrc    = 0
    $totalBefore = 0
    $totalAfter  = 0

    foreach ($item in $AuditList) {
        $totalSrc    += $item.SrcKb
        $totalBefore += $item.BeforeKb
        $totalAfter  += $item.AfterKb
        $bStr = "$($item.BeforeKb) KB"
        $compactedDisplay = if ($item.IsMerged) { "merged" } else { "$($item.AfterKb) KB" }
        Write-Host ($headerFmt -f $item.FileName, $item.SrcDisplay, $bStr, $compactedDisplay) -ForegroundColor White
    }

    Write-Host $divLine -ForegroundColor DarkGray
    Write-Host ($headerFmt -f "TOTAL PAYLOAD", "$([math]::Round($totalSrc,2)) KB", "$([math]::Round($totalBefore,2)) KB", "$([math]::Round($totalAfter,2)) KB") -ForegroundColor Green
    Write-Host "$bannerDiv`n" -ForegroundColor Green

    # Calculate 4 Core Sizes
    if ($Context) {
        $srcPath = $Context.ResolvedSource
        $appsPath = $Context.ResolvedApps
        $outputPath = $Context.ResolvedOutput

        $srcMeasure = Get-ChildItem -Path $srcPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
        $appsMeasure = Get-ChildItem -Path $appsPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
        $outMeasure = Get-ChildItem -Path $outputPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum

        $srcKb = if ($srcMeasure.Sum) { [math]::Round(($srcMeasure.Sum / 1024), 2) } else { 0 }
        $appsKb = if ($appsMeasure.Sum) { [math]::Round(($appsMeasure.Sum / 1024), 2) } else { 0 }
        $outKb = if ($outMeasure.Sum) { [math]::Round(($outMeasure.Sum / 1024), 2) } else { 0 }
        $compactedKb = [math]::Round($totalAfter, 2)

        Write-Host "$bannerDiv" -ForegroundColor Yellow
        Write-Host "  FOUR CORE BUILD SIZES:" -ForegroundColor Yellow
        Write-Host "$bannerDiv" -ForegroundColor Yellow
        Write-Host "  [1] src                         : $srcKb KB  (Raw source code in src/)" -ForegroundColor White
        Write-Host "  [2] apps                        : $appsKb KB  (Raw cartridges in apps/)" -ForegroundColor White
        Write-Host "  [3] build include apps          : $outKb KB  (Total compiled distribution in public/)" -ForegroundColor White
        Write-Host "  [4] build compacted include apps: $compactedKb KB  (Total compacted distribution)" -ForegroundColor White
        Write-Host "$bannerDiv" -ForegroundColor Yellow

        # Write clean CSV
        $csvLines = [System.Collections.Generic.List[string]]::new()
        $csvLines.Add("# VINTAGE COMPUTING ARCADE - PRODUCTION BUILD AUDIT REPORT")
        $csvLines.Add("# Generated: $((Get-Date).ToString('yyyy-MM-ddTHH:mm:ss'))")
        $csvLines.Add("")
        $csvLines.Add("# --- FOUR CORE SIZES SUMMARY ---")
        $csvLines.Add("Metric,Size_KB,Description")
        $csvLines.Add("src,$srcKb,Total raw source code size (src/)")
        $csvLines.Add("apps,$appsKb,Total cartridges directory size (apps/)")
        $csvLines.Add("build_include_apps,$outKb,Total compiled distribution size including apps (public/)")
        $csvLines.Add("build_compacted_include_apps,$compactedKb,Total compacted distribution size including apps (public/)")
        $csvLines.Add("")
        $csvLines.Add("# --- DETAILED BUNDLE AUDIT ---")
        $csvLines.Add("File_Name,Source_Type,Compiled_KB,Compacted_KB,Saved_KB,Reduction_Pct")

        foreach ($item in $AuditList) {
            $csvLines.Add("$($item.FileName),""$($item.SrcDisplay)"",$($item.BeforeKb),$($item.AfterKb),$($item.SavedKb),$($item.Reduction)")
        }

        $csvText = $csvLines -join [Environment]::NewLine
        $csvPathPublic = Join-Path $outputPath "build-audit.csv"
        $csvPathRoot = Join-Path $Context.RepoRoot "build-audit.csv"
        [System.IO.File]::WriteAllText($csvPathPublic, $csvText, [System.Text.Encoding]::UTF8)
        [System.IO.File]::WriteAllText($csvPathRoot, $csvText, [System.Text.Encoding]::UTF8)
        Write-Host "  Audit CSV written to: public/build-audit.csv & build-audit.csv`n" -ForegroundColor DarkGray
    }
}
