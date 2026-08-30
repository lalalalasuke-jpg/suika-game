# build/web/ の中身を gh-pages ブランチ（orphan）へ force-push する。
# GitHub の Settings > Pages で Source = gh-pages / (root) にしておくこと。
$ErrorActionPreference = "Stop"

$proj = Split-Path $PSScriptRoot -Parent
$web = Join-Path $proj "build\web"
if (-not (Test-Path (Join-Path $web "index.html"))) { throw "先に tools\build_web.ps1 を実行して" }

$wt = Join-Path $proj ".gh-pages-wt"
if (Test-Path $wt) { git -C $proj worktree remove --force $wt }

$hasBranch = git -C $proj ls-remote --heads origin gh-pages
if ($hasBranch) {
	git -C $proj fetch -q origin gh-pages
	git -C $proj worktree add -q $wt gh-pages
} else {
	git -C $proj worktree add -q --detach $wt
	git -C $wt switch -q --orphan gh-pages
}

# 中身を build/web の内容で総入れ替え（.git は残す）
Get-ChildItem $wt -Force | Where-Object { $_.Name -ne ".git" } | Remove-Item -Recurse -Force
Copy-Item (Join-Path $web "*") $wt -Recurse -Force

git -C $wt add -A
git -C $wt commit -q -m ("deploy " + (Get-Date -Format "yyyy-MM-dd HH:mm"))
git -C $wt push -f -q origin gh-pages
git -C $proj worktree remove --force $wt

Write-Host "pushed -> gh-pages"
Write-Host "https://lalalalasuke-jpg.github.io/suika-game/"
