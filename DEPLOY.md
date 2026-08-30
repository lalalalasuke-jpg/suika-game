# スイカゲームもどき — スマホ配布手順

Godot で **Web（HTML5）書き出し** → **Cloudflare Pages** に置いて、**Cloudflare Access** で自分だけ見られるようにする。
（OPCG シムと同じ構成。共通ノウハウは memory の `web-game-deploy` 参照）

## 前提

- **書き出しは標準版 Godot（`Godot_v4.7.2-stable_win64.exe`）を使う**。mono 版は Web 書き出しが実質使えないため。
  このプロジェクトは GDScript のみなので標準版で普通に開ける。
- `export_presets.cfg`（`Web` プリセット）はリポジトリにコミット済み。
- 出力先 `build/web/` は `.gitignore` 済み。

## 1. エクスポートテンプレートを入れる（初回のみ）

必要ファイル: `%APPDATA%\Godot\export_templates\4.7.2.stable\web_nothreads_{debug,release}.zip` など。

### 方法A: エディタからダウンロード（速いが proxy 次第）

1. 標準版 Godot でこのプロジェクトを開く
2. エディタ設定 → `Network > TLS > Certificate Bundle Override` に
   `C:\Users\PC_User\.config\certs\win-ca-bundle.pem` を設定（この PC は HTTPS が再署名されるため）
3. メニュー `エディタ > エクスポートテンプレートの管理` → `ダウンロードしてインストール`

### 方法B: 手動ダウンロード（確実）

1. ブラウザで取得（ブラウザは社内 proxy の証明書を信頼済み）:
   `https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz`
2. `.tpz` は zip。`tools/install_templates.ps1` に渡すと
   `%APPDATA%\Godot\export_templates\4.7.2.stable\` へ展開する

## 2. Web に書き出す

```
& "C:\Users\PC_User\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" `
  --headless --path "C:\Users\PC_User\projects\suika-game" `
  --export-release "Web" "build/web/index.html"
```

`build/web/` に `index.html` / `*.wasm` / `*.pck` / `*.js` / `*.png` / `*.webmanifest` / `*.service.worker.js` などが出る。

## 3. Cloudflare Pages に置く

1. [dash.cloudflare.com](https://dash.cloudflare.com) → Workers & Pages → Create → Pages → **Direct Upload**
2. プロジェクト名（例 `suika`）→ `build/web/` の中身をまるごとドラッグ
3. 本番 URL: `https://suika.pages.dev`（名前による）

### 注意: クロスオリジン分離ヘッダ

Godot 4 の Web は `SharedArrayBuffer` を使うため、**COOP/COEP ヘッダ**が要る。
`build/web/` に `_headers` ファイルを置く（Cloudflare Pages が読む）:

```
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
```

（`tools/build_web.ps1` が書き出し後に自動で置く）

## 4. Cloudflare Access で自分だけに制限

OPCG シムと同じ。Zero Trust チーム `gentle-union-1169`:

1. Zero Trust → Access → Applications → Add an application → Self-hosted and private → **Public DNS** タブ
2. Destination = `suika.pages.dev`
3. ポリシー: Action=Allow / Include > Emails = 自分の gmail ＋ スマホで使うアドレス
4. ログインは One-time PIN、Session Duration 1 month 推奨

## 5. スマホで開く → ホーム画面に追加

PWA 有効で書き出してるので、ホーム画面に追加すると単体アプリっぽく起動する。

## 更新のたび

```
# 1. 書き出し（build_web.ps1 が _headers も置く）
tools\build_web.ps1
# 2. Cloudflare ダッシュ → suika プロジェクト → Create deployment → build/web/ を再アップロード
```
