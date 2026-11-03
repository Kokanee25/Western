#!/usr/bin/env python3
"""Fetch recorded sounds where the workspace can't (issue #596; run by .github/workflows/sounds.yml).

Probe stage: the sites' terms and robots, one search page, so we know how a fetch may be made.
"""
import argparse, os, pathlib, urllib.request

UA = "SaltCreek-sound-fetch/0.1 (game audio research; github.com/Kokanee25/Western)"


def get(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="build/sounds")
    a = ap.parse_args()
    out = pathlib.Path(a.out); out.mkdir(parents=True, exist_ok=True)
    print("api key present:", bool(os.environ.get("FREESOUND_API_KEY")))
    probes = {
        "fs_robots.txt": "https://freesound.org/robots.txt",
        "fs_tos.html": "https://freesound.org/help/tos_web/",
        "fs_api_tos.html": "https://freesound.org/help/tos_api/",
        "fs_search.html": "https://freesound.org/search/?q=dynamite+explosion&f=license%3A%22Creative+Commons+0%22",
        "fs_api_noauth.json": "https://freesound.org/apiv2/search/text/?query=explosion",
        "sonniss.html": "https://sonniss.com/gameaudiogdc",
        "sonniss_licence.html": "https://sonniss.com/gdc-bundle-license/",
    }
    for name, url in probes.items():
        try:
            (out / name).write_bytes(get(url)); print("ok", name)
        except Exception as e:
            print("fail", name, e)


if __name__ == "__main__":
    main()
