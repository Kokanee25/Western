"""The main street's map: where its earth is packed and where it's churned, its wagon ruts and the old
prints in its dirt, drawn from the town's layout (config/town.json) so the detail lies where the
traffic would put it (docs/briefs/road.md, roadmap 1.4; Sean, 2026-10-15).

    python3 tools/textures/draw_street.py [--sheet]

Writes assets/textures/street/street_map.png (RGBA, MAP_PX a metre over AREA, x along the street and
z across it, row 0 at AREA's z0) and street_map.json (the area and scale, for the ground shader and
RoadStones):

    R  looseness: 0 packed earth (road_compact), 1 churned (road_loose). Packed down the wheel lanes
       and the middle of the street; churned along the ruts' lips, between a track's wheels where the
       horses walk, at porch steps and doors, in front of hitching rails and the trough, where the
       cross streets come in; slow noise over it all so it's never a stencil.
    G  the ruts' height, 0.5 = level, RUT_RANGE metres a full step: wagon tracks down the street
       at a wagon's gauge (GAUGE), each groove's depth, width and crumbled edge varying along it
       (fresh and deep with a raised lip of thrown-up dirt in places, shallow or nearly worn away
       in others), the tracks drifting a little across the street and doubling where wagons ran.
    B  unused (0.5).
And the old prints, as decals (src/art/road_prints.gd): street_map.json "prints", each a kind
(hoof, boot), a place, a turn and how worn, horseshoes in front of the rails and the trough, boot
prints at the porch steps, half worn away; print_<kind>.png (its colour, alpha where it marks the
dirt) and print_<kind>_normal.png (its relief), drawn here. Fresh prints from people walking are
gameplay's (docs/BACKLOG.md), pressed by the same decals; these are the town's past traffic.
    A  how likely a loose stone is (RoadStones): churned ground and the ruts' lips, none in a
       groove's bottom.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/textures/street"
SHEET = ROOT / "docs/screenshots/textures/street_map.png"
TOWN = ROOT / "config/town.json"

MAP_PX = 24  # a metre
# x0, z0, x1, z1: the main street between its fronts and the mouths of the cross streets.
AREA = (-86.0, -22.0, 35.0, 5.0)
# Metres from 0.5 to 0 or 1 in G and B.
RUT_RANGE = 0.12
# A wagon's wheels, centre to centre (a farm wagon's track, about five feet).
GAUGE = 1.52
# The tracks down the main street: (offset of the track's middle from the centre line, how used).
TRACKS = [(-1.7, 1.0), (1.5, 0.9), (0.0, 0.55), (-3.4, 0.35), (3.3, 0.3)]
SEED = 1882
# The prints' decal pictures, pixels a side.
PRINT_PX = 64


def noise(shape, cells, rng):
    """Smooth noise about -0.5..0.5 from octaves of blurred white noise (cell sizes in pixels)."""
    out = np.zeros(shape)
    for cell, amp in cells:
        g = rng.standard_normal(shape)
        g = gaussian_filter(g, cell, mode="wrap")
        out += g / (g.std() + 1e-9) * amp
    return out / 6.0


def noise1(n, cell, rng):
    g = gaussian_filter(rng.standard_normal(n), cell, mode="wrap")
    return g / (g.std() + 1e-9)


def to_px(x, z):
    return (x - AREA[0]) * MAP_PX, (z - AREA[1]) * MAP_PX


def places():
    """World (x, z) of the steps, doors, rails and trough, from the layout: a node's local (lx, lz)
    turned by its facing (0 or 180, all the street's are) and moved to its place."""
    town = json.loads(TOWN.read_text())
    nodes = town["nodes"]

    def world(name, lx, lz):
        n = nodes[name]
        x, _, z = n["at"]
        f = n.get("facing", 0)
        if "in" in n:
            px, pz = world(n["in"], 0.0, 0.0)
            pf = nodes[n["in"]].get("facing", 0)
            sx = -1 if pf == 180 else 1
            return px + sx * (x + lx), pz + sx * (z + lz)
        s = -1 if f == 180 else 1
        return x + s * lx, z + s * lz

    steps, hooves = [], []
    for name, n in nodes.items():
        st = (n.get("set") or {}).get("steps") or n.get("steps")
        if st and name not in ("StreetDressing/WaterTower",):
            for along, _w in st:
                bx, bz = world(name, along, 0.0)
                # In front of the boardwalk: a couple of metres into the street.
                steps.append((bx, bz - 2.2 if bz > -8.4 else bz + 2.2))
    for name in ("HitchingRail", "WaterTrough"):
        if name in nodes:
            hx, hz = world(name, 0.0, 0.0)
            hooves.append((hx, hz - 0.9 if hz > -8.4 else hz + 0.9))
    return steps, hooves


def ruts(w, h, rng):
    """G (height in metres) and the lips' mask: the grooves of each track's two wheels."""
    hgt = np.zeros((h, w))
    lip = np.zeros((h, w))
    xs = np.arange(w) / MAP_PX + AREA[0]
    zrow = np.arange(h) / MAP_PX + AREA[1]
    zc = town_centre()
    for k, (off, use) in enumerate(TRACKS):
        drift = noise1(w, 18 * MAP_PX, rng) * 0.25 + noise1(w, 5 * MAP_PX, rng) * 0.06
        for side in (-0.5, 0.5):
            for twin in range(2 if use > 0.5 else 1):
                spread = (0.0 if twin == 0 else 0.12 + 0.08 * noise1(w, 6 * MAP_PX, rng))
                centre = zc + off + side * GAUGE + drift + spread * np.sign(side)
                # How deep and wide along the street: fresh stretches, worn ones, nearly gone ones.
                wear = noise1(w, 7 * MAP_PX, rng) * 0.5 + noise1(w, 1.5 * MAP_PX, rng) * 0.25
                depth = np.clip(0.065 * use * (1.0 + wear), 0.0, 0.1) * (0.55 if twin else 1.0)
                depth *= np.clip(1.0 + noise1(w, 0.4 * MAP_PX, rng) * 0.25, 0.4, 1.4)
                width = np.clip(0.18 + 0.05 * noise1(w, 3 * MAP_PX, rng), 0.1, 0.28)
                fresh = np.clip(wear + 0.2, 0.0, 1.0)
                d = np.abs(zrow[:, None] - centre[None, :])
                # The groove: a rounded trough, its edge crumbled (wobbled by fine noise).
                edge = width[None, :] * 0.5 * (1.0 + 0.25 * noise((h, w), ((1.2, 1.0), (3, 0.6)), rng))
                groove = np.clip(1.0 - (d / np.maximum(edge, 1e-3)) ** 2, 0.0, 1.0)
                hgt -= groove * depth[None, :]
                # The lip: dirt thrown up just outside, where the rut is fresh and deep.
                ring = np.exp(-((d - edge * 1.25) / (edge * 0.45)) ** 2)
                lift = ring * depth[None, :] * 0.55 * fresh[None, :]
                hgt += lift
                lip = np.maximum(lip, ring * fresh[None, :] * np.clip(depth[None, :] / 0.04, 0.0, 1.0))
    return hgt, np.clip(lip, 0.0, 1.0)


def town_centre():
    return json.loads(TOWN.read_text())["streets"]["main"]["from"][1]


def horseshoe(size_px):
    n = int(size_px)
    y, x = np.mgrid[0:n, 0:n] / (n - 1) - 0.5
    r = np.hypot(x, y * 1.15)
    ring = np.exp(-((r - 0.32) / 0.07) ** 2) * (y < 0.18)
    frog = np.exp(-(x / 0.08) ** 2 - ((y + 0.02) / 0.16) ** 2) * 0.4
    return ring + frog


def boot(size_px):
    n = int(size_px)
    y, x = np.mgrid[0:n, 0:n] / (n - 1) - 0.5
    sole = np.exp(-((x / 0.17) ** 2 + ((y + 0.12) / 0.28) ** 2) ** 2)
    heel = np.exp(-((x / 0.14) ** 2 + ((y - 0.32) / 0.11) ** 2) ** 2)
    return np.clip(sole + heel, 0.0, 1.0)


def print_pictures():
    """The prints' decal pictures, PRINT_PX square: the dirt pressed down in the print's shape (a
    darker, damper earth at its bottom, alpha where it marks), and its relief as a normal map (the
    print's walls catch the low sun)."""
    for kind, shape in (("hoof", horseshoe(PRINT_PX)), ("boot", boot(PRINT_PX))):
        hgt = gaussian_filter(shape, 1.2)
        hgt /= hgt.max()
        gy, gx = np.gradient(-hgt * 6.0)
        nrm = np.stack([-gx, -gy, np.ones_like(gx)], -1)
        nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True)
        normal = (nrm * 0.5 + 0.5)
        normal[..., 1] = 1.0 - normal[..., 1]  # Godot's normal maps are OpenGL-style (green up)
        a = np.clip(hgt * 1.4, 0.0, 1.0)
        col = np.stack([np.full_like(a, 0.42), np.full_like(a, 0.28), np.full_like(a, 0.19), a], -1)
        Image.fromarray((col * 255 + 0.5).astype(np.uint8), "RGBA").save(OUT / ("print_%s.png" % kind))
        Image.fromarray((normal * 255 + 0.5).astype(np.uint8), "RGB").save(OUT / ("print_%s_normal.png" % kind))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args()
    rng = np.random.default_rng(SEED)
    w = int(round((AREA[2] - AREA[0]) * MAP_PX))
    h = int(round((AREA[3] - AREA[1]) * MAP_PX))
    zrow = np.arange(h) / MAP_PX + AREA[1]
    xs = np.arange(w) / MAP_PX + AREA[0]
    zc = town_centre()

    rut_h, lip = ruts(w, h, rng)

    # Looseness: broad slow noise, churned between a used track's wheels (hooves), on the lips, near
    # the edges of the street, at the steps, rails, trough and the cross streets' mouths.
    loose = 0.32 + noise((h, w), ((6 * MAP_PX, 1.0), (1.5 * MAP_PX, 0.6), (0.4 * MAP_PX, 0.3)), rng)
    for off, use in TRACKS[:2]:
        d = np.abs(zrow - (zc + off))[:, None]
        loose += 0.28 * use * np.exp(-(d / 0.45) ** 2)
    edge = np.abs(zrow - zc)[:, None]
    loose += 0.3 * np.clip((edge - 5.2) / 2.0, 0.0, 1.0)
    loose += 0.45 * lip
    steps, hooves = places()
    X, Z = np.meshgrid(xs, zrow)
    for (sx, sz) in steps:
        loose += 0.5 * np.exp(-(((X - sx) / 1.6) ** 2 + ((Z - sz) / 1.3) ** 2))
    for (hx, hz) in hooves:
        loose += 0.6 * np.exp(-(((X - hx) / 2.2) ** 2 + ((Z - hz) / 1.2) ** 2))
    for cx in (-31.0, 23.0):
        loose += 0.35 * np.exp(-((X - cx) / 4.0) ** 2) * np.clip((edge - 3.0) / 3.0, 0.0, 1.0)
    loose = np.clip(loose, 0.0, 1.0)

    # The old prints: horseshoes in front of the rails and trough, boots at the steps.
    prints = []
    for (hx, hz) in hooves:
        for _ in range(14):
            prints.append({"kind": "hoof", "x": round(hx + rng.normal(0, 1.1), 3), "z": round(hz + rng.normal(0, 0.5), 3),
                           "turn": round(float(rng.uniform(-0.4, 0.4) + (np.pi if rng.random() < 0.5 else 0)), 3),
                           "wear": round(float(rng.uniform(0.25, 0.65)), 2)})
    for (sx, sz) in steps:
        for _ in range(6):
            prints.append({"kind": "boot", "x": round(sx + rng.normal(0, 0.6), 3), "z": round(sz + rng.normal(0, 0.7), 3),
                           "turn": round(float(rng.uniform(-0.5, 0.5) + (np.pi if rng.random() < 0.5 else 0)), 3),
                           "wear": round(float(rng.uniform(0.3, 0.7)), 2)})
    print_pictures()

    # Stones: in churned ground and on the lips, never in a groove's bottom.
    stones = np.clip(loose * 0.8 + lip * 0.6, 0.0, 1.0) * np.clip(1.0 + rut_h / 0.02, 0.0, 1.0)

    def enc(m):
        return np.clip(0.5 + m / (2 * RUT_RANGE), 0.0, 1.0)

    rgba = np.stack([loose, enc(rut_h), np.full((h, w), 0.5), stones], -1)
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray((rgba * 255 + 0.5).astype(np.uint8), "RGBA").save(OUT / "street_map.png", optimize=True)
    info = {"about": "tools/textures/draw_street.py: R looseness, G ruts' height, B prints' height (0.5 level, "
                     "rut_range metres a full step), A stones' likelihood; x along the street, z across it, "
                     "row 0 at area's z0.",
            "area": list(AREA), "px_per_metre": MAP_PX, "rut_range": RUT_RANGE,
            "prints_about": "decals (RoadPrints): kind, x, z (world), turn (radians), wear (0 fresh .. 1 gone)",
            "prints": prints}
    (OUT / "street_map.json").write_text(json.dumps(info, indent=1) + "\n")
    print("street_map.png %dx%d (%d px a metre over x %.0f..%.0f, z %.0f..%.0f); %d steps, %d rails/troughs, %d prints"
          % (w, h, MAP_PX, AREA[0], AREA[2], AREA[1], AREA[3], len(steps), len(hooves), len(prints)))
    if args.sheet:
        crop = slice(int((AREA[3] - AREA[1]) * 0), h), slice(int((-20 - AREA[0]) * MAP_PX), int((15 - AREA[0]) * MAP_PX))
        rows = [loose, enc(rut_h), stones]
        img = np.concatenate([r[crop] for r in rows], 0)
        SHEET.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray((img * 255).astype(np.uint8)).save(SHEET)
        print("sheet", SHEET)


if __name__ == "__main__":
    main()
