"""The doctor's office, batch D2 (#805; docs/briefs/prop-factory.md "The doctor's office batch"): the
dispensary's medicine bottles, mortar and pestle and scales, and the brass and leather of his desk,
modelled here in the kit's space from tools/props/doctor.py's numbers and baked the gun way
(metal.py): glass drawn by the game (the kit's `glass:` looks), paper labels printed here onto their
own sheet (medicine_labels_albedo.png, Pillow: period druggist's labels, Latin names as the
pharmacopoeia of the 1870s-80s gave them), cork, what's in the bottles, Wedgwood stoneware, brass.

    ~/bpyenv/bin/python tools/blender/props/build.py --only=doctor_d2    (~1 min a model)
    ~/bpyenv/bin/python tools/blender/props/doctor_d2.py --only=bottles,labels,mortar,scales,desk

Then `godot --headless --import` and commit the .glb and .png files with their .import files.
"""
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "props"))

import common  # noqa: E402
import doctor  # noqa: E402  (tools/props/doctor.py: the numbers)
import metal  # noqa: E402
from common import Part, box, lathe, moved, tube  # noqa: E402


def torus_ring(name, radius, y, tube_r, segs=40, sides=6):
    pts = [(math.cos(2 * math.pi * k / segs) * radius, y, math.sin(2 * math.pi * k / segs) * radius) for k in range(segs + 1)]
    return tube(name, pts, tube_r, sides=sides, caps=(False, False))

# The label sheet: 1024 px square, four rows (one a kind of bottle), four labels a row, at
# LABEL_PX pixels a metre of label (a 4 oz bottle's label is ~130 px tall: its small print legible
# from a step away, as the target sheet's shelf is seen).
SHEET = 1024
LABEL_PX = 3000.0
KINDS = ["panel", "round", "poison", "jar"]
RING = 24  # points round a bottle (a multiple of 6: the hexagon's corners land on points)


def merged(name, parts, smooth=True):
    out = Part(name, smooth)
    for p in parts:
        out.merge(p)
    return out


# --- The bottles' shape ---------------------------------------------------------------------------

def section_point(sec, th):
    """A section's outline at angle th (from +x toward +z): a superellipse (squareness 2 an ellipse,
    6 a box with round corners) or, with sides 6, a hexagon with a flat to +z, its corners eased."""
    _, a, b, p, sides = sec
    c, s = math.cos(th), math.sin(th)
    if sides:
        seg = 2 * math.pi / sides
        k = ((th - math.pi * 0.5 + seg * 0.5) % seg) - seg * 0.5
        apo = a * math.cos(math.pi / sides)
        rr = 0.9 * apo / math.cos(k) + 0.1 * apo * 1.05
        return (c * rr, s * rr)
    e = 2.0 / p
    return (a * math.copysign(abs(c) ** e, c), b * math.copysign(abs(s) ** e, s))


def section_at(sections, y):
    """The section at height y, between the two it lies between (half widths eased linearly)."""
    for lo, hi in zip(sections, sections[1:]):
        if lo[0] <= y <= hi[0]:
            t = (y - lo[0]) / max(1e-9, hi[0] - lo[0])
            return (y, lo[1] + (hi[1] - lo[1]) * t, lo[2] + (hi[2] - lo[2]) * t, lo[3], lo[4])
    return sections[-1]


def loft(name, sections, shrink=0.0, top_cap=False, n=RING):
    """A bottle's skin: a ring at each section, its bottom closed (pushed up into a kick, as blown
    bottles are), its top open (the neck's bore) or closed with `top_cap` (a liquid's surface).
    `shrink` takes that much off every half width (the glass's wall: what's inside it)."""
    verts, faces = [], []
    secs = [(y, max(1e-4, a - shrink), max(1e-4, b - shrink), p, sd) for y, a, b, p, sd in sections]
    for sec in secs:
        for k in range(n):
            x, z = section_point(sec, 2 * math.pi * k / n)
            verts.append((x, sec[0], z))
    for i in range(len(secs) - 1):
        for k in range(n):
            a = i * n + k
            b = i * n + (k + 1) % n
            faces.append([a, a + n, b + n, b])
    verts.append((0.0, secs[0][0] + (0.004 if not shrink else 0.0), 0.0))
    c = len(verts) - 1
    faces += [[c, k, (k + 1) % n] for k in range(n)]
    if top_cap:
        verts.append((0.0, secs[-1][0], 0.0))
        c = len(verts) - 1
        base = (len(secs) - 1) * n
        faces += [[c, base + (k + 1) % n, base + k] for k in range(n)]
    return Part(name, smooth=True).add(verts, faces)


def label_patch(name, sections, y0, y1, half, px_rect, nu=14, nv=4, lift=0.0005):
    """A paper label laid on the bottle between heights y0..y1, round the front (+z) from angle
    pi/2 + half (the viewer's left) to pi/2 - half, standing `lift` off the glass; its UVs the
    rectangle `px_rect` (x0, y0, x1, y1 in the sheet's pixels, y down) of the label sheet."""
    verts, uvs, faces = [], [], []
    x0, py0, x1, py1 = px_rect
    for j in range(nv + 1):
        y = y0 + (y1 - y0) * j / nv
        sec = section_at(sections, y)
        for i in range(nu + 1):
            th = math.pi * 0.5 + half - 2 * half * i / nu
            x, z = section_point(sec, th)
            rr = math.hypot(x, z)
            verts.append((x + x / rr * lift, y, z + z / rr * lift))
            u = (x0 + (x1 - x0) * i / nu) / SHEET
            v = 1.0 - (py1 + (py0 - py1) * j / nv) / SHEET  # Blender's v runs up the image
            uvs.append((u, v))
    for j in range(nv):
        for i in range(nu):
            a = j * (nu + 1) + i
            faces.append([a, a + 1, a + nu + 2, a + nu + 1])
    part = Part(name, smooth=True).add(verts, faces)
    part.uvs = uvs
    return part


def label_size(kind):
    """A label's width (its arc at mid height) and height, in metres."""
    b = doctor.BOTTLES[kind]
    y0, y1, half = b["label"]
    sec = section_at(b["sections"], (y0 + y1) * 0.5)
    pts = [section_point(sec, math.pi * 0.5 + half - 2 * half * i / 40) for i in range(41)]
    arc = sum(math.dist(p, q) for p, q in zip(pts, pts[1:]))
    return arc, y1 - y0


def label_rect(kind, n):
    """Where label n of a kind sits on the sheet (pixels, y down): row by kind, column by n."""
    w, h = label_size(kind)
    pw, ph = int(round(w * LABEL_PX)), int(round(h * LABEL_PX))
    cell = SHEET // 4
    x0 = n * cell + (cell - pw) // 2
    y0 = KINDS.index(kind) * cell + (cell - ph) // 2
    return (x0, y0, x0 + pw, y0 + ph)


def bottles():
    parts = []
    for kind in KINDS:
        b = doctor.BOTTLES[kind]
        k = kind.capitalize()
        secs = b["sections"]
        parts.append((loft("Glass" + k, secs), None))
        # What's in it: the inside of the glass up to its level, its surface flat.
        level, finish = b["liquid"]
        inside = [s for s in secs if s[0] < level] + [section_at(secs, level)]
        inside = [(max(y, 0.006), *rest) for y, *rest in inside]
        if b.get("fills"):
            # What's in it by its label (the Nth label's jar holds the Nth fill).
            for n, fill in enumerate(b["fills"]):
                parts.append((loft("Liquid%s%d" % (k, n), inside, shrink=0.0028, top_cap=True), fill))
        else:
            parts.append((loft("Liquid" + k, inside, shrink=0.0028, top_cap=True), finish))
        y0, y1, half = b["label"]
        for n in range(len(b["labels"])):
            parts.append((label_patch("Label%s%d" % (k, n), secs, y0, y1, half, label_rect(kind, n)), None))
        kind_s, rad, sy0, sy1 = b["stopper"]
        if kind_s == "cork":
            parts.append((lathe("Cork" + k, [(rad * 0.86, sy0), (rad, sy0 + 0.004), (rad * 1.04, sy1 - 0.003), (rad * 0.96, sy1), (0.0, sy1)], 14), "cork"))
        else:
            # A ground glass stopper: its plug in the neck, a flat mushroom head.
            parts.append((lathe("Stopper" + k, [(rad * 0.9, sy0), (rad, sy0 + 0.014), (rad * 0.62, sy0 + 0.02), (rad * 1.45, sy0 + 0.028),
                                               (rad * 1.55, sy0 + 0.036), (rad * 1.3, sy1), (0.0, sy1)], 24), None))
    metal.export_baked("medicine_bottles", parts, size=512)


# --- The labels: printed on their own sheet --------------------------------------------------------

FONT_DIR = "/usr/share/fonts/truetype/liberation/"


def _font(style, size):
    from PIL import ImageFont
    name = {"bold": "LiberationSerif-Bold.ttf", "italic": "LiberationSerif-Italic.ttf", "regular": "LiberationSerif-Regular.ttf"}[style]
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size)


def _fit(draw, text, style, size, width):
    """The font at `size` or smaller that sets `text` within `width` pixels."""
    while size > 6:
        f = _font(style, size)
        if draw.textlength(text, font=f) <= width:
            return f
        size -= 1
    return _font(style, 6)


def _centred(draw, text, y, f, cx, fill):
    w = draw.textlength(text, font=f)
    draw.text((cx - w * 0.5, y), text, font=f, fill=fill)


def _skull(draw, cx, cy, s, fill):
    """A small skull and crossbones (the poison label's)."""
    for d in (-1, 1):
        draw.line([(cx - s * 1.1, cy + s * 0.2 - d * s * 0.9), (cx + s * 1.1, cy + s * 0.2 + d * s * 0.9)], fill=fill, width=max(2, int(s * 0.28)))
    draw.ellipse([cx - s * 0.62, cy - s * 0.95, cx + s * 0.62, cy + s * 0.25], fill=fill)
    draw.rectangle([cx - s * 0.35, cy + s * 0.1, cx + s * 0.35, cy + s * 0.45], fill=fill)


def labels():
    """The label sheet (medicine_labels_albedo.png) and its ORM (paper: no metal, dull)."""
    from PIL import Image, ImageDraw, ImageFilter

    img = Image.new("RGB", (SHEET, SHEET), (60, 50, 40))
    rng = random.Random(805)
    for kind in KINDS:
        b = doctor.BOTTLES[kind]
        for n, (name, sub, dose) in enumerate(b["labels"]):
            x0, y0, x1, y1 = label_rect(kind, n)
            w, h = x1 - x0, y1 - y0
            lab = Image.new("RGB", (w, h))
            d = ImageDraw.Draw(lab)
            if kind == "poison":
                paper, ink = (196, 62, 38), (24, 14, 10)
            elif b.get("gilt"):
                paper, ink = (22, 19, 17), (196, 156, 82)
            else:
                # Cream paper, gone a little brown with age, each label its own.
                t = rng.uniform(-12, 8)
                paper, ink = (int(232 + t), int(220 + t), int(188 + t * 1.3)), (28, 22, 18)
            d.rectangle([0, 0, w, h], fill=paper)
            m = max(3, int(w * 0.045))
            # The border: a heavy rule and a hair rule inside it (the period's printed labels).
            d.rectangle([m, m, w - m - 1, h - m - 1], outline=ink, width=max(2, m // 2))
            d.rectangle([m * 2, m * 2, w - m * 2 - 1, h - m * 2 - 1], outline=ink, width=1)
            cx = w * 0.5
            inner = w - m * 5
            if kind == "poison":
                f = _fit(d, "POISON", "bold", int(h * 0.2), inner)
                _centred(d, "POISON", m * 2.4, f, cx, ink)
                _skull(d, cx, h * 0.5, w * 0.16, ink)
                f2 = _fit(d, sub, "bold", int(h * 0.13), inner)
                _centred(d, sub, h * 0.7, f2, cx, ink)
            elif b.get("gilt"):
                # Gilt lettering on black (the shop round's label, varnished over): the name alone.
                d.rectangle([m * 3, m * 3, w - m * 3 - 1, h - m * 3 - 1], outline=ink, width=1)
                inner = w - m * 8
                words = name.split(" ")
                lines = [" ".join(words[:1]), " ".join(words[1:])] if len(words) > 1 else [name]
                fs = min(int(h * 0.28), min(int(h * 0.28 * inner / max(1, d.textlength(l, font=_font("bold", int(h * 0.28))))) for l in lines))
                f = _font("bold", max(8, fs))
                top = h * 0.5 - len(lines) * fs * 0.55
                for i, line in enumerate(lines):
                    _centred(d, line, top + i * fs * 1.1, f, cx, ink)
            else:
                small = _fit(d, "DISPENSARY", "regular", int(h * 0.08), inner)
                _centred(d, "DISPENSARY", m * 2.5, small, cx, ink)
                d.line([(cx - inner * 0.3, m * 2.5 + h * 0.11), (cx + inner * 0.3, m * 2.5 + h * 0.11)], fill=ink, width=1)
                words = name.split(" ")
                lines = [name] if d.textlength(name, font=_font("bold", int(h * 0.15))) <= inner else [" ".join(words[:-1]), words[-1]]
                fs = min(int(h * 0.15), min(int(h * 0.15 * inner / max(1, d.textlength(l, font=_font("bold", int(h * 0.15))))) for l in lines))
                f = _font("bold", max(8, fs))
                y = h * 0.3
                for line in lines:
                    _centred(d, line, y, f, cx, ink)
                    y += fs * 1.08
                dose_y = h - m * 2.6 - h * 0.15
                if sub:
                    fi = _fit(d, sub, "italic", int(h * 0.09), inner)
                    _centred(d, sub, y + h * 0.02, fi, cx, ink)
                    y += h * 0.02 + h * 0.1
                if dose and y < dose_y:
                    fd = _fit(d, dose, "regular", int(h * 0.07), inner)
                    _centred(d, dose, dose_y, fd, cx, ink)
                fd = _fit(d, "SALT CREEK", "regular", int(h * 0.06), inner * 0.6)
                _centred(d, "SALT CREEK", h - m * 2.4 - h * 0.075, fd, cx, ink)
            # Age: a soft tide mark from below, flecks, the print a touch soft.
            px = lab.load()
            stain = rng.uniform(0.0, 0.5) if not b.get("gilt") else 0.0
            for yy in range(h):
                for xx in range(w):
                    r_, g_, b_ = px[xx, yy]
                    k = 1.0 - stain * max(0.0, (yy / h - 0.7) / 0.3) * 0.35
                    k *= 1.0 - 0.06 * rng.random()
                    px[xx, yy] = (int(r_ * k), int(g_ * k * 0.98), int(b_ * k * 0.94))
            lab = lab.filter(ImageFilter.GaussianBlur(0.4))
            img.paste(lab, (x0, y0))
    out = os.path.join(common.MODELS, "medicine_labels_albedo.png")
    img.save(out)
    Image.new("RGB", (64, 64), (255, int(0.78 * 255), 0)).save(os.path.join(common.MODELS, "medicine_labels_orm.png"))
    print("labels ->", os.path.relpath(out, common.ROOT))


# --- The mortar and pestle (Wedgwood ware) ---------------------------------------------------------

def mortar():
    m = doctor.MORTAR
    R, H, F = m["radius"], m["height"], m["foot"]
    br, bd = m["bowl"], m["bowl_depth"]
    # (the Met's: a low rounded foot ring, the body swelling to a thick rounded rim)
    prof = [(F, 0.0), (F + 0.002, 0.004), (F + 0.001, 0.008), (R * 0.86, 0.02), (R * 0.97, 0.038), (R, H - 0.014),
            (R + 0.002, H - 0.006), (R - 0.002, H), (br + 0.006, H + 0.001), (br, H - 0.006)]
    # The bowl: a deep round hollow, ground smooth.
    for k in range(1, 9):
        a = math.pi * 0.5 * k / 8
        prof.append((br * math.cos(a), H - 0.006 - (bd - 0.006) * math.sin(a)))
    body = lathe("Mortar", prof, 40, caps=(True, False))
    # The pouring lip: the rim's +x side drawn out and down a little into a spout.
    verts = []
    for vx, vy, vz in body.verts:
        if vy > H - 0.03 and vx > 0.0:
            k = (vx / max(1e-6, math.hypot(vx, vz))) ** 10 * min(1.0, (vy - (H - 0.03)) / 0.03)
            vx += 0.026 * k
            vy -= 0.003 * k
        verts.append((vx, vy, vz))
    body.verts = verts
    p = m["pestle"]
    tilt = math.radians(p["tilt"])
    # The pestle: its stoneware head in the bowl's bottom, its turned handle leaning out over the
    # rim away from the lip (-x).
    head = lathe("Pestle", [(0.0, 0.0), (p["head"] * 0.7, 0.004), (p["head"], 0.016), (p["head"] * 0.9, 0.03), (0.013, 0.045), (0.011, 0.05), (0.0, 0.05)], 20)
    handle = lathe("PestleHandle", [(0.0105, 0.048), (0.012, 0.06), (0.0105, 0.11), (0.0125, 0.15), (0.016, p["length"] - 0.025),
                                    (0.017, p["length"] - 0.012), (0.012, p["length"] - 0.003), (0.0, p["length"])], 16)
    at = (0.0, H - bd + 0.004, 0.0)
    head = moved(head, math.degrees(tilt), (0, 0, 1), at)
    handle = moved(handle, math.degrees(tilt), (0, 0, 1), at)
    metal.export_baked("mortar", [(body, "stoneware"), (head, "stoneware"), (handle, "turned_wood")], size=512)


# --- The scales ----------------------------------------------------------------------------------

def scales():
    c = doctor.SCALES
    bx, by, bz = c["base"]
    z = -0.02
    knob = lathe("Knob", [(0.007, 0.0), (0.009, 0.005), (0.005, 0.009), (0.010, 0.014), (0.0, 0.018)], 12, axis="z", at=(0, by * 0.5, bz * 0.5 + 0.012))
    by0 = by
    top = c["beam_y"]
    # The pillar: a turned brass column on a round foot, a collar, a fork at its head for the beam's
    # knife edge; the scale's ivory-white arc at its foot (a brass plate here) under the pointer.
    col = lathe("c", [(0.032, by0), (0.032, by0 + 0.006), (0.024, by0 + 0.012), (0.012, by0 + 0.02), (0.008, by0 + 0.03),
                      (0.0065, top - 0.09), (0.011, top - 0.085), (0.011, top - 0.075), (0.0065, top - 0.07), (0.0065, top - 0.02),
                      (0.010, top - 0.016), (0.010, top - 0.006), (0.0, top - 0.006)], 20, at=(0, 0, z))
    fork = [box("f", (0.004, 0.022, 0.014), (s_ * 0.007, top + 0.002, z), bevel=0.001) for s_ in (-1, 1)]
    plate = box("p", (0.036, 0.014, 0.002), (0, by0 + 0.06, z + 0.011), bevel=0.0008)
    pillar = merged("Pillar", [col, *fork, plate])  # (the scale: a small plate the pointer reads against)
    # The beam: thicker at its middle, tapering to its ends' hooks; its pointer down the pillar's
    # front to the scale.
    lx, ly, lz = c["beam"]
    beam = tube("b", [(-lx * 0.5, top, z), (0.0, top, z), (lx * 0.5, top, z)], [(0.0025, 0.003), (0.004, 0.007), (0.0025, 0.003)], sides=8,
                up_hint=(0, 1, 0))
    hub = lathe("h", [(0.0, -0.007), (0.009, -0.006), (0.009, 0.006), (0.0, 0.007)], 16, axis="z", at=(0, top, z))
    pointer = tube("n", [(0.0, top - 0.008, z + 0.01), (0.0, by0 + 0.06, z + 0.01)], [(0.0016, 0.0016), (0.0008, 0.0008)], sides=5)
    hooks = [lathe("k", [(0.0, -0.004), (0.004, -0.003), (0.004, 0.004), (0.0, 0.005)], 8, at=(s_ * lx * 0.5, top - 0.003, z)) for s_ in (-1, 1)]
    beam_part = merged("Beam", [beam, hub, pointer, *hooks])
    p = c["pan"]
    pans = []
    for s_, name in ((-1, "L"), (1, "R")):
        x = s_ * lx * 0.5
        R = p["radius"]
        dish = lathe("d", [(0.0, -0.002), (R * 0.6, -0.001), (R * 0.92, 0.008), (R, 0.014), (R - 0.002, 0.0145), (R * 0.9, 0.009),
                           (R * 0.58, 0.002), (0.0, 0.001)], 28, at=(x, p["y"], z), caps=(False, False))
        wires = []
        for k in range(3):
            a = 2 * math.pi * k / 3 + math.pi * 0.5
            wires.append(tube("w", [(x + math.cos(a) * (R - 0.004), p["y"] + 0.014, z + math.sin(a) * (R - 0.004)), (x, top - 0.012, z)],
                              0.0009, sides=5))
        pans.append(merged("Pan" + name, [dish, *wires]))
    metal.export_baked("scales", [(knob, "brass"), (pillar, "brass"), (beam_part, "brass"), (pans[0], "brass"), (pans[1], "brass")], size=512)


# --- The desk's brass: a bail pull on each drawer, a knob on each small one -------------------------

def desk_brass():
    parts = []
    for did, (w, h), (x, y, zf) in doctor.desk_drawers():
        z = zf + 0.01
        # A cast brass bail pull (round 1: "tiny"; a roll-top's are ~10 cm across): an oval back plate,
        # two posts, the bail hanging in them.
        plate = moved(lathe("p", [(0.0, 0.0), (0.02, 0.0), (0.02, 0.0022), (0.0, 0.003)], 16, axis="z"), 0, (0, 0, 1), (0, 0, 0))
        plate.verts = [(vx * 2.6, vy, vz) for vx, vy, vz in plate.verts]
        plate = moved(plate, 0, (0, 0, 1), (x, y + 0.006, z))
        posts = [lathe("o", [(0.004, 0.0), (0.0045, 0.01), (0.003, 0.015), (0.0, 0.016)], 8, axis="z", at=(x + s_ * 0.04, y + 0.008, z)) for s_ in (-1, 1)]
        pts = [(x + 0.04 * math.cos(math.pi * k / 12), y + 0.008 - 0.028 * math.sin(math.pi * k / 12), z + 0.014) for k in range(13)]
        bail = tube("b", pts, 0.003, sides=6, caps=(True, True))
        parts.append((merged("Pull_" + did, [plate, *posts, bail]), "brass"))
    # The counter's drawers' turned knobs.
    for did, (w, h), (x, y, z) in doctor.counter_drawers():
        parts.append((lathe("Knob_" + did, [(0.006, 0.0), (0.008, 0.005), (0.005, 0.01), (0.009, 0.016), (0.0, 0.021)], 10, axis="z",
                            at=(x, y, z - 0.009 - 0.021) if False else (x, y, z - 0.009)), "brass"))
    for did, (w, h), (x, y, z) in doctor.desk_small_drawers():
        parts.append((lathe("Pull_" + did, [(0.004, 0.0), (0.006, 0.004), (0.0035, 0.008), (0.0065, 0.012), (0.0, 0.015)], 10, axis="z",
                            at=(x, y, z + 0.006)), "brass"))
    # His papers in the pigeonholes: bundles of letters standing, a ledger lying, a few envelopes.
    d = doctor.DESK
    inner = d["width"] - d["panel"] * 2
    pd = d["pigeon_depth"]
    zb = -d["depth"] * 0.5 + d["panel"]
    py0 = d["pigeon_y"][0]
    rng = random.Random(7)
    papers = []
    n = d["pigeons"]
    cell = (inner - 0.012) / n
    for k in range(n):
        if k in (2, 6):
            continue
        cx = -inner * 0.5 + 0.006 + cell * (k + 0.5)
        kind = rng.random()
        if kind < 0.45:
            # Letters standing on edge, a bundle leaning.
            for i in range(rng.randint(3, 6)):
                hgt = rng.uniform(0.09, 0.14)
                papers.append(moved(box("l", (0.004, hgt, pd * rng.uniform(0.55, 0.8)), (0, hgt * 0.5, 0), bevel=0.0008),
                                    rng.uniform(-8, 8), (0, 0, 1), (cx - cell * 0.3 + i * 0.012, py0, zb + pd * 0.55)))
        elif kind < 0.8:
            # A stack of papers lying flat, a little askew.
            for i in range(rng.randint(2, 5)):
                papers.append(moved(box("s", (cell * 0.75, 0.004, pd * 0.8), (0, 0.002, 0)), rng.uniform(-5, 5), (0, 1, 0),
                                    (cx + rng.uniform(-0.006, 0.006), py0 + i * 0.0045, zb + pd * 0.55)))
        else:
            # A ledger lying.
            papers.append(box("g", (cell * 0.8, 0.025, pd * 0.85), (cx, py0 + 0.0125, zb + pd * 0.52), bevel=0.003))
    parts.append((merged("Papers", papers, smooth=False), "paper"))
    metal.export_baked("desk_brass", parts, size=512)


# --- His bentwood chair (Thonet's No. 14) ----------------------------------------------------------

def bentwood_chair():
    c = doctor.BENTWOOD
    sy, R, top = c["seat_y"], c["seat_r"], c["back_top"]
    r = 0.014  # the bent rod's radius (~28 mm beech)
    parts = []
    # The seat: its bent ring, the caned seat inside it.
    parts.append((torus_ring("SeatRing", R, sy, r, segs=36, sides=8), "bentwood"))
    cane = lathe("Seat", [(0.0, sy + 0.004), (R - 0.004, sy + 0.004), (R - 0.006, sy + 0.001), (0.0, sy + 0.001)], 36)
    parts.append((cane, "cane"))
    # The front legs: from under the ring's front quarters down and out to the floor, tapering.
    for name, sx in (("LegFL", -1), ("LegFR", 1)):
        a = math.radians(90 - 42 * sx)
        x0, z0 = math.cos(a) * R * 0.92 * -1 * -1, math.sin(a) * R * 0.92
        x0 = sx * abs(x0)
        pts = [(x0, sy - 0.01, z0), (x0 * 1.08, sy * 0.5, z0 * 1.08), (x0 * 1.16, 0.0, z0 * 1.16)]
        parts.append((tube(name, pts, [(r, r), (r * 0.95, r * 0.95), (r * 0.8, r * 0.8)], sides=10), "bentwood"))
    # The back legs: one bent rod each, from the floor behind up through the seat's back into the
    # hoop of the back (the No. 14's one piece), meeting at its top.
    hoop = []
    for sx in (-1, 1):
        side = []
        side.append((sx * 0.17, 0.0, -0.27))
        side.append((sx * 0.155, sy * 0.5, -0.22))
        side.append((sx * 0.15, sy - 0.01, -0.175))
        for k in range(1, 8):
            t = k / 7.0
            side.append((sx * (0.15 - 0.01 * t), sy + (top - 0.08 - sy) * t, -0.18 - 0.07 * math.sin(t * math.pi * 0.5)))
        hoop.append(side)
    # The top arc joining the two sides.
    arc = []
    for k in range(1, 12):
        a = math.pi * k / 12
        arc.append((-math.cos(a) * 0.14, top - 0.08 + math.sin(a) * 0.08, -0.25))
    path_back = list(reversed(hoop[0][3:])) + arc + hoop[1][3:]
    back = tube("b", path_back, r, sides=10, caps=(False, False))
    # The inner loop: a smaller oval inside the hoop, from the seat's back up to just under the top.
    loop = []
    for k in range(25):
        a = 2 * math.pi * k / 24
        loop.append((math.sin(a) * 0.085, sy + 0.2 + math.cos(a) * 0.13, -0.215 - 0.03 * (math.cos(a) * 0.5 + 0.5)))
    inner = tube("i", loop, r * 0.75, sides=8, caps=(False, False))
    parts.append((merged("Back", [back, inner]), "bentwood"))
    parts.append((tube("LegBL", hoop[0][:4], r, sides=10), "bentwood"))
    parts.append((tube("LegBR", hoop[1][:4], r, sides=10), "bentwood"))
    # The leg ring: a bent hoop round the four legs, a little under halfway up.
    ry = c["ring_y"]
    ring = []
    for k in range(29):
        a = 2 * math.pi * k / 28
        ring.append((math.cos(a) * 0.19, ry, math.sin(a) * 0.165 - 0.02))
    parts.append((tube("LegRing", ring, r * 0.7, sides=8, caps=(False, False)), "bentwood"))
    metal.export_baked("bentwood_chair", parts, size=512)


def build():
    labels()
    bottles()
    mortar()
    scales()
    desk_brass()
    bentwood_chair()


if __name__ == "__main__":
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    for f in (labels, bottles, mortar, scales, desk_brass, bentwood_chair):
        if only is None or f.__name__ in only:
            f()
