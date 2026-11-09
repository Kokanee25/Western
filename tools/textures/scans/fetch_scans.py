#!/usr/bin/env python3
"""Scanned CC0 woods for the material library (#701, docs/briefs/material-library.md).

Poly Haven and ambientCG can't be reached from the workspace, so this runs on GitHub
(.github/workflows/scans.yml) and commits what it makes back to the branch:

  python3 tools/textures/scans/fetch_scans.py catalogue --out=DIR
      every wood-like texture of both sources: DIR/catalogue.json (id, source, name, tags,
      size in metres where the source gives it) and contact sheets DIR/sheet_<source>_<n>.jpg
      (thumbnails with their ids), for choosing.
  python3 tools/textures/scans/fetch_scans.py fetch --picks=... --out=DIR --hi=1   (4K: albedo 4096,
      normal 2048, roughness 1024; the lab's sharp close-ups, kept off the repo)
  python3 tools/textures/scans/fetch_scans.py fetch --picks=tools/textures/scans/picks.json \
      --out=assets/textures/scans
      each pick's albedo, normal (OpenGL) and roughness maps, cut to the sizes the library draws
      (albedo 2048, normal 1024, roughness 512; JPEG) -> OUT/<id>/, with meta.json (source, page,
      licence, metres a tile). Picks already there are skipped.

Both sources are CC0 (polyhaven.com/license, ambientcg.com/license): redistributable, credited in
CREDITS.md all the same. Standard library and Pillow only.
"""
import io
import json
import os
import re
import sys
import time
import urllib.request
import zipfile

UA = "SaltCreekMaterialLibrary/1.0 (github.com/Kokanee25/Western)"
PH_API = "https://api.polyhaven.com"
ACG_API = "https://ambientcg.com/api/v2/full_json"
# What counts as a wood on each source (names and tags matched, case blind).
WOODY = re.compile(r"wood|plank|board|timber|siding|parquet|veneer|bark|walnut|oak|cherry|mahogany|pine|fir|barn", re.I)
SIZES = {"albedo": 2048, "normal": 1024, "rough": 512}
# --hi (4K): for the lab's sharp close-ups only; too heavy for the repo, so the workflow pushes them
# to a pool branch (Sean, 2026-11-09) and the lab reads them from a git-ignored folder.
SIZES_HI = {"albedo": 4096, "normal": 2048, "rough": 1024}


def get(url: str, tries: int = 4) -> bytes:
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=120) as r:
                return r.read()
        except Exception as e:  # noqa: BLE001: retried, then raised
            if i == tries - 1:
                raise
            print(f"  retry {url}: {e}", flush=True)
            time.sleep(2 ** (i + 1))
    raise RuntimeError("unreachable")


def get_json(url: str):
    return json.loads(get(url).decode("utf-8"))


# ---------------------------------------------------------------- catalogue

def ph_catalogue() -> list:
    assets = get_json(f"{PH_API}/assets?t=textures")
    out = []
    for aid, a in assets.items():
        text = " ".join([aid, a.get("name", "")] + a.get("categories", []) + a.get("tags", []))
        if not WOODY.search(text):
            continue
        dims = a.get("dimensions") or []  # millimetres, [w, h]
        out.append({
            "id": aid, "source": "polyhaven", "name": a.get("name", aid),
            "tags": sorted(set(a.get("categories", []) + a.get("tags", []))),
            "metres": [round(d / 1000.0, 3) for d in dims[:2]] if dims else None,
            "page": f"https://polyhaven.com/a/{aid}",
            "thumb": f"https://cdn.polyhaven.com/asset_img/thumbs/{aid}.png?width=256&height=256",
        })
    return out


def acg_catalogue() -> list:
    seen = {}
    for q in ["wood", "planks", "wood siding", "wood floor", "bark"]:
        url = f"{ACG_API}?type=Material&limit=250&include=tagData,imageData&q={urllib.parse.quote(q)}"
        data = get_json(url)
        for a in data.get("foundAssets", []):
            aid = a.get("assetId")
            if not aid or aid in seen:
                continue
            tags = a.get("tags", []) or []
            text = " ".join([aid, a.get("displayName", "")] + tags)
            if not WOODY.search(text):
                continue
            thumb = None
            prev = a.get("previewImage") or {}
            for key in ["256-PNG", "256-JPG-FFFFFF", "256-JPG-242424", "128-PNG"]:
                if prev.get(key):
                    thumb = prev[key]
                    break
            if not thumb and prev:
                thumb = next(iter(prev.values()))
            seen[aid] = {
                "id": aid, "source": "ambientcg", "name": a.get("displayName", aid),
                "tags": sorted(set(tags)), "metres": None,
                "page": f"https://ambientcg.com/view?id={aid}", "thumb": thumb,
            }
    return list(seen.values())


def contact_sheets(items: list, out: str, prefix: str) -> list:
    from PIL import Image, ImageDraw
    cell, cols, rows = 200, 8, 6
    paths = []
    per = cols * rows
    for s in range(0, len(items), per):
        page = items[s:s + per]
        sheet = Image.new("RGB", (cols * cell, rows * (cell + 18)), (24, 24, 24))
        d = ImageDraw.Draw(sheet)
        for i, it in enumerate(page):
            x, y = (i % cols) * cell, (i // cols) * (cell + 18)
            try:
                im = Image.open(io.BytesIO(get(it["thumb"]))).convert("RGB")
                im.thumbnail((cell - 4, cell - 4))
                sheet.paste(im, (x + 2, y + 2))
            except Exception as e:  # noqa: BLE001: a missing thumbnail leaves its cell blank
                print(f"  no thumb {it['id']}: {e}", flush=True)
            label = it["id"] + (f" {it['metres'][0]}m" if it.get("metres") else "")
            d.text((x + 3, y + cell), label[:30], fill=(235, 235, 235))
        p = os.path.join(out, f"sheet_{prefix}_{s // per + 1}.jpg")
        sheet.save(p, quality=85)
        paths.append(p)
        print("wrote", p, flush=True)
    return paths


def catalogue(out: str) -> None:
    os.makedirs(out, exist_ok=True)
    ph = sorted(ph_catalogue(), key=lambda a: a["id"])
    print(f"polyhaven: {len(ph)} woods", flush=True)
    try:
        acg = sorted(acg_catalogue(), key=lambda a: a["id"])
    except Exception as e:  # noqa: BLE001: one source down still gives the other
        print(f"ambientcg failed: {e}", flush=True)
        acg = []
    print(f"ambientcg: {len(acg)} woods", flush=True)
    with open(os.path.join(out, "catalogue.json"), "w") as f:
        json.dump(ph + acg, f, indent=1)
    contact_sheets(ph, out, "polyhaven")
    contact_sheets(acg, out, "ambientcg")


# ---------------------------------------------------------------- fetch

def _cut(data: bytes, size: int, mode: str) -> bytes:
    from PIL import Image
    im = Image.open(io.BytesIO(data))
    if im.mode in ("I;16", "I", "F"):
        im = im.point(lambda v: v / 256.0).convert("L") if im.mode != "F" else im.convert("L")
    im = im.convert(mode)
    if im.width > size:
        im = im.resize((size, round(im.height * size / im.width)), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=90 if mode == "RGB" else 88, optimize=True)
    return buf.getvalue()


def ph_maps(aid: str, hi: bool = False) -> dict:
    files = get_json(f"{PH_API}/files/{aid}")
    want = {"albedo": ["Diffuse", "diff", "Color"], "normal": ["nor_gl", "Normal"], "rough": ["Rough", "rough"]}
    out = {}
    for role, keys in want.items():
        for k in keys:
            if k in files:
                res = files[k]
                for r in (["4k", "8k", "2k"] if hi else ["2k", "4k", "1k"]):
                    if r in res:
                        fmt = res[r].get("jpg") or res[r].get("png")
                        if fmt:
                            out[role] = get(fmt["url"])
                            break
                break
    return out


def acg_maps(aid: str, hi: bool = False) -> dict:
    z = zipfile.ZipFile(io.BytesIO(get(f"https://ambientcg.com/get?file={aid}_{'4K' if hi else '2K'}-JPG.zip")))
    out = {}
    for n in z.namelist():
        low = n.lower()
        if low.endswith("_color.jpg"):
            out["albedo"] = z.read(n)
        elif low.endswith("_normalgl.jpg"):
            out["normal"] = z.read(n)
        elif low.endswith("_roughness.jpg"):
            out["rough"] = z.read(n)
    return out


def fetch(picks_path: str, out: str, hi: bool = False) -> None:
    picks = json.load(open(picks_path))
    sizes = SIZES_HI if hi else SIZES
    for p in picks["picks"]:
        aid, src = p["id"], p["source"]
        d = os.path.join(out, aid)
        if os.path.exists(os.path.join(d, "meta.json")):
            print("have", aid, flush=True)
            continue
        print("fetch", src, aid, flush=True)
        try:
            maps = ph_maps(aid, hi) if src == "polyhaven" else acg_maps(aid, hi)
        except Exception as e:  # noqa: BLE001: report and go on to the next pick
            print(f"  FAILED {aid}: {e}", flush=True)
            continue
        os.makedirs(d, exist_ok=True)
        for role, data in maps.items():
            with open(os.path.join(d, f"{role}.jpg"), "wb") as f:
                f.write(_cut(data, sizes[role], "RGB" if role != "rough" else "L"))
        meta = {
            "id": aid, "source": src, "licence": "CC0 1.0",
            "page": f"https://polyhaven.com/a/{aid}" if src == "polyhaven" else f"https://ambientcg.com/view?id={aid}",
            "metres": p.get("metres"), "maps": sorted(maps.keys()), "fetched": time.strftime("%Y-%m-%d"),
        }
        if src == "polyhaven" and not meta["metres"]:
            a = get_json(f"{PH_API}/info/{aid}")
            dims = a.get("dimensions") or []
            meta["metres"] = [round(x / 1000.0, 3) for x in dims[:2]] or None
        with open(os.path.join(d, "meta.json"), "w") as f:
            json.dump(meta, f, indent=1)
        print("  maps", meta["maps"], "metres", meta["metres"], flush=True)


def main() -> int:
    import urllib.parse  # noqa: F401: used through urllib.parse in acg_catalogue
    args = dict(a[2:].split("=", 1) for a in sys.argv[2:] if a.startswith("--") and "=" in a)
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode == "catalogue":
        catalogue(args.get("out", "build/scans"))
    elif mode == "fetch":
        fetch(args.get("picks", "tools/textures/scans/picks.json"), args.get("out", "assets/textures/scans"),
              "hi" in sys.argv[2:] or args.get("hi") == "1")
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    import urllib.parse  # noqa: F401
    sys.exit(main())
