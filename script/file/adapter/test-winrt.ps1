try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
    [Windows.ApplicationModel.DataTransfer.Clipboard, Windows.ApplicationModel.DataTransfer, ContentType = WindowsRuntime] | Out-Null
    $op = [Windows.ApplicationModel.DataTransfer.Clipboard]::GetHistoryItemsAsync()
    $task = $asTaskGeneric.MakeGenericMethod([Windows.ApplicationModel.DataTransfer.ClipboardHistoryItemsResult]).Invoke($null, @($op))
    $task.Wait()
    $result = $task.Result
    Write-Host "WinRT Status: $($result.Status) | Items: $($result.Items.Count)"
} catch {
    Write-Host "WinRT Error: $($_.Exception.Message)"
}
