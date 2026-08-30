# Web（HTML5）へ書き出して build/web/ に出す（GitHub Pages 配布向け）。
# GitHub Pages は 1ファイル100MBまで＝gzip 不要。ヘッダ設定は不可だが
# スレッド無効ビルドなので COOP/COEP は不要。
$ErrorActionPreference = "Stop"

$godot = "C:\Users\PC_User\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
$proj = Split-Path $PSScriptRoot -Parent
$buildDir = Join-Path $proj "build"
$out = Join-Path $buildDir "web"

# 出力を毎回まっさらに
if (Test-Path $buildDir) { Remove-Item $buildDir -Recurse -Force }
New-Item -ItemType Directory -Force $out | Out-Null
# Godot のリソーススキャナに build/ を無視させる
New-Item -ItemType File -Force (Join-Path $buildDir ".gdignore") | Out-Null

& $godot --headless --path $proj --export-release "Web" "build/web/index.html"
if ($LASTEXITCODE -ne 0) { throw "エクスポート失敗 (exit $LASTEXITCODE)。DEPLOY.md 参照" }

# GitHub Pages: Jekyll 処理を無効化（_ 始まりファイル対策）
New-Item -ItemType File -Force (Join-Path $out ".nojekyll") | Out-Null

# 検索避け（GitHub Pages はヘッダを付けられないので meta で）
$idx = Join-Path $out "index.html"
(Get-Content $idx -Raw) -replace '</head>', "  <meta name=`"robots`" content=`"noindex`">`n</head>" |
	Set-Content -NoNewline -Encoding utf8 $idx

Write-Host "done -> $out"
Get-ChildItem $out -Force | Select-Object Name, @{n="Size";e={"{0:N0}" -f $_.Length}}