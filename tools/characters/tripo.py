#!/usr/bin/env python3
"""Characters by image-to-3D, step 2: Tripo builds a textured, rigged model from the full-length
painting (tools/characters/paint_full_length.py).

    TRIPO_API_KEY=... python3 tools/characters/tripo.py [--only=stranger] [--again]
    python3 tools/characters/tripo.py --dry-run      (no key, no network: see below)
    TRIPO_API_KEY=... python3 tools/characters/tripo.py --balance   (checks the key, spends nothing)

For each assets/people/tripo/<id>_full.png: upload it (with <id>_left/_back/_right.png when the
turnaround's there: Tripo's multi-view input, front/left/back/right, so his sides and back are
painted as drawn and not guessed from the front), ask for a model (textured, PBR), wait, ask for
that model rigged (glb), wait, and save assets/people/tripo/<id>.glb (and the unrigged one as
<id>_mesh.glb), with every answer the API gave in <id>_tripo.json, which starts with a hash of
each picture: a model is made again when its pictures change (or with --again). Our own Blender
step then fits it to the game's skeleton and hitboxes (tools/blender/, as MakeHuman's body is
now; the MakeHuman pipeline stays the fallback).

image_to_model and animate_rig ran against the live API on 2026-10-02 (People run 17), written
to Tripo's v2 "openapi" (one /task endpoint, the job in `type`); multiview_to_model is written
the same way and untested. Every answer is printed and saved, so the first run on Actions shows
what to change. TRIPO_API_BASE overrides the base URL.

--dry-run runs the whole thing (upload, both tasks, waiting, downloads, the log) against a stand-in
Tripo on this machine that answers as the v2 API does and checks what it's sent (the key in a
Bearer header, the picture as a multipart `file`, each task's fields), on every full-length painting
there is (or a blank stand-in), writing into a scratch folder, never assets/. Nothing is needed
for it: no key, no .env, no network. If it passes, tonight's first real run needs only the secret.
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


# Seconds between asks while a task runs (the dry run doesn't wait).
POLL = 5.0


def wait(task_id, key, log, what):
    for _ in range(240):
        answer = call("GET", "/task/" + task_id, key)
        status = answer.get("data", {}).get("status")
        if status in ("success", "failed", "cancelled", "banned", "expired", "unknown"):
            log.append({what: answer})
            if status != "success":
                raise RuntimeError("%s: %s" % (what, json.dumps(answer)[:800]))
            return answer["data"]
        time.sleep(POLL)
    raise RuntimeError("%s: still not done after 20 minutes" % what)


def download(url, path):
    with urllib.request.urlopen(url, timeout=300) as r, open(path, "wb") as f:
        f.write(r.read())


def model_url(data):
    out = data.get("output", {})
    return out.get("model") or out.get("pbr_model") or out.get("base_model")


# The views Tripo's multi-view input takes, in its order; the front is <id>_full.png, the others
# <id>_<view>.png (tools/characters/paint_full_length.py's turnaround). With only the front it's
# image_to_model as before.
VIEWS = ("full", "left", "back", "right")


def inputs_of(cid, src):
    """The pictures Tripo gets for this man and a hash of each, so a model is made again only
    when they change (git keeps no dates)."""
    import hashlib
    found = {}
    for view in VIEWS:
        p = os.path.join(src, "%s_%s.png" % (cid, view))
        if os.path.exists(p):
            found["%s_%s.png" % (cid, view)] = hashlib.sha256(open(p, "rb").read()).hexdigest()
    return found


def made_from(cid, out):
    """The input hashes the model there was made from (empty for a model made before they were
    kept, or none)."""
    p = os.path.join(out, cid + "_tripo.json")
    if not os.path.exists(p):
        return {}
    try:
        for entry in json.load(open(p)):
            if isinstance(entry, dict) and "inputs" in entry:
                return entry["inputs"]
    except (ValueError, TypeError):
        pass
    return {}


def upload(name, path, key, log):
    up = call("POST", "/upload", key, files={"file": (name, open(path, "rb").read(), "image/png")})
    log.append({"upload": {"file": name, "answer": up}})
    return up.get("data", {}).get("image_token") or up.get("data", {}).get("file_token")


def make(cid, key, src=None, out=None):
    src = src or DIR
    out = out or DIR
    inputs = inputs_of(cid, src)
    log = [{"inputs": inputs}]
    views = {v: os.path.join(src, "%s_%s.png" % (cid, v)) for v in VIEWS if "%s_%s.png" % (cid, v) in inputs}
    if all(v in views for v in VIEWS):
        # Four views: front, left, back, right (a missing one is {} in Tripo's list; we have all).
        files = []
        for v in VIEWS:
            token = upload("%s_%s.png" % (cid, v), views[v], key, log)
            files.append({"type": "png", "file_token": token})
        task = call("POST", "/task", key, {"type": "multiview_to_model", "files": files, "texture": True, "pbr": True})
        what = "multiview_to_model"
    else:
        token = upload(cid + ".png", views["full"], key, log)
        task = call("POST", "/task", key, {"type": "image_to_model", "file": {"type": "png", "file_token": token},
                                           "texture": True, "pbr": True})
        what = "image_to_model"
    log.append({what: task})
    mesh = wait(task["data"]["task_id"], key, log, what)
    download(model_url(mesh), os.path.join(out, cid + "_mesh.glb"))
    rig = call("POST", "/task", key, {"type": "animate_rig", "original_model_task_id": task["data"]["task_id"],
                                      "out_format": "glb"})
    log.append({"animate_rig": rig})
    rigged = wait(rig["data"]["task_id"], key, log, "animate_rig")
    download(model_url(rigged), os.path.join(out, cid + ".glb"))
    json.dump(log, open(os.path.join(out, cid + "_tripo.json"), "w"), indent=1)
    print("made:", cid)


def balance(key):
    """What the key has left (GET /user/balance): proves the key and the base URL, spends nothing."""
    answer = call("GET", "/user/balance", key)
    print("Tripo balance:", json.dumps(answer.get("data", answer)))


def dry_run():
    """The whole client against a stand-in Tripo (tools/characters/tripo_standin.py)."""
    global BASE, POLL
    import tempfile
    import tripo_standin
    server, base, seen = tripo_standin.start()
    BASE, POLL = base, 0.0
    scratch = tempfile.mkdtemp(prefix="tripo_dry_")
    names = [n[:-len("_full.png")] for n in sorted(os.listdir(DIR)) if n.endswith("_full.png")] if os.path.isdir(DIR) else []
    # Plus a stand-in man with all four views (multiview_to_model) and one with the front alone
    # (image_to_model), whatever paintings there are.
    from PIL import Image
    standins = os.path.join(scratch, "standins")
    os.makedirs(standins)
    for v in VIEWS:
        Image.new("RGB", (512, 1024), (128, 110, 90)).save(os.path.join(standins, "turned_%s.png" % v))
    Image.new("RGB", (512, 1024), (128, 110, 90)).save(os.path.join(standins, "front_full.png"))
    jobs = [(cid, DIR) for cid in names] + [("turned", standins), ("front", standins)]
    ok = True
    try:
        for cid, src in jobs:
            make(cid, "dry-run-key", src, scratch)
            kinds = [k for e in json.load(open(os.path.join(scratch, cid + "_tripo.json"))) for k in e if k.endswith("_to_model")]
            print("  %s: %s" % (cid, ", ".join(dict.fromkeys(kinds))))
            if cid == "turned" and "multiview_to_model" not in kinds or cid == "front" and "image_to_model" not in kinds:
                print("  wrong task for", cid)
                ok = False
            for f in (cid + ".glb", cid + "_mesh.glb", cid + "_tripo.json"):
                p = os.path.join(scratch, f)
                good = os.path.exists(p) and (not f.endswith(".glb") or open(p, "rb").read(4) == b"glTF")
                print("  %-28s %s" % (f, "ok" if good else "MISSING or not a glb"))
                ok = ok and good
    finally:
        server.shutdown()
    for problem in seen["problems"]:
        print("  the stand-in Tripo objected:", problem)
    ok = ok and not seen["problems"]
    print("dry run %s: %s (requests: %s)" % ("passed" if ok else "FAILED", scratch, ", ".join(seen["requests"])))
    if not ok:
        sys.exit(1)


def main():
    if "--dry-run" in sys.argv:
        dry_run()
        return
    key = os.environ.get("TRIPO_API_KEY", "")
    if not key:
        print("No TRIPO_API_KEY: no models made (--dry-run runs it all against a stand-in).")
        return
    if "--balance" in sys.argv:
        balance(key)
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
            if made_from(cid, DIR) == inputs_of(cid, DIR):
                print("already made:", cid)
                continue
            print("the pictures changed since the model was made:", cid)
        try:
            make(cid, key)
        except (RuntimeError, OSError, KeyError, ValueError, TypeError) as e:
            print("failed:", cid, e)
            failed.append(cid)
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
