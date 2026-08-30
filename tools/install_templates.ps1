# .tpz（Godot エクスポートテンプレート）を %APPDATA%\Godot\export_templates\4.7.2.stable\ へ展開する
# 使い方: tools\install_templates.ps1 -Tpz "C:\path\to\Godot_v4.7.2-stable_export_templates.tpz"
param([Parameter(Mandatory)][string]$Tpz)
$ErrorActionPreference = "Stop"

$dest = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable"
$tmp = Join-Path $env:TEMP ("godot_tpl_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force $tmp | Out-Null

$zip = Join-Path $tmp "t.zip"
Copy-Item $Tpz $zip
Expand-Archive $zip -DestinationPath $tmp -Force

$src = Join-Path $tmp "templates"
if (-not (Test-Path $src)) { throw "'.tpz' の中に templates/ が見つからない: $Tpz" }

New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item (Join-Path $src "*") $dest -Recurse -Force
Remove-Item $tmp -Recurse -Force

Get-ChildItem $dest | Select-Object Name
Write-Host "installed -> $dest"
