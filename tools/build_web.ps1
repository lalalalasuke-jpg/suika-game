# Web（HTML5）へ書き出して build/web/ に出す。COOP/COEP 用の _headers も置く。
$ErrorActionPreference = "Stop"

$godot = "C:\Users\PC_User\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
$proj = Split-Path $PSScriptRoot -Parent
$out = Join-Path $proj "build\web"

New-Item -ItemType Directory -Force $out | Out-Null
& $godot --headless --path $proj --export-release "Web" "build/web/index.html"
if ($LASTEXITCODE -ne 0) { throw "エクスポート失敗 (exit $LASTEXITCODE)。テンプレート未インストールかも。DEPLOY.md 参照" }

# Cloudflare Pages が読む _headers（cross-origin isolation。Godot 4 Web に必須）
@"
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
"@ | Set-Content -NoNewline -Encoding utf8 (Join-Path $out "_headers")

Write-Host "done -> $out"
Get-ChildItem $out | Select-Object Name, Length
