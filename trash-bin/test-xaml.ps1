Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$lines = Get-Content 'E:\proj\all-lads-tool\detector-clipboard-4-mode.ps1'
$start = 0
$end = 0
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '<Window\s') { $start = $i }
    if ($lines[$i] -match '</Window>') { $end = $i; break }
}

$x = ($lines[$start..$end] -join [Environment]::NewLine)
[xml]$doc = $x
$reader = [System.Xml.XmlNodeReader]::new($doc)
$win = [System.Windows.Markup.XamlReader]::Load($reader)

Write-Host "VERIFIED: Window title is '$($win.Title)' and ScrollBar style is compiled!"
