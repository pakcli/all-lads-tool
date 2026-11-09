<#
.SYNOPSIS
    Universal Standalone Decompiler Engine Adapter (Context: common)
.DESCRIPTION
    Conforms strictly to Brief v01-04-00.
    Losslessly unbundles standalone compiled scripts back into modular
    adapter/*.psm1 files and reconstructed modular runner scripts.
#>

function Invoke-ScriptDecompilation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$StandaloneScriptPath,

        [Parameter(Mandatory = $false)]
        [string]$TargetDir,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    if (-not (Test-Path -LiteralPath $StandaloneScriptPath)) {
        throw "Standalone script not found: $StandaloneScriptPath"
    }

    $sourceFile = Get-Item -LiteralPath $StandaloneScriptPath
    $sourceText = [System.IO.File]::ReadAllText($StandaloneScriptPath, [System.Text.Encoding]::UTF8)

    if ([string]::IsNullOrWhiteSpace($TargetDir)) {
        $TargetDir = $sourceFile.DirectoryName
    }

    $adapterOutDir = Join-Path $TargetDir "adapter"
    $extractedAdapters = [System.Collections.Generic.List[string]]::new()

    # Pattern for bounded standalone modules
    $moduleRegex = [regex]'# \[STANDALONE-MODULE:\s*([^\]]+)\]\r?\n& \{\r?\n([\s\S]*?)\r?\n\}\r?\n# \[/STANDALONE-MODULE:\s*\1\]'
    $matches = $moduleRegex.Matches($sourceText)

    foreach ($m in $matches) {
        $moduleRelPath = $m.Groups[1].Value.Trim()
        $moduleCode = $m.Groups[2].Value
        $moduleFileName = [System.IO.Path]::GetFileName($moduleRelPath)
        $extractedAdapters.Add($moduleFileName)

        if (-not $DryRun) {
            if (-not (Test-Path -LiteralPath $adapterOutDir)) {
                New-Item -Path $adapterOutDir -ItemType Directory -Force | Out-Null
            }
            $targetModulePath = Join-Path $adapterOutDir $moduleFileName
            [System.IO.File]::WriteAllText($targetModulePath, $moduleCode, [System.Text.Encoding]::UTF8)
        }
    }

    # Extract runner body
    $runnerRegex = [regex]'# \[RUNNER-BODY:\s*([^\]]+)\]\r?\n([\s\S]*?)\r?\n# \[/RUNNER-BODY:\s*\1\]'
    $runnerMatch = $runnerRegex.Match($sourceText)
    $reconstructedRunner = ""

    if ($runnerMatch.Success) {
        $runnerName = $runnerMatch.Groups[1].Value.Trim()
        $rawRunner = $runnerMatch.Groups[2].Value

        # Restore compiled-inlined lines
        $runnerLines = $rawRunner -split "\r?\n"
        $cleanedLines = [System.Collections.Generic.List[string]]::new()
        foreach ($rl in $runnerLines) {
            if ($rl -match '^# \[COMPILED-INLINED\] (.*)') {
                $cleanedLines.Add($Matches[1])
            } else {
                $cleanedLines.Add($rl)
            }
        }
        $reconstructedRunner = [string]::Join("`r`n", $cleanedLines)

        if (-not $DryRun) {
            $runnerTargetPath = Join-Path $TargetDir $runnerName
            [System.IO.File]::WriteAllText($runnerTargetPath, $reconstructedRunner, [System.Text.Encoding]::UTF8)
        }
    }

    return [PSCustomObject]@{
        Status            = if ($DryRun) { "DryRun" } else { "Success" }
        SourceFile        = $StandaloneScriptPath
        TargetDirectory   = $TargetDir
        ExtractedAdapters = $extractedAdapters.ToArray()
        HasRunnerBody     = $runnerMatch.Success
    }
}

Export-ModuleMember -Function @(
    "Invoke-ScriptDecompilation"
)
