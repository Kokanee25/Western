#!/usr/bin/env python3
"""The X-ray sheet (#695; the building lab's step 3): a building's framing as a timber framer reviews
it, drawn from the members the builder made (build/<id>_members.json, written by its test:
tests/test_building_doctor.gd) and its spec. Each outer wall from outside with its siding off
(the frame: studs, kings, headers, sills, cripples, plates, the end rafters) and on; a section
across the building; the ground floor's framing from above (sills, girders, piers, joists) and
the loft's. Every opening's clear area is outlined in red. Orthographic, to scale, north up on the
plans; the street (south) at the bottom.

    python3 tools/buildings/xray.py experiments/building_lab/doctor/doctor.json build/doctor_members.json OUT.png
"""
import json
import math
import sys

from PIL import Image, ImageDraw, ImageFont

S = 56  # pixels a metre
PAD = 30

# What each member is drawn as: fill colour by kind (and by wood for stone and brick).
COLOURS = {
    "stud": (222, 196, 150), "cripple": (236, 214, 170), "king": (184, 140, 92), "header": (226, 128, 52),
    "plate": (150, 104, 60), "ledger": (150, 104, 60), "sill": (130, 96, 64), "joist": (200, 170, 120),
    "rafter": (176, 112, 70), "ridge": (90, 60, 40), "post": (120, 82, 50), "beam": (120, 82, 50),
    "board": (246, 244, 236), "roof_board": (150, 130, 110), "floor_board": (214, 186, 140),
    "trim": (60, 110, 70), "glass": (190, 220, 240), "door": (90, 60, 50), "stone": (150, 150, 150),
    "brick": (160, 70, 50), "nailer": (210, 190, 150),
}
FRAMING = {"stud", "cripple", "header", "plate", "ledger", "sill", "joist", "rafter", "ridge", "post", "beam"}


def font(size, bold=False):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    for f in ("/usr/share/fonts/truetype/dejavu/" + name, name):
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            pass
    return ImageFont.load_default()


def corners(m):
    c, ax, ay, az, s = m["c"], m["x"], m["y"], m["z"], m["s"]
    out = []
    for i in (-0.5, 0.5):
        for j in (-0.5, 0.5):
            for k in (-0.5, 0.5):
                out.append(tuple(c[n] + ax[n] * s[0] * i + ay[n] * s[1] * j + az[n] * s[2] * k for n in range(3)))
    return out


def hull(points):
    pts = sorted(set(points))
    if len(pts) < 3:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def colour(m):
    if m["wood"] == "stone":
        return COLOURS["stone"]
    if m["wood"] == "brick" or m["id"].startswith("chimney/"):
        return COLOURS["brick"]
    if "/king" in m["id"]:
        return COLOURS["king"]
    if "/nailer/" in m["id"]:
        return COLOURS["nailer"]
    return COLOURS.get(m["kind"], (200, 200, 200))


class View:
    """An orthographic view: proj(p) -> (u, v, depth), u right, v up, depth away from the viewer."""

    def __init__(self, title, proj, keep, umin, umax, vmin, vmax, openings=()):
        self.title, self.proj, self.keep = title, proj, keep
        self.umin, self.umax, self.vmin, self.vmax = umin, umax, vmin, vmax
        self.openings = openings

    def draw(self, members):
        w = int((self.umax - self.umin) * S) + 2 * PAD
        h = int((self.vmax - self.vmin) * S) + 2 * PAD + 40
        im = Image.new("RGB", (w, h), (250, 248, 242))
        d = ImageDraw.Draw(im)
        d.text((PAD, 8), self.title, fill=(30, 25, 20), font=font(20, True))

        def px(u, v):
            return (PAD + (u - self.umin) * S, 40 + PAD + (self.vmax - v) * S)
        items = []
        for m in members:
            if not self.keep(m):
                continue
            pr = [self.proj(p) for p in corners(m)]
            depth = sum(p[2] for p in pr) / 8.0
            items.append((depth, m, [(p[0], p[1]) for p in pr]))
        items.sort(key=lambda t: -t[0])
        for _, m, pts in items:
            poly = [px(u, v) for u, v in hull(pts)]
            if len(poly) >= 3:
                d.polygon(poly, fill=colour(m), outline=(60, 45, 30))
        for (u0, v0, u1, v1, label) in self.openings:
            a, b = px(min(u0, u1), max(v0, v1)), px(max(u0, u1), min(v0, v1))
            d.rectangle([a, b], outline=(220, 20, 20), width=3)
            d.text((a[0] + 3, a[1] + 2), label, fill=(200, 20, 20), font=font(11))
        # A 1 m tick bar.
        x0, y0 = PAD, h - 14
        for k in range(4):
            d.rectangle([x0 + k * S, y0, x0 + (k + 1) * S, y0 + 6], fill=(30, 30, 30) if k % 2 == 0 else (255, 255, 255), outline=(30, 30, 30))
        d.text((x0 + 4 * S + 6, y0 - 6), "4 m", fill=(30, 30, 30), font=font(12))
        return im


def wall_openings(spec, wall_id, lv, to_uv):
    """A wall's openings' clear areas as (u0, v0, u1, v1, label) in a view (to_uv: (s along, y) -> (u, v))."""
    out = []
    for w in spec["walls"]:
        if w["id"] != wall_id:
            continue
        for o in w.get("openings", []):
            lvl = o.get("level", w.get("level", "ground"))
            y0 = lv[lvl] + float(o.get("sill", 0.0))
            s0, s1 = float(o["at"]) - float(o["width"]) / 2, float(o["at"]) + float(o["width"]) / 2
            a, b = to_uv(s0, y0), to_uv(s1, y0 + float(o["height"]))
            out.append((a[0], a[1], b[0], b[1], o["type"]))
    return out


def main(spec_path, members_path, out):
    spec = json.load(open(spec_path))
    members = json.load(open(members_path))["members"]
    if spec.get("frame", {}).get("stone_wall"):
        return main_stone(spec, members, out)
    W, D = float(spec["lot"]["width"]), float(spec["lot"]["depth"])
    lv = {"ground": float(spec["levels"]["ground"]["top"]), "upper": float(spec["levels"]["upper"]["top"])}
    top = max(max(p[1] for p in corners(m)) for m in members) + 0.3
    bot = min(min(p[1] for p in corners(m)) for m in members) - 0.1

    def in_slab(m, axis, lo, hi):
        cs = corners(m)
        return max(p[axis] for p in cs) > lo and min(p[axis] for p in cs) < hi

    def framing(m):
        return m["kind"] in FRAMING or m["wood"] in ("stone", "brick") or "/nailer/" in m["id"]

    def bare(m):
        # Siding off: the frame, not the finish boards inside or the siding, trim and glass outside.
        return framing(m) and not m["id"].startswith(("fence/", "ladder/"))

    views = []
    # The front (from the street, north up the page: east on the right).
    fz = lambda m: in_slab(m, 2, -0.08, 0.11) and not m["id"].startswith(("floor/", "back_porch", "stoop"))
    front_ops = wall_openings(spec, "front", lv, lambda s, y: (W - s, y))
    views.append(View("Front (south), siding off", lambda p: (W - p[0], p[1], p[2]), lambda m: fz(m) and bare(m), -0.5, W + 0.5, bot, top, front_ops))
    views.append(View("Front (south), siding on", lambda p: (W - p[0], p[1], p[2]), lambda m: fz(m) and not m["id"].startswith(("fence/",)), -0.5, W + 0.5, bot, top, []))
    bz = lambda m: in_slab(m, 2, D - 0.11, D + 0.08) and not m["id"].startswith(("floor/", "back_porch", "stoop"))
    back_ops = wall_openings(spec, "back", lv, lambda s, y: (s, y))
    views.append(View("Back (north), siding off", lambda p: (p[0], p[1], -p[2]), lambda m: bz(m) and bare(m), -0.5, W + 0.5, bot, top, back_ops))
    views.append(View("Back (north), siding on", lambda p: (p[0], p[1], -p[2]), lambda m: bz(m) or m["id"].startswith(("back_porch", "ladder/")), -0.5, W + 0.5, bot, top, []))
    side_top = lv["upper"] + 0.6
    yx = lambda m: in_slab(m, 0, -0.08, 0.11) and not m["id"].startswith(("floor/", "roof/board", "stoop", "fence/"))
    yard_ops = wall_openings(spec, "yard", lv, lambda s, y: (s, y))
    views.append(View("East side (the yard), siding off", lambda p: (p[2], p[1], p[0]), lambda m: yx(m) and bare(m) and not m["id"].startswith("roof/"), -0.3, D + 0.3, bot, side_top, yard_ops))
    lx = lambda m: in_slab(m, 0, W - 0.11, W + 0.08) and not m["id"].startswith(("floor/", "roof/board"))
    lane_ops = wall_openings(spec, "lane", lv, lambda s, y: (D - s, y))
    views.append(View("West side (the lane), siding off", lambda p: (D - p[2], p[1], -p[0]), lambda m: lx(m) and bare(m) and not m["id"].startswith("roof/"), -0.3, D + 0.3, bot, side_top, lane_ops))
    # A section across the building through the surgery and the dispensary, looking north.
    cz = 6.3
    views.append(View("Section across at %.1f m (surgery | hall | dispensary), looking north" % cz, lambda p: (W - p[0], p[1], p[2]),
                      lambda m: in_slab(m, 2, cz - 0.22, cz + 0.22) and (bare(m) or m["kind"] in ("floor_board", "roof_board")) and not m["id"].startswith("fence/"),
                      -0.6, W + 0.6, bot, top, []))
    # Plans from above (north up: v = z; east on the right).
    def below(y):
        return lambda m: max(p[1] for p in corners(m)) < y and m["kind"] not in ("floor_board", "board", "trim", "glass", "door") and not m["id"].startswith(("fence/", "stoop", "back_porch", "stair/"))
    views.append(View("Ground floor framing from above (sills, girders on piers, 2x10 joists)", lambda p: (W - p[0], p[2], -p[1]), below(lv["ground"] - 0.01), -0.6, W + 0.6, -0.4, D + 0.4, []))
    loft = lambda m: lv["ground"] + 2.5 < (sum(p[1] for p in corners(m)) / 8.0) < lv["upper"] and m["kind"] not in ("board", "floor_board", "trim", "glass", "door") and "/siding/" not in m["id"] and not m["id"].startswith(("back_porch", "ladder/", "stoop"))
    views.append(View("Loft framing from above (plates, summer beams, 2x10 joists, the scuttle, chimneys)", lambda p: (W - p[0], p[2], -p[1]), loft, -0.6, W + 0.6, -0.4, D + 0.4, []))

    ims = [v.draw(members) for v in views]
    cols = 2
    rows = [ims[i:i + cols] for i in range(0, len(ims), cols)]
    widths = [sum(im.width for im in r) for r in rows]
    Wpx = max(widths) + 20
    Hpx = sum(max(im.height for im in r) for r in rows) + 120
    sheet = Image.new("RGB", (Wpx, Hpx), (236, 232, 222))
    d = ImageDraw.Draw(sheet)
    d.text((14, 12), "%s: the X-ray sheet (framing from the built members, %d of them)" % (spec["id"], len(members)), fill=(25, 20, 15), font=font(28, True))
    d.text((14, 50), "red: each opening's clear area (nothing may cross it)   tan: studs   dark: kings   orange: headers and rough sills   brown: plates, sills, posts, beams   sienna: rafters   grey: stone   red-brown: brick",
           fill=(25, 20, 15), font=font(15))
    y = 90
    for r in rows:
        x = 10
        for im in r:
            sheet.paste(im, (x, y))
            x += im.width
        y += max(im.height for im in r)
    sheet.save(out, quality=90)
    print(out, sheet.size, len(members), "members")


def main_stone(spec, members, out):
    """A load-bearing stone building (#780, the jail; facing 0, its front to the north): each wall
    from outside with every opening's clear area, two sections (along through the corridor, across
    through the cells), the floors' framing and the roofs' from above, and the whole lot from above."""
    W, D = float(spec["lot"]["width"]), float(spec["lot"]["depth"])
    feet = spec["lot"].get("footprint", [[0, 0, W, D]])
    DT = max(float(f[3]) for f in feet)
    yard = spec["lot"].get("yard", [0, 0, W, DT])
    lv = {"ground": float(spec["levels"]["ground"]["top"]), "upper": float(spec["levels"]["upper"]["top"])}
    house = [m for m in members if not m["id"].startswith(("yard_", "gate/"))]
    top = max(max(p[1] for p in corners(m)) for m in house) + 0.3
    bot = min(min(p[1] for p in corners(m)) for m in house) - 0.1
    lines = {w["id"]: w["line"] for w in spec["walls"]}
    plane = spec["lot"].get("ground", {}).get("plane", [0.0, 0.0, 0.0])

    def above_ground(m):
        # Not a footing under a gateway (buried, it would read as the wall across it).
        c = m["c"]
        return max(p[1] for p in corners(m)) > plane[0] + plane[1] * c[0] + plane[2] * c[2] + 0.05

    def in_slab(m, axis, lo, hi):
        cs = corners(m)
        return max(p[axis] for p in cs) > lo and min(p[axis] for p in cs) < hi

    def ops(wall_id, to_uv):
        return wall_openings(spec, wall_id, lv, to_uv)

    def solid(m):
        return m["kind"] not in ("glass",) and not m["id"].startswith(("yard_", "gate/"))
    views = []
    # The front from Main Street (looking south: west on the right).
    views.append(View("Front (north, on Main Street), looking south: west on the right", lambda p: (W - p[0], p[1], p[2]),
                      lambda m: solid(m) and in_slab(m, 2, -0.1, 0.75) and not m["id"].startswith(("floor/", "stair/")), -0.5, W + 0.5, bot, top,
                      ops("front", lambda s_, y: (W - s_, y))))
    z0 = float(lines["west"][0][1])
    views.append(View("West side (the cross street), looking east: Main Street on the left", lambda p: (p[2], p[1], p[0]),
                      lambda m: solid(m) and (in_slab(m, 0, -0.1, 0.75) or (in_slab(m, 0, 6.0, 6.8) and min(p[2] for p in corners(m)) > D - 0.1)) and not m["id"].startswith("floor/"),
                      -0.5, DT + 0.5, bot, top,
                      ops("west", lambda s_, y: (z0 + s_, y)) + ops("ell_west", lambda s_, y: (float(lines["ell_west"][0][1]) + s_, y))))
    views.append(View("East side (the yard): the office and the cell wing, looking west", lambda p: (DT - p[2], p[1], -p[0]),
                      lambda m: solid(m) and in_slab(m, 0, W - 0.75, W + 2.5) and not m["id"].startswith("floor/"), -0.5, DT + 0.5, bot, top,
                      ops("east", lambda s_, y: (DT - (z0 + s_), y)) + ops("ell_east", lambda s_, y: (DT - (float(lines["ell_east"][0][1]) + s_), y))))
    ex0 = float(lines["ell_south"][0][0])
    views.append(View("Back: the cell wing's end (the jailbreak's wall) and the office's back, looking north", lambda p: (p[0], p[1], -p[2]),
                      lambda m: solid(m) and (in_slab(m, 2, DT - 0.75, DT + 0.1) or (in_slab(m, 2, D - 0.75, D + 0.1) and min(p[0] for p in corners(m)) < 6.2)) and not m["id"].startswith("floor/"),
                      -0.5, W + 0.5, bot, top,
                      ops("ell_south", lambda s_, y: (ex0 + s_, y)) + [o for o in ops("back", lambda s_, y: (s_, y)) if max(o[0], o[2]) < 6.0]))
    cx = 7.3
    views.append(View("Section along at x %.1f m (office | cross wall | guard room | corridor), looking west" % cx, lambda p: (p[2], p[1], p[0]),
                      lambda m: solid(m) and in_slab(m, 0, cx - 0.25, cx + 0.25), -0.5, DT + 0.5, bot, top, []))
    zc = 18.6
    views.append(View("Section across the cell wing at z %.1f m (corridor | cage 2), looking south" % zc, lambda p: (W - p[0], p[1], p[2]),
                      lambda m: solid(m) and in_slab(m, 2, zc - 0.2, zc + 0.2), -0.5, W - 5.5, bot, top, []))

    def below(y):
        return lambda m: max(p[1] for p in corners(m)) < y and m["kind"] not in ("floor_board", "board", "trim", "glass", "door") and solid(m)
    views.append(View("The floors' framing from above (set-offs, girders on piers, 2x10 joists; the cells' fill), north up",
                      lambda p: (p[0], -p[2], -p[1]), below(lv["ground"] - 0.01), -0.6, W + 0.6, -DT - 0.4, 0.4, []))
    roof = lambda m: lv["ground"] + 2.9 < (sum(p[1] for p in corners(m)) / 8.0) < lv["upper"] + 0.01 and m["kind"] not in ("board", "floor_board", "trim", "glass") and solid(m)
    views.append(View("The roofs' framing from above (3x12 and 3x10 joists on the walls' ledges, the hatch), north up",
                      lambda p: (p[0], -p[2], -p[1]), roof, -0.6, W + 0.6, -DT - 0.4, 0.4, []))
    views.append(View("The lot from above: the jail, the cages, the yard's stone walls and gates (roofs off), north up",
                      lambda p: (p[0], -p[2], -p[1]), lambda m: (sum(p[1] for p in corners(m)) / 8.0) < lv["ground"] + 2.4 and m["kind"] not in ("floor_board",) and not m["id"].startswith("floor/") and above_ground(m),
                      float(yard[0]) - 0.6, float(yard[2]) + 0.6, -float(yard[3]) - 0.6, 0.6, []))

    ims = [v.draw(members) for v in views]
    cols = 2
    rows = [ims[i:i + cols] for i in range(0, len(ims), cols)]
    Wpx = max(sum(im.width for im in r) for r in rows) + 20
    Hpx = sum(max(im.height for im in r) for r in rows) + 120
    sheet = Image.new("RGB", (Wpx, Hpx), (236, 232, 222))
    d = ImageDraw.Draw(sheet)
    d.text((14, 12), "%s: the X-ray sheet (the stone and the frame from the built members, %d of them)" % (spec["id"], len(members)), fill=(25, 20, 15), font=font(28, True))
    d.text((14, 50), "red: each opening's clear area (nothing may cross it)   grey: stone pieces (rows, lintels, sills, set-offs, ledges)   tan: studs and the cages' iron   brown: girders, plates   wheat: joists   blue: glass",
           fill=(25, 20, 15), font=font(15))
    y = 90
    for r in rows:
        x = 10
        for im in r:
            sheet.paste(im, (x, y))
            x += im.width
        y += max(im.height for im in r)
    sheet.save(out, quality=90)
    print(out, sheet.size, len(members), "members")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
