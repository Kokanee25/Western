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
# Every target in these folders (the portrait factory's fit solves over the face's targets).
# And the build parameters it fits (tools/characters/portrait.py BUILD).
BUILD = ["macrodetails/universal-male-young-averagemuscle-maxweight",
         "macrodetails/universal-male-young-averagemuscle-minweight", "macrodetails/caucasian-male-old"]
FACE_DIRS = ["cheek", "chin", "ears", "eyebrows", "eyes", "forehead", "head", "mouth", "neck", "nose"]


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
    wanted = [t for p in people["people"].values() for t in p.get("targets", {})]
    # The character factory's base head and archetypes (assets/people/factory.json; "{s}" = r, l).
    factory = json.load(open("assets/people/factory.json"))
    for block in [factory["base"]] + list(factory["archetypes"].values()):
        wanted += list(block.get("targets", {}))
    for t in wanted:
        for name in ([t.replace("{s}", s) for s in "rl"] if "{s}" in t else [t]):
            paths.append("makehuman/data/targets/%s.target" % name)
    paths += face_targets(dest) + ["makehuman/data/targets/%s.target" % t for t in BUILD]
    for path in sorted(set(paths)):
        fetch(path, dest)


def face_targets(dest: str) -> list:
    """The paths of every target in FACE_DIRS at COMMIT (listed by a blobless clone, kept in
    build/makehuman_tree.txt so later runs need no git)."""
    listing = os.path.join(os.path.dirname(dest.rstrip("/")) or ".", "makehuman_tree.txt")
    if not os.path.exists(listing):
        import subprocess
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            subprocess.run(["git", "clone", "-q", "--filter=blob:none", "--no-checkout",
                            "https://github.com/makehumancommunity/makehuman.git", tmp], check=True)
            out = subprocess.run(["git", "-C", tmp, "ls-tree", "-r", "--name-only", COMMIT,
                                  "makehuman/data/targets"], check=True, capture_output=True, text=True).stdout
        with open(listing, "w") as f:
            f.write(out)
    names = open(listing).read().split()
    return [n for n in names if n.endswith(".target") and n.split("/")[3] in FACE_DIRS]


if __name__ == "__main__":
    main()
