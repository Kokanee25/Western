#!/usr/bin/env python3
"""A stand-in for Tripo's v2 API on this machine, for tripo.py --dry-run: it answers as the real
one does (as far as its published v2 "openapi" goes) and writes down anything it's sent that the
real one would refuse. Not a model maker: its models are an empty glTF.

    POST /upload          multipart, a `file` part        -> {"code": 0, "data": {"image_token"}}
    POST /task            {"type": "image_to_model", "file": {"type", "file_token"}, ...}
                          {"type": "animate_rig", "original_model_task_id", "out_format"}
                                                          -> {"code": 0, "data": {"task_id"}}
    GET  /task/<id>       queued, then running, then success with output.model (a URL here)
    GET  /user/balance    -> {"code": 0, "data": {"balance", "frozen"}}
    GET  /files/<name>    the model
Every request must carry "Authorization: Bearer <key>".
"""
import json
import struct
import threading
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


def empty_glb():
    """A valid, empty glTF binary (one scene, no meshes)."""
    doc = json.dumps({"asset": {"version": "2.0", "generator": "tripo stand-in"}, "scenes": [{"nodes": []}], "scene": 0}).encode()
    doc += b" " * (-len(doc) % 4)
    return struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(doc)) + struct.pack("<I4s", len(doc), b"JSON") + doc


def start():
    """Run it on a free port; returns (server, base URL, seen), seen = {"requests": [...], "problems": [...]}."""
    seen = {"requests": [], "problems": []}
    tasks = {}
    tokens = set()
    glb = empty_glb()

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def _answer(self, code, body, ctype="application/json"):
            data = body if isinstance(body, bytes) else json.dumps(body).encode()
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def _authorised(self):
            auth = self.headers.get("Authorization", "")
            if not auth.startswith("Bearer ") or len(auth) <= len("Bearer "):
                seen["problems"].append("%s %s without a Bearer key" % (self.command, self.path))
                self._answer(401, {"code": 1002, "message": "no key"})
                return False
            return True

        def do_GET(self):
            path = self.path.split("/v2/openapi", 1)[-1]
            seen["requests"].append("GET " + path.split("?")[0].rsplit("/", 1)[0] if path.startswith("/task/") else "GET " + path)
            if path.startswith("/files/"):
                return self._answer(200, glb, "model/gltf-binary")
            if not self._authorised():
                return
            if path == "/user/balance":
                return self._answer(200, {"code": 0, "data": {"balance": 2000, "frozen": 0}})
            if path.startswith("/task/"):
                tid = path[len("/task/"):]
                if tid not in tasks:
                    seen["problems"].append("asked after a task it never made: " + tid)
                    return self._answer(404, {"code": 2001, "message": "no such task"})
                t = tasks[tid]
                t["asks"] += 1
                status = ["queued", "running", "success"][min(t["asks"] - 1, 2)]
                data = {"task_id": tid, "type": t["type"], "status": status, "progress": {"queued": 0, "running": 50, "success": 100}[status]}
                if status == "success":
                    host = "http://%s:%d" % self.server.server_address[:2]
                    data["output"] = {"model": "%s/files/%s.glb" % (host, tid)}
                return self._answer(200, {"code": 0, "data": data})
            seen["problems"].append("GET to an unknown path " + path)
            self._answer(404, {"code": 1, "message": "not found"})

        def do_POST(self):
            path = self.path.split("/v2/openapi", 1)[-1]
            seen["requests"].append("POST " + path)
            if not self._authorised():
                return
            body = self.rfile.read(int(self.headers.get("Content-Length", "0")))
            if path == "/upload":
                ctype = self.headers.get("Content-Type", "")
                if not ctype.startswith("multipart/form-data; boundary="):
                    seen["problems"].append("upload not multipart: " + ctype)
                elif b'name="file"' not in body or b"\x89PNG" not in body:
                    seen["problems"].append("upload without a PNG in a `file` part")
                token = uuid.uuid4().hex
                tokens.add(token)
                return self._answer(200, {"code": 0, "data": {"image_token": token}})
            if path == "/task":
                try:
                    job = json.loads(body)
                except ValueError:
                    seen["problems"].append("task body isn't JSON")
                    return self._answer(400, {"code": 1, "message": "bad json"})
                kind = job.get("type")
                if kind == "image_to_model":
                    f = job.get("file", {})
                    if f.get("file_token") not in tokens or f.get("type") not in ("png", "jpg", "jpeg", "webp"):
                        seen["problems"].append("image_to_model without an uploaded file: %s" % json.dumps(f))
                elif kind == "animate_rig":
                    if job.get("original_model_task_id") not in tasks:
                        seen["problems"].append("animate_rig of a model it never made")
                    if job.get("out_format") not in ("glb", "fbx"):
                        seen["problems"].append("animate_rig out_format %s" % job.get("out_format"))
                else:
                    seen["problems"].append("unknown task type %s" % kind)
                tid = uuid.uuid4().hex
                tasks[tid] = {"type": kind, "asks": 0}
                return self._answer(200, {"code": 0, "data": {"task_id": tid}})
            seen["problems"].append("POST to an unknown path " + path)
            self._answer(404, {"code": 1, "message": "not found"})

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    host, port = server.server_address[:2]
    return server, "http://%s:%d/v2/openapi" % (host, port), seen
