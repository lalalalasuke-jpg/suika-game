# スイカゲーム — 配布メモ

**本番: <https://lalalalasuke-jpg.github.io/suika-game/>**

配信は **GitHub Pages**（リポジトリは public）。`main` に push すると **GitHub Actions が自動でビルド＆デプロイ**する。
共通ノウハウは memory の `web-game-deploy` も参照。

## 自動デプロイ（通常はこれだけ）

`main` に push → `.github/workflows/deploy.yml` が動く:

1. Ubuntu ランナーで Godot 4.7.2（標準版）＋ export templates を取得
2. `godot --headless --export-release "Web" build/web/index.html`
3. `.nojekyll` と `<meta name="robots" content="noindex">` を付与
4. `actions/deploy-pages` で GitHub Pages に反映（Pages の Source は "GitHub Actions"）

数分で本番反映。進捗は GitHub の **Actions** タブ。手動再実行は Actions → "Build & Deploy (Web)" → **Run workflow**。

→ **出先でスマホからコードを直して push すれば、PC を触らず本番更新できる。**

## ローカルで確認したいとき

```powershell
tools\build_web.ps1        # build/web/ に書き出し（初回は下の「テンプレート」が必要）
python tools\serve_web.py  # http://127.0.0.1:8099 で確認
```

### エクスポートテンプレート（ローカルの初回のみ）

必要ファイル: `%APPDATA%\Godot\export_templates\4.7.2.stable\web_nothreads_{debug,release}.zip` など。
（CI 側は毎回ランナーに取得するので不要）

1. ブラウザで取得（この PC は HTTPS が proxy 再署名されるためブラウザ推奨）:
   `https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz`
2. `tools\install_templates.ps1 -Tpz <落としたパス>` で `%APPDATA%\Godot\export_templates\4.7.2.stable\` へ展開

## 前提・ハマりどころ

- **書き出しは標準版 Godot**（`Godot_v4.7.2-stable_win64.exe` / CI は linux 版）。mono 版は Web 書き出し不可。本プロジェクトは GDScript のみなので標準版で開ける。
- スレッド無効ビルド（`export_presets.cfg` の `thread_support=false`）なので **COOP/COEP ヘッダは不要**。GitHub Pages はヘッダを付けられないが問題なし。
- **なぜ Cloudflare Pages をやめたか**: `_headers` で `Content-Encoding` を設定できず、25MB 制限（`index.wasm` は約38MB）を gzip で回避できなかった。GitHub Pages は 1ファイル100MBまで＝素の wasm でOK。
- GitHub Pages 無料プランは **public リポジトリのみ**。`suika-game` は public。
- UI 文言は ASCII（Godot 標準フォントに日本語グリフが無く Web で豆腐になる）。日本語フォント同梱は将来の課題。

## スマホで遊ぶ

本番 URL を開く → **ホーム画面に追加**（PWA、`Suika Game` のラベルで単体アプリっぽく起動）。2回目以降はオフラインでも起動（Service Worker）。
