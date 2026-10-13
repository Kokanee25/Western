"""Fetches the Smithsonian's 3D scans of Leonard Volk's 1860 casts of Abraham Lincoln's hands (CC0,
Smithsonian Open Access) into assets/held/scan/, for your hand on the gun in the painterly test: a
real hand's surface (knuckles, tendons, creases, nails) closed round a piece of broom handle.

Runs on Actions (People workflow, `style: scan`): the Smithsonian's servers are blocked from the
workspace. It asks the Open Access API (api.data.gov's DEMO_KEY) and the 3D API about each package,
reads each package's Voyager document for its models, writes everything it was told to
`index.json`, and downloads every glb of a hand under MAX_MB."""
import json, os, re, sys, urllib.parse, urllib.request

OUT = "assets/held/scan"
PACKAGES = ["d8c642d6-4ebc-11ea-b77f-2e728ce88125", "2b4a081a-9ea1-4b0c-b1c3-6f5389da3244"]
SEARCHES = ["Lincoln hand cast Volk", "Lincoln right hand", "Lincoln left hand", "hand cast 3D"]
KEY = os.environ.get("SI_API_KEY") or "DEMO_KEY"
MAX_MB = 90


def get(url, binary=False):
    req = urllib.request.Request(url, headers={"User-Agent": "salt-creek-fetch/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            data = r.read()
            return data if binary else json.loads(data.decode("utf-8", "replace"))
    except Exception as e:  # noqa: BLE001 - every answer is recorded, failures too
        print(f"  {url}: {e}")
        return None


def size_mb(url):
    req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": "salt-creek-fetch/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return int(r.headers.get("Content-Length") or 0) / 1e6
    except Exception as e:  # noqa: BLE001
        print(f"  HEAD {url}: {e}")
        return -1


def urls_in(obj, found):
    if isinstance(obj, dict):
        for v in obj.values():
            urls_in(v, found)
    elif isinstance(obj, list):
        for v in obj:
            urls_in(v, found)
    elif isinstance(obj, str) and re.match(r"https?://", obj):
        found.add(obj)
    return found


def main():
    os.makedirs(OUT, exist_ok=True)
    index = {"open_access": {}, "search": {}, "files_api": {}, "voyager": {}}
    for q in SEARCHES:
        url = ("https://api.si.edu/openaccess/api/v1.0/search?rows=40&api_key=" + KEY
               + "&q=" + urllib.parse.quote(q))
        index["search"][q] = get(url)
    ids = set(PACKAGES)
    for answer in index["search"].values():
        rows = ((answer or {}).get("response") or {}).get("rows") or []
        for row in rows:
            title = (row.get("title") or "").lower()
            if "hand" in title or "lincoln" in title:
                for u in urls_in(row, set()):
                    m = re.search(r"3d_package:([0-9a-f-]{36})", u)
                    if m:
                        ids.add(m.group(1))
    candidates = set()
    for pid in sorted(ids):
        print("package", pid)
        oa = get(f"https://api.si.edu/openaccess/api/v1.0/content/3d_package:{pid}?api_key={KEY}")
        index["open_access"][pid] = oa
        fa = get("https://3d-api.si.edu/api/v1.0/content/file/search?q=" + pid)
        index["files_api"][pid] = fa
        base = f"https://3d-api.si.edu/content/document/3d_package:{pid}/"
        doc = get(base + "document.json")
        index["voyager"][pid] = doc
        for u in urls_in(oa, set()) | urls_in(fa, set()):
            candidates.add(u)
        for model in (doc or {}).get("models") or []:
            for d in model.get("derivatives") or []:
                for a in d.get("assets") or []:
                    if a.get("uri"):
                        candidates.add(urllib.parse.urljoin(base, a["uri"]))
    index["candidates"] = sorted(candidates)
    with open(os.path.join(OUT, "index.json"), "w") as f:
        json.dump(index, f, indent=1)
    got = []
    for u in sorted(candidates):
        name = urllib.parse.unquote(u.split("?")[0].rsplit("/", 1)[-1])
        if not re.search(r"\.(glb|gltf|obj|zip|jpg|png)$", name, re.I):
            continue
        if not re.search(r"\.glb$", name, re.I) and "hand" not in u.lower():
            continue
        mb = size_mb(u)
        print(f"{name}: {mb:.1f} MB")
        if mb > MAX_MB:
            continue
        data = get(u, binary=True)
        if data:
            with open(os.path.join(OUT, name), "wb") as f:
                f.write(data)
            got.append(name)
    with open(os.path.join(OUT, ".gdignore"), "w") as f:
        f.write("")
    print("downloaded:", got)
    return 0


if __name__ == "__main__":
    sys.exit(main())
