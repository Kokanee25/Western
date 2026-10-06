#!/usr/bin/env python3
"""A stand-in for fal's queue and storage on this machine, for rodin.py --dry-run: it answers as
fal does for fal-ai/hyper3d/rodin/v2.5 (as far as fal's published schema goes) and writes down
anything it's sent that the real one would refuse. Not a model maker: its model is an empty glTF.

    POST /storage/upload/initiate  {"file_name", "content_type"} -> {"upload_url", "file_url"}
    PUT  /put/<id>                 the picture's bytes
    POST /queue/fal-ai/hyper3d/rodin/v2.5   the request -> {"request_id", "status_url", "response_url"}
    GET  .../requests/<id>/status  IN_QUEUE, then IN_PROGRESS, then COMPLETED
    GET  .../requests/<id>         {"model_mesh": {"url", ...}}
    GET  /files/<name>             the model
Every request but the PUT and the download must carry "Authorization: Key <key>".
"""
import json
import struct
import threading
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

APP = "fal-ai/hyper3d/rodin/v2.5"
TIERS = ("Gen-2.5-Minimum", "Gen-2.5-Extreme-Low", "Gen-2.5-Low", "Gen-2.5-Medium", "Gen-2.5-High",
         "Gen-2.5-Extreme-High")
MESHES = ("Auto", "4K Quad", "8K Quad", "18K Quad", "50K Quad", "100K Quad", "200K Quad",
          "2K Triangle", "20K Triangle", "150K Triangle", "500K Triangle")
# HighPack only on the dense meshes (fal's notes).
HIGHPACK_MESHES = ("18K Quad", "50K Quad", "150K Triangle")


def empty_glb():
    doc = json.dumps({"asset": {"version": "2.0", "generator": "rodin stand-in"}, "scenes": [{"nodes": []}], "scene": 0}).encode()
    doc += b" " * (-len(doc) % 4)
    return struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(doc)) + struct.pack("<I4s", len(doc), b"JSON") + doc


def start():
    """Run it on a free port; returns (server, base URL, seen), seen = {"requests": [...], "problems": [...]}."""
    seen = {"requests": [], "problems": []}
    files = {}
    jobs = {}
    glb = empty_glb()

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def _host(self):
            return "http://%s:%d" % self.server.server_address[:2]

        def _answer(self, code, body, ctype="application/json"):
            data = body if isinstance(body, bytes) else json.dumps(body).encode()
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def _authorised(self):
            auth = self.headers.get("Authorization", "")
            if not auth.startswith("Key ") or len(auth) <= len("Key "):
                seen["problems"].append("%s %s without a Key" % (self.command, self.path))
                self._answer(401, {"detail": "no key"})
                return False
            return True

        def do_PUT(self):
            seen["requests"].append("PUT /put")
            body = self.rfile.read(int(self.headers.get("Content-Length", "0")))
            fid = self.path.rsplit("/", 1)[-1]
            if fid not in files:
                seen["problems"].append("PUT to an upload it never began")
            elif not body.startswith(b"\x89PNG"):
                seen["problems"].append("PUT without a PNG")
            else:
                files[fid] = True
            self._answer(200, b"", "text/plain")

        def do_GET(self):
            path = self.path
            if path.startswith("/files/"):
                seen["requests"].append("GET /files")
                return self._answer(200, glb, "model/gltf-binary")
            seen["requests"].append("GET " + ("status" if path.endswith("/status") else "result"))
            if not self._authorised():
                return
            rid = path.split("/requests/", 1)[-1].split("/")[0]
            if rid not in jobs:
                seen["problems"].append("asked after a request it never queued: " + rid)
                return self._answer(404, {"detail": "no such request"})
            job = jobs[rid]
            if path.endswith("/status"):
                job["asks"] += 1
                return self._answer(200, {"status": ["IN_QUEUE", "IN_PROGRESS", "COMPLETED"][min(job["asks"] - 1, 2)],
                                          "request_id": rid})
            if job["asks"] < 3:
                seen["problems"].append("asked for the result before it was COMPLETED")
            return self._answer(200, {"model_mesh": {"url": "%s/files/%s.glb" % (self._host(), rid),
                                                     "file_name": "model.glb", "content_type": "model/gltf-binary"},
                                      "seed": 1})

        def do_POST(self):
            path = self.path
            seen["requests"].append("POST " + ("storage" if "storage" in path else "queue"))
            if not self._authorised():
                return
            try:
                body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", "0"))))
            except ValueError:
                seen["problems"].append("body isn't JSON")
                return self._answer(400, {"detail": "bad json"})
            if path == "/storage/upload/initiate":
                if body.get("content_type") != "image/png" or not body.get("file_name"):
                    seen["problems"].append("upload begun without a name or as %s" % body.get("content_type"))
                fid = uuid.uuid4().hex
                files[fid] = False
                return self._answer(200, {"upload_url": "%s/put/%s" % (self._host(), fid),
                                          "file_url": "%s/stored/%s.png" % (self._host(), fid)})
            if path == "/queue/" + APP:
                urls = body.get("image_urls")
                if not isinstance(urls, list) or not 1 <= len(urls) <= 5:
                    seen["problems"].append("image_urls wants a list of 1 to 5: %s" % json.dumps(urls)[:200])
                else:
                    for u in urls:
                        fid = str(u).rsplit("/", 1)[-1].split(".")[0]
                        if not files.get(fid):
                            seen["problems"].append("an image URL that was never uploaded: %s" % u)
                if body.get("tier") not in TIERS:
                    seen["problems"].append("tier %s" % body.get("tier"))
                mesh = body.get("quality_mesh_option", "Auto")
                if mesh not in MESHES:
                    seen["problems"].append("quality_mesh_option %s" % mesh)
                if body.get("material", "PBR") not in ("PBR", "Shaded", "All"):
                    seen["problems"].append("material %s" % body.get("material"))
                if body.get("geometry_file_format", "glb") not in ("glb", "usdz", "fbx", "obj", "stl"):
                    seen["problems"].append("geometry_file_format %s" % body.get("geometry_file_format"))
                if "TAPose" in body and not isinstance(body["TAPose"], bool):
                    seen["problems"].append("TAPose not a bool")
                if body.get("addons") not in (None, "HighPack"):
                    seen["problems"].append("addons %s" % body.get("addons"))
                if body.get("addons") == "HighPack" and mesh not in HIGHPACK_MESHES:
                    seen["problems"].append("HighPack with the %s mesh" % mesh)
                if "prompt" in body and not isinstance(body["prompt"], str):
                    seen["problems"].append("prompt not a string")
                rid = uuid.uuid4().hex
                jobs[rid] = {"asks": 0}
                base = "%s/queue/%s/requests/%s" % (self._host(), APP, rid)
                return self._answer(200, {"request_id": rid, "status_url": base + "/status", "response_url": base})
            seen["problems"].append("POST to an unknown path " + path)
            self._answer(404, {"detail": "not found"})

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    host, port = server.server_address[:2]
    return server, "http://%s:%d" % (host, port), seen
