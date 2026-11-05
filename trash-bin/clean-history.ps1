$jsonPath = 'E:\proj\all-lads-tool\script\file\detector-clipboard-4-mode.json'
$raw = Get-Content $jsonPath -Raw -Encoding UTF8
$list = $raw | ConvertFrom-Json
$clean = New-Object System.Collections.ArrayList

foreach ($it in $list) {
    $t = [string]$it.Mode1_Text
    if ($t -like '*[string]@*' -or $t -like '@{*' -or $t -like '*Id=*Timestamp=*') {
        continue
    }
    $t = $t.Trim('"').Trim("'")
    $it.Mode1_Text = $t
    $clean.Add($it) | Out-Null
}

$clean | ConvertTo-Json -Depth 5 | Set-Content $jsonPath -Encoding UTF8
Write-Host "Cleaned items count: $($clean.Count)"
