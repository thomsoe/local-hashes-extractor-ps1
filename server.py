from http.server import HTTPServer, BaseHTTPRequestHandler
import cgi, subprocess

def get_ips():
    result = subprocess.run(['ip', '-4', 'addr', 'show'], capture_output=True, text=True)
    ips = []
    for line in result.stdout.splitlines():
        if 'inet ' in line:
            ip = line.strip().split()[1].split('/')[0]
            if ip != '127.0.0.1':
                ips.append(ip)
    return ips

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
        print(f"[+] Received: {f.filename}")

ips = get_ips()
print("Available interfaces :")
for i, ip in enumerate(ips):
    print(f"  [{i}] {ip}")

choix = int(input("Choose an interface : "))
ip = ips[choix]

server = HTTPServer((ip, 8000), Handler)
print(f"Serving on http://{ip}:8000/")
server.serve_forever()
