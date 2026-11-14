#!/usr/bin/env python3
"""Fetch recorded sounds where the workspace can't (issue #596; run by .github/workflows/sounds.yml).

Freesound through its API only: its robots.txt shuts out crawlers (ClaudeBot by name), and its API
terms (https://freesound.org/help/tos_api/, read 2026-11-03) forbid robots or scraping to reach its
content (4f); nothing here touches the site's pages. Needs the repo secret FREESOUND_API_KEY (a free
key, https://freesound.org/apiv2/apply), sent in the Authorization header (kept secret, terms §2 and
B4). For every layer in tools/sounds/queries.json it searches
Creative Commons 0 sounds only, keeps the most downloaded few of each query inside the layer's
length, and downloads each one's high-quality OGG preview (no login needed for previews) with its
record: id, name, author, licence, page, length, rating, downloads, tags, description.

Out (--out): pool.json and <layer>/<id>.ogg. These are the terms' "limited intermediate copies"
(1b): the workflow encrypts them before they leave the runner (tools/sounds/pool_key.sh; never
published as they are, 4a) and the pool is deleted once the sets are chosen. Only the few files
picked for the game, CC0, go in the repo. About 26 searches and 80 downloads a run, paced (4g). The Sonniss GDC bundles are not fetched: their
licence (restriction c) forbids publishing the files as sound effects, which a public repo does.

    FREESOUND_API_KEY=... python3 tools/sounds/fetch.py --out=build/sounds
"""
import argparse
import json
import os
import pathlib
import sys
import time
import urllib.parse
import urllib.request

UA = "SaltCreek-sound-fetch/0.2 (github.com/Kokanee25/Western)"
API = "https://freesound.org/apiv2/search/text/"
CC0 = "Creative Commons 0"
FIELDS = "id,name,username,license,url,duration,samplerate,channels,avg_rating,num_ratings,num_downloads,tags,description,previews"
HERE = pathlib.Path(__file__).resolve().parent


def get(url: str, timeout=60, key="") -> bytes:
    headers = {"User-Agent": UA}
    if key:
        headers["Authorization"] = f"Token {key}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def search(key: str, query: str, lo: float, hi: float, n: int) -> list:
    q = {"query": query, "filter": f'license:"{CC0}" duration:[{lo} TO {hi}]', "fields": FIELDS,
         "sort": "downloads_desc", "page_size": str(n)}
    d = json.loads(get(API + "?" + urllib.parse.urlencode(q), key=key))
    return d.get("results", [])


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="build/sounds")
    ap.add_argument("--queries", default=str(HERE / "queries.json"))
    a = ap.parse_args()
    out = pathlib.Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    key = os.environ.get("FREESOUND_API_KEY", "")
    if not key:
        print("No FREESOUND_API_KEY: add the repo secret (a free key, https://freesound.org/apiv2/apply).")
        (out / "pool.json").write_text(json.dumps({"error": "no FREESOUND_API_KEY"}, indent=1))
        return 0
    spec = json.loads(pathlib.Path(a.queries).read_text())
    pool, seen = {}, set()
    for layer, L in spec["layers"].items():
        got = []
        for query in L["queries"]:
            try:
                res = search(key, query, L["min_s"], L["max_s"], spec.get("per_query", 6))
            except Exception as e:
                print(f"search failed: {layer} '{query}': {e}")
                continue
            time.sleep(0.5)
            for r in res:
                # The filter asks for CC0; each record's own licence is checked again.
                if r["id"] in seen or "publicdomain/zero" not in r.get("license", ""):
                    continue
                seen.add(r["id"])
                r["query"] = query
                got.append(r)
        got = got[: L.get("keep", 12)]
        (out / layer).mkdir(exist_ok=True)
        for r in got:
            url = r.get("previews", {}).get("preview-hq-ogg")
            dest = out / layer / f"{r['id']}.ogg"
            try:
                dest.write_bytes(get(url))
                r["file"] = f"{layer}/{r['id']}.ogg"
            except Exception as e:
                print(f"download failed: {r['id']}: {e}")
            time.sleep(0.3)
        pool[layer] = [{k: r.get(k) for k in ("id", "name", "username", "license", "url", "duration", "samplerate",
                                              "channels", "avg_rating", "num_ratings", "num_downloads", "tags",
                                              "description", "query", "file")} for r in got]
        print(f"{layer}: {len(got)}")
    (out / "pool.json").write_text(json.dumps(pool, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
