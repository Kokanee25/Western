#!/usr/bin/env python3
"""A building spec's ground plan, drawn from the spec alone (the building lab's step 2): its lot and
walk, outer walls and partitions, every door (its leaf and swing) and window, the rooms by name and
size, the girders, chimneys, stairs and porch, the use points. Drawn as the world sees it: north up,
the street at the bottom, for a lot facing 180 (the north side of Main Street) the builder's x
mirrored so east is on the right; for a lot facing 0 (the south side) the street at the top. A stone
building (#780, the jail): its walls drawn at their thickness (the line their outer face), the
footprint's wings (`lot.footprint`), the yard's walls and gates, the cells' cages.

    python3 tools/buildings/plan_sheet.py experiments/building_lab/doctor/doctor.json OUT.png
"""
import json
import math
import sys

from PIL import Image, ImageDraw, ImageFont

S = 70          # pixels a metre
M = 90          # margin


def font(size, bold=False):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    for f in ("/usr/share/fonts/truetype/dejavu/" + name, name):
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            pass
    return ImageFont.load_default()


def main(spec_path, out):
    sp = json.load(open(spec_path))
    lot = sp["lot"]
    W, D = float(lot["width"]), float(lot["depth"])
    mirror = float(lot.get("facing", 0)) == 180
    south = float(lot.get("facing", 0)) == 0 and lot.get("side") == "south"
    yard = lot.get("yard", [0, 0, 0, 0])
    feet = lot.get("footprint", [[0, 0, W, D]])
    xmin = min(0.0, float(yard[0]), float(lot.get("footprint_with_stair", [0])[0])) - 1.0
    xmax = max(W, float(yard[2])) + 1.0
    zmin = -3.4
    zmax = max(D, float(yard[3]), max(float(f[3]) for f in feet), float(lot.get("footprint_with_stair", [0, 0, 0, D])[3])) + 1.5
    stone_t = float(sp.get("frame", {}).get("stone_wall", {}).get("thick", 0.0))
    wpx = int((xmax - xmin) * S) + 2 * M
    hpx = int((zmax - zmin) * S) + 2 * M + 80

    def P(x, z):
        sx = (xmax - x) if mirror else (x - xmin)
        sz = (z - zmin) if south else (zmax - z)
        return (M + sx * S, M + 60 + sz * S)

    im = Image.new("RGB", (wpx, hpx), (246, 241, 230))
    d = ImageDraw.Draw(im)
    ink, red, blue, grey = (25, 20, 15), (190, 40, 30), (40, 80, 170), (150, 140, 125)
    title = "%s: ground plan from the spec (%s)" % (sp["id"], spec_path.split("/")[-1])
    d.text((M, 20), title, fill=ink, font=font(28, True))
    sub = "north up, the street at the %s; metres; %s%.2f x %.2f m (%.0f x %.0f ft)" % (
        "top" if south else "bottom", "the main block " if len(feet) > 1 else "", W, D, W / 0.3048, D / 0.3048)
    d.text((M, 56), sub, fill=ink, font=font(18))

    def rect(r, **kw):
        a, b = P(r[0], r[1]), P(r[2], r[3])
        d.rectangle([min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1])], **kw)

    # The side yard, the walk (2.4 m in front of the front line), the street's edge.
    rect([yard[0], yard[1], yard[2], yard[3]], fill=(232, 226, 205), outline=grey)
    yname = lot.get("yard_name", "SIDE YARD")
    if south:
        a = P(float(yard[2]) - 9.0, float(yard[3]) * 0.5)
        d.text(a, yname, fill=grey, font=font(20, True))
    else:
        a = P(float(yard[0]) + 0.3, float(yard[3]) - 0.6)
        d.text((min(a[0], P(float(yard[2]), 0)[0]) + 20, a[1]), yname, fill=grey, font=font(20, True))
    wx = lot.get("walk_x", [min(0, float(yard[0])), max(W, float(yard[2]))])
    rect([float(wx[0]), -2.4, float(wx[1]), 0.0], fill=(222, 206, 180), outline=grey)
    a = P(float(wx[0]) + 0.3 if south else W * 0.5 + 2.5, -1.0)
    d.text((a[0], a[1] - 10), "THE WALK (ValleyTown's, %.2f m up)" % float(lot.get("walk_h", 0.95)), fill=ink, font=font(18))
    a = P(W * 0.5 + 1.0, -3.0)
    d.text((a[0], a[1] - 10), "MAIN STREET", fill=grey, font=font(20, True))
    if south:
        a = P(-0.8, float(yard[3]) * 0.5)
        d.text((a[0] - 30, a[1]), "CROSS\nSTREET", fill=grey, font=font(18, True))
        a = P(float(yard[2]) * 0.5, float(yard[3]) + 0.9)
        d.text((a[0], a[1] - 10), "REAR LANE", fill=grey, font=font(20, True))
    # A yard's stone walls (#780), their gates gaps with the leaves drawn open.
    yw = sp.get("yard_walls", {})
    for w in yw.get("walls", []):
        (ax, az), (bx, bz) = w["line"]
        t = float(yw["thick"])
        sgn = -1 if w["out"] in ("+x", "+z") else 1
        L = math.hypot(bx - ax, bz - az)
        ux, uz = (bx - ax) / L, (bz - az) / L
        nx, nz = (1, 0) if abs(uz) > 0.5 else (0, 1)
        s0 = 0.0
        cuts = sorted((float(g["at"]) - float(g["width"]) / 2, float(g["at"]) + float(g["width"]) / 2) for g in w.get("gates", []))
        for c0, c1 in cuts + [(L, L)]:
            if c0 > s0:
                q = [(ax + ux * s0 + nx * tt * sgn, az + uz * s0 + nz * tt * sgn) for tt in (0, t)]
                q += [(ax + ux * c0 + nx * tt * sgn, az + uz * c0 + nz * tt * sgn) for tt in (t, 0)]
                d.polygon([P(*pt) for pt in q], fill=(110, 100, 88))
            if c1 > c0:
                g = P(ax + ux * (c0 + c1) / 2, az + uz * (c0 + c1) / 2)
                d.text((g[0] - 18, g[1] + (8 if nz else -8)), "gate", fill=red, font=font(14))
            s0 = c1
    for o in sp.get("outbuildings", []):
        if "rect" in o:
            rect(o["rect"], fill=(214, 196, 166), outline=ink, width=2)
            c = P((o["rect"][0] + o["rect"][2]) / 2, (o["rect"][1] + o["rect"][3]) / 2)
            d.text((c[0] - 22, c[1] - 8), o["kind"].upper(), fill=ink, font=font(14, True))
        elif "at" in o:
            rect([o["at"][0] - 0.6, o["at"][1] - 0.6, o["at"][0] + 0.6, o["at"][1] + 0.6], fill=(214, 196, 166), outline=ink, width=2)

    # Back porch, stairs and their stoop.
    bp = sp.get("back_porch")
    if bp:
        rect(bp["rect"], fill=(225, 214, 190), outline=ink, width=2)
    for st in sp.get("stairs", []):
        if "stoop" in st:
            rect(st["stoop"], fill=(225, 214, 190), outline=ink, width=2)
        hx, hz = st["head"]
        n, g, w = int(st["risers"]), float(st["going"]), float(st["width"])
        dx, dz = {"+x": (-1, 0), "-x": (1, 0), "+z": (0, 1), "-z": (0, -1)}[st["dir"]]
        run = (n - 1) * g if n > 1 else g
        if dx:
            r = [hx, hz, hx + dx * run, hz + w]
        else:
            r = [hx, hz, hx + w, hz + dz * run]
        rect([min(r[0], r[2]), min(r[1], r[3]), max(r[0], r[2]), max(r[1], r[3])], fill=(236, 228, 210), outline=ink)
        for k in range(1, n):
            if dx:
                x = hx + dx * g * k
                d.line([P(x, hz), P(x, hz + w)], fill=ink)
            else:
                z = hz + dz * g * k
                d.line([P(hx, z), P(hx + w, z)], fill=ink)
        c = P((r[0] + r[2]) * 0.5, (r[1] + r[3]) * 0.5)
        d.text((c[0] - 14, c[1] - 8), "%dR" % n, fill=ink, font=font(14))

    # The building's floor (its footprint's wings, #780).
    for f in feet:
        rect(f, fill=(250, 246, 236))
    # Cells' cages (#780): their lattice drawn as a fine grid, the doors on their side.
    ce = sp.get("cells")
    if ce:
        cx0, cx1 = ce["x"]
        zs = ce["z"]
        for k in range(len(zs) - 1):
            rect([cx0, zs[k], cx1, zs[k + 1]], fill=(236, 232, 226), outline=(60, 60, 70), width=3)
            for j in range(1, 8):
                x = cx0 + (cx1 - cx0) * j / 8
                d.line([P(x, zs[k]), P(x, zs[k + 1])], fill=(170, 170, 180), width=1)
            c = P((cx0 + cx1) / 2, (zs[k] + zs[k + 1]) / 2)
            d.text((c[0] - 22, c[1] - 8), "CAGE %d" % (k + 1), fill=(60, 60, 70), font=font(14, True))
            dw = float(ce["door"]["width"])
            zm = (zs[k] + zs[k + 1]) / 2
            d.line([P(cx0, zm - dw / 2), P(cx0 - dw, zm - dw / 2)], fill=red, width=3)
        g = ce.get("gate")
        if g:
            d.line([P(g["x"][0], g["z"]), P(g["x"][1], g["z"])], fill=(60, 60, 70), width=5)
    rf = sp.get("roof", {})
    if "hatch" in rf:
        rect(rf["hatch"]["rect"], outline=red, width=2)
        c = P(rf["hatch"]["rect"][0], rf["hatch"]["rect"][1])
        d.text((c[0] - 4, c[1] - 18), "hatch", fill=red, font=font(13))
    # Girders (dashed) and chimneys.
    for gx in sp.get("girders", {}).get("x", []):
        z = 0.2
        while z < D - 0.2:
            d.line([P(gx, z), P(gx, min(z + 0.3, D))], fill=grey, width=2)
            z += 0.6
    for ch in sp.get("chimneys", {}).get("list", []):
        h = float(ch["size"]) * 0.5
        rect([ch["at"][0] - h, ch["at"][1] - h, ch["at"][0] + h, ch["at"][1] + h], fill=(160, 70, 50), outline=ink)

    # Rooms.
    for r in sp.get("rooms", []):
        if r["level"] != "ground":
            continue
        x0, z0, x1, z1 = r["rect"]
        c = P((x0 + x1) * 0.5, (z0 + z1) * 0.5)
        name = r["id"].replace("_", " ").upper()
        size = "%.1f x %.1f m" % (x1 - x0, z1 - z0)
        f = font(20 if x1 - x0 > 2 else 15, True)
        tw = d.textlength(name, font=f)
        if x1 - x0 < 1.5:
            d.text((c[0] - 8, c[1] - 60), "\n".join(name), fill=ink, font=font(15, True))
        else:
            d.text((c[0] - tw / 2, c[1] - 22), name, fill=ink, font=f)
            sw = d.textlength(size, font=font(16))
            d.text((c[0] - sw / 2, c[1] + 4), size, fill=ink, font=font(16))

    # Walls: the outer ones as their stud depth (0.1 m) plus the siding, partitions centred.
    def wall_box(w):
        (ax, az), (bx, bz) = w["line"]
        if w.get("stone"):
            # A stone wall: its line the outer face (a partition's: its north or west face), the
            # stone on inward (+x/+z for a partition) at its thickness.
            t = float(w.get("thick", stone_t))
            if w.get("partition") or w["out"] in ("-x", "-z"):
                t0, t1 = 0.0, t
            else:
                t0, t1 = -t, 0.0
        elif w.get("partition"):
            t0, t1 = -0.05, 0.05
        else:
            o = w["out"]
            t0, t1 = (0.0, 0.12) if o in ("+x", "+z") else (-0.12, 0.0)
            # The line is the studs' outer face: the studs inside it.
            t0, t1 = (-0.1, 0.02) if o in ("+x", "+z") else (-0.02, 0.1)
        return (ax, az, bx, bz, t0, t1)

    def along_pt(w, s, t):
        (ax, az), (bx, bz) = w["line"]
        L = math.hypot(bx - ax, bz - az)
        ux, uz = (bx - ax) / L, (bz - az) / L
        nx, nz = (1, 0) if abs(uz) > 0.5 else (0, 1)
        return ax + ux * s + nx * t, az + uz * s + nz * t

    for w in sp["walls"]:
        if w.get("level", "ground") != "ground" and w.get("partition"):
            continue
        ax, az, bx, bz, t0, t1 = wall_box(w)
        L = math.hypot(bx - ax, bz - az)
        cuts = sorted([(float(o["at"]) - float(o["width"]) / 2, float(o["at"]) + float(o["width"]) / 2, o)
                       for o in w.get("openings", []) if o.get("level", "ground") == "ground"], key=lambda c: c[0])
        s = 0.0
        pieces = []
        for c0, c1, o in cuts:
            if o["type"] in ("door", "hatch") or (o["type"] == "window" and (float(o.get("sill", 0)) < 2.2 or o.get("glass") is False)):
                if c0 > s:
                    pieces.append((s, c0))
                s = max(s, c1)
        pieces.append((s, L))
        for s0, s1 in pieces:
            q = [P(*along_pt(w, s0, t0)), P(*along_pt(w, s1, t0)), P(*along_pt(w, s1, t1)), P(*along_pt(w, s0, t1))]
            d.polygon(q, fill=ink)
        for c0, c1, o in cuts:
            mid = (t0 + t1) / 2
            if o["type"] == "window":
                if float(o.get("sill", 0)) >= 2.2 and o.get("glass") is not False:
                    continue   # a transom: shown with its door (a high slit with no glass, #780, is drawn)
                for t in (t0, mid, t1):
                    d.line([P(*along_pt(w, c0, t)), P(*along_pt(w, c1, t))], fill=blue, width=2)
                d.line([P(*along_pt(w, c0, t0)), P(*along_pt(w, c0, t1))], fill=ink, width=2)
                d.line([P(*along_pt(w, c1, t0)), P(*along_pt(w, c1, t1))], fill=ink, width=2)
            elif o["type"] == "hatch":
                d.line([P(*along_pt(w, c0, mid)), P(*along_pt(w, c1, mid))], fill=red, width=3)
            elif o["type"] == "door":
                # The leaf drawn open 90 degrees from its hinge (c0) into the side it swings to, the arc.
                wout = w.get("out", "+z")
                if w.get("partition"):
                    side = 1 if o.get("leaf", "inward") == "outward" else -1
                else:
                    side = -1 if wout in ("+x", "+z") else 1
                    if o.get("leaf", "inward") == "outward":
                        side = -side
                wd = c1 - c0
                hinge = along_pt(w, c0, t1 if side > 0 else t0)
                tip = along_pt(w, c0, (t1 if side > 0 else t0) + side * wd)
                d.line([P(*hinge), P(*tip)], fill=red, width=3)
                pts = [P(*along_pt(w, c0 + wd * math.cos(a), (t1 if side > 0 else t0) + side * wd * math.sin(a)))
                       for a in [i * math.pi / 2 / 12 for i in range(13)]]
                d.line(pts, fill=red, width=1)

    # Use points.
    for u in sp.get("use_points", []):
        if "at" not in u:
        	continue  # a kit's seats (the card tables')
        x, _, z = u["at"]
        c = P(x, z)
        d.ellipse([c[0] - 6, c[1] - 6, c[0] + 6, c[1] + 6], fill=(40, 140, 60), outline=ink)
        if "look" in u:
            e = P(x + (u["look"][0] - x) * 0.12, z + (u["look"][1] - z) * 0.12)
            d.line([c, e], fill=(40, 140, 60), width=2)
        d.text((c[0] + 8, c[1] - 7), u["id"], fill=(30, 100, 45), font=font(12))

    # North arrow and a scale bar (metres and feet).
    nx, ny = wpx - M - 30, M + 80
    d.polygon([(nx, ny - 40), (nx - 14, ny), (nx + 14, ny)], fill=ink)
    d.text((nx - 8, ny + 4), "N", fill=ink, font=font(22, True))
    sx, sy = M, hpx - 40
    for k in range(6):
        d.rectangle([sx + k * S, sy, sx + (k + 1) * S, sy + 10], fill=ink if k % 2 == 0 else (250, 250, 250), outline=ink)
    d.text((sx + 6 * S + 10, sy - 6), "6 m", fill=ink, font=font(16))
    ft = 0.3048 * S
    for k in range(4):
        d.rectangle([sx + k * 5 * ft, sy - 22, sx + (k + 1) * 5 * ft, sy - 14], fill=ink if k % 2 == 0 else (250, 250, 250), outline=ink)
    d.text((sx + 20 * ft + 10, sy - 28), "20 ft", fill=ink, font=font(16))
    # Key.
    kx, ky = wpx - M - 330, hpx - 60
    d.text((kx, ky), "blue: windows   red: doors & swings, the hatch\ngreen: use points   dashed: girders   brown: chimneys",
           fill=ink, font=font(15))
    im.save(out)
    print(out, im.size)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
