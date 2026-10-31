import sys
import http.server
import socketserver

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080

import os
import urllib.parse

class MultiThreadedNoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self, path):
        parsed = urllib.parse.urlsplit(path)
        clean_path = parsed.path
        translated = super().translate_path(clean_path)
        if os.path.isdir(translated):
            index_path = os.path.join(translated, 'index.html')
            if os.path.isfile(index_path):
                return index_path
        elif not os.path.exists(translated) and os.path.isfile(translated + '.html'):
            return translated + '.html'
        return super().translate_path(path)

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

if __name__ == '__main__':
    socketserver.ThreadingTCPServer.allow_reuse_address = True
    print(f"> Memulai Multi-Threaded No-Cache Server di 0.0.0.0:{PORT}...")
    try:
        with socketserver.ThreadingTCPServer(('0.0.0.0', PORT), MultiThreadedNoCacheHandler) as httpd:
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer dihentikan.")
