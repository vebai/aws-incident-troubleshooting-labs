import json, os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import boto3

BUCKET = os.environ["SHOP_BUCKET"]
s3 = boto3.client("s3")

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            self.reply(200, {"status": "alive"})
        elif self.path in ("/readyz", "/catalog"):
            try:
                obj = s3.get_object(Bucket=BUCKET, Key="catalog.json")
                data = json.loads(obj["Body"].read())
                self.reply(200, {"status": "ready"} if self.path == "/readyz" else data)
            except Exception as exc:
                print(f"ERROR s3:GetObject catalog.json: {exc}", flush=True)
                self.reply(503 if self.path == "/readyz" else 500, {"error": "catalogue unavailable"})
        else:
            self.reply(404, {"error": "not found"})
    def reply(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

ThreadingHTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
