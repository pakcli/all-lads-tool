# ==============================================================================
# Bimbel Bintang Prestasi - Local Web Server Script
# Serves static files on Port 8080 accessible from any device on local Wi-Fi
# ==============================================================================

$port = 8080

# 1. Dapatkan IP Address Lokal (IPv4)
$ipAddresses = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
    Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254*" -and $_.IPAddress -notlike "172.*" } | 
    Select-Object -ExpandProperty IPAddress

if (-not $ipAddresses) {
    # Fallback method jika Get-NetIPAddress kosong
    $ipAddresses = [System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName()) | 
        Where-Object { $_.AddressFamily.ToString() -eq "InterNetwork" -and $_.IPAddressToString -ne "127.0.0.1" } | 
        Select-Object -ExpandProperty IPAddressToString
}

Clear-Host
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  BIMBEL BINTANG PRESTASI - LOCAL WEB SERVER" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host " Silakan buka URL berikut di browser Anda:" -ForegroundColor Yellow
Write-Host " [PC / Localhost] : http://localhost:$port" -ForegroundColor Cyan

if ($ipAddresses) {
    Write-Host " [HP / Tablet / Device Lain di Wi-Fi yang Sama]:" -ForegroundColor Yellow
    foreach ($ip in $ipAddresses) {
        Write-Host "    -> http://$ip`:$port" -ForegroundColor Green
    }
} else {
    Write-Host " [!] IP Wi-Fi tidak terdeteksi secara otomatis." -ForegroundColor Red
}

Write-Host ""
Write-Host " Tekan Ctrl + C untuk menghentikan server." -ForegroundColor Gray
Write-Host "------------------------------------------------------------" -ForegroundColor Gray
Write-Host ""

# 2. Jalankan HTTP Server (Python Multi-Threaded -> npx -> PowerShell HttpListener)
if (Get-Command python -ErrorAction SilentlyContinue) {
    python server.py $port
} elseif (Get-Command npx -ErrorAction SilentlyContinue) {
    Write-Host "> Memulai server dengan npx serve..." -ForegroundColor Green
    npx -y serve -l $port --listen 0.0.0.0
} else {
    Write-Host "> Memulai server bawaan PowerShell di 0.0.0.0:$port..." -ForegroundColor Green
    
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://*:$port/")
    
    try {
        $listener.Start()
    } catch {
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://+:$port/")
        $listener.Start()
    }

    $mimeTypes = @{
        ".html" = "text/html; charset=utf-8"
        ".css"  = "text/css"
        ".js"   = "text/javascript"
        ".json" = "application/json"
        ".webp" = "image/webp"
        ".png"  = "image/png"
        ".jpg"  = "image/jpeg"
        ".jpeg" = "image/jpeg"
        ".svg"  = "image/svg+xml"
        ".ico"  = "image/x-icon"
    }

    $root = (Get-Location).Path

    try {
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response

            $urlPath = [System.Uri]::UnescapeDataString($request.Url.LocalPath)
            if ($urlPath -eq "/") { $urlPath = "/index.html" }

            $relPath = $urlPath.TrimStart("/")
            $filePath = Join-Path $root $relPath

            if (Test-Path $filePath -PathType Container) {
                $filePath = Join-Path $filePath "index.html"
            } elseif (-not (Test-Path $filePath) -and (Test-Path "$filePath.html")) {
                $filePath = "$filePath.html"
            }

            if (Test-Path $filePath -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                if ($mimeTypes.ContainsKey($ext)) {
                    $response.ContentType = $mimeTypes[$ext]
                } else {
                    $response.ContentType = "application/octet-stream"
                }

                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
                $response.StatusCode = 200
            } else {
                $response.StatusCode = 404
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("404 - File Not Found")
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            $response.Close()
        }
    } finally {
        $listener.Stop()
    }
}
