#!/usr/bin/env python3
"""The material lab's measures and sheets (roadmap 1.4a; tools/material_lab.gd renders what this reads).

    python3 tools/material_measure.py measure DIR [--masks=BASEDIR]  # DIR/<material>/ -> DIR/measure.json, .md
    python3 tools/material_measure.py sheet --a=DIR [--b=DIR2[,DIR3...]] --out=SHEETS [--material=a,b] [--light=golden]
    python3 tools/material_measure.py crops DIR --out=CROPS  # the blind critic's crops, a man in front of each wood
    python3 tools/material_measure.py pick --cands=A:DIR,B:DIR2 --out=FILE.jpg  # Sean's pick: a row a wood

The style every material is held to is the Character Studio's three men (bold_cowboy_s0,
old_rancher_s1, young_drifter_s1), measured in the same frames under the same light:

- Colour: the wood's lightness (L*) and chroma (C*) under each light, against the range the men's
  pixels span in the same frames (their 5th to 95th percentile). It passes when the wood's median and
  its 10th and 90th percentiles sit inside the men's range.
- Detail: how big the painting's detail is, in mm on the thing. On the textures: the blur radius at
  which half the fine variance of the luminance is gone, in texels, over the texels a metre (the men's
  from their meshes, numbers.json; the wood's its lab.json density). On screen, the same in pixels for
  the man and the wood in one frame, as a check (they stand at different distances; the ratio is a
  guide, not a gate). It passes when the wood's detail is within a factor of 1.5 of the men's clothes'.
"""
import glob
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEN = ["bold_cowboy_s0", "old_rancher_s1", "young_drifter_s1"]
LIGHTS = ["noon", "golden", "saloon"]
WOODS = os.path.join(ROOT, "assets", "textures", "woods")
# The detail measure's blur radii (pixels or texels).
RADII = [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0, 12.0, 16.0]
DETAIL_FACTOR = 1.5
# The props the lab puts on the deck draw with these (--material=props).
PROPS = ["prop_wood", "prop_felt", "shot_table", "prop_staves", "prop_barrel_head"]


def lab(rgb):
    """sRGB (0-255, ...x3) to CIE L*a*b* (D65)."""
    c = rgb.astype(np.float64) / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16.0 / 116.0)
    L = 116.0 * f[..., 1] - 16.0
    a = 500.0 * (f[..., 0] - f[..., 1])
    b = 200.0 * (f[..., 1] - f[..., 2])
    return np.stack([L, a, b], axis=-1)


def stats(lab_px):
    """Percentiles of L* and C*, and the chroma-weighted mean hue (degrees)."""
    if len(lab_px) == 0:
        return None
    L = lab_px[:, 0]
    C = np.hypot(lab_px[:, 1], lab_px[:, 2])
    hue = np.degrees(np.arctan2((lab_px[:, 2] * C).sum(), (lab_px[:, 1] * C).sum())) % 360.0
    pct = lambda v: {str(p): round(float(np.percentile(v, p)), 1) for p in (5, 10, 50, 90, 95)}
    return {"L": pct(L), "C": pct(C), "hue": round(float(hue), 1), "pixels": int(len(L))}


def erode(mask, px):
    im = Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(px * 2 + 1))
    return np.asarray(im) > 127


MASK_DIRS = []


def mask_path(base, i):
    """A render's mask: beside it (<view>_mask<i>.png, or the older <light>_<view>_mask<i>.png), or
    in another run's same material (--masks=DIR: masks are geometry, the same for every set)."""
    d, f = os.path.split(base)
    view = f.split("_", 1)[1]
    material = os.path.basename(d)
    for root in [d] + [os.path.join(m, material) for m in MASK_DIRS]:
        for name in ("%s_mask%d.png" % (view, i), "%s_mask%d.png" % (f, i)):
            if os.path.exists(os.path.join(root, name)):
                return os.path.join(root, name)
        for light in LIGHTS:
            p = os.path.join(root, "%s_%s_mask%d.png" % (light, view, i))
            if os.path.exists(p):
                return p
    return None


def masks(base):
    """(men, per-man list, wood) boolean masks for a render's path without .png."""
    men = []
    for i in range(3):
        p = mask_path(base, i)
        men.append(np.asarray(Image.open(p).convert("L")) > 127 if p else None)
    wp = mask_path(base, 3)
    if any(m is None for m in men) or not wp:
        return None
    any_man = men[0] | men[1] | men[2]
    wood = (np.asarray(Image.open(wp).convert("L")) > 127) & ~any_man
    return any_man, men, wood


def detail(lum, mask):
    """The blur radius (in the image's own pixels) at which half the fine variance under `mask` is
    gone: the size of the painting's detail. None if the mask is too small."""
    m = erode(mask, 4)
    if m.sum() < 400:
        return None
    im = Image.fromarray(np.clip(lum, 0, 255).astype(np.uint8))
    res = []
    for r in RADII:
        bl = np.asarray(im.filter(ImageFilter.GaussianBlur(r))).astype(np.float64)
        res.append(float(np.var((lum - bl)[m])))
    top = res[-1]
    if top <= 1e-6:
        return None
    for i, v in enumerate(res):
        if v >= top * 0.5:
            if i == 0:
                return RADII[0]
            # Linear between the two radii either side of half.
            r0, r1, v0, v1 = RADII[i - 1], RADII[i], res[i - 1], v
            return round(r0 + (r1 - r0) * (top * 0.5 - v0) / max(v1 - v0, 1e-9), 2)
    return RADII[-1]


def texture_detail_mm(paths, texels_per_metre):
    """The detail size in mm of textures laid at texels_per_metre (the median over the textures)."""
    out = []
    for p in paths:
        a = np.asarray(Image.open(p).convert("L")).astype(np.float64)
        if min(a.shape) < 16:
            continue
        # Islands and their padding alike for the men's atlases: the padding is their own colour.
        d = detail(a, np.ones(a.shape, bool))
        if d:
            out.append(d / texels_per_metre * 1000.0)
    return round(float(np.median(out)), 1) if out else None


def wood_strips(wood, set_dir=WOODS):
    return sorted(glob.glob(os.path.join(set_dir, "%s_b*.png" % wood)))


def measure(root):
    result = {}
    for mdir in sorted(glob.glob(os.path.join(root, "*", "numbers.json"))):
        mdir = os.path.dirname(mdir)
        name = os.path.basename(mdir)
        nums = json.load(open(os.path.join(mdir, "numbers.json")))
        set_dir = os.path.join(ROOT, "assets", "textures", nums.get("set", "woods"))
        entry = {"numbers": nums, "lights": {}, "views": {}}
        for light in LIGHTS:
            men_px, wood_px, per_view = [], [], {}
            for v in nums["views"]:
                base = os.path.join(mdir, "%s_%s" % (light, v))
                if not os.path.exists(base + ".png"):
                    continue
                mk = masks(base)
                if mk is None:
                    continue
                any_man, men, wood = mk
                rgb = np.asarray(Image.open(base + ".png").convert("RGB"))
                L = lab(rgb)
                am, wd = erode(any_man, 2), erode(wood, 2)
                men_px.append(L[am])
                wood_px.append(L[wd])
                lum = L[..., 0] * 2.55
                vm, vw = stats(L[am]), stats(L[wd])
                per_view[v] = {"men_L": vm and vm["L"], "men_C": vm and vm["C"], "wood_L": vw and vw["L"], "wood_C": vw and vw["C"],
                               "colour_pass": colour_pass(vm, vw),
                               "men_detail_px": detail(lum, any_man), "wood_detail_px": detail(lum, wood),
                               "wood_share": round(float(wood.mean()), 3), "men_share": round(float(any_man.mean()), 3)}
            if not men_px:
                continue
            ms = stats(np.concatenate(men_px))
            ws = stats(np.concatenate(wood_px))
            entry["lights"][light] = {"men": ms, "wood": ws, "colour_pass": colour_pass(ms, ws)}
            entry["views"][light] = per_view
        # Detail on the textures, in mm.
        men_mm = {}
        for m, info in nums.get("men", {}).items():
            tex = os.path.join(ROOT, "assets", "people", "%s_skin.png" % m)
            if os.path.exists(tex) and info.get("texels_per_metre"):
                men_mm[m] = {"texels_per_metre": round(info["texels_per_metre"], 1),
                             "texel_mm": round(1000.0 / info["texels_per_metre"], 2),
                             "detail_mm": texture_detail_mm([tex], info["texels_per_metre"])}
        woods_mm = {}
        for wood, info in nums.get("woods", {}).items():
            sd = set_dir if os.path.exists(os.path.join(set_dir, "%s_b0.png" % wood)) else WOODS
            tpm = float(info.get("texels_per_metre") or 128.0)
            woods_mm[wood] = {"texels_per_metre": tpm, "texel_mm": round(1000.0 / tpm, 2),
                              "detail_mm": texture_detail_mm(wood_strips(wood, sd), tpm)}
        focus_woods = [w for w in nums["woods"] if name == "stand" or w.startswith(name)]
        if name == "props":
            # The props' own textures: the set's where it has them, else the game's factory tiles.
            index = json.load(open(os.path.join(ROOT, "assets", "textures", "textures.json")))
            set_index = json.load(open(os.path.join(set_dir, "lab.json")))["woods"] if os.path.exists(os.path.join(set_dir, "lab.json")) else {}
            woods_mm = {}
            for pid in PROPS:
                if pid in set_index:
                    path, tpm = os.path.join(set_dir, pid + ".png"), float(set_index[pid]["texels_per_metre"])
                else:
                    e = index[pid]
                    path, tpm = os.path.join(ROOT, "assets", "textures", pid + ".png"), e["texels"][0] / e["metres"][0]
                woods_mm[pid] = {"texels_per_metre": tpm, "texel_mm": round(1000.0 / tpm, 2), "detail_mm": texture_detail_mm([path], tpm)}
            focus_woods = PROPS
        entry["detail"] = {"men": men_mm, "woods": woods_mm}
        men_d = [v["detail_mm"] for v in men_mm.values() if v["detail_mm"]]
        if men_d:
            md = float(np.median(men_d))
            entry["detail_pass"] = {w: bool(woods_mm[w]["detail_mm"] and 1.0 / DETAIL_FACTOR <= woods_mm[w]["detail_mm"] / md <= DETAIL_FACTOR)
                                    for w in focus_woods if w in woods_mm}
            entry["detail_men_mm"] = round(md, 1)
        result[name] = entry
    json.dump(result, open(os.path.join(root, "measure.json"), "w"), indent=1)
    open(os.path.join(root, "measure.md"), "w").write(report(result))
    print(report(result))


def colour_pass(ms, ws):
    if not ms or not ws:
        return None
    ok = {}
    for k in ("L", "C"):
        lo, hi = ms[k]["5"], ms[k]["95"]
        ok[k] = all(lo <= ws[k][p] <= hi for p in ("10", "50", "90"))
    return ok


def report(result):
    lines = ["# The material lab's measures", "",
             "The men's range is their 5th-95th percentile in the same frames; the wood's is its 10th / "
             "median / 90th. Detail: mm on the thing (textures).", ""]
    for name, e in result.items():
        lines.append("## %s (set %s)" % (name, e["numbers"].get("set")))
        lines.append("")
        lines.append("| Light | Men L* | Wood L* | L* ok | Men C* | Wood C* | C* ok | Men hue | Wood hue |")
        lines.append("|---|---|---|---|---|---|---|---|---|")
        for light, s in e["lights"].items():
            m, w, ok = s["men"], s["wood"], s["colour_pass"] or {}
            lines.append("| %s | %s-%s | %s / %s / %s | %s | %s-%s | %s / %s / %s | %s | %s | %s |" % (
                light, m["L"]["5"], m["L"]["95"], w["L"]["10"], w["L"]["50"], w["L"]["90"], "yes" if ok.get("L") else "**no**",
                m["C"]["5"], m["C"]["95"], w["C"]["10"], w["C"]["50"], w["C"]["90"], "yes" if ok.get("C") else "**no**",
                m["hue"], w["hue"]))
        part_views = [v for v in e["numbers"]["views"] if v not in ("stand", "gameplay")]
        if part_views:
            lines.append("")
            lines.append("In the part's own views (a man within a metre or two of the wood): " + "; ".join(
                "%s %s L* %s vs men %s-%s, C* %s vs %s-%s%s" % (light, v, pv["wood_L"]["50"], pv["men_L"]["5"], pv["men_L"]["95"],
                                                         pv["wood_C"]["50"], pv["men_C"]["5"], pv["men_C"]["95"],
                                                         "" if pv["colour_pass"] and all(pv["colour_pass"].values()) else " (**out**)")
                for light, views in e["views"].items() for v, pv in views.items()
                if v in part_views and pv.get("wood_L") and pv.get("men_L")) + ".")
        d = e.get("detail", {})
        if d:
            lines.append("")
            lines.append("Detail (mm): men %s; woods %s." % (
                ", ".join("%s %s (texel %s mm, %.0f/m)" % (k, v["detail_mm"], v["texel_mm"], v["texels_per_metre"]) for k, v in d["men"].items()),
                ", ".join("%s %s (texel %s mm)" % (k, v["detail_mm"], v["texel_mm"]) for k, v in d["woods"].items())))
            if "detail_pass" in e:
                lines.append("Detail within x%.1f of the men's (%s mm): %s." % (DETAIL_FACTOR, e["detail_men_mm"], ", ".join(
                    "%s %s" % (w, "yes" if ok else "**no**") for w, ok in e["detail_pass"].items())))
        n = e["numbers"]
        lines.append("")
        lines.append("Stand: %d meshes (draws), %d triangles, %d textures, %.2f MB of texture memory." % (
            n["meshes"], n["triangles"], n["textures"], n["texture_bytes"] / 1e6))
        for wood, w in n["woods"].items():
            lines.append("- %s: %d boards (%s), %d of %d strips, %s texels/m" % (
                wood, w["boards"], "; ".join("%s x%d" % (k, c) for k, c in w["sizes"].items()), w["strips_used"], w["strips"], w["texels_per_metre"]))
        lines.append("")
    return "\n".join(lines)


def label(im, text):
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 8 + 7 * len(text), 16), fill=(0, 0, 0))
    d.text((4, 2), text, fill=(255, 255, 255))
    return im


def sheet(a_dir, b_dir, out, materials, lights, width=480):
    """Per material: one row a light, its views across; A above B when there's a B."""
    os.makedirs(out, exist_ok=True)
    names = materials or sorted(os.path.basename(os.path.dirname(p)) for p in glob.glob(os.path.join(a_dir, "*", "numbers.json")))
    for name in names:
        nums = json.load(open(os.path.join(a_dir, name, "numbers.json")))
        views = nums["views"]
        h = width * 9 // 16
        # B may be several candidates (comma-separated): B, C, D... under A.
        cands = [("A", a_dir)] + [(chr(ord("B") + i), d) for i, d in enumerate((b_dir or "").split(",")) if d]
        rows = [(tag, d, light) for light in lights for tag, d in cands
                if os.path.exists(os.path.join(d, name))]
        im = Image.new("RGB", (width * len(views), h * len(rows)), (20, 20, 20))
        for r, (tag, d, light) in enumerate(rows):
            for c, v in enumerate(views):
                p = os.path.join(d, name, "%s_%s.png" % (light, v))
                if os.path.exists(p):
                    im.paste(label(Image.open(p).convert("RGB").resize((width, h), Image.LANCZOS), "%s %s %s" % (tag, light, v)), (c * width, r * h))
        im.save(os.path.join(out, "%s.jpg" % name), quality=88)
        print("sheet:", os.path.join(out, "%s.jpg" % name))


def crops(root, out, light="golden", size=(560, 420)):
    """For each material, its part views' crops round the man nearest the most wood: a man and the
    wood in one frame, for the blind critic."""
    os.makedirs(out, exist_ok=True)
    made = []
    for mdir in sorted(glob.glob(os.path.join(root, "*", "numbers.json"))):
        mdir = os.path.dirname(mdir)
        name = os.path.basename(mdir)
        nums = json.load(open(os.path.join(mdir, "numbers.json")))
        for v in nums["views"]:
            if v in ("stand", "gameplay") and name != "stand":
                continue
            base = os.path.join(mdir, "%s_%s" % (light, v))
            mk = masks(base) if os.path.exists(base + ".png") else None
            if mk is None:
                continue
            any_man, men, wood = mk
            if any_man.sum() < 2000 or wood.sum() < 4000:
                continue
            # The crop's centre: between the biggest man's middle and the wood's.
            big = max(men, key=lambda m: m.sum())
            ys, xs = np.nonzero(big)
            wy, wx = np.nonzero(wood)
            cx = int((np.median(xs) + np.median(wx)) / 2)
            cy = int((np.median(ys) + np.median(wy)) / 2)
            img = Image.open(base + ".png").convert("RGB")
            x0 = int(np.clip(cx - size[0] // 2, 0, img.width - size[0]))
            y0 = int(np.clip(cy - size[1] // 2, 0, img.height - size[1]))
            p = os.path.join(out, "%s_%s_%s.jpg" % (name, light, v))
            img.crop((x0, y0, x0 + size[0], y0 + size[1])).save(p, quality=90)
            made.append(p)
    print("\n".join(made))


# The view each wood is picked on (its part's own, a man in it).
PICK_VIEW = {"saloon_red": "wall", "store_boards": "wall", "weathered_pine": "wall", "floor": "steps",
             "timber": "post", "fascia": "deck_ends", "framing": "wall_end", "dark_trim": "wall"}


def pick(cands, out, light="golden", width=540):
    """One sheet for Sean's pick, short enough for a phone: a row a wood (its part view at `light`,
    cropped round the man nearest the wood, the same crop in every column), the candidates across
    (`cands`: [(tag, dir)], the first the game's today, whose masks place the crop: mostly the wood)."""
    rows = []
    font = ImageFont.load_default(size=26) if hasattr(ImageFont, "load_default") else None
    for name, view in PICK_VIEW.items():
        base = os.path.join(cands[0][1], name, "%s_%s" % (light, view))
        if not os.path.exists(base + ".png"):
            continue
        img0 = Image.open(base + ".png")
        mk = masks(base)
        cw, ch = 960, 640
        if mk is not None:
            _, men, wood = mk
            big = max(men, key=lambda m: m.sum())
            ys, xs = np.nonzero(big)
            wy, wx = np.nonzero(wood)
            # Mostly the wood: the man at its edge for scale.
            cx = int(np.median(xs) * 0.3 + np.median(wx) * 0.7) if len(wx) else int(np.median(xs))
            cy = int(np.median(ys) * 0.3 + np.median(wy) * 0.7) if len(wy) else int(np.median(ys))
        else:
            cx, cy = img0.width // 2, img0.height // 2
        x0 = int(np.clip(cx - cw // 2, 0, img0.width - cw))
        y0 = int(np.clip(cy - ch // 2, 0, img0.height - ch))
        h = width * ch // cw
        row = Image.new("RGB", (width * len(cands), h + 36), (24, 22, 20))
        d = ImageDraw.Draw(row)
        d.text((8, 2), name.replace("_", " "), fill=(240, 230, 210), font=font)
        for c, (tag, dirp) in enumerate(cands):
            p = os.path.join(dirp, name, "%s_%s.png" % (light, view))
            if os.path.exists(p):
                im = Image.open(p).convert("RGB").crop((x0, y0, x0 + cw, y0 + ch)).resize((width, h), Image.LANCZOS)
                row.paste(im, (c * width, 36))
                dd = ImageDraw.Draw(row)
                dd.rectangle((c * width, 36, c * width + 14 + 15 * len(tag), 70), fill=(0, 0, 0))
                dd.text((c * width + 6, 38), tag, fill=(255, 255, 255), font=font)
        rows.append(row)
    sheet_im = Image.new("RGB", (rows[0].width, sum(r.height for r in rows)))
    y = 0
    for r in rows:
        sheet_im.paste(r, (0, y))
        y += r.height
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    sheet_im.save(out, quality=84)
    print("pick:", out, sheet_im.size)


def main():
    args = sys.argv[1:]
    opt = {a.split("=", 1)[0][2:]: a.split("=", 1)[1] for a in args if a.startswith("--") and "=" in a}
    pos = [a for a in args if not a.startswith("--")]
    if not pos:
        print(__doc__)
        return
    if "masks" in opt:
        MASK_DIRS.extend(opt["masks"].split(","))
    if pos[0] == "measure":
        measure(pos[1])
    elif pos[0] == "sheet":
        sheet(opt["a"], opt.get("b"), opt["out"], opt["material"].split(",") if "material" in opt else None,
              opt.get("light", ",".join(LIGHTS)).split(","))
    elif pos[0] == "pick":
        pick([tuple(c.split(":", 1)) for c in opt["cands"].split(",")], opt["out"], opt.get("light", "golden"),
             int(opt.get("width", 540)))
    elif pos[0] == "crops":
        crops(pos[1], opt["out"], opt.get("light", "golden"))


if __name__ == "__main__":
    main()
