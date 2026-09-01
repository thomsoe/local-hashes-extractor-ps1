from http.server import HTTPServer, BaseHTTPRequestHandler
import cgi, os

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        form = cgi.FieldStorage(fp=self.rfile, headers=self.headers,
            environ={'REQUEST_METHOD': 'POST'})
        f = form['file']
        with open(f.filename, 'wb') as out:
            out.write(f.file.read())
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'OK')
        print(f"[+] Recu: {f.filename}")

HTTPServer(('0.0.0.0', 8000), Handler).serve_forever()
