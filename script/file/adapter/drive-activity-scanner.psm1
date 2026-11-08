<#
.SYNOPSIS
    Engine: Dynamic System Drives Discovery & Interactive Directory Tree Scanner
.DESCRIPTION
    Enumerates system drives (C:, D:, E:, etc.) dynamically without hardcoded machine letters,
    providing lazy-loaded hierarchical directory inspection and open-file mapping.
#>

function Get-SystemDrivesOverview {
    [CmdletBinding()]
    param()

    $drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.IsReady }
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($d in $drives) {
        $totalGB = [Math]::Round($d.TotalSize / 1GB, 1)
        $freeGB  = [Math]::Round($d.AvailableFreeSpace / 1GB, 1)
        $usedGB  = [Math]::Round(($d.TotalSize - $d.AvailableFreeSpace) / 1GB, 1)
        $percentFree = [Math]::Round(($d.AvailableFreeSpace / $d.TotalSize) * 100, 1)

        $results.Add([PSCustomObject]@{
            Name        = $d.Name
            DriveLetter = $d.Name.TrimEnd('\')
            VolumeLabel = if ($d.VolumeLabel) { $d.VolumeLabel } else { "Local Disk" }
            DriveType   = $d.DriveType.ToString()
            TotalGB     = $totalGB
            FreeGB      = $freeGB
            UsedGB      = $usedGB
            PercentFree = $percentFree
            RootPath    = $d.RootDirectory.FullName
        })
    }
    return ,$results.ToArray()
}

function Get-DirectoryTreeNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [int]$MaxDepth = 1
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return $null }

    $dirs = Get-ChildItem -LiteralPath $Path -Directory -ErrorAction SilentlyContinue | Select-Object -First 30
    $files = Get-ChildItem -LiteralPath $Path -File -ErrorAction SilentlyContinue | Select-Object -First 30

    return [PSCustomObject]@{
        Path        = $Path
        Name        = [System.IO.Path]::GetFileName($Path)
        Directories = $dirs
        Files       = $files
    }
}

Export-ModuleMember -Function Get-SystemDrivesOverview, Get-DirectoryTreeNode
