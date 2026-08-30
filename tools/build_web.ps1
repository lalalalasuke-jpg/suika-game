# Web（HTML5）へ書き出して build/web/ に出す。COOP/COEP 用の _headers も置く。
$ErrorActionPreference = "Stop"

$godot = "C:\Users\PC_User\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
$proj = Split-Path $PSScriptRoot -Parent
$buildDir = Join-Path $proj "build"
$out = Join-Path $buildDir "web"

# 出力を毎回まっさらに（前回の残骸を持ち越さない）
if (Test-Path $buildDir) { Remove-Item $buildDir -Recurse -Force }
New-Item -ItemType Directory -Force $out | Out-Null
# Godot のリソーススキャナに build/ を無視させる（export 出力の PNG などを取り込ませない）
New-Item -ItemType File -Force (Join-Path $buildDir ".gdignore") | Out-Null

& $godot --headless --path $proj --export-release "Web" "build/web/index.html"
if ($LASTEXITCODE -ne 0) { throw "エクスポート失敗 (exit $LASTEXITCODE)。テンプレート未インストールかも。DEPLOY.md 参照" }

# Cloudflare Pages が読む _headers（cross-origin isolation。Godot 4 Web に必須級）
@"
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
"@ | Set-Content -NoNewline -Encoding utf8 (Join-Path $out "_headers")

Write-Host "done -> $out"
Get-ChildItem $out | Select-Object Name, Length