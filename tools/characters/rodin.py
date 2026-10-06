#!/usr/bin/env python3
"""The model test's other half (tools/characters/tripo.py --test; Sean, 2026-10-06, after the fitted
men came out lumpy): Rodin (Hyper3D's Gen-2.5, on fal) builds the same man from the same four
pictures, to be judged beside Tripo's newest before either is fitted.

    FAL_KEY=... python3 tools/characters/rodin.py [--only=stranger]
    python3 tools/characters/rodin.py --dry-run      (a stand-in fal on this machine)

For each man asked for (stranger by default) with his four pictures in assets/people/tripo/
(<id>_full.png, the front, and _left, _back, _right: tools/characters/paint_full_length.py's
turnaround): upload them to fal's storage, ask fal-ai/hyper3d/rodin/v2.5 for a model (REQUEST:
its top tier, an 18K quad mesh, PBR, in an A-pose, with HighPack's sharper textures: $1.60 at
fal's prices, 2026-10), wait, and save assets/people/tripo/test/<id>_rodin.glb with every answer
in <id>_rodin.json. The model comes unrigged: fitting him to our skeleton means finding his joints
from his shape. Nothing in the game reads that folder.

--dry-run runs it all against a stand-in fal (tools/characters/rodin_standin.py) that answers as
fal's queue and storage do and checks what it's sent (the key, the pictures' URLs, each field's
value), writing into a scratch folder: no key, no network.
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DIR = os.path.join(ROOT, "assets", "people", "tripo")
OUT = os.path.join(DIR, "test")
SPEC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "characters.json")
QUEUE = "https://queue.fal.run/"
STORAGE = "https://rest.alpha.fal.ai/storage/upload/initiate"
APP = "fal-ai/hyper3d/rodin/v2.5"
# The views in Rodin's order: the first is the main one (his front).
VIEWS = ("full", "left", "back", "right")
# What Rodin is asked for. Tier Gen-2.5-Extreme-High is fal's $0.80 a model and HighPack (sharper
# textures, only on the dense meshes: 18K or 50K quads) another $0.80; the quads give a clean,
# even mesh for our Blender fit; TAPose has him built standing square in an A-pose.
REQUEST = {"tier": "Gen-2.5-Extreme-High", "quality_mesh_option": "18K Quad", "material": "PBR",
           "geometry_file_format": "glb", "TAPose": True, "addons": "HighPack"}
# Seconds between asks while it runs (the dry run doesn't wait), and how many asks.
POLL = 10.0
ASKS = 180


def request(method, url, key, body=None):
    headers = {"Authorization": "Key " + key}
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            text = r.read().decode(errors="replace")
            return json.loads(text) if text.strip() else {}
    except urllib.error.HTTPError as e:
        raise RuntimeError("%s %s: fal said %d: %s" % (method, url, e.code, e.read().decode(errors="replace")[:800])) from None


def upload(path, key, log):
    """A picture into fal's storage; returns its URL."""
    init = request("POST", STORAGE, key, {"file_name": os.path.basename(path), "content_type": "image/png"})
    log.append({"upload_initiate": {"file": os.path.basename(path), "answer": init}})
    put = urllib.request.Request(init["upload_url"], data=open(path, "rb").read(),
                                 headers={"Content-Type": "image/png"}, method="PUT")
    with urllib.request.urlopen(put, timeout=600) as r:
        log.append({"upload_put": r.status})
    return init["file_url"]


def model_url(answer):
    """The glb's URL in Rodin's answer (model_mesh.url), or any .glb URL in it."""
    mesh = answer.get("model_mesh")
    if isinstance(mesh, dict) and mesh.get("url"):
        return mesh["url"]
    found = []

    def walk(v):
        if isinstance(v, dict):
            for x in v.values():
                walk(x)
        elif isinstance(v, list):
            for x in v:
                walk(x)
        elif isinstance(v, str) and v.startswith("http") and ".glb" in v:
            found.append(v)

    walk(answer)
    if not found:
        raise RuntimeError("no model in the answer: %s" % json.dumps(answer)[:800])
    return found[0]


def what_of(cid):
    """How he looks (characters.json `what`): Rodin takes a few words beside the pictures."""
    try:
        return json.load(open(SPEC))["characters"][cid]["what"]
    except (OSError, ValueError, KeyError):
        return ""


def make(cid, key, src=None, out=None):
    src = src or DIR
    out = out or OUT
    os.makedirs(out, exist_ok=True)
    paths = [os.path.join(src, "%s_%s.png" % (cid, v)) for v in VIEWS]
    missing = [p for p in paths if not os.path.exists(p)]
    if missing:
        raise RuntimeError("missing pictures: %s" % ", ".join(os.path.basename(p) for p in missing))
    log = [{"asked": REQUEST}]
    urls = [upload(p, key, log) for p in paths]
    body = dict(REQUEST, image_urls=urls)
    words = what_of(cid)
    if words:
        body["prompt"] = words
    queued = request("POST", QUEUE + APP, key, body)
    log.append({"queued": queued})
    status_url = queued.get("status_url") or "%s%s/requests/%s/status" % (QUEUE, APP, queued["request_id"])
    response_url = queued.get("response_url") or "%s%s/requests/%s" % (QUEUE, APP, queued["request_id"])
    try:
        for _ in range(ASKS):
            st = request("GET", status_url, key)
            state = st.get("status")
            if state == "COMPLETED":
                answer = request("GET", response_url, key)
                log.append({"answer": answer})
                with urllib.request.urlopen(model_url(answer), timeout=600) as r, \
                        open(os.path.join(out, cid + "_rodin.glb"), "wb") as f:
                    f.write(r.read())
                print("made:", cid + "_rodin")
                return
            if state not in ("IN_QUEUE", "IN_PROGRESS"):
                log.append({"status": st})
                raise RuntimeError("Rodin stopped: %s" % json.dumps(st)[:800])
            time.sleep(POLL)
        raise RuntimeError("Rodin: still not done after %d minutes" % (ASKS * POLL / 60))
    finally:
        json.dump(log, open(os.path.join(out, cid + "_rodin.json"), "w"), indent=1)


def dry_run():
    """The whole client against a stand-in fal (tools/characters/rodin_standin.py)."""
    global QUEUE, STORAGE, POLL
    import tempfile
    import rodin_standin
    from PIL import Image
    server, base, seen = rodin_standin.start()
    QUEUE, STORAGE, POLL = base + "/queue/", base + "/storage/upload/initiate", 0.0
    scratch = tempfile.mkdtemp(prefix="rodin_dry_")
    src = os.path.join(scratch, "pictures")
    os.makedirs(src)
    for v in VIEWS:
        Image.new("RGB", (512, 1024), (128, 110, 90)).save(os.path.join(src, "turned_%s.png" % v))
    ok = True
    try:
        make("turned", "dry-run-key", src, scratch)
    except RuntimeError as e:
        print("  failed:", e)
        ok = False
    finally:
        server.shutdown()
    for f in ("turned_rodin.glb", "turned_rodin.json"):
        p = os.path.join(scratch, f)
        good = os.path.exists(p) and (not f.endswith(".glb") or open(p, "rb").read(4) == b"glTF")
        print("  %-22s %s" % (f, "ok" if good else "MISSING or not a glb"))
        ok = ok and good
    for problem in seen["problems"]:
        print("  the stand-in fal objected:", problem)
    ok = ok and not seen["problems"]
    print("dry run %s: %s (requests: %s)" % ("passed" if ok else "FAILED", scratch, ", ".join(seen["requests"])))
    if not ok:
        sys.exit(1)


def main():
    if "--dry-run" in sys.argv:
        dry_run()
        return
    key = os.environ.get("FAL_KEY", "")
    if not key:
        print("No FAL_KEY: no model made (--dry-run runs it all against a stand-in).")
        return
    only = ["stranger"]
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1]:
            only = a.split("=", 1)[1].split(",")
    failed = []
    for cid in only:
        try:
            make(cid, key)
        except (RuntimeError, OSError, KeyError, ValueError, TypeError) as e:
            print("failed:", cid, e)
            failed.append(cid)
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
