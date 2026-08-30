"""build/web/ をローカル確認する簡易サーバー。
Cloudflare の _headers 相当（COOP/COEP ＋ index.wasm の Content-Encoding: gzip）を付ける。
使い方: python tools/serve_web.py  ->  http://127.0.0.1:8099
"""
import http.server
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "build", "web")


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=os.path.abspath(ROOT), **kw)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        if self.path.endswith("index.wasm"):
            self.send_header("Content-Encoding", "gzip")
        super().end_headers()


if __name__ == "__main__":
    http.server.HTTPServer(("127.0.0.1", 8099), Handler).serve_forever()
