#!/usr/bin/env python3
"""The woods painted in the men's hand (docs/briefs/match-the-man.md; Sean, 2026-10-16): each of the
game's woods (assets/textures/woods/, grain_woods.py's C, read by PixelArt) repainted by the image
model with the men's sheet as the style reference, then cut back into the very strips the game
reads, so no game code changes. The sheet: the Character Studio's three men since 2026-10-21
(docs/concept/targets/9_studio_men.png; roadmap 1.4a), the layered cowboy's (target 8) before.

    OPENROUTER_API_KEY=... python3 tools/textures/paint_woods.py [--only=store_boards,...] [--repaint]
    python3 tools/textures/paint_woods.py --cut [--only=...]     # re-cut the kept paintings, no calls
    ... paint_woods.py --set=NAME [--only=...] [--cut]            # a material lab candidate set

--set=NAME (the material lab, roadmap 1.4a): the set's woods (tools/textures/material_lab.json
"sets"), painted from the game's strips as above but cut into assets/textures/mlab_NAME/ at the
set's texels_per_metre (the strips' texels scaled to it), with its own lab.json; the game's woods
untouched. tools/material_lab.gd --set=mlab_NAME shows them on the stand beside the game's.
Paintings kept as raw/woods_NAME_<wood>.jpg.

For a wood with `boards` strips (<wood>_b<k>.png, 2 m along the grain, `rows` across) and, if it is
painted, its bare strip (<wood>_bare.png, the wood under the paint): the strips are stacked one
above another, stretched to the nearest picture shape the model paints, and sent with the man's
sheet. The painting is kept (assets/textures/raw/woods_<wood>.jpg), stretched back, and cut into the
same strips; each strip's two ends crossfaded so it still tiles along its length. The stacked
preview <wood>.png (its first four boards) is rewritten. End grain (<wood>_end.png) is left as it is.
Runs on GitHub Actions (People workflow, textures = woods); each call's cost printed.
"""
import http.client
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import paint_textures as pt  # noqa: E402

WOODS = os.path.join(pt.ROOT, "assets", "textures", "woods")
SPEC = os.path.join(pt.ROOT, "tools", "textures", "woods_grain.json")
MAN = pt.MAN
RAW = os.path.join(pt.RAW, "woods_%s.jpg")
SETS = os.path.join(pt.ROOT, "tools", "textures", "material_lab.json")
# The most one wood's call is expected to cost (FLUX.2 [max], ~$0.22 a call in runs 87-88), held back
# from a set's budget before each call.
NEXT_CALL = 0.35
# The picture shapes the model paints (width / height).
ASPECTS = {"1:1": 1.0, "4:3": 4 / 3, "3:4": 3 / 4, "3:2": 1.5, "2:3": 2 / 3, "16:9": 16 / 9, "9:16": 9 / 16}
# Texels at each strip's ends crossfaded into each other so it tiles along its length.
WRAP = 24

HAND = ("Repaint it in the same painted hand as the second image, the game's characters: the painted "
        "cloth of their vests, shirts, trousers and boots, a few close painted tones to each board with "
        "soft changes of light and dark along it, fine grain strokes along its length at the size of "
        "their cloth's weave and creases, knots and worn edges painted, not photographed; no "
        "photographic noise.")
ASK = (
    "The first image is a stack of {n} wooden boards seen flat and face on, each one a horizontal "
    "strip running the full width of the picture, one above another with no gaps: {what}.{bare} "
    "{hand}{wear} Keep every board exactly where it is, the same height "
    "and the same base colour as in the first image, every strip straight and horizontal "
    "across the full width. Flat, even light: no shadows, no highlights, no perspective. Only the "
    "boards: no text, no frame, no border."
)
BARE = " The bottom strip is the same wood with its paint worn off: bare weathered wood."
# How used and dirty each wood is (Sean, 2026-10-16: "make the floor boards look more weathered and
# damaged and dirty ... this would all be dirty and stained"): painted into the boards themselves.
WEAR = {
    "floor": "Heavily used and dirty, a frontier boardwalk and saloon floor: dark grime ground into "
             "the grain and the cracks between boards, tobacco-juice and whisky stains, dark rings "
             "and old spills, muddy boot scuffs tracked in from the street, dust in the cracks, split "
             "and broken board ends, gouges, rusted nail heads with dark rust bleeding into the wood, "
             "paler worn paths where boots pass most.",
    "store_boards": "Old and dirty: the paint chalky, flaking and blistered, streaks of grime and rust "
                    "running down from the nails, dust and mud splashed up the lowest boards, fly specks, "
                    "hand-greased smudges, cracks with dirt in them.",
    "saloon_red": "Old and dirty: the red paint faded, chalky and flaking to grey wood in patches, grime "
                  "in the grain and along the board edges, rust streaks below the nails, dust and mud "
                  "splashed low, water stains.",
    "weathered_pine": "Old and dirty: silvered, cracked and split, dark water stains and mildew, grime "
                      "in every crack, rust bleeding from the nails, dust and mud on the lower boards.",
    "timber": "Old posts and beams, dirty and used: dark hand grime where people lean and hitch horses, "
              "deep checks and splits with dirt in them, rope and bridle wear, mud splashed at the foot, "
              "rust stains from iron.",
    "dark_trim": "Old and dirty: the dark paint scuffed, chipped and worn through to wood at the edges, "
                 "greasy hand marks, dust in the corners.",
    "fascia": "Old and dirty: mud and dust splashed up from the street, dark water stains, cracks and "
              "split ends, rust from the nails.",
}


def strips(wood, info):
    """The wood's strips in order: its boards, then its bare strip if it has one. A candidate set may
    ask for more boards than the game's wood has (info["paint_boards"]): the extra ones are sent as
    the game's boards turned end for end and moved a metre along, and painted as boards of their own."""
    names = ["%s_b%d.png" % (wood, k) for k in range(int(info.get("paint_boards", info["boards"])))]
    if os.path.exists(os.path.join(WOODS, "%s_bare.png" % wood)):
        names.append("%s_bare.png" % wood)
    return names


def source(wood, name, info):
    """A strip of the game's wood to send: its own, or for an extra board (see strips) one of the
    game's boards turned end for end and rolled a metre. A set may want longer boards
    (info["length_scale"]: a 2 m strip made 3 m by running on into its own mirror) so a long
    member (a post, the bar's top) doesn't show its strip twice."""
    src = info.get("from", wood)
    path = os.path.join(WOODS, name.replace(wood, src, 1))
    if os.path.exists(path):
        im = Image.open(path).convert("RGB")
    else:
        k = int(name[len(wood) + 2:-4])
        im = Image.open(os.path.join(WOODS, "%s_b%d.png" % (src, k % int(info["boards"])))).convert("RGB")
        im = Image.fromarray(np.ascontiguousarray(np.roll(np.asarray(im)[:, ::-1], im.width // 2, axis=1)))
    scale = float(info.get("length_scale", 1.0))
    if scale > 1.0:
        a = np.asarray(im)
        more = int(round(a.shape[1] * (scale - 1.0)))
        tail = np.tile(a[:, ::-1], (1, int(np.ceil(scale)), 1))[:, :more]
        im = Image.fromarray(np.ascontiguousarray(np.concatenate([a, tail], axis=1)))
    return im


def aspect_for(w, h):
    r = w / h
    return min(ASPECTS.items(), key=lambda kv: abs(np.log(kv[1] / r)))


def what_of(spec, wood):
    w = spec.get(wood, {}).get("what", wood.replace("_", " "))
    return w.split(" (")[0]


def paint(wood, info, spec, key, raw=RAW, extra=""):
    names = strips(wood, info)
    ims = [source(wood, n, info) for n in names]
    w = ims[0].width
    stack = Image.new("RGB", (w, sum(i.height for i in ims)))
    y = 0
    for i in ims:
        stack.paste(i, (0, y))
        y += i.height
    name, r = aspect_for(stack.width, stack.height)
    send = stack.resize((1024, int(round(1024 / r))), Image.LANCZOS)
    if info.get("blur"):
        # The set's `blur_source`: the boards sent soft, so the model has no fine grain to copy.
        from PIL import ImageFilter
        send = send.filter(ImageFilter.GaussianBlur(float(info["blur"])))
    man = Image.open(MAN).convert("RGB")
    man.thumbnail((768, 768))  # the style, not the detail: a smaller request (a 1024 one dropped mid-reply)
    bare = BARE if names[-1].endswith("_bare.png") else ""
    wear = (" " + info["wear"]) if "wear" in info else (" " + WEAR[wood]) if wood in WEAR else ""
    if info.get("no_wear"):
        wear = ""
    what = info.get("what") or what_of(spec, wood)
    img = pt.ask(ASK.format(n=len(names), what=what, bare=bare, wear=wear, hand=info.get("hand", HAND)) + extra, [send, man],
                 {"aspect_ratio": name}, "woods_" + wood, key)
    img.convert("RGB").save(raw % wood, "JPEG", quality=94)
    print("painted: woods_%s %s (%s)" % (wood, img.size, name))


def wrap(strip, n=WRAP):
    """A strip seamless along its length: its last n texels crossfaded over its first."""
    a = np.asarray(strip).astype(np.float32)
    w = a.shape[1]
    t = np.linspace(0.0, 1.0, n)[None, :, None]
    head = a[:, :n] * t + a[:, w - n:] * (1.0 - t)
    out = np.concatenate([head, a[:, n:w - n]], axis=1)
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).resize((w, a.shape[0]), Image.LANCZOS)


def seams(painted, n):
    """Where the painting's boards meet: the darkest row (the gap between two boards) near each of
    the n - 1 even splits, searched within a third of a board either way. The model paints the
    right number of boards but not to the texel, so cut lines at fixed rows ran through boards."""
    lum = np.asarray(painted.convert("L")).astype(np.float32).mean(axis=1)
    lum = np.convolve(lum, np.ones(5) / 5.0, mode="same")
    h = len(lum)
    step = h / n
    cuts = [0]
    for k in range(1, n):
        lo = int(k * step - step / 3)
        hi = int(k * step + step / 3)
        cuts.append(lo + int(np.argmin(lum[lo:hi])))
    cuts.append(h)
    return cuts


def grade(im, g):
    """Lightness and chroma scaled in L*a*b* about the picture's own median ({"L": x, "C": x}; the
    material lab's fit into the men's range under the game's light). No paid call."""
    if not g:
        return im
    import reduce  # noqa: E402 (its Lab conversions)
    a = reduce.to_lab(np.asarray(im))
    med = np.median(a[..., 0])
    a[..., 0] = np.clip(med + (a[..., 0] - med) * g.get("contrast", 1.0), 0, 100) * g.get("L", 1.0)
    a[..., 1:] *= g.get("C", 1.0)
    return Image.fromarray(reduce.lab_to_rgb(a))


def cut(wood, info, raw=RAW, out_dir=WOODS, scale=1.0, g=None):
    names = strips(wood, info)
    sizes = [source(wood, n, info).size for n in names]
    sizes = [(round(w * scale), round(h * scale)) for w, h in sizes]
    painted = grade(Image.open(raw % wood).convert("RGB"), g)
    cuts = seams(painted, len(names))
    # Each board between its seams, the seam's dark line itself left out (the game draws the
    # boards' edges: edge_shade, edge_lip).
    trim = max(int(painted.height / len(names) * 0.06), 1)
    out = []
    for i, (n, (sw, sh)) in enumerate(zip(names, sizes)):
        top = cuts[i] + (trim if i > 0 else 0)
        bottom = cuts[i + 1] - (trim if i < len(names) - 1 else 0)
        piece = painted.crop((0, top, painted.width, bottom)).resize((sw, sh), Image.LANCZOS)
        piece = wrap(piece, round(WRAP * scale))
        piece.save(os.path.join(out_dir, n))
        out.append(piece)
    w = sizes[0][0]
    boards = [p for n, p in zip(names, out) if not n.endswith("_bare.png")][:4]
    preview = Image.new("RGB", (w, sum(p.height for p in boards)))
    y = 0
    for p in boards:
        preview.paste(p, (0, y))
        y += p.height
    preview.save(os.path.join(out_dir, "%s.png" % wood))
    print("cut: %s into %d strips" % (wood, len(names)))


def import_like_woods(out_dir):
    """Each new png in a candidate set imported as the game's woods are (lossless, mipmapped): an
    .import stub with their [params]; `godot --headless --import` fills in the rest."""
    params = open(os.path.join(WOODS, "floor_b0.png.import")).read().split("[params]", 1)[1]
    for f in sorted(os.listdir(out_dir)):
        if f.endswith(".png") and not os.path.exists(os.path.join(out_dir, f + ".import")):
            with open(os.path.join(out_dir, f + ".import"), "w") as fh:
                fh.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]' + params)


def bands(wood, cfg, out_dir, tpm):
    """A set's wood cut from a kept painting of one surface (`from_painting`: no call): the
    painting's height split into `boards` bands, each a board `board_m` high and `length_m` long,
    graded, every other one turned end for end so neighbours differ."""
    fp = cfg["from_painting"][wood]
    im = grade(Image.open(os.path.join(pt.RAW, fp["raw"])).convert("RGB"), cfg.get("grade", {}).get(wood))
    n = int(fp["boards"])
    size = (round(float(fp["length_m"]) * tpm), round(float(fp["board_m"]) * tpm))
    h = im.height // n
    out = []
    for k in range(n):
        piece = im.crop((0, k * h, im.width, (k + 1) * h)).resize(size, Image.LANCZOS)
        if k % 2:
            piece = piece.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        piece = wrap(piece, max(4, size[0] // 32))
        piece.save(os.path.join(out_dir, "%s_b%d.png" % (wood, k)))
        out.append(piece)
    for k in range(n, 16):
        # Boards a earlier cut of this wood left past this one's last (WoodMaterials counts strips
        # until one is missing).
        for stale in ("%s_b%d.png" % (wood, k), "%s_b%d.png.import" % (wood, k)):
            if os.path.exists(os.path.join(out_dir, stale)):
                os.remove(os.path.join(out_dir, stale))
    preview = Image.new("RGB", (size[0], size[1] * min(4, n)))
    for k, p in enumerate(out[:4]):
        preview.paste(p, (0, k * size[1]))
    preview.save(os.path.join(out_dir, "%s.png" % wood))
    print("cut: %s into %d boards from %s" % (wood, n, fp["raw"]))
    return {"boards": n, "rows": size[1], "length": size[0], "texels_per_metre": tpm,
            "end": "%s_end.png" % wood, "end_texels": 256}


def candidate(name, only, cut_only, repaint, key, spec):
    """A material lab candidate set: painted from the game's strips, cut into mlab_<name>/."""
    sets = json.load(open(SETS))["sets"]
    if name not in sets:
        print("No set %s in %s" % (name, SETS))
        sys.exit(1)
    cfg = sets[name]
    lab = json.load(open(os.path.join(WOODS, "lab.json")))["woods"]
    out_dir = os.path.join(pt.ROOT, "assets", "textures", "mlab_" + name)
    os.makedirs(out_dir, exist_ok=True)
    # `raw`: cut another set's kept paintings instead (e.g. the game's own, "woods_%s.jpg": no calls).
    raw = os.path.join(pt.RAW, cfg.get("raw", "woods_" + name + "_%s.jpg"))
    if "raw" in cfg:
        cut_only = True
    tpm = float(cfg.get("texels_per_metre", 128))
    index_path = os.path.join(out_dir, "lab.json")
    index = json.load(open(index_path)) if os.path.exists(index_path) else {"woods": {}}
    index["set"] = name
    index["note"] = cfg.get("note", "")
    failed = []
    if "inherit" in cfg:
        # The woods this set doesn't paint, as the set it builds on has them.
        base = os.path.join(pt.ROOT, "assets", "textures", "mlab_" + cfg["inherit"])
        base_index = json.load(open(os.path.join(base, "lab.json")))["woods"]
        for wood, entry in base_index.items():
            if wood in cfg["woods"] or wood in cfg.get("props", []):
                continue
            for f in os.listdir(base):
                if f.endswith(".png") and (f == wood + ".png" or f.startswith(wood + "_")) and \
                        not any(f.startswith(w + "_") for w in base_index if w != wood and w.startswith(wood + "_")):
                    Image.open(os.path.join(base, f)).save(os.path.join(out_dir, f))
            index["woods"][wood] = entry
    new_woods = cfg.get("new_woods", {})
    for wood in list(cfg["woods"]) + list(new_woods):
        if only and wood not in only:
            continue
        if wood in new_woods:
            # A wood the game hasn't got: painted from another's boards (`from`), as `what` says.
            nw = new_woods[wood]
            info = dict(lab[nw["from"]])
            info.update({k: v for k, v in nw.items() if k in ("from", "what", "wear")})
        else:
            info = dict(lab[wood])
        if wood in cfg.get("boards", {}):
            info["paint_boards"] = int(cfg["boards"][wood])
        if wood in cfg.get("length", {}):
            info["length_scale"] = float(cfg["length"][wood]) / 2.0
        for k, ck in (("hand", "hand"), ("blur", "blur_source"), ("no_wear", "no_wear")):
            if ck in cfg:
                info[k] = cfg[ck]
        if not cut_only and (repaint or not os.path.exists(raw % wood)):
            for attempt in range(2):
                # The set's budget (Sean's approval): no call that could take the run past it.
                if "budget" in cfg and pt.SPENT + NEXT_CALL > float(cfg["budget"]):
                    print("budget: $%.2f spent of $%.2f; %s not painted" % (pt.SPENT, float(cfg["budget"]), wood))
                    break
                try:
                    paint(wood, info, spec, key, raw, cfg.get("ask", ""))
                    break
                except (RuntimeError, OSError, KeyError, ValueError, http.client.HTTPException) as e:
                    print("failed (try %d):" % (attempt + 1), e)
            else:
                failed.append(wood)
                continue
        if not os.path.exists(raw % wood):
            continue
        scale = tpm / float(info.get("texels_per_metre", 128))
        cut(wood, info, raw, out_dir, scale, cfg.get("grade", {}).get(wood))
        # End grain as the game's (its own density): copied.
        end = os.path.join(WOODS, "%s_end.png" % info.get("from", wood))
        if os.path.exists(end):
            Image.open(end).save(os.path.join(out_dir, "%s_end.png" % wood))
        entry = dict(info)
        for k in ("hand", "blur", "no_wear"):
            entry.pop(k, None)
        entry["boards"] = int(entry.pop("paint_boards", entry["boards"]))
        if "from" in entry:
            # Its own wood: none of the other's paint wear (it has no bare strip).
            entry.pop("end_wear", None)
        for k in ("from", "what", "wear"):
            entry.pop(k, None)
        entry["end"] = "%s_end.png" % wood
        entry["texels_per_metre"] = tpm
        entry["length"] = round(info["length"] * scale * float(entry.pop("length_scale", 1.0)))
        entry["rows"] = round(info["rows"] * scale)
        index["woods"][wood] = entry
    json.dump(index, open(index_path, "w"), indent=1)
    for wood in cfg.get("from_painting", {}):
        if only and wood not in only:
            continue
        index["woods"][wood] = bands(wood, cfg, out_dir, tpm)
        end = os.path.join(WOODS, "%s_end.png" % cfg["from_painting"][wood].get("end_from", "dark_trim"))
        if os.path.exists(end):
            Image.open(end).save(os.path.join(out_dir, "%s_end.png" % wood))
    json.dump(index, open(index_path, "w"), indent=1)
    # The set's props (materials.json ids: chairs, the card table, barrels), painted with the same
    # sheet inside the same budget and cut by reduce.py --set into this set.
    props = [p for p in cfg.get("props", []) if not only or p in only]
    if props:
        materials = json.load(open(pt.SPEC))["materials"]
        for mid in props:
            out = os.path.join(pt.RAW, "%s_%s.jpg" % (name, mid))
            if not cut_only and (repaint or not os.path.exists(out)):
                if pt.paint_material(mid, materials[mid], key, out, True, 2, float(cfg.get("budget", 1e9))) is None:
                    failed.append(mid)
        import subprocess
        subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), "reduce.py"),
                        "--set=" + name, "--only=" + ",".join(props)]
                       + (["--texels=%g" % cfg["prop_texels"]] if "prop_texels" in cfg else []), check=False)
        # A prop painted as boards (reduce made it a wood of the set) takes the timber's end grain.
        for mid in props:
            end = os.path.join(out_dir, "%s_end.png" % mid)
            if materials[mid].get("boards") and not os.path.exists(end):
                Image.open(os.path.join(WOODS, "timber_end.png")).save(end)
    import_like_woods(out_dir)
    print("spent: $%.2f" % pt.SPENT)
    if failed:
        print("not painted:", ", ".join(failed))
        sys.exit(1)


def main():
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1] not in ("", "all", "woods"):
            only = a.split("=", 1)[1].split(",")
    cut_only = "--cut" in sys.argv
    repaint = "--repaint" in sys.argv
    lab = json.load(open(os.path.join(WOODS, "lab.json")))["woods"]
    spec = json.load(open(SPEC))["woods"]
    key = os.environ.get("OPENROUTER_API_KEY", "")
    if not cut_only and not key:
        print("No OPENROUTER_API_KEY: woods not painted.")
        return
    os.makedirs(pt.RAW, exist_ok=True)
    for a in sys.argv[1:]:
        if a.startswith("--set="):
            candidate(a.split("=", 1)[1], only, cut_only, repaint, key, spec)
            return
    failed = []
    for wood, info in lab.items():
        if only and wood not in only:
            continue
        if not cut_only and (repaint or not os.path.exists(RAW % wood)):
            for attempt in range(2):
                try:
                    paint(wood, info, spec, key)
                    break
                except (RuntimeError, OSError, KeyError, ValueError, http.client.HTTPException) as e:
                    print("failed (try %d):" % (attempt + 1), e)
            else:
                failed.append(wood)
                continue
        if os.path.exists(RAW % wood):
            cut(wood, info)
    if failed:
        print("not painted:", ", ".join(failed))
        sys.exit(1)


if __name__ == "__main__":
    main()
