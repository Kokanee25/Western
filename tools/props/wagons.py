"""The prop factory's wagons and wheels (docs/briefs/prop-factory.md, batch 1): writes their kit files.

    python3 tools/props/wagons.py            # assets/props/kit/{wagon_wheel,broken_wagon_wheel,buckboard,freight_wagon,covered_wagon}.json

Every wagon is members, so it splinters, burns and is carved as the buildings are, and a wheel can
be shot or knocked off it. Its kit space: origin on the ground under its middle, long along X with
the tongue toward -X (as PropModels.wagon, so the street's placements stay where they were), its
wheels' axes along Z.

How it stands (the support graph: a member rests only on a lower tier, or the same kind stacked
under it; tier <= 1 at the bottom stands on the ground): each wheel stands on the felloe under its
hub (`post`); the two spokes in that felloe (`stud`) carry the hub (`furniture_frame`); the hub
carries the other spokes (`cripple`) and they the rest of the rim (`board`); the axle rests on the
two hubs (`cripple`, unchecked), the bolsters and the reach on the axles (`furniture_top`), the bed
on the bolsters and everything above it on what's under it (`trim`). So two spokes shot out under a
hub drop that corner, a wheel's rim shot through falls away in pieces, and the canvas comes down
when the sideboard under it burns.

Measures from period wagon makers' catalogues (Studebaker's farm and freight wagons, the
buckboard): wheels 3 ft 6 in to 5 ft high, the hind ones bigger; 12 spokes to a wheel in 6
felloes, an iron tyre shrunk on; track about 5 ft; a box about 10 ft by 3 ft 6 in.
"""
import json
import math
import os

import numpy as np

KIT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "props", "kit")

GEAR_WOOD = "oak"              # running gear: hubs, spokes, felloes, axles, bolsters, tongue
BOX_WOOD = "weathered_pine"    # the bed and its sides
# Sun-cooked and dirty (the blind critic, round 1: the pale wheels and pink pine read new).
# Round 2: dark_wood went cold lilac at noon beside the bed's oak; the gear in the same old oak.
GEAR_LOOK = "wood:dark_oak"
HUB_LOOK = "wood:dark_oak"
BOX_LOOK = "wood:dark_oak"
IRON = "prop:iron"
CANVAS_LOOK = "prop:canvas"

TYRE = 0.012       # the iron tyre's thickness (m)
SPOKES = 12
FELLOES = 6


def r4(v):
    return round(float(v), 4)


def vec(*v):
    return [r4(x) for x in v]


def hub_bands(hub_r, hub_len, ends, **place):
    """A hub's iron bands, standing proud of the wood where it narrows: at each of `ends` (+1, -1:
    the hub's two ends along its axis), a band from 0.27 to 0.41 of its length out."""
    out = []
    for e in ends:
        y0, y1 = sorted((e * hub_len * 0.27, e * hub_len * 0.41))
        prof = [vec(hub_r * 0.84, y0), vec(hub_r * 0.95, y0 + 0.006), vec(hub_r * 0.95, y1 - 0.006), vec(hub_r * 0.84, y1)]
        out.append({"look": IRON, "draw": dict({"shape": "lathe", "profile": prof, "segments": 10}, **place)})
    return out


def ring(r_in, r_out, y0, y1):
    """A closed outline in (r, y) for a sweep: a felloe's or a tyre's section."""
    return [vec(r_out, y0), vec(r_out, y1), vec(r_in, y1), vec(r_in, y0), vec(r_out, y0)]


# --- A wheel on its rim (axis along Z) -------------------------------------------------------------

def standing_wheel(name, centre, radius, width=0.07, hub_r=0.085, hub_len=0.3, spoke=(0.055, 0.04), depth=0.075):
    """A wheel standing on its tyre, its hub at `centre` (x, y, z), axis along Z.

    The felloes are centred at 270 deg (the one on the ground) and every 60 deg from it; two spokes
    in each, at +-15 deg from its middle."""
    cx, cy, cz = centre
    r_out = radius - TYRE
    r_in = r_out - depth
    half = math.radians(180.0 / FELLOES)
    out = []
    for j in range(FELLOES):
        phi = math.radians(270.0 + 60.0 * j)
        mid_r = (r_in * math.cos(half) + r_out) * 0.5
        box_depth = r_out - r_in * math.cos(half)
        length = 2.0 * r_out * math.sin(half)
        a0 = math.degrees(phi - half)
        a1 = math.degrees(phi + half)
        # The sweep turned 90 deg about X: its angle t lands at -t in the wheel's plane.
        draw = {"shape": "sweep", "profile": ring(r_in, r_out, -width * 0.5, width * 0.5), "from": r4(-a1), "to": r4(-a0),
                "segments": 4, "caps": True, "rot": [90, 0, 0], "at": vec(cx, cy, cz)}
        tyre = {"look": IRON, "draw": {"shape": "sweep", "profile": ring(r_out, radius, -width * 0.5 - 0.004, width * 0.5 + 0.004),
                                       "from": r4(-a1), "to": r4(-a0), "segments": 4, "rot": [90, 0, 0], "at": vec(cx, cy, cz)}}
        out.append({
            "id": "%s_felloe%d" % (name, j), "kind": "post" if j == 0 else "board", "wood": GEAR_WOOD, "look": GEAR_LOOK,
            "size": vec(length, box_depth, width), "at": vec(cx + math.cos(phi) * mid_r, cy + math.sin(phi) * mid_r, cz),
            "rot": vec(0, 0, math.degrees(phi) + 90.0), "draw": draw, "dress": [tyre],
            "splits_below": 0.35,
        })
    for k in range(SPOKES):
        phi = math.radians(15.0 + 30.0 * k)
        inner = hub_r - 0.01
        outer = r_in + 0.015
        mid = (inner + outer) * 0.5
        in_ground_felloe = abs(((15.0 + 30.0 * k) - 270.0)) <= 15.0 + 1e-6
        out.append({
            "id": "%s_spoke%d" % (name, k), "kind": "stud" if in_ground_felloe else "cripple", "wood": GEAR_WOOD, "look": GEAR_LOOK,
            "size": vec(spoke[0], outer - inner, spoke[1]), "at": vec(cx + math.cos(phi) * mid, cy + math.sin(phi) * mid, cz),
            "rot": vec(0, 0, math.degrees(phi) - 90.0), "splits_below": 0.7, "blow_span": r4(outer - inner),
        })
    hub_profile = [vec(0.05, -hub_len * 0.5), vec(hub_r * 0.8, -hub_len * 0.42), vec(hub_r, -hub_len * 0.12), vec(hub_r, hub_len * 0.12),
                   vec(hub_r * 0.8, hub_len * 0.42), vec(0.05, hub_len * 0.5)]
    out.append({
        "id": "%s_hub" % name, "kind": "furniture_frame", "wood": GEAR_WOOD, "look": HUB_LOOK,
        "size": vec(hub_r * 2, hub_r * 2, hub_len), "at": vec(cx, cy, cz),
        "draw": {"shape": "lathe", "profile": hub_profile, "segments": 10, "rot": [90, 0, 0], "at": vec(cx, cy, cz)},
        "dress": hub_bands(hub_r, hub_len, (1, -1), rot=[90, 0, 0], at=vec(cx, cy, cz)),
    })
    return out


# --- A wheel lying flat (axis up) ------------------------------------------------------------------

def lying_wheel(name, radius=0.6, width=0.07, hub_r=0.085, hub_len=0.28, spoke=(0.055, 0.04), missing_felloes=(), broken_spokes=(),
                gone_spokes=()):
    """A wheel lying on the ground, hub up: every felloe a foot (`post`), the spokes on them
    (`stud`), the hub on the spokes. `missing_felloes`/`gone_spokes` leave pieces out; a broken
    spoke is a stub out of the hub, half its length."""
    r_out = radius - TYRE
    depth = 0.075
    r_in = r_out - depth
    half = math.radians(180.0 / FELLOES)
    y0 = 0.0
    yc = width * 0.5
    out = []
    for j in range(FELLOES):
        if j in missing_felloes:
            continue
        phi = math.radians(30.0 + 60.0 * j)
        mid_r = (r_in * math.cos(half) + r_out) * 0.5
        box_depth = r_out - r_in * math.cos(half)
        length = 2.0 * r_out * math.sin(half)
        a0 = math.degrees(phi - half)
        a1 = math.degrees(phi + half)
        # Lying flat, the sweep is the prop's own (angle t from +X toward +Z); the box's long side
        # along the tangent, turned about Y.
        out.append({
            "id": "%s_felloe%d" % (name, j), "kind": "post", "wood": GEAR_WOOD, "look": GEAR_LOOK,
            "size": vec(length, width, box_depth), "at": vec(math.cos(phi) * mid_r, yc, math.sin(phi) * mid_r),
            "rot": vec(0, -math.degrees(phi) - 90.0, 0),
            "draw": {"shape": "sweep", "profile": ring(r_in, r_out, y0, y0 + width), "from": r4(a0), "to": r4(a1), "segments": 4, "caps": True},
            "dress": [{"look": IRON, "draw": {"shape": "sweep", "profile": ring(r_out, radius, y0 + 0.004, y0 + width - 0.004),
                                              "from": r4(a0), "to": r4(a1), "segments": 4}}],
            "splits_below": 0.35,
        })
    for k in range(SPOKES):
        if k in gone_spokes:
            continue
        phi = math.radians(30.0 * k)
        inner = hub_r - 0.01
        outer = r_in + 0.015
        draw = {}
        if k in broken_spokes:
            outer = inner + (outer - inner) * 0.45
            # Snapped, not sawn: a sliver of it runs on past the break.
            d = np.array([math.cos(phi), 0.0, math.sin(phi)])
            tang = np.array([-math.sin(phi), 0.0, math.cos(phi)])
            lift = np.array([0.0, yc, 0.0])
            draw = {"shape": "boxes", "boxes": [
                {"from": vec(*(d * inner + lift)), "to": vec(*(d * (outer - 0.01) + lift)), "thick": spoke[1]},
                {"from": vec(*(d * (outer - 0.03) + tang * 0.012 + lift)), "to": vec(*(d * (outer + 0.05 + 0.02 * (k % 2)) + tang * 0.016 + lift)), "thick": 0.014}]}
        mid = (inner + outer) * 0.5
        # A stub out of the hub hangs on it (`cripple`, over the hub's tier); whole spokes stand on the rim.
        out.append({
            "id": "%s_spoke%d" % (name, k), "kind": "cripple" if k in broken_spokes else "stud", "wood": GEAR_WOOD, "look": GEAR_LOOK,
            "size": vec(outer - inner, spoke[1], spoke[0]), "at": vec(math.cos(phi) * mid, yc, math.sin(phi) * mid),
            "rot": vec(0, -math.degrees(phi), 0), "splits_below": 0.7, "blow_span": r4(outer - inner),
        })
        if draw:
            out[-1]["draw"] = draw
    hub_profile = [vec(0.05, 0.0), vec(hub_r * 0.85, 0.02), vec(hub_r, yc + 0.03), vec(hub_r, yc + 0.08), vec(hub_r * 0.8, hub_len),
                   vec(0.05, hub_len)]
    out.append({
        "id": "%s_hub" % name, "kind": "furniture_frame", "wood": GEAR_WOOD, "look": HUB_LOOK,
        "size": vec(hub_r * 2, hub_len - 0.005, hub_r * 2), "at": vec(0, hub_len * 0.5 + 0.005, 0),
        "draw": {"shape": "lathe", "profile": hub_profile, "segments": 10},
        "dress": hub_bands(hub_r, hub_len, (1,), at=vec(0, hub_len * 0.5, 0)),
    })
    return out


def wheel_wreck(radius=0.61, width=0.07):
    """What came off a broken wheel, lying by it (the critic, round 1: a neat gap reads as a
    cut-away): a felloe with its spoke tenons, the tyre sprung out of true, a spoke. Each a foot."""
    r_out = radius - TYRE
    r_in = r_out - 0.075
    half = math.radians(180.0 / FELLOES)
    mid_r = (r_in * math.cos(half) + r_out) * 0.5
    out = []
    # The felloe, turned 20 deg off where it was and 0.4 m out; drawn where it was and moved there.
    turn, off, phi = 20.0, 0.42, 180.0
    lands = math.radians(phi - turn)
    out.append({"id": "loose_felloe", "kind": "post", "wood": GEAR_WOOD, "look": GEAR_LOOK,
                "size": vec(2.0 * r_out * math.sin(half), width, r_out - r_in * math.cos(half)),
                "at": vec(math.cos(lands) * (mid_r + off), width * 0.5, math.sin(lands) * (mid_r + off)), "rot": vec(0, -(phi - turn) - 90.0, 0),
                "draw": {"shape": "sweep", "profile": ring(r_in, r_out, 0.0, width), "from": phi - 30, "to": phi + 30, "segments": 4, "caps": True,
                         "rot": [0, turn, 0], "at": vec(math.cos(lands) * off, 0, math.sin(lands) * off)}})
    # The tyre sprung open: a flatter arc of iron (it straightens when the felloes go).
    big = 0.92
    a0, a1 = 200.0, 242.0
    am = math.radians((a0 + a1) * 0.5)
    h = math.radians((a1 - a0) * 0.5)
    out.append({"id": "sprung_tyre", "kind": "post", "wood": "iron", "look": IRON,
                "size": vec(2 * big * math.sin(h), width - 0.008, big * (1 - math.cos(h)) + TYRE),
                "at": vec(math.cos(am) * (big * (1 + math.cos(h)) * 0.5 - TYRE * 0.5), (width - 0.008) * 0.5, math.sin(am) * (big * (1 + math.cos(h)) * 0.5 - TYRE * 0.5)),
                "rot": vec(0, -math.degrees(am) - 90.0, 0),
                "draw": {"shape": "sweep", "profile": ring(big - TYRE, big, 0.0, width - 0.008), "from": a0, "to": a1, "segments": 5}})
    out.append({"id": "loose_spoke", "kind": "post", "wood": GEAR_WOOD, "look": GEAR_LOOK,
                "size": vec(0.44, 0.04, 0.055), "at": vec(0.22, 0.02, -0.86), "rot": [0, 38, 0]})
    return out


# --- Wagons ------------------------------------------------------------------------------------------

def wagon(spec):
    """A wagon from its measures (see WAGONS)."""
    members = []
    track = spec["track"]          # between the wheels' middles (m)
    fx, rx = spec["axles"]         # front and hind axle x
    fr, rr = spec["wheels"]        # front and hind wheel radius
    # A heavy wagon's (the freight wagon's) wheels, axles and boards are stouter all through.
    heavy = spec.get("heavy", {})
    hub_len = heavy.get("hub_len", 0.3)
    wheel = {"width": heavy.get("felloe", 0.07), "depth": heavy.get("felloe", 0.075), "hub_r": heavy.get("hub_r", 0.085),
             "hub_len": hub_len, "spoke": heavy.get("spoke", (0.055, 0.04))}
    for side, z in (("l", -track * 0.5), ("r", track * 0.5)):
        members += standing_wheel("front_%s" % side, (fx, fr, z), fr, **wheel)
        members += standing_wheel("hind_%s" % side, (rx, rr, z), rr, **wheel)
    # The axles through the hubs (their arms and the wood between as one member each).
    axle = heavy.get("axle", 0.09)
    for name, x, r in (("front_axle", fx, fr), ("hind_axle", rx, rr)):
        members.append({"id": name, "kind": "cripple", "wood": GEAR_WOOD, "look": HUB_LOOK,
                        "size": vec(axle, axle, track + hub_len * 0.8), "at": vec(x, r, 0)})
    # The bolsters on the axles (the hind one raised on its block where the hind wheels are bigger),
    # the bed level on them.
    bed_y = spec["bed_y"]           # the bed floor's underside
    bw = spec["bed_width"]
    bl = spec["bed_length"]
    bolster = 0.1
    for name, x, r in (("front_bolster", fx, fr), ("hind_bolster", rx, rr)):
        bottom = r + axle * 0.5
        members.append({"id": name, "kind": "furniture_top", "wood": GEAR_WOOD, "look": HUB_LOOK,
                        "size": vec(bolster, bed_y - bottom, bw + 0.08), "at": vec(x, (bottom + bed_y) * 0.5, 0)})
    # The reach: the pole from the front axle back under the hind one.
    reach_y = (fr + rr) * 0.5
    members.append({"id": "reach", "kind": "furniture_top", "wood": GEAR_WOOD, "look": HUB_LOOK,
                    "size": vec(rx - fx + 0.3, 0.07, 0.08), "at": vec((fx + rx) * 0.5, reach_y + axle * 0.5 + 0.035, 0),
                    "rot": vec(0, 0, -math.degrees(math.atan2(rr - fr, rx - fx)))})
    # The tongue: from the front axle forward and down to the ground, where a parked wagon's rests;
    # the doubletree across it near the axle, drawn on.
    tl = spec["tongue"]
    ty = fr
    drop = math.asin(min(0.95, (ty - 0.04) / tl))
    tx = fx - math.cos(drop) * tl * 0.5
    # Its tip on the ground is a foot (`post`): held only at the axle it'd tear out of its hounds.
    members.append({"id": "tongue", "kind": "post", "wood": GEAR_WOOD, "look": GEAR_LOOK,
                    "size": vec(tl, 0.075, 0.075), "at": vec(tx - 0.05, ty - math.sin(drop) * tl * 0.5, 0),
                    "rot": vec(0, 0, math.degrees(drop)),
                    "dress": [{"look": HUB_LOOK, "draw": {"shape": "boxes", "boxes": [
                        {"size": vec(0.07, 0.06, 1.0), "at": vec(fx - 0.55, fr - math.tan(drop) * 0.5 + 0.05, 0)},
                        {"size": vec(0.06, 0.05, 0.6), "at": vec(fx - 0.62, fr - math.tan(drop) * 0.57 + 0.05, -0.32)},
                        {"size": vec(0.06, 0.05, 0.6), "at": vec(fx - 0.62, fr - math.tan(drop) * 0.57 + 0.05, 0.32)}]}}],
                    "splits_below": 0.4})
    # The bed: boards along it on the bolsters.
    floor_t = heavy.get("board", 0.025)
    boards = spec["floor_boards"]
    bx = (fx + rx) * 0.5 + spec.get("bed_shift", 0.0)
    for i in range(boards):
        z = -bw * 0.5 + bw * (i + 0.5) / boards
        members.append({"id": "floor%d" % i, "kind": "trim", "wood": BOX_WOOD, "look": BOX_LOOK,
                        "size": vec(bl, floor_t, bw / boards - 0.004), "at": vec(bx, bed_y + floor_t * 0.5, z)})
    top = bed_y + floor_t
    # Sides and ends, a board or two high, standing on the floor's edges; the stakes and straps on
    # them drawn on.
    side_t = heavy.get("board", 0.025)
    rows = spec["side_boards"]
    bh = spec["side_height"] / rows
    stakes = spec.get("stakes", 4)
    for row in range(rows):
        y = top + bh * (row + 0.5)
        for side, z in (("l", -bw * 0.5 + side_t * 0.5), ("r", bw * 0.5 - side_t * 0.5)):
            dress = []
            if row == 0:
                out_z = z + (-1 if side == "l" else 1) * (side_t * 0.5 + 0.012)
                dress = [{"look": IRON, "draw": {"shape": "boxes", "boxes": [
                    {"size": vec(0.035, spec["side_height"] - 0.01, 0.012), "at": vec(bx - bl * 0.5 + bl * (s + 0.5) / stakes, top + spec["side_height"] * 0.5, out_z)}
                    for s in range(stakes)]}}]
            members.append({"id": "side_%s%d" % (side, row), "kind": "trim", "wood": BOX_WOOD, "look": BOX_LOOK,
                            "size": vec(bl, bh - 0.004, side_t), "at": vec(bx, y, z), "dress": dress})
        for end, x in (("front", bx - bl * 0.5 + side_t * 0.5), ("tail", bx + bl * 0.5 - side_t * 0.5)):
            members.append({"id": "%s_board%d" % (end, row), "kind": "trim", "wood": BOX_WOOD, "look": BOX_LOOK,
                            "size": vec(side_t, bh - 0.004, bw - side_t * 2 - 0.004), "at": vec(x, y, 0)})
    side_top = top + spec["side_height"]
    # A seat on two risers across the box at the front (the buckboard's with a back).
    seat = spec.get("seat")
    if seat:
        sx = bx - bl * 0.5 + seat["from_front"]
        rh = seat["height"]
        for side, z in (("l", -bw * 0.5 + side_t + 0.03), ("r", bw * 0.5 - side_t - 0.03)):
            members.append({"id": "seat_riser_%s" % side, "kind": "trim", "wood": BOX_WOOD, "look": BOX_LOOK,
                            "size": vec(0.32, rh, 0.04), "at": vec(sx, top + rh * 0.5, z)})
        members.append({"id": "seat", "kind": "trim", "wood": BOX_WOOD, "look": HUB_LOOK,
                        "size": vec(0.36, 0.035, bw - side_t * 2 - 0.01), "at": vec(sx, top + rh + 0.0175, 0)})
        if seat.get("back"):
            members.append({"id": "seat_back", "kind": "trim", "wood": BOX_WOOD, "look": HUB_LOOK,
                            "size": vec(0.03, 0.26, bw - side_t * 2 - 0.05), "at": vec(sx + 0.17, top + rh + 0.035 + 0.13, 0),
                            "rot": [0, 0, -12]})
        if seat.get("dash"):
            members.append({"id": "dash", "kind": "trim", "wood": BOX_WOOD, "look": BOX_LOOK,
                            "size": vec(0.025, 0.4, bw - 0.02), "at": vec(bx - bl * 0.5 - 0.07, top + 0.19, 0),
                            "rot": [0, 0, -20]})
    # The brake: a beam before the hind wheels, its lever up the right side (drawn on the side).
    if spec.get("brake"):
        lever_x = rx - rr - 0.08
        for m in members:
            if m["id"] == "hind_bolster":
                # The beam across before the hind wheels, a shoe on each tyre.
                m["dress"] = [{"look": HUB_LOOK, "draw": {"shape": "boxes", "boxes": [
                    {"size": vec(0.08, 0.08, track - 0.1), "at": vec(rx - rr - 0.09, rr * 0.9, 0)}] + [
                    {"size": vec(0.06, 0.22, 0.09), "at": vec(rx - rr * 0.97 - 0.01, rr * 0.92, z * track * 0.5)} for z in (-1, 1)]}}]
            if m["id"] == "side_r0":
                m["dress"].append({"look": HUB_LOOK, "draw": {"shape": "boxes", "boxes": [
                    {"from": vec(lever_x, bed_y - 0.1, bw * 0.5 + 0.05), "to": vec(lever_x - 0.12, side_top + 0.45, bw * 0.5 + 0.06), "thick": 0.04}]}})
    # The cover: canvas on bows, straight up from the sides and arched over (Conestoga's cousin,
    # the prairie schooner's square-ended cover): each side's wall and two arcs, and the crown's two,
    # thin members each on the one under it; the bows drawn on the canvas.
    cover = spec.get("cover")
    if cover:
        # Over the sideboards' outer half, clear of the end boards between them.
        r = bw * 0.5 - 0.006
        wall = cover["wall"]
        hc = side_top + wall
        t = 0.01
        cl = bl + cover.get("overhang", 0.2)
        bows = cover["bows"]
        bow_xs = [bx - bl * 0.5 + bl * (i + 0.5) / bows for i in range(bows)]
        for side, sign in (("l", -1), ("r", 1)):
            z = sign * r
            members.append({"id": "canvas_wall_%s" % side, "kind": "trim", "wood": "canvas", "look": CANVAS_LOOK,
                            "size": vec(cl, wall, t), "at": vec(bx, side_top + wall * 0.5, z),
                            "dress": [{"look": HUB_LOOK, "draw": {"shape": "boxes", "boxes": [
                                {"size": vec(0.04, wall, 0.025), "at": vec(x, side_top + wall * 0.5, z - sign * 0.018)} for x in bow_xs]}},
                                      # Its ends drawn in toward the opening, as the arcs' are.
                                      {"look": CANVAS_LOOK, "draw": {"shape": "boxes", "boxes": [
                                          {"size": vec(0.12, wall * 0.9, 0.008), "at": vec(xe + e * 0.05, side_top + wall * 0.55, z - sign * 0.04),
                                           "rot": vec(0, sign * e * 35.0, 0)} for e, xe in ((-1, bx - cl * 0.5), (1, bx + cl * 0.5))]}}]})
            # Arcs: psi from the +Z side's horizontal up over (0..90 the right side, 90..180 the left).
            arcs = [(0.0, 45.0), (45.0, 90.0)] if sign > 0 else [(180.0, 135.0), (135.0, 90.0)]
            for k, (pa, pb) in enumerate(arcs):
                lo, hi = min(pa, pb), max(pa, pb)
                pm = math.radians((lo + hi) * 0.5)
                h = math.radians((hi - lo) * 0.5)
                cr = r * math.cos(h)
                # The sweep turned -90 about Z: its axis along X, its angle t at psi + 90.
                draw = {"shape": "sweep", "profile": [vec(r, bx - cl * 0.5), vec(r, bx + cl * 0.5), vec(r - 0.006, bx + cl * 0.5),
                                                      vec(r - 0.006, bx - cl * 0.5), vec(r, bx - cl * 0.5)],
                        "from": r4(lo + 90.0), "to": r4(hi + 90.0), "segments": 4, "rot": [0, 0, -90], "at": vec(0, hc, 0)}
                arc = {"from": r4(lo + 90.0), "to": r4(hi + 90.0), "segments": 4, "rot": [0, 0, -90], "at": vec(0, hc, 0)}
                bow_draws = [{"look": HUB_LOOK, "draw": dict({"shape": "sweep", "profile": ring(r - 0.036, r - 0.007, x - 0.02, x + 0.02)}, **arc)}
                             for x in bow_xs]
                # The cloth drawn tight over each bow (a rib), and gathered in at both ends on its
                # drawstring (the critic, round 1: a smooth loaf, no bows, no puckered end).
                bow_draws += [{"look": CANVAS_LOOK, "draw": dict({"shape": "sweep", "profile": ring(r, r + 0.012, x - 0.03, x + 0.03)}, **arc)}
                              for x in bow_xs]
                x0, x1 = bx - cl * 0.5, bx + cl * 0.5
                for e, xe in ((-1, x0), (1, x1)):
                    prof = [vec(r, xe), vec(r * 0.82, xe + e * 0.11), vec(r * 0.82 - 0.006, xe + e * 0.11), vec(r - 0.006, xe), vec(r, xe)]
                    bow_draws.append({"look": CANVAS_LOOK, "draw": dict({"shape": "sweep", "profile": prof}, **arc)})
                members.append({"id": "canvas_%s%d" % (side, k), "kind": "trim", "wood": "canvas", "look": CANVAS_LOOK,
                                "size": vec(cl, 2.0 * r * math.sin(h), t),
                                "at": vec(bx, hc + math.sin(pm) * cr, math.cos(pm) * cr), "rot": vec(-math.degrees(pm), 0, 0),
                                "draw": draw, "dress": bow_draws})
    return members


WAGONS = {
    "buckboard": {
        "_doc": "A buckboard: the light ranch and town wagon. Wheels 3 ft 8 in front, 4 ft hind; a box 8 ft by 3 ft 4 in a board deep; a spring seat with a back over the front, a dash before it. 12-spoke wheels in six oak felloes with iron tyres (each wheel stands on the felloe under its hub, its spokes carry the hub: shoot two out and that corner drops); the bed in old oak on two bolsters; the tongue down on the ground as a parked wagon's. ~300 kg.",
        "axles": [-0.85, 0.85], "wheels": [0.56, 0.61], "track": 1.45, "bed_y": 0.82, "bed_width": 1.0, "bed_length": 2.45,
        "floor_boards": 5, "side_boards": 1, "side_height": 0.24, "stakes": 3, "tongue": 2.4,
        "seat": {"from_front": 0.35, "height": 0.36, "back": True, "dash": True},
    },
    "freight_wagon": {
        "_doc": "A freight wagon: the heavy road wagon that brings the store its goods. Wheels 4 ft front, 5 ft hind; a box 12 ft by 3 ft 8 in, two boards deep, iron stakes along the sides; a brake lever up the right side; no seat (the driver rides the wheel horse or walks). ~650 kg.",
        "axles": [-1.35, 1.35], "wheels": [0.61, 0.76], "track": 1.6, "bed_y": 1.0, "bed_width": 1.12, "bed_length": 3.65,
        "floor_boards": 6, "side_boards": 2, "side_height": 0.6, "stakes": 5, "tongue": 2.7, "brake": True,
        "heavy": {"felloe": 0.095, "hub_r": 0.115, "hub_len": 0.4, "spoke": (0.075, 0.055), "axle": 0.13, "board": 0.04},
    },
    "covered_wagon": {
        "_doc": "A covered wagon (the prairie schooner): a farm wagon's box with its canvas on five bows, straight up from the sides and arched over. Wheels 3 ft 8 in front, 4 ft 4 in hind; a box 10 ft by 3 ft 6 in, two boards deep; a seat at the front. The canvas is six thin members on the sideboards (they burn, a ball holes them, they come down when the side under them goes); the bows drawn on it. ~450 kg.",
        "axles": [-1.0, 1.15], "wheels": [0.56, 0.66], "track": 1.55, "bed_y": 0.92, "bed_width": 1.07, "bed_length": 3.1,
        "floor_boards": 5, "side_boards": 2, "side_height": 0.48, "stakes": 4, "tongue": 2.6,
        "seat": {"from_front": 0.3, "height": 0.34},
        "cover": {"wall": 0.42, "bows": 5, "overhang": 0.25},
    },
}


def write(id_, data):
    path = os.path.join(KIT, id_ + ".json")
    with open(path, "w") as f:
        json.dump(data, f, indent=1)
        f.write("\n")
    return path


def main():
    common = {"kind": "members", "in_game": True, "factory": "tools/props/wagons.py", "wood": GEAR_WOOD, "look": GEAR_LOOK,
              "splits_below": 0.4, "blow_wood_share": 0.5}
    out = {}
    out["wagon_wheel"] = dict(common, **{
        "_doc": "A spare wagon wheel lying on the ground, hub up (a hind wheel, 4 ft): six oak felloes with the iron tyre shrunk on, twelve spokes, an elm hub with its iron bands. Every felloe a foot; the spokes on them, the hub on the spokes: a ball through a spoke splits it, a stick throws the wheel or blows it into felloes and spokes. ~45 kg.",
        "id": "wagon_wheel", "members": lying_wheel("wheel", radius=0.61)})
    out["broken_wagon_wheel"] = dict(common, **{
        "_doc": "A broken wagon wheel lying where it was thrown: two felloes gone with their tyre, their spokes snapped off short out of the hub and one more gone. As the wagon wheel otherwise.",
        "id": "broken_wagon_wheel", "members": lying_wheel("wheel", radius=0.61, missing_felloes=(2, 3), broken_spokes=(4, 5, 6, 7), gone_spokes=(8,))
        + wheel_wreck(radius=0.61)})
    for id_, spec in WAGONS.items():
        out[id_] = dict(common, **{"_doc": spec["_doc"], "id": id_, "members": wagon(spec)})
    for id_, data in out.items():
        print(write(id_, data), len(data["members"]), "members")


if __name__ == "__main__":
    main()
