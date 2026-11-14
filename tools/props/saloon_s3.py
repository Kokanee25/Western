"""Saloon B's props, batch S3 (#892; docs/briefs/saloon-design.md "The props B needs", "The store room and
cellar", "Upstairs"; "The new props in order", 8, 10 and 11): the kit files of the keg lying on its side
and its rack redone as a stillage (S2's critic: DIFFERENT, the kegs stood on end), the rented rooms' bed
and the owner's desk, written from the numbers here, so a change is one number and a re-run.

    python3 tools/props/saloon_s3.py [--only=beer_keg_side,keg_rack]   # writes assets/props/kit/<id>.json

No Blender this batch (bpy couldn't be installed in the session that made it, #892): the keg is the
barrel's staves (kit sweeps), the bed's bedding is the doctor's cot's (its Tick, Blanket and Pillow parts,
the same size: a single bed of the period), the desk library oak with its ledgers, papers and cigar box
drawn on as boxes. Few members (each a physics body standing; the valley is near Jolt's limit, #865).
Where each goes in saloon B (room, count) and its bodies: experiments/prop_lab/README.md "Saloon B,
batch S3".
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from doctor import COT, KIT, OAK, OAK_FRONT, OAK_TOP, ROOT, member, mesh, r  # noqa: E402
from saloon import OAK_OLD  # noqa: E402
from saloon_s2 import KEG, _keg_r  # noqa: E402

WALNUT_OLD = "lib:furniture_walnut/old"
WALNUT_OLD_TOP = WALNUT_OLD + "/top"


def euler_yxz(cols):
    """The kit's `rot` (degrees, Godot's YXZ: basis = Ry * Rx * Rz) of a basis given by its columns
    (where the member's own x, y and z go)."""
    (m00, m10, m20), (m01, m11, m21), (m02, m12, m22) = cols
    x = math.asin(max(-1.0, min(1.0, -m12)))
    y = math.atan2(m02, m22)
    z = math.atan2(m10, m11)
    return [math.degrees(x), math.degrees(y), math.degrees(z)]


# --- The keg on its side ---------------------------------------------------------------------------
# S2's half-barrel keg (its numbers, KEG) laid on its side, its axis along z (the tap head at +z, as it
# lies in a rack: tap end out), its eight staves laid out one by one round that axis: a repeat turns its
# copies round y only. Two staves at the bottom are its feet; the staves up each side rest on the ones
# under them (a tier each: the kit's supports are boxes, and a lying stave's box overlaps its
# neighbour's in height), the heads stand in the croze at the ends, held by the staves round them.
# Each stave's box is the chord of the bulge (its outer face at R cos 22.5, its width 2 R sin 22.5), so
# the bottom corners meet the floor where the drawn bulge does.
SIDE_KINDS = ["post", "stud", "furniture_frame", "rafter"]  # tiers 1-4, the bottom pair to the top pair
# A foot's box (x out from the keg's bottom line, its height): it reaches the next stave's box (whose
# lowest corner is at x 0.148, y 0.070) and keeps inside the drawn bulge.
FOOT = (0.155, 0.062)
FOOT_SOLID = 0.32


def _stave_angles():
    n = KEG["staves"]
    step = 360.0 / n
    return [-90.0 - step * 0.5 + step * k for k in range(n)]  # -112.5 .. : two straddle the bottom


def beer_keg_side():
    k = KEG
    H, n, t = k["height"], k["staves"], k["stave_t"]
    R = k["r_end"] + k["bulge"]  # the bulge's outer radius: the floor's under it
    cy = R
    half = 180.0 / n
    outer_face = R * math.cos(math.radians(half))
    width = 2 * R * math.sin(math.radians(half))
    rc = outer_face - t * 0.5
    seg = 8
    # The sweep is drawn about the keg's own y and laid down: Rx(90) takes its y to the prop's z (its
    # bottom head at -H/2), its +z to the prop's -y, so a stave at phi (in the xy plane, from +x toward
    # +y) is the sweep's angle -phi.
    lay = {"at": r([0, cy, -H * 0.5]), "rot": [90.0, 0.0, 0.0]}
    w = k["hoop_w"] * 0.5
    ms = []
    for i, phi in enumerate(_stave_angles()):
        a = math.radians(phi)
        c, s = math.cos(a), math.sin(a)
        rot = euler_yxz([(-s, c, 0.0), (0.0, 0.0, 1.0), (c, s, 0.0)])  # own x tangent, y along z, z out
        # Its tier by how high it is: the bottom pair 0, the top pair 3.
        tier = min(3, int((s + 1.0) * 0.5 * 4.0 + 1e-6))
        # The bottom pair, its feet, are each two members end to end (KitProp sets a prop down by a ray
        # under each foot's middle: a whole stave's is the keg's middle, between a rack's rails).
        halves = [(0.0, H * 0.5, "a"), (H * 0.5, H, "b")] if tier == 0 else [(0.0, H, "")]
        for y0, y1, suffix in halves:
            out = [(_keg_r(y0 + (y1 - y0) * j / seg), y0 + (y1 - y0) * j / seg) for j in range(seg + 1)]
            profile = [r(q) for q in out + [(rr - t, y) for rr, y in reversed(out)] + [out[0]]]
            sweep = {"shape": "sweep", "profile": profile, "from": r(-phi - half), "to": r(-phi + half), "segments": 3,
                     "grain_up": True, "caps": True}
            sweep.update(lay)
            zc = (y0 + y1) * 0.5 - H * 0.5
            if tier == 0:
                # A foot's box lies flat under its stave (drawn as the stave), from the keg's bottom line
                # out to where the stave beside it starts (their boxes must touch to carry it), so all
                # four of its bottom corners are on the floor: KitProp settles a prop onto the middle of
                # its feet's lowest corners, and a tilted stave's sank it 11 mm into a rack's rails.
                # `solid`: the stave's own section's share of the box (its weight a stave's).
                fx, fy = FOOT
                m = member("stave%d%s" % (i, suffix), "post", [fx, y1 - y0, fy], [(1 if c > 0 else -1) * fx * 0.5, fy * 0.5, zc],
                           rot=[90.0, 0.0, 0.0], draw=sweep, solid=FOOT_SOLID)
            else:
                m = member("stave%d%s" % (i, suffix), SIDE_KINDS[tier], [width, y1 - y0, t], [rc * c, cy + rc * s, zc], rot=r(rot), draw=sweep)
            hoops = []
            for y in k["hoops"]:
                if not (y0 <= y < y1):
                    continue
                d = {"shape": "sweep", "profile": [r([_keg_r(y - w) + 0.002, y - w]), r([_keg_r(y) + 0.006, y]), r([_keg_r(y + w) + 0.002, y + w])],
                     "from": r(-phi - half), "to": r(-phi + half), "segments": 3}
                d.update(lay)
                hoops.append({"look": "prop:iron", "draw": d})
            m["dress"] = hoops
            ms.append(m)
    ri = k["r_end"] - t + 0.008
    side = ri * 2 * 0.86
    ht = k["head_t"]
    for name, z, look in (("head_tap", H * 0.5 - k["croze"] + ht * 0.5, "prop:barrel_head"),
                          ("head_back", -H * 0.5 + k["croze"] - ht * 0.5, "prop:barrel_head")):
        hm = member(name, "board", [side, ht, side], [0, cy, z], look=look, rot=[90.0, 0.0, 0.0],
                    draw={"shape": "disc", "radius": r(ri), "segments": 24})
        if name == "head_tap":
            # The tap's bung: a brass-ringed oak plug a third of the way down the head (drawn on).
            hm["dress"] = [{"look": "prop:brass", "draw": {"shape": "lathe", "profile": [[0.03, 0.0], [0.03, 0.012], [0.022, 0.016], [0.0, 0.016]],
                                                             "segments": 12, "at": r([0, cy - 0.07, z + ht * 0.5]), "rot": [90.0, 0.0, 0.0]}}]
        ms.append(hm)
    # Its inside as PropContents reads one (an upright cask's: heights and a radius at the ends and the
    # middle): the horizontal cylinder's height across, the middle's radius the circle whose area is the
    # middle slice's (2 Ri x its length), the ends' radius solved so it holds what it held upright.
    Ri = k["r_end"] + k["bulge"] * 0.5 - t  # the staves' mean inner radius
    L = H - 2 * k["croze"]
    r_mid = math.sqrt(2.0 * Ri * L / math.pi)
    up = _upright_capacity()
    r_end = _solve_end(Ri * 2.0, r_mid, up)
    return {
        "_doc": "A beer keg on its side (#892; refs experiments/prop_lab/refs/saloon/, batch S2's keg photos: the racking room's kegs lie on their sides): S2's half-barrel keg (`beer_keg`, the same staves, hoops and heads, 15 1/2 gallons) laid down, its axis along z, the tap head (its bung drawn on) at +z: tap end out, as it lies in a stillage (`keg_rack`) or on the cellar floor. Its eight staves laid out one by one round the axis (each its own `rot`: a repeat turns round y only); the two at the bottom are its feet, the others rest on the ones under them, the heads stand in the croze. Full of beer (PropContents, its inside the lying cask's: a hole low lets it run). A kit prop is held only by what's under its own bottom, so `beer_keg` turned over goes loose: this one lies as it's built, the two bottom staves its feet (each in two lengths, so a rack's two rails are under them). 12 physics bodies (8 staves, the bottom two its feet in two lengths each, and 2 heads). Written by tools/props/saloon_s3.py.",
        "like": "barrel", "id": "beer_keg_side", "replaces": "", "in_game": False, "fixture": True,
        "holds": {"_doc": "Its inside lying (PropContents reads an upright cask's heights and radii): from the bottom staves' inside to the top's, the middle's radius the round whose area is the middle slice's, the ends' solved so it holds what the upright keg does (~59 l).",
                  "from": r(cy - Ri), "to": r(cy + Ri), "radius": r([r_end, r_mid])},
        "contents": {"liquid": "beer", "full": True},
        "members": ms,
    }


def _capacity(h, r_end, r_mid, steps=200):
    tot = 0.0
    for i in range(steps):
        u = ((i + 0.5) / steps) * 2.0 - 1.0
        rr = r_mid - (r_mid - r_end) * u * u
        tot += math.pi * rr * rr * h / steps
    return tot


def _upright_capacity():
    k = KEG
    return _capacity(k["height"] - 2 * k["croze"], k["r_end"] - k["stave_t"], k["r_end"] + k["bulge"] - k["stave_t"])


def _solve_end(h, r_mid, want):
    lo, hi = 0.0, r_mid
    for _ in range(60):
        mid = (lo + hi) * 0.5
        if _capacity(h, mid, r_mid) < want:
            lo = mid
        else:
            hi = mid
    return (lo + hi) * 0.5


# --- The keg rack, redone as a stillage ----------------------------------------------------------
# The cellar's stillage: two tiers of oak cradle rails running the rack's length, the kegs lying across
# them on their sides, tap end out (+z), four a tier, a chock nailed to the rail either side of each keg
# (drawn on the rails: 32 chocks as members would be 32 bodies). Posts at the ends and in the middle,
# where the kegs leave a gap for them; the upper tier's rails clear the lower kegs.
RACK = {"post": 0.09, "rail": (0.09, 0.075), "rail_z": 0.15, "low": 0.16, "gap": 0.04, "pitch": 0.54, "clear": 0.03,
        "chock": (0.07, 0.05, 0.07)}


def rack_slots():
    """Where its kegs lie: [(x, y)] the rack's space, the keg's bottom (beer_keg_side's origin)."""
    c = RACK
    d = (KEG["r_end"] + KEG["bulge"]) * 2.0
    x0 = c["post"] * 0.5 + c["gap"] + d * 0.5
    xs = [-x0 - c["pitch"], -x0, x0, x0 + c["pitch"]]
    hi = c["low"] + d + c["clear"] + c["rail"][1]
    return [(x, y) for y in (c["low"], hi) for x in xs]


def keg_rack():
    c = RACK
    p = c["post"]
    rw, rh = c["rail"]
    d = (KEG["r_end"] + KEG["bulge"]) * 2.0
    slots = rack_slots()
    tiers = sorted({y for _, y in slots})
    end_x = max(x for x, _ in slots) + d * 0.5 + c["gap"] + p * 0.5
    L = end_x * 2.0 + p
    top = tiers[-1]
    hz = c["rail_z"] + rw * 0.5 + p * 0.5
    ms = []
    for i, x in enumerate((-end_x, 0.0, end_x)):
        for s_, name in ((-1, "b"), (1, "f")):
            ms.append(member("post%d%s" % (i, name), "post", [p, top, p], [x, top * 0.5, s_ * hz], look=OAK_OLD, blow_span=tiers[0]))
    cw, ch, cd = c["chock"]
    for j, y in enumerate(tiers):
        for s_, name in ((-1, "b"), (1, "f")):
            z = s_ * c["rail_z"]
            m = member("rail%d%s" % (j, name), "furniture_top", [L, rh, rw], [0, y - rh * 0.5, z], look=OAK_OLD)
            # The chocks: a wedge either side of each keg, its slope to the keg (a box turned 35 degrees).
            boxes = []
            for x, _ in [sl for sl in slots if sl[1] == y]:
                for side in (-1, 1):
                    cx = x + side * (d * 0.5 - 0.06)
                    boxes.append({"size": r([cw, ch, cd]), "at": r([cx, y + ch * 0.3, z]), "rot": [0.0, 0.0, -side * 35.0]})
            m["dress"] = [{"look": OAK_OLD, "draw": {"shape": "boxes", "boxes": boxes}}]
            ms.append(m)
    return {
        "_doc": "A keg rack (#879, redone #892; refs experiments/prop_lab/refs/saloon/, the Columbia racking room's kegs on their sides): the cellar's stillage, two tiers of heavy oak cradle rails (3 x 4 in) running its length on six 4 in posts, the kegs lying across the rails on their sides, tap end out (+z), four a tier (`beer_keg_side`, placed on it: `rack_slots` in tools/props/saloon_s3.py, the lower tier's rails at 16 cm, the upper's clear of the lower kegs), a chock either side of each keg nailed to the rail (drawn on). %.2f m long, %.2f m deep, %.2f m to the upper rails. Old oak from the material library (a cellar's: unpainted, slopped and dark). Saloon B's store room and cellar: 2. 10 physics bodies (its members). Written by tools/props/saloon_s3.py." % (L, hz * 2 + p, top),
        "id": "keg_rack", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.5, "blow_wood_share": 0.5,
        "slots": [r([x, y, 0.0]) for x, y in slots],
        "members": ms,
    }


# --- The rented rooms' bed ------------------------------------------------------------------------
# A plain single bedstead of the period's boarding houses and hotels' cheaper rooms (a "cottage" bed):
# four square walnut-stained posts with turned caps, a headboard of two wide boards and a lower
# footboard of one, side rails into the posts carrying a bottom of slats, the doctor's cot's bedding on
# it (a straw tick in ticking, a grey wool blanket, a pillow: `iron_cot`'s parts, the same size). Not
# the cot itself: the rooms let to a man for the night want a bed, not a ward's cot (the cot is iron,
# narrow and plain; the brief asks for "iron or plain wood": two rooms can take the cot, two this).
BED = {"post": 0.06, "head_h": 1.15, "foot_h": 0.78, "rail": (0.13, 0.03), "board_t": 0.022, "head_boards": (0.42, 0.87),
       "foot_board": (0.47, 0.66), "board_h": 0.2, "slats_t": 0.02}


def plank_bed():
    c, cot = BED, COT
    tx, ty, tz = cot["tick"]
    p = c["post"]
    spring = cot["spring_y"]  # the tick's bottom: the cot's (its drawn parts lie there)
    inner_x, inner_z = tx * 0.5 + 0.02, tz * 0.5 + 0.02
    px, pz = inner_x + p * 0.5, inner_z + p * 0.5
    ms = []
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        h = c["head_h"] if sz < 0 else c["foot_h"]
        m = member("post%d" % i, "post", [p, h, p], [sx * px, h * 0.5, sz * pz], look=WALNUT_OLD, blow_span=0.3)
        # Its turned cap (drawn on).
        m["dress"] = [{"look": WALNUT_OLD, "draw": {"shape": "lathe", "profile": [[p * 0.55, h], [p * 0.6, h + 0.02], [p * 0.45, h + 0.05], [0.0, h + 0.06]],
                                                    "segments": 10, "at": r([sx * px, 0, sz * pz])}}]
        ms.append(m)
    rh, rt = c["rail"]
    bt, bh = c["board_t"], c["board_h"]
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("rail_" + name, "furniture_frame", [rt, rh, inner_z * 2], [s_ * (inner_x - rt * 0.5), spring - c["slats_t"] - rh * 0.5 + 0.03, 0],
                         look=WALNUT_OLD))
    for k, y in enumerate(c["head_boards"]):
        ms.append(member("head_board%d" % k, "furniture_frame", [inner_x * 2, bh * (1.6 if k else 1.0), bt], [0, y + bh * (0.3 if k else 0.0), -pz],
                         look=WALNUT_OLD))
    for k, y in enumerate(c["foot_board"]):
        ms.append(member("foot_board%d" % k, "furniture_frame", [inner_x * 2, bh, bt], [0, y, pz], look=WALNUT_OLD))
    # The slats: one member (they lie loose in the rails' rebate, a fire takes them together), drawn as six.
    sy = spring - c["slats_t"] * 0.5
    slats = [{"size": r([inner_x * 2 - 2 * rt, c["slats_t"], 0.09]), "at": r([0, sy, -inner_z + 0.16 + k * (inner_z * 2 - 0.32) / 5.0])} for k in range(6)]
    ms.append(member("slats", "furniture_top", [inner_x * 2 - 2 * rt, c["slats_t"], inner_z * 2 - 0.1], [0, sy, 0], look=WALNUT_OLD,
                     draw={"shape": "boxes", "boxes": slats}))
    ms.append(member("tick", "trim", [tx, ty, tz], [0, spring + ty * 0.5, 0.0], wood="straw", look="pbr:iron_cot", draw=mesh("iron_cot", "Tick")))
    bx, by, bz = cot["blanket"]
    ms.append(member("blanket", "trim", [bx - 0.04, by, bz], [0, spring + ty + by * 0.5, tz * 0.5 - bz * 0.5], wood="canvas", look="pbr:iron_cot",
                     draw=mesh("iron_cot", "Blanket")))
    qx, qy, qz = cot["pillow"]
    ms.append(member("pillow", "trim", [qx, qy, qz], [0, spring + ty + qy * 0.5, -tz * 0.5 + qz * 0.5 + 0.03], wood="straw", look="pbr:iron_cot",
                     draw=mesh("iron_cot", "Pillow")))
    return {
        "_doc": "A rented room's bed (#892; saloon-design.md \"Upstairs\": beds, iron or plain wood, for the four rented rooms): a plain single cottage bedstead of the period's boarding houses and hotels, four square posts with turned caps, a headboard of two wide boards (the upper one deeper) at 1.15 m and a footboard of two at 0.78, side rails carrying a bottom of slats, and on it the doctor's cot's bedding (`iron_cot`'s Tick, Blanket and Pillow: a straw tick in blue-and-white ticking, a grey wool blanket, a pillow; the same size, a single bed's). Walnut-stained hardwood from the material library, old (rubbed pale on the posts' caps and the rails' edges). The head at -z: a man lies looking +z. The rails, slats and bedding burn; a ball through a post splits it. 14 physics bodies (its members). Written by tools/props/saloon_s3.py.",
        "id": "plank_bed", "kind": "members", "fixture": True, "in_game": False, "wood": "walnut",
        "splits_below": 0.5, "blow_wood_share": 0.5,
        "seat": {"member": "tick", "at": [0.0, r(spring + ty), 0.1], "share": 1.0, "hold": 0.1, "sway": 0.0},
        "members": ms,
    }


# --- The owner's desk -----------------------------------------------------------------------------
# A flat-top kneehole office desk (a merchant's or saloon keeper's of the 1870s-80s): two pedestals of
# three drawers either side of the knee hole, a top of two oak boards overhanging them, a low gallery
# along its back (a rail on the top's back edge), and on the top his ledgers, papers, an inkstand and
# a cigar box, drawn on. Not the doctor's roll-top: that's 42 bodies and a professional man's; the
# owner's office wants a plain desk he does his books at, ~12. His strongbox is the kit's (`strongbox`,
# the Baron's: iron, padlocked, papers inside) on the floor by the desk.
DESK = {"width": 1.22, "depth": 0.68, "top": 0.76, "top_t": 0.028, "over": 0.025, "ped": 0.38, "side_t": 0.019, "drawers": 3,
        "plinth": 0.08, "gallery": (0.09, 0.016)}


def owner_desk():
    c = DESK
    W, D, T, tt, ov = c["width"], c["depth"], c["top"], c["top_t"], c["over"]
    pw, st = c["ped"], c["side_t"]
    h = T - tt
    ms = []
    dd = D - ov * 2
    for s_, name in ((-1, "l"), (1, "r")):
        cx = s_ * (W * 0.5 - ov - pw * 0.5)
        for k, sx in enumerate((-1, 1)):
            ms.append(member("ped_%s_side%d" % (name, k), "post", [st, h, dd], [cx + sx * (pw * 0.5 - st * 0.5), h * 0.5, 0], look=OAK))
        ms.append(member("ped_%s_back" % name, "furniture_frame", [pw - 2 * st, h - 0.02, st], [cx, h * 0.5 + 0.01, -dd * 0.5 + st * 0.5], look=OAK))
        # Its drawer fronts: one member (they come out together when it's smashed), drawn as three with pulls.
        dh = (h - c["plinth"]) / c["drawers"]
        fr = member("ped_%s_drawers" % name, "trim", [pw - 2 * st, h - c["plinth"], 0.02], [cx, c["plinth"] + (h - c["plinth"]) * 0.5, dd * 0.5 - 0.01],
                    look=OAK_FRONT)
        fr["dress"] = [{"look": "prop:brass", "draw": {"shape": "boxes", "boxes": [{"size": [0.07, 0.012, 0.014], "at": r([cx, c["plinth"] + dh * (k + 0.55), dd * 0.5 + 0.007])}
                                                                                   for k in range(c["drawers"])]}}]
        ms.append(fr)
    # The knee hole's back (a modesty panel) and the shallow drawer over it.
    kw = W - 2 * ov - 2 * pw
    ms.append(member("knee_back", "furniture_frame", [kw, h * 0.55, st], [0, h - h * 0.275, -dd * 0.5 + st * 0.5], look=OAK))
    ms.append(member("knee_drawer", "trim", [kw - 0.01, 0.075, 0.02], [0, h - 0.0375 - 0.005, dd * 0.5 - 0.01], look=OAK_FRONT))
    ms[-1]["dress"] = [{"look": "prop:brass", "draw": {"shape": "boxes", "boxes": [{"size": [0.07, 0.012, 0.014], "at": r([0, h - 0.04, dd * 0.5 + 0.007])}]}}]
    # The top: two boards, front and back.
    bd = D / 2.0
    for k in range(2):
        ms.append(member("top%d" % k, "furniture_top", [W, tt, bd], [0, T - tt * 0.5, -D * 0.5 + bd * (k + 0.5)], look=OAK_TOP))
    gh, gt = c["gallery"]
    # On the top, drawn on its boards (they go where the top goes): two ledgers (one open), loose papers,
    # an inkstand with a pen, a cigar box with its paper label. Ledgers: half-bound in red-brown leather
    # with buckram sides; the cigar box cedar with a paper label and a brass tack.
    y = T
    back_items = [
        # A closed ledger lying, and a second on it.
        {"size": [0.30, 0.045, 0.40], "at": r([-0.38, y + 0.0225, -0.05]), "rot": [0, 6, 0]},
        {"size": [0.27, 0.035, 0.36], "at": r([-0.37, y + 0.045 + 0.0175, -0.06]), "rot": [0, -4, 0]},
    ]
    ms[-2]["dress"] = [
        {"look": "prop:hide_dark", "draw": {"shape": "boxes", "boxes": back_items}},
    ]
    open_ledger = [{"size": [0.26, 0.018, 0.36], "at": r([0.02, y + 0.009, 0.0]), "rot": [0, 0, -3]},
                   {"size": [0.26, 0.018, 0.36], "at": r([0.28, y + 0.009, 0.0]), "rot": [0, 0, 3]}]
    pages = [{"size": [0.245, 0.004, 0.34], "at": r([0.02, y + 0.02, 0.0]), "rot": [0, 0, -3]},
             {"size": [0.245, 0.004, 0.34], "at": r([0.28, y + 0.02, 0.0]), "rot": [0, 0, 3]},
             {"size": [0.21, 0.002, 0.28], "at": r([-0.12, y + 0.001, 0.2]), "rot": [0, 18, 0]},
             {"size": [0.21, 0.002, 0.28], "at": r([-0.08, y + 0.003, 0.22]), "rot": [0, -9, 0]}]
    cigar = [{"size": [0.22, 0.055, 0.14], "at": r([0.47, y + 0.0275, -0.17]), "rot": [0, -12, 0]}]
    label = [{"size": [0.12, 0.002, 0.08], "at": r([0.47, y + 0.056, -0.17]), "rot": [0, -12, 0]}]
    ink = [{"size": [0.05, 0.05, 0.05], "at": r([0.35, y + 0.025, -0.27])},
           {"from": r([0.33, y + 0.05, -0.26]), "to": r([0.25, y + 0.13, -0.2]), "thick": 0.006}]
    front = ms[-1]
    front["dress"] = [
        {"look": "prop:hide_dark", "draw": {"shape": "boxes", "boxes": open_ledger + ink}},
        {"look": "prop:ivory", "draw": {"shape": "boxes", "boxes": pages + label}},
        {"look": "prop:mid_wood", "draw": {"shape": "boxes", "boxes": cigar}},
    ]
    ms.append(member("gallery", "trim", [W - 0.02, gh, gt], [0, T + gh * 0.5, -D * 0.5 + gt * 0.5 + 0.01], look=OAK))
    return {
        "_doc": "The owner's desk (#892; saloon-design.md \"Upstairs\": the owner's desk, his chair, a strongbox, ledgers and papers, a cigar box): a flat-top kneehole office desk of the 1870s-80s, a merchant's or saloon keeper's, 1.22 m wide, 0.68 deep, its top at 30 in, two pedestals of three drawers with brass pulls either side of the knee hole, a shallow drawer over it, a top of two oak boards overhanging, a low gallery along its back edge. On the top, drawn on its boards: two ledgers half-bound in dark leather, a third open with its pages, loose papers, an inkstand and pen, a cedar cigar box with its paper label. Oak from the material library (a few years). Not the doctor's roll-top (42 bodies, a professional man's): a plain desk he does his books at. His chair is the kit's (`chair` or `bentwood_chair`); his strongbox the kit's (`strongbox`) on the floor by it. 13 physics bodies (its members). Written by tools/props/saloon_s3.py.",
        "id": "owner_desk", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.5, "blow_wood_share": 0.5,
        "members": ms,
    }


BATCH_S3 = [beer_keg_side, keg_rack, plank_bed, owner_desk]


def main():
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    for make in BATCH_S3:
        if only and make.__name__ not in only:
            continue
        d = make()
        d["factory"] = "tools/props/saloon_s3.py"
        path = os.path.join(KIT, d["id"] + ".json")
        with open(path, "w") as f:
            json.dump(d, f, indent=2)
            f.write("\n")
        print("wrote", os.path.relpath(path, ROOT), "(%d members)" % len(d.get("members", [])))


if __name__ == "__main__":
    main()
