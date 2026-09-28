#!/usr/bin/env python3
"""Generate the saloon props with Meshy and save them as assets/props/<id>.glb.

Reads assets/props/manifest.json. For each prop without a .glb yet:
  1. text-to-3d "preview" (the shape) from the manifest prompt + shared style,
  2. text-to-3d "refine" (the textures),
  3. download the textured GLB.
Task IDs are kept in assets/props/meshy_tasks.json, so a run that stops can be resumed
without paying for the same prop twice.

Needs MESHY_API_KEY in the environment (never commit it). Standard library only.

  python3 tools/meshy_fetch.py                 # every missing prop
  python3 tools/meshy_fetch.py --only barrel   # one prop (or a comma list)
  python3 tools/meshy_fetch.py --redo barrel   # throw away and regenerate
  python3 tools/meshy_fetch.py --dry-run       # show what would be sent
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROPS = os.path.join(ROOT, "assets", "props")
MANIFEST = os.path.join(PROPS, "manifest.json")
TASKS = os.path.join(PROPS, "meshy_tasks.json")
API = "https://api.meshy.ai/openapi/v2/text-to-3d"
POLL_SECONDS = 10


def request(method, url, key, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
    })
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        sys.exit(f"Meshy {method} {url} failed: {e.code} {e.read().decode(errors='replace')}")


def wait(task_id, key, label):
    while True:
        t = request("GET", f"{API}/{task_id}", key)
        status = t.get("status")
        print(f"  {label}: {status} {t.get('progress', '')}%", flush=True)
        if status == "SUCCEEDED":
            return t
        if status in ("FAILED", "CANCELED", "EXPIRED"):
            sys.exit(f"  {label} {status}: {t.get('task_error', t)}")
        time.sleep(POLL_SECONDS)


def load_json(path, default):
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return default


def save_tasks(tasks):
    with open(TASKS, "w") as f:
        json.dump(tasks, f, indent=2, sort_keys=True)
        f.write("\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="", help="comma-separated prop ids")
    ap.add_argument("--redo", default="", help="comma-separated prop ids to regenerate")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    manifest = load_json(MANIFEST, {})
    style = manifest.get("style", "")
    props = manifest.get("props", {})
    only = [s for s in args.only.split(",") if s]
    redo = [s for s in args.redo.split(",") if s]
    tasks = load_json(TASKS, {})

    key = os.environ.get("MESHY_API_KEY", "")
    if not key and not args.dry_run:
        sys.exit("Set MESHY_API_KEY (environment variable; never commit it).")

    for pid, p in props.items():
        if only and pid not in only and pid not in redo:
            continue
        glb = os.path.join(PROPS, f"{pid}.glb")
        if pid in redo:
            tasks.pop(pid, None)
            if os.path.exists(glb):
                os.remove(glb)
        if os.path.exists(glb):
            print(f"{pid}: already have {os.path.relpath(glb, ROOT)}")
            continue
        preview_body = {
            "mode": "preview",
            "prompt": f"{p['prompt']}. {style}"[:600],
            "art_style": "realistic",
            "ai_model": "latest",
            "topology": "triangle",
            "target_polycount": int(p.get("polycount", 5000)),
            "should_remesh": True,
        }
        print(f"{pid}:")
        if args.dry_run:
            print("  " + json.dumps(preview_body))
            continue
        t = tasks.setdefault(pid, {})
        if "preview" not in t:
            t["preview"] = request("POST", API, key, preview_body)["result"]
            save_tasks(tasks)
        wait(t["preview"], key, "shape")
        if "refine" not in t:
            t["refine"] = request("POST", API, key, {
                "mode": "refine",
                "preview_task_id": t["preview"],
                "enable_pbr": True,
            })["result"]
            save_tasks(tasks)
        done = wait(t["refine"], key, "texture")
        url = done.get("model_urls", {}).get("glb")
        if not url:
            sys.exit(f"  no GLB in result: {done}")
        with urllib.request.urlopen(url, timeout=300) as r, open(glb, "wb") as f:
            f.write(r.read())
        print(f"  saved {os.path.relpath(glb, ROOT)} ({os.path.getsize(glb) // 1024} KB)")


if __name__ == "__main__":
    main()
