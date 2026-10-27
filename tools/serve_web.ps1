param([int]$Port = 5184)
$ErrorActionPreference = 'Stop'
$webRoot = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $PSScriptRoot) 'build\web'))
if (!(Test-Path -LiteralPath (Join-Path $webRoot 'index.html'))) {
    throw 'Run flutter build web --release --no-web-resources-cdn first.'
}
$server = [Net.HttpListener]::new()
$server.Prefixes.Add("http://127.0.0.1:$Port/")
$server.Start()
Write-Host "Open http://127.0.0.1:$Port/ . Leave this window open. Ctrl+C to stop."
$types = @{ '.html'='text/html; charset=utf-8'; '.js'='application/javascript'; '.json'='application/json'; '.wasm'='application/wasm'; '.css'='text/css'; '.png'='image/png'; '.svg'='image/svg+xml'; '.ttf'='font/ttf'; '.ico'='image/x-icon' }
try {
    while ($server.IsListening) {
        $context = $server.GetContext()
        try {
            $relative = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath).TrimStart('/')
            if (!$relative) { $relative = 'index.html' }
            $file = [IO.Path]::GetFullPath((Join-Path $webRoot $relative))
            if (!$file.StartsWith($webRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
                $context.Response.StatusCode = 404
            } else {
                if (!(Test-Path -LiteralPath $file -PathType Leaf)) {
                    $navigation = ![IO.Path]::HasExtension($relative) -or $context.Request.Headers['Accept'] -like '*text/html*'
                    if (!$navigation) { $context.Response.StatusCode = 404; continue }
                    $file = Join-Path $webRoot 'index.html'
                }
                $extension = [IO.Path]::GetExtension($file)
                $context.Response.ContentType = if ($types.ContainsKey($extension)) { $types[$extension] } else { 'application/octet-stream' }
                $bytes = [IO.File]::ReadAllBytes($file)
                $context.Response.ContentLength64 = $bytes.Length
                if ($context.Request.HttpMethod -ne 'HEAD') {
                    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
                }
            }
        } catch { $context.Response.StatusCode = 500 }
        finally { $context.Response.Close() }
    }
} finally { $server.Stop(); $server.Close() }
