#!/usr/bin/env python3
"""Fetch MPFB's data and MakeHuman's system assets for tools/blender/mpfb_man.py (the bake-off's
route B, issue #505). Into build/mpfb/ (git-ignored):

    build/mpfb/mpfb2/      MPFB 2 at a pinned commit (its src/mpfb/data: base mesh, targets, rigs and
                           weights; CC0, LICENSE.ASSETS.md). Its code (GPL-3) is NOT run or copied:
                           mpfb_man.py reads the data files itself.
    build/mpfb/mh_system/  MakeHuman's "legacy system asset kit" (skins, eyes, brows, hair, clothes,
                           shoes, the fedora; "All of these assets are CC0", its README), as released
                           by the MakeHuman 2 project on GitHub.

    python3 tools/blender/fetch_mpfb.py
"""
import os
import subprocess
import sys
import urllib.request
import zipfile

MPFB_REPO = "https://github.com/makehumancommunity/mpfb2.git"
MPFB_COMMIT = "6ff1eb358f6c1959ced77e79e6dd2406d9a71f49"  # master, 2026-10-31 (version 2.0.18)
ASSETS_URL = "https://github.com/Makehuman-2/MH2_Asset_Repository_CCO/releases/download/CC0/mh_system_CC0.zip"
DEST = "build/mpfb"


def main() -> None:
    os.makedirs(DEST, exist_ok=True)
    open(os.path.join(DEST, ".gdignore"), "w").close()  # or Godot imports MPFB's 400 MB of files
    repo = os.path.join(DEST, "mpfb2")
    if not os.path.isdir(repo):
        subprocess.run(["git", "clone", "-q", "--filter=blob:none", MPFB_REPO, repo], check=True)
    subprocess.run(["git", "-C", repo, "checkout", "-q", MPFB_COMMIT], check=True)
    assets = os.path.join(DEST, "mh_system")
    if not os.path.isdir(os.path.join(assets, "skins")):
        z = os.path.join(DEST, "mh_system_CC0.zip")
        if not os.path.exists(z):
            print("downloading", ASSETS_URL, file=sys.stderr)
            urllib.request.urlretrieve(ASSETS_URL, z)
        with zipfile.ZipFile(z) as f:
            f.extractall(assets)
    print("mpfb data:", os.path.join(repo, "src/mpfb/data"), "assets:", assets)


if __name__ == "__main__":
    main()
