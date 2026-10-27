$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
$candidates = @($env:FLUTTER_ROOT, 'F:\flutter_windows_3.47.4-stable\flutter')
if ($flutterCommand) {
    $candidates = @((Split-Path -Parent (Split-Path -Parent $flutterCommand.Source))) + $candidates
}
$flutterRoot = $candidates | Where-Object {
    $_ -and (Test-Path -LiteralPath (Join-Path $_ 'bin\cache\flutter_tools.snapshot'))
} | Select-Object -First 1
if (!$flutterRoot) {
    throw 'Flutter was not found. Install Flutter and add its bin directory to PATH.'
}
$dartExecutable = Join-Path $flutterRoot 'bin\cache\dart-sdk\bin\dart.exe'
$flutterSnapshot = Join-Path $flutterRoot 'bin\cache\flutter_tools.snapshot'
& $dartExecutable $flutterSnapshot pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $dartExecutable $flutterSnapshot run -d chrome --web-hostname 127.0.0.1 --web-port 5184
exit $LASTEXITCODE
