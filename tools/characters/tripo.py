#!/usr/bin/env python3
"""Characters by image-to-3D, step 2: Tripo builds a textured, rigged model from the full-length
painting (tools/characters/paint_full_length.py).

    TRIPO_API_KEY=... python3 tools/characters/tripo.py [--only=stranger] [--again]

For each assets/people/tripo/<id>_full.png: upload it, ask for a model from it (textured, PBR),
wait, ask for that model rigged (glb), wait, and save assets/people/tripo/<id>.glb (and the
unrigged one as <id>_mesh.glb), with every answer the API gave in <id>_tripo.json. Our own
Blender step then fits it to the game's skeleton and hitboxes (tools/blender/, as MakeHuman's
body is now; the MakeHuman pipeline stays the fallback).

UNTESTED against the live API (the key isn't set yet, and the API's documentation is blocked from
the workspace): written to Tripo's v2 "openapi" (one /task endpoint, the job in `type`); they've
since published v3 (an endpoint per job). Every answer is printed and saved, so the first run on
Actions shows what to change. TRIPO_API_BASE overrides the base URL.
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DIR = os.path.join(ROOT, "assets", "people", "tripo")
BASE = os.environ.get("TRIPO_API_BASE") or "https://api.tripo3d.ai/v2/openapi"


def call(method, path, key, body=None, files=None):
    headers = {"Authorization": "Bearer " + key}
    data = None
    if files:
        boundary = uuid.uuid4().hex
        parts = []
        for name, (filename, blob, ctype) in files.items():
            parts.append(("--%s\r\nContent-Disposition: form-data; name=\"%s\"; filename=\"%s\"\r\n"
                          "Content-Type: %s\r\n\r\n" % (boundary, name, filename, ctype)).encode() + blob + b"\r\n")
        data = b"".join(parts) + ("--%s--\r\n" % boundary).encode()
        headers["Content-Type"] = "multipart/form-data; boundary=" + boundary
    elif body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        raise RuntimeError("%s %s: Tripo said %d: %s" % (method, path, e.code, e.read().decode(errors="replace")[:800])) from None


def wait(task_id, key, log, what):
    for _ in range(240):
        answer = call("GET", "/task/" + task_id, key)
        status = answer.get("data", {}).get("status")
        if status in ("success", "failed", "cancelled", "banned", "expired", "unknown"):
            log.append({what: answer})
            if status != "success":
                raise RuntimeError("%s: %s" % (what, json.dumps(answer)[:800]))
            return answer["data"]
        time.sleep(5)
    raise RuntimeError("%s: still not done after 20 minutes" % what)


def download(url, path):
    with urllib.request.urlopen(url, timeout=300) as r, open(path, "wb") as f:
        f.write(r.read())


def model_url(data):
    out = data.get("output", {})
    return out.get("model") or out.get("pbr_model") or out.get("base_model")


def make(cid, key):
    log = []
    png = os.path.join(DIR, cid + "_full.png")
    up = call("POST", "/upload", key, files={"file": (cid + ".png", open(png, "rb").read(), "image/png")})
    log.append({"upload": up})
    token = up.get("data", {}).get("image_token") or up.get("data", {}).get("file_token")
    task = call("POST", "/task", key, {"type": "image_to_model", "file": {"type": "png", "file_token": token},
                                       "texture": True, "pbr": True})
    log.append({"image_to_model": task})
    mesh = wait(task["data"]["task_id"], key, log, "image_to_model")
    download(model_url(mesh), os.path.join(DIR, cid + "_mesh.glb"))
    rig = call("POST", "/task", key, {"type": "animate_rig", "original_model_task_id": task["data"]["task_id"],
                                      "out_format": "glb"})
    log.append({"animate_rig": rig})
    rigged = wait(rig["data"]["task_id"], key, log, "animate_rig")
    download(model_url(rigged), os.path.join(DIR, cid + ".glb"))
    json.dump(log, open(os.path.join(DIR, cid + "_tripo.json"), "w"), indent=1)
    print("made:", cid)


def main():
    key = os.environ.get("TRIPO_API_KEY", "")
    if not key:
        print("No TRIPO_API_KEY: no models made.")
        return
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1]:
            only = a.split("=", 1)[1].split(",")
    again = "--again" in sys.argv
    failed = []
    for name in sorted(os.listdir(DIR)) if os.path.isdir(DIR) else []:
        if not name.endswith("_full.png"):
            continue
        cid = name[:-len("_full.png")]
        if only and cid not in only:
            continue
        if os.path.exists(os.path.join(DIR, cid + ".glb")) and not again:
            print("already made:", cid)
            continue
        try:
            make(cid, key)
        except (RuntimeError, OSError, KeyError, ValueError, TypeError) as e:
            print("failed:", cid, e)
            failed.append(cid)
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
