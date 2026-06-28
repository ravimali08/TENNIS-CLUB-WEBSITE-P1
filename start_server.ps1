$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Prefixes.Add("http://127.0.0.1:$port/")
try {
    $listener.Start()
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "  Ace Reserve Tennis Club Local Dev Server" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "Server started at: http://localhost:$port/ and http://127.0.0.1:$port/" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C in this terminal to stop the server." -ForegroundColor Yellow
} catch {
    Write-Error "Failed to start server: $_"
    exit 1
}

$projectRoot = "C:\Users\sujal\Documents\antigravity\blissful-hertz"

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $rawPath = $request.Url.LocalPath
        $cleanPath = $rawPath.TrimStart('/')
        
        # Default to index.html
        if ($cleanPath -eq "") {
            $cleanPath = "index.html"
        }
        
        $filePath = Join-Path $projectRoot $cleanPath
        
        # If file does not exist and has no file extension, serve index.html (SPA fallback)
        if (-not (Test-Path $filePath) -and -not (Split-Path $filePath -Leaf).Contains(".")) {
            $filePath = Join-Path $projectRoot "index.html"
        }
        
        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = switch ($ext) {
                ".html" { "text/html; charset=utf-8" }
                ".js"   { "application/javascript; charset=utf-8" }
                ".css"  { "text/css; charset=utf-8" }
                ".svg"  { "image/svg+xml" }
                ".png"  { "image/png" }
                ".jpg"  { "image/jpeg" }
                ".jpeg" { "image/jpeg" }
                ".mp4"  { "video/mp4" }
                ".json" { "application/json; charset=utf-8" }
                default { "application/octet-stream" }
            }
            
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.Headers.Add("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
            $response.Headers.Add("Pragma", "no-cache")
            $response.Headers.Add("Expires", "0")
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $bytes = [System.Text.Encoding]::UTF8.GetBytes("File Not Found")
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        }
        $response.Close()
    } catch {
        Write-Host "Error in loop: $_" -ForegroundColor Red
        if ($null -ne $response) {
            try { $response.Close() } catch {}
        }
    }
}
