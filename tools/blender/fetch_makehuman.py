#!/usr/bin/env python3
"""Download the MakeHuman assets the people pipeline uses, pinned to one commit.

    python3 tools/blender/fetch_makehuman.py [--dest build/makehuman]

MakeHuman's assets (the base mesh, targets) are CC0 (see LICENSE.ASSETS.md, fetched with them), so
anything made from them can live in this public repo. The program code is AGPL; we don't use any
of it. Files land in build/makehuman/ (git-ignored); the generated people go to assets/people/.
Which targets are needed is read from assets/people/people.json.
"""
import json
import os
import sys
import urllib.request

# makehumancommunity/makehuman, tag v1.2.0.
COMMIT = "c28443c2af7e6b6e9367a3c6ee76f090c81796fd"
BASE = "https://raw.githubusercontent.com/makehumancommunity/makehuman/%s/" % COMMIT
ALWAYS = ["LICENSE.md", "LICENSE.ASSETS.md", "makehuman/data/3dobjs/base.obj"]


def fetch(path: str, dest: str) -> None:
    out = os.path.join(dest, path)
    if os.path.exists(out) and os.path.getsize(out) > 0:
        return
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with urllib.request.urlopen(BASE + path, timeout=120) as r:
        data = r.read()
    with open(out, "wb") as f:
        f.write(data)
    print("fetched", path, len(data))


def main() -> None:
    dest = "build/makehuman"
    for a in sys.argv[1:]:
        if a.startswith("--dest="):
            dest = a.split("=", 1)[1]
    people = json.load(open("assets/people/people.json"))
    paths = list(ALWAYS)
    for p in people["people"].values():
        for t in p.get("targets", {}):
            paths.append("makehuman/data/targets/%s.target" % t)
    for path in sorted(set(paths)):
        fetch(path, dest)


if __name__ == "__main__":
    main()
