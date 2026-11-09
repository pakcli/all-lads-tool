<#
.SYNOPSIS
    Universal Standalone Compiler Engine Adapter (Context: common)
.DESCRIPTION
    Conforms strictly to Brief v01-04-00.
    Inlines modular adapter dependencies into a single portable executable
    using standardized boundary markers (# [STANDALONE-MODULE: <path>]).
#>

function Invoke-ScriptCompilation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolScriptPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputDir,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    if (-not (Test-Path -LiteralPath $ToolScriptPath)) {
        throw "Tool script not found: $ToolScriptPath"
    }

    $toolFile = Get-Item -LiteralPath $ToolScriptPath
    $toolDir = $toolFile.DirectoryName
    $adapterDir = Join-Path $toolDir "adapter"
    $scriptName = $toolFile.Name
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($scriptName)

    # Resolve target output directory
    if ([string]::IsNullOrWhiteSpace($OutputDir)) {
        $repoRoot = Split-Path -Path (Split-Path -Path $toolDir -Parent) -Parent
        $contextName = (Get-Item -LiteralPath $toolDir).Name
        $OutputDir = Join-Path (Join-Path $repoRoot "dist") $contextName
    }

    $outTargetFile = Join-Path $OutputDir $scriptName

    $lines = [System.IO.File]::ReadAllLines($ToolScriptPath, [System.Text.Encoding]::UTF8)
    $compiledLines = [System.Collections.Generic.List[string]]::new()

    $headerComment = @"
<#
================================================================================
  STANDALONE COMPILED EXECUTABLE: $scriptName
  Generated via: script/common/compiler.ps1
  Architecture: Brief v01-04-00 Universal 2-Way Distribution Standard
  Note: This file is compiled for self-contained execution.
================================================================================
#>
"@
    $compiledLines.Add($headerComment)

    # Discover and inline adapters
    $inlinedModules = [System.Collections.Generic.List[string]]::new()
    if (Test-Path -LiteralPath $adapterDir) {
        $adapterFiles = Get-ChildItem -LiteralPath $adapterDir -Filter "*.psm1" -File
        foreach ($af in $adapterFiles) {
            $relPath = "adapter/$($af.Name)"
            $inlinedModules.Add($af.Name)
            $moduleContent = [System.IO.File]::ReadAllText($af.FullName, [System.Text.Encoding]::UTF8)

            $compiledLines.Add("# [STANDALONE-MODULE: $relPath]")
            $compiledLines.Add("& {")
            $compiledLines.Add($moduleContent)
            $compiledLines.Add("}")
            $compiledLines.Add("# [/STANDALONE-MODULE: $relPath]")
            $compiledLines.Add("")
        }
    }

    # Append runner body while sanitizing local Import-Module calls
    $compiledLines.Add("# [RUNNER-BODY: $scriptName]")
    foreach ($line in $lines) {
        if ($line -match '^\s*Import-Module\s+.*adapter\\.*' -or $line -match '^\s*\$adapterPath\s*=.*Join-Path.*adapter.*') {
            $compiledLines.Add("# [COMPILED-INLINED] $line")
        } else {
            $compiledLines.Add($line)
        }
    }
    $compiledLines.Add("# [/RUNNER-BODY: $scriptName]")

    $compiledContent = [string]::Join("`r`n", $compiledLines)

    if ($DryRun) {
        return [PSCustomObject]@{
            Status         = "DryRun"
            ToolScript     = $ToolScriptPath
            TargetFile     = $outTargetFile
            InlinedModules = $inlinedModules.ToArray()
            TotalLines     = $compiledLines.Count
            ContentPreview = $compiledContent.Substring(0, [Math]::Min(500, $compiledContent.Length))
        }
    }

    if (-not (Test-Path -LiteralPath $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($outTargetFile, $compiledContent, [System.Text.Encoding]::UTF8)

    return [PSCustomObject]@{
        Status         = "Success"
        ToolScript     = $ToolScriptPath
        TargetFile     = $outTargetFile
        InlinedModules = $inlinedModules.ToArray()
        TotalLines     = $compiledLines.Count
    }
}

Export-ModuleMember -Function @(
    "Invoke-ScriptCompilation"
)
