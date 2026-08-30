# Web（HTML5）へ書き出して build/web/ に出す。
# Cloudflare Pages の 1ファイル25MB制限のため index.wasm を gzip 圧縮し、
# _headers で Content-Encoding: gzip を指定する（ブラウザが透過解凍）。
$ErrorActionPreference = "Stop"

$godot = "C:\Users\PC_User\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
$py = "C:\Users\PC_User\.local\bin\python3.12.exe"
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

# index.wasm を gzip 圧縮（ファイル名は据え置き、中身を .gz バイトに差し替え）
& $py -c "import gzip,sys; p=sys.argv[1]; d=open(p,'rb').read(); open(p,'wb').write(gzip.compress(d,9))" (Join-Path $out "index.wasm")

# Cloudflare Pages 用 _headers
@"
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp

/index.wasm
  Content-Encoding: gzip
  Content-Type: application/wasm
"@ | Set-Content -NoNewline -Encoding utf8 (Join-Path $out "_headers")

Write-Host "done -> $out"
Get-ChildItem $out | Select-Object Name, @{n="Size";e={"{0:N0} B" -f $_.Length}}