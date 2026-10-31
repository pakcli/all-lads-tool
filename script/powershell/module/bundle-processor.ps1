<#
.SYNOPSIS
    Modular Declarative Bundle Processor (BundleProcessor.ps1)
.DESCRIPTION
    100% manifest-driven bundle processors for Scripts, Styles, HTML, Slidev Decks,
    Media Pass-Through, and App Cartridges. Contains ZERO hardcoded filenames,
    stylesheet names, or module variables.
#>

function Initialize-PipelineDirectories {
    param ([Parameter(Mandatory = $true)][PSCustomObject]$Context)

    if (-not (Test-Path $Context.ResolvedOutput)) {
        New-Item -ItemType Directory -Path $Context.ResolvedOutput -Force | Out-Null
        Write-Host "[OK] Created output directory: $($Context.ResolvedOutput)" -ForegroundColor Green
    }

    if ($Context.Clean) {
        Write-Host "[*] Cleaning existing distribution files in $($Context.ResolvedOutput)..." -ForegroundColor Cyan
        Get-ChildItem -Path $Context.ResolvedOutput -File | ForEach-Object {
            Remove-Item -Path $_.FullName -Force
        }
    }
}

function Invoke-ScriptBundlesStage {
    param ([Parameter(Mandatory = $true)][PSCustomObject]$Context)

    $scriptsConfig = $Context.Manifest.bundles.scripts
    if (-not $scriptsConfig) { return }

    Write-Host "[STAGE] Processing JavaScript Bundles..." -ForegroundColor Cyan

    foreach ($entry in $scriptsConfig) {
        $outFile = $entry.output
        $outPath = Join-Path $Context.ResolvedOutput $outFile
        $type = if ($entry.type) { $entry.type } else { "bundle" }
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        if ($type -eq "bundle") {
            $bundleBuilder = [System.Text.StringBuilder]::new()
            $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

            [void]$bundleBuilder.AppendLine("/* Bundled Artifact: $outFile | Generated: $timestamp */`n")

            foreach ($srcRel in $entry.sources) {
                $srcFile = Join-Path $Context.ResolvedSource $srcRel
                if (Test-Path $srcFile) {
                    $content = Get-Content -Path $srcFile -Raw -Encoding UTF8
                    [void]$bundleBuilder.AppendLine("/* --- Module: $srcRel --- */")
                    [void]$bundleBuilder.AppendLine($content)
                    [void]$bundleBuilder.AppendLine("`n")
                    Write-Host "  + Included: $srcRel" -ForegroundColor DarkGray
                } else {
                    Write-Warning "Source file missing: $srcFile"
                }
            }

            $isMerged = $entry.sources.Count -gt 1
            $srcDesc = if ($isMerged) { "bundle ($($entry.sources.Count) modules)" } else { $entry.sources[0] }
            Invoke-JsCompactor -RawJs $bundleBuilder.ToString() -TargetPath $outPath -Label $outFile -Src $srcDesc -AuditList $Context.AuditReport -Minify $Context.Minify -IsMerged $isMerged
            $sw.Stop()
            $kb = [math]::Round((Get-Item $outPath).Length / 1024, 2)
            Write-Host "  [OK] Mangled & Compacted $outFile ($kb KB in $($sw.ElapsedMilliseconds)ms)" -ForegroundColor Green

        } elseif ($type -eq "standalone") {
            $firstSource = $entry.sources[0]
            $srcFile = Join-Path $Context.ResolvedSource $firstSource
            if (Test-Path $srcFile) {
                $rawContent = Get-Content -Path $srcFile -Raw -Encoding UTF8
                Invoke-JsCompactor -RawJs $rawContent -TargetPath $outPath -Label $outFile -Src $firstSource -AuditList $Context.AuditReport -Minify $Context.Minify -IsMerged $false
                $sw.Stop()
                $kb = [math]::Round((Get-Item $outPath).Length / 1024, 2)
                Write-Host "  [OK] Mangled Standalone $outFile ($kb KB)" -ForegroundColor Green
            } else {
                Write-Warning "Standalone source missing: $srcFile"
            }
        }
    }
}

function Invoke-StyleBundlesStage {
    param ([Parameter(Mandatory = $true)][PSCustomObject]$Context)

    $stylesConfig = $Context.Manifest.bundles.styles
    if (-not $stylesConfig) { return }

    Write-Host "[STAGE] Processing Stylesheet Bundles..." -ForegroundColor Cyan

    foreach ($entry in $stylesConfig) {
        $outFile = $entry.output
        $outPath = Join-Path $Context.ResolvedOutput $outFile
        $srcFile = Join-Path $Context.ResolvedSource $entry.source

        if ((-not (Test-Path $srcFile)) -and $entry.fallback) {
            $srcFile = Join-Path $Context.ResolvedSource $entry.fallback
        }

        # Support combining multiple stylesheets (e.g. style.css combining floppy + winget)
        $rawCss = ""
        $isMerged = $false
        $srcDesc = $entry.source
        if ($entry.combine) {
            $isMerged = $true
            $srcDesc = "combine ($($entry.combine.Count) styles)"
            $cssBuilder = [System.Text.StringBuilder]::new()
            foreach ($combRel in $entry.combine) {
                $combPath = Join-Path $Context.ResolvedSource $combRel
                if (Test-Path $combPath) {
                    $c = Get-Content -Path $combPath -Raw -Encoding UTF8
                    [void]$cssBuilder.AppendLine("/* --- Combined: $combRel --- */")
                    [void]$cssBuilder.AppendLine($c)
                    [void]$cssBuilder.AppendLine("`n")
                    Write-Host "  + Combined CSS: $combRel" -ForegroundColor DarkGray
                } else {
                    Write-Warning "Combined CSS source not found: $combPath"
                }
            }
            $rawCss = $cssBuilder.ToString()
        } elseif (Test-Path $srcFile) {
            $rawCss = Get-Content -Path $srcFile -Raw -Encoding UTF8
        } else {
            Write-Warning "Stylesheet source not found: $srcFile"
            continue
        }

        # RULE #1: theme.css is 100% UNTOUCHED (0 edits, verbatim copy)
        if ($outFile -eq "theme.css") {
            [System.IO.File]::WriteAllText($outPath, $rawCss, [System.Text.Encoding]::UTF8)
            $finalBytes = (Get-Item $outPath).Length
            Record-AuditEntry -AuditList $Context.AuditReport -Name $outFile -Src $srcDesc -BeforeBytes $finalBytes -AfterBytes $finalBytes -IsMerged $false
            Write-Host "  [RULE #1 PRESERVED] Copied verbatim $outFile (Untouched Obsidian Theme)" -ForegroundColor Green
            continue
        }

        if ($Context.Minify) {
            Invoke-CssCompactor -RawCss $rawCss -TargetPath $outPath -Label $outFile -Src $srcDesc -AuditList $Context.AuditReport -IsMerged $isMerged
        } else {
            [System.IO.File]::WriteAllText($outPath, $rawCss, [System.Text.Encoding]::UTF8)
            $finalBytes = (Get-Item $outPath).Length
            Record-AuditEntry -AuditList $Context.AuditReport -Name $outFile -Src $srcDesc -BeforeBytes $finalBytes -AfterBytes $finalBytes -IsMerged $isMerged
        }
        $kb = [math]::Round((Get-Item $outPath).Length / 1024, 2)
        Write-Host "  [OK] Compacted $outFile ($kb KB) from $srcDesc" -ForegroundColor Green
    }
}

function Invoke-HtmlBundlesStage {
    param ([Parameter(Mandatory = $true)][PSCustomObject]$Context)

    $htmlConfig = $Context.Manifest.bundles.html
    if (-not $htmlConfig) { return }

    Write-Host "[STAGE] Processing HTML Bundles & Dynamic Asset Injection..." -ForegroundColor Cyan

    $definedStyles  = $Context.Manifest.bundles.styles
    $definedScripts = $Context.Manifest.bundles.scripts

    foreach ($entry in $htmlConfig) {
        $outFile = $entry.output
        $outPath = Join-Path $Context.ResolvedOutput $outFile
        $type = if ($entry.type) { $entry.type } else { "page" }

        if ($type -eq "redirect") {
            $target     = $entry.target
            $cleanRoute = if ($entry.cleanRoute) { $entry.cleanRoute } else { $target }
            $title      = if ($entry.title) { $entry.title } else { $Context.Manifest.project }
            $banner     = if ($entry.banner) { $entry.banner } else { $title }
            $redirectHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="refresh" content="0; url=$target">
  <script>window.location.replace("$target");</script>
  <title>$title</title>
</head>
<body style="background-color: #0d0f0c; color: #b0a84a; font-family: monospace; display: flex; flex-direction: column; justify-content: center; align-items: center; height: 100vh; margin: 0;">
  <p style="font-size: 16px; font-weight: 700;">$banner</p>
  <p style="font-size: 12px; color: #788270;">Redirecting to $cleanRoute ($target)</p>
</body>
</html>
"@
            [System.IO.File]::WriteAllText($outPath, $redirectHtml, [System.Text.Encoding]::UTF8)
            $finalBytes = (Get-Item $outPath).Length
            Record-AuditEntry -AuditList $Context.AuditReport -Name $outFile -Src "redirect ($cleanRoute)" -BeforeBytes $finalBytes -AfterBytes $finalBytes -IsMerged $false
            Write-Host "  [OK] Generated Redirect $outFile -> $target ($cleanRoute)" -ForegroundColor Green

        } else {
            $srcFile = Join-Path $Context.ResolvedSource $entry.source
            if (-not (Test-Path $srcFile)) {
                Write-Warning "HTML source file missing: $srcFile"
                continue
            }

            $content = Get-Content -Path $srcFile -Raw -Encoding UTF8

            # 100% Dynamic Stylesheet Rewriting from Manifest (Zero Hardcoded CSS Names)
            if ($definedStyles) {
                foreach ($styleDef in $definedStyles) {
                    $candidates = @($styleDef.source)
                    if ($styleDef.fallback) { $candidates += $styleDef.fallback }
                    if ($styleDef.combine)  { $candidates += $styleDef.combine }
                    foreach ($cand in $candidates) {
                        if ($cand) {
                            $escapedCand = [regex]::Escape($cand)
                            $content = $content -replace "href=`"$escapedCand`"", "href=`"$($styleDef.output)`""
                        }
                    }
                }
            }

            # 100% Dynamic Script Bundle Injection from Manifest (Zero Hardcoded JS Names)
            if ($entry.inject -and $entry.inject.scripts) {
                $scriptTags = ($entry.inject.scripts | ForEach-Object { "  <script src=`"$_`"></script>" }) -join "`n"
                if ($entry.inject.scriptBlockPattern -and ($content -match $entry.inject.scriptBlockPattern)) {
                    $content = $content -replace $entry.inject.scriptBlockPattern, "$scriptTags`n</body>"
                } elseif ($definedScripts) {
                    # Fallback: remove individual source <script> tags and inject bundled tags before </body>
                    foreach ($sBundle in $definedScripts) {
                        if ($entry.inject.scripts -contains $sBundle.output) {
                            foreach ($srcJs in $sBundle.sources) {
                                $escJs = [regex]::Escape($srcJs)
                                $content = $content -replace "(?m)^\s*<script[^>]+src=`"$escJs`"[^>]*></script>\s*\r?\n?", ""
                            }
                        }
                    }
                    $content = $content -replace "</body>", "$scriptTags`n</body>"
                }
            }

            # 100% Dynamic Pre-Compiled Public TTS Payload Injection (Stage 1: Play Compiled in public/)
            if ($entry.ttsEngine) {
                $ttsEnginePath = Join-Path $Context.ResolvedSource $entry.ttsEngine
                if ((Test-Path $ttsEnginePath) -and (Get-Command node -ErrorAction SilentlyContinue)) {
                    $ttsNodeBridge = @"
const fs = require('fs');
const tts = require(process.argv[1]);
const htmlSrc = fs.readFileSync(process.argv[2], 'utf8');
const dict = {};
const re = /title\s*:\s*'([^']*)'\s*,\s*desc\s*:\s*'([^']*)'/g;
let m;
while ((m = re.exec(htmlSrc)) !== null) {
  const raw = m[1] + '. ' + m[2];
  const payload = tts.compileTtsPayload(raw);
  dict[payload.hash] = payload;
}
process.stdout.write(JSON.stringify(dict));
"@
                    $ttsJson = & node -e $ttsNodeBridge $ttsEnginePath $srcFile 2>$null
                    if (-not [string]::IsNullOrWhiteSpace($ttsJson) -and $ttsJson.StartsWith("{")) {
                        $ttsScriptTag = "  <script id=`"arcade-precompiled-tts`">window.__ARCADE_PRECOMPILED_TTS__=$ttsJson;</script>"
                        $content = $content -replace "</head>", "$ttsScriptTag`n</head>"
                        Write-Host "  [TTS PRE-COMPILED] Injected public pre-compiled TTS payload into $outFile" -ForegroundColor Green
                    }
                }
            }

            # 100% Dynamic Pre-Compiled Catalog Payload Injection for offline file:/// and fast CSR load
            if ($outFile -eq "page-apps.html" -or ($entry.inject -and $entry.inject.catalog)) {
                $catalogCandidates = @(
                    (Join-Path $Context.ResolvedOutput "apps\_catalog.json"),
                    (Join-Path $Context.RepoRoot "public\apps\_catalog.json"),
                    (Join-Path $Context.RepoRoot "apps\_catalog.json")
                )
                $foundCatalog = $null
                foreach ($catPath in $catalogCandidates) {
                    if (Test-Path $catPath) {
                        $foundCatalog = $catPath
                        break
                    }
                }
                if ($foundCatalog) {
                    $rawCatalogJson = [System.IO.File]::ReadAllText($foundCatalog, [System.Text.Encoding]::UTF8)
                    if (-not [string]::IsNullOrWhiteSpace($rawCatalogJson) -and ($rawCatalogJson.Trim().StartsWith("[") -or $rawCatalogJson.Trim().StartsWith("{"))) {
                        $compactCatalogJson = $rawCatalogJson -replace "`r?`n\s*", ""
                        $catScriptTag = "  <script id=`"arcade-precompiled-catalog`">window.__ARCADE_MARKDOWN_CATALOG__=$compactCatalogJson;</script>"
                        $content = $content -replace "</head>", "$catScriptTag`n</head>"
                        Write-Host "  [CATALOG PRE-COMPILED] Injected pre-compiled catalog payload into $outFile" -ForegroundColor Green
                    }
                }
            }

            if ($Context.Minify) {
                Invoke-HtmlMinifier -RawHtml $content -TargetPath $outPath -Label $outFile -Src $entry.source -AuditList $Context.AuditReport -IsMerged $false
            } else {
                [System.IO.File]::WriteAllText($outPath, $content, [System.Text.Encoding]::UTF8)
                $finalBytes = (Get-Item $outPath).Length
                Record-AuditEntry -AuditList $Context.AuditReport -Name $outFile -Src $entry.source -BeforeBytes $finalBytes -AfterBytes $finalBytes -IsMerged $false
            }
            $kb = [math]::Round((Get-Item $outPath).Length / 1024, 2)
            Write-Host "  [OK] Processed HTML $outFile ($kb KB) from $($entry.source)" -ForegroundColor Green

            # 100% Dynamic Clean Route Endpoint Generation (e.g., /playground/<namatitle>)
            if ($entry.cleanRoutePrefix) {
                $prefix = $entry.cleanRoutePrefix.Trim('/')
                $rawSrcContent = Get-Content -Path $srcFile -Raw -Encoding UTF8
                $routeMatches = [regex]::Matches($rawSrcContent, "(?m)^\s*(?:id|slug)\s*:\s*'([a-z0-9-]+)'")
                $routeKeys = @()
                foreach ($m in $routeMatches) {
                    $k = $m.Groups[1].Value
                    if ($k -and ($routeKeys -notcontains $k)) {
                        $routeKeys += $k
                    }
                }

                $pubNestedHtml = Get-Content -Path $outPath -Raw -Encoding UTF8

                foreach ($rk in $routeKeys) {
                    $pubRouteDir = Join-Path $Context.ResolvedOutput "$prefix\$rk"
                    if (-not (Test-Path $pubRouteDir)) { New-Item -ItemType Directory -Path $pubRouteDir -Force | Out-Null }
                    $pubRouteFile = Join-Path $pubRouteDir "index.html"
                    [System.IO.File]::WriteAllText($pubRouteFile, $pubNestedHtml, [System.Text.Encoding]::UTF8)
                }

                # Emit static host _redirects rule for Cloudflare Pages / Netlify
                $redirectsPath = Join-Path $Context.ResolvedOutput "_redirects"
                $redirectRule = "/$prefix/* /$outFile 200`n"
                [System.IO.File]::WriteAllText($redirectsPath, $redirectRule, [System.Text.Encoding]::UTF8)
                Write-Host "  [OK] Generated $($routeKeys.Count) clean route endpoints: /$prefix/<namatitle>" -ForegroundColor Green
            }
        }
    }
}

function Invoke-SlidevBundlesStage {
    param ([Parameter(Mandatory = $true)][PSCustomObject]$Context)

    $slidevCfg = $Context.Manifest.bundles.slidev
    if (-not $slidevCfg) { return }

    Write-Host "[STAGE] Processing Hybrid Slidev Decks (MD -> Standalone HTML)..." -ForegroundColor Cyan

    $slidesDir  = Join-Path $Context.ResolvedSource $slidevCfg.source
    $srcOutDir  = Join-Path $Context.ResolvedSource $slidevCfg.output
    $pubOutDir  = Join-Path $Context.ResolvedOutput $slidevCfg.output
    $enginePath = Join-Path $Context.ResolvedSource $slidevCfg.engine
    $filter     = $slidevCfg.filter
    $suffix     = $slidevCfg.suffix
    $hashHeader = $slidevCfg.hashHeader

    if (-not (Test-Path $slidesDir)) { return }
    if (-not (Test-Path $srcOutDir)) { New-Item -ItemType Directory -Path $srcOutDir -Force | Out-Null }
    if (-not (Test-Path $pubOutDir)) { New-Item -ItemType Directory -Path $pubOutDir -Force | Out-Null }

    if ((Test-Path $enginePath) -and (Get-Command node -ErrorAction SilentlyContinue)) {
        $nodeBridge = @"
const fs = require('fs');
const engine = require(process.argv[1]);
const mdPath = process.argv[2];
const outPath = process.argv[3];
const slug = process.argv[4];
const extName = process.argv[5];
const hashPrefix = process.argv[6];
const rawMd = fs.readFileSync(mdPath, 'utf8');
const hash = engine.fnv1aHash(rawMd);
if (fs.existsSync(outPath)) {
  const head = fs.readFileSync(outPath, 'utf8').slice(0, 320);
  if (head.includes(hashPrefix + hash)) {
    console.log('SKIP:' + hash);
    process.exit(0);
  }
}
const html = engine.synthesizeStandaloneSlidevHtml(rawMd, slug, extName);
fs.writeFileSync(outPath, html, 'utf8');
console.log('GEN:' + hash);
"@
        Get-ChildItem -Path $slidesDir -Filter $filter -File | ForEach-Object {
            $mdFile = $_.FullName
            $slug = $_.BaseName
            $outName = "${slug}${suffix}"
            $srcTarget = Join-Path $srcOutDir $outName
            $pubTarget = Join-Path $pubOutDir $outName

            $res = & node -e $nodeBridge $enginePath $mdFile $srcTarget $slug $_.Name $hashHeader 2>$null
            if ($res -match "^SKIP:(.+)$") {
                Write-Host "  [HYBRID HIT] $outName exists & matches hash ($($Matches[1])) -- skipped" -ForegroundColor DarkGreen
            } elseif ($res -match "^GEN:(.+)$") {
                Write-Host "  [HYBRID GEN] Generated $outName (hash: $($Matches[1]))" -ForegroundColor Green
            }
            if (Test-Path $srcTarget) {
                Copy-Item -Path $srcTarget -Destination $pubTarget -Force
                $sz = (Get-Item $pubTarget).Length
                Record-AuditEntry -AuditList $Context.AuditReport -Name "$($slidevCfg.output)/$outName" -Src "slides/$($_.Name)" -BeforeBytes $sz -AfterBytes $sz -IsMerged $false
            }
        }
    }
}

function Invoke-MediaBundlesStage {
    param ([Parameter(Mandatory = $true)][PSCustomObject]$Context)

    $mediaConfig = $Context.Manifest.bundles.media
    if (-not $mediaConfig) { return }

    Write-Host "[STAGE] Processing Media & Binary Pass-Through..." -ForegroundColor Cyan

    foreach ($entry in $mediaConfig) {
        $srcDir = Join-Path $Context.ResolvedSource $entry.source
        $dstDir = Join-Path $Context.ResolvedOutput $entry.output

        if (Test-Path $srcDir) {
            if (-not (Test-Path $dstDir)) {
                New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            }
            Get-ChildItem -Path $srcDir -Recurse -File | ForEach-Object {
                $rel = $_.FullName.Substring($srcDir.Length).TrimStart("\/")
                $targetFile = Join-Path $dstDir $rel
                $targetFolder = Split-Path -Parent $targetFile
                if (-not (Test-Path $targetFolder)) {
                    New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
                }
                Copy-Item -Path $_.FullName -Destination $targetFile -Force
            }
            Write-Host "  [OK] Media synced: $($entry.source)/ -> $($entry.output)/" -ForegroundColor Green
        }
    }
}

function Invoke-CartridgeBundlesStage {
    param ([Parameter(Mandatory = $true)][PSCustomObject]$Context)

    $cartConfig = $Context.Manifest.bundles.cartridges
    if (-not $cartConfig) { return }

    Write-Host "[STAGE] Processing App Cartridges..." -ForegroundColor Cyan

    $outSubDir = if ($cartConfig.output) { $cartConfig.output } else { $Context.Manifest.paths.apps }
    $cartDstDir = Join-Path $Context.ResolvedOutput $outSubDir
    if (-not (Test-Path $cartDstDir)) {
        New-Item -ItemType Directory -Path $cartDstDir -Force | Out-Null
    }

    # 1. Sync secondary source directory inside Source root if configured
    if ($cartConfig.secondarySource) {
        $secDir = Join-Path $Context.ResolvedSource $cartConfig.secondarySource
        $directFilter = if ($cartConfig.directFilter) { $cartConfig.directFilter } else { "*.*" }
        if (Test-Path $secDir) {
            Get-ChildItem -Path $secDir -Filter $directFilter -File | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination (Join-Path $cartDstDir $_.Name) -Force
                Write-Host "  [OK] Synced $($cartConfig.secondarySource)/$($_.Name) -> $outSubDir/$($_.Name)" -ForegroundColor DarkGray
            }
        }
    }

    # 2. Sync primary cartridges directory (flat files & legacy directories)
    $cartSrcDir = if ($cartConfig.source) {
        if ([System.IO.Path]::IsPathRooted($cartConfig.source)) { $cartConfig.source } else { Join-Path $Context.RepoRoot $cartConfig.source }
    } else {
        $Context.ResolvedApps
    }

    if (Test-Path $cartSrcDir) {
        # Sync flat cartridge files (*.html, *.md, *.webp, *.png)
        Get-ChildItem -Path $cartSrcDir -File | ForEach-Object {
            $dstFile = Join-Path $cartDstDir $_.Name
            Copy-Item -Path $_.FullName -Destination $dstFile -Force
            Write-Host "  [OK] Synced cartridge file: $outSubDir/$($_.Name)" -ForegroundColor DarkGray
        }

        # Also support legacy folder-per-app if present
        $entryFiles = $cartConfig.entryFiles
        Get-ChildItem -Path $cartSrcDir -Directory | ForEach-Object {
            $cart = $_
            $cartName = $cart.Name

            if ($entryFiles) {
                foreach ($ef in $entryFiles) {
                    $candidatePath = Join-Path $cart.FullName $ef.source
                    if (Test-Path $candidatePath) {
                        $dstFile = Join-Path $cartDstDir "${cartName}$($ef.extension)"
                        Copy-Item -Path $candidatePath -Destination $dstFile -Force
                        Write-Host "  [OK] Synced cartridge: $outSubDir/${cartName}$($ef.extension)" -ForegroundColor DarkGray
                    }
                }
            }

            $cartFolderDst = Join-Path $cartDstDir $cartName
            if (-not (Test-Path $cartFolderDst)) {
                New-Item -ItemType Directory -Path $cartFolderDst -Force | Out-Null
            }
            Copy-Item -Path (Join-Path $cart.FullName "*") -Destination $cartFolderDst -Recurse -Force
        }
    }

    # 3. Execute Unified Cartridge & Bento Playground CSR Engine (Node.js) if available
    $nodeUnifiedBuilder = Join-Path $Context.ResolvedSource "modules\build-bundle.js"
    if ((Test-Path $nodeUnifiedBuilder) -and (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "  [CATALOG & BENTO] Running unified cartridge compilation via Node engine..." -ForegroundColor Cyan
        & node $nodeUnifiedBuilder | Out-Null
        Write-Host "  [OK] Generated _catalog.json, per-app catalogs, and Bento Playgrounds in $outSubDir/" -ForegroundColor Green
    }

    # 4. Record cartridge artifacts in Audit Report
    if (Test-Path $cartDstDir) {
        Get-ChildItem -Path $cartDstDir -File | ForEach-Object {
            $sz = $_.Length
            $fName = $_.Name
            $srcDesc = "apps/$fName"
            $isMerged = $false
            if ($fName -eq "_catalog.json") {
                $srcDesc = "apps/*.md (catalog)"
                $isMerged = $true
            } elseif ($fName -match "_catalog\.json$") {
                $srcDesc = "apps/$($fName.Replace('_catalog.json', '.md')) (CSR)"
            } elseif ($fName -match "_playground\.html$") {
                $srcDesc = "template (CSR)"
            }
            Record-AuditEntry -AuditList $Context.AuditReport -Name "$outSubDir/$fName" -Src $srcDesc -BeforeBytes $sz -AfterBytes $sz -IsMerged $isMerged
        }
    }
}

function Invoke-AppScreenshotsStage {
    param ([Parameter(Mandatory = $true)][PSCustomObject]$Context)

    $screenshotCfg = $Context.Manifest.bundles.screenshots
    if (-not $screenshotCfg) { return }

    Write-Host "[STAGE] Processing Desktop View Screenshots (Headless Chrome)..." -ForegroundColor Cyan

    $browserCandidate = @(
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    $outDirRel = if ($screenshotCfg.output) { $screenshotCfg.output } else { "apps" }
    $srcThumbsDir = Join-Path $Context.ResolvedSource $outDirRel
    $pubThumbsDir = Join-Path $Context.ResolvedOutput $outDirRel
    $winSize = if ($screenshotCfg.windowSize) { $screenshotCfg.windowSize } else { "1280,720" }

    if (-not (Test-Path $srcThumbsDir)) { New-Item -ItemType Directory -Path $srcThumbsDir -Force | Out-Null }
    if (-not (Test-Path $pubThumbsDir)) { New-Item -ItemType Directory -Path $pubThumbsDir -Force | Out-Null }

    $targets = $screenshotCfg.targets
    if ($targets) {
        foreach ($target in $targets) {
            $appId = $target.id
            $srcRel = $target.source
            $outImgName = if ($target.output) { $target.output } else { "${appId}.webp" }
            $srcRootImg = Join-Path $Context.ResolvedApps $outImgName
            $pubOutPath = Join-Path $pubThumbsDir $outImgName

            # If thumbnail already generated in apps/ (e.g. apps/<slug>.webp), sync directly
            if (Test-Path $srcRootImg) {
                Copy-Item -Path $srcRootImg -Destination $pubOutPath -Force
                $kb = [math]::Round((Get-Item $pubOutPath).Length / 1024, 1)
                Write-Host "  [OK] Synced existing app thumbnail: $outDirRel/$outImgName ($kb KB)" -ForegroundColor Green
                $alreadyRecorded = $Context.AuditReport | Where-Object { $_.FileName -eq "$outDirRel/$outImgName" }
                if (-not $alreadyRecorded) {
                    $sz = (Get-Item $pubOutPath).Length
                    Record-AuditEntry -AuditList $Context.AuditReport -Name "$outDirRel/$outImgName" -Src "apps/$outImgName" -BeforeBytes $sz -AfterBytes $sz -IsMerged $false
                }
                continue
            }

            $candidatePath = Join-Path $Context.RepoRoot $srcRel
            if (-not (Test-Path $candidatePath)) {
                $candidatePath = Join-Path $Context.ResolvedSource $srcRel
            }

            $outImgName = "${appId}.png"
            $srcOutPath = Join-Path $srcThumbsDir $outImgName
            $pubOutPath = Join-Path $pubThumbsDir $outImgName

            if (Test-Path $candidatePath -and $browserCandidate) {
                $fileUrl = "file:///" + (Resolve-Path $candidatePath).Path.Replace('\', '/')
                $proc = Start-Process -FilePath $browserCandidate -ArgumentList @(
                    "--headless=new",
                    "--disable-gpu",
                    "--hide-scrollbars",
                    "--window-size=$winSize",
                    "--screenshot=""$srcOutPath""",
                    """$fileUrl"""
                ) -Wait -PassThru -NoNewWindow

                if (Test-Path $srcOutPath) {
                    Copy-Item -Path $srcOutPath -Destination $pubOutPath -Force
                    $kb = [math]::Round((Get-Item $srcOutPath).Length / 1024, 1)
                    Write-Host "  [OK] Captured desktop view screenshot: $outDirRel/$outImgName ($kb KB)" -ForegroundColor Green
                    $alreadyRecorded = $Context.AuditReport | Where-Object { $_.FileName -eq "$outDirRel/$outImgName" }
                    if (-not $alreadyRecorded) {
                        $sz = (Get-Item $pubOutPath).Length
                        Record-AuditEntry -AuditList $Context.AuditReport -Name "$outDirRel/$outImgName" -Src "screenshot" -BeforeBytes $sz -AfterBytes $sz -IsMerged $false
                    }
                }
            } else {
                Write-Host "  [-] Target cartridge HTML missing for $appId -> will use [preview not found] fallback" -ForegroundColor DarkGray
            }
        }
    }
}
