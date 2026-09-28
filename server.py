from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess, re

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
        content_type = self.headers.get('Content-Type', '')
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)

        # Récupère le boundary
        boundary_match = re.search(r'boundary=([^\s;]+)', content_type)
        if not boundary_match:
            self.send_response(400)
            self.end_headers()
            return

        boundary = ('--' + boundary_match.group(1)).encode()

        # Split sur le boundary
        parts = body.split(boundary)
        for part in parts:
            if b'filename=' not in part:
                continue

            # Extrait le nom du fichier
            filename_match = re.search(rb'filename="([^"]+)"', part)
            if not filename_match:
                continue
            filename = filename_match.group(1).decode()

            # Sépare headers et contenu (double CRLF)
            header_end = part.find(b'\r\n\r\n')
            if header_end == -1:
                continue
            file_data = part[header_end + 4:]

            # Retire le CRLF final
            if file_data.endswith(b'\r\n'):
                file_data = file_data[:-2]

            with open(filename, 'wb') as f:
                f.write(file_data)

            print(f"[+] Received: {filename}")

        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'OK')

ips = get_ips()
print("Available interfaces :")
for i, ip in enumerate(ips):
    print(f"  [{i}] {ip}")

choix = int(input("Choose an interface : "))
ip = ips[choix]

server = HTTPServer((ip, 8000), Handler)
print(f"Serving on http://{ip}:8000/")
server.serve_forever()
