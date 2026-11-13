"""Saloon B's props, batch S2 (#879; docs/briefs/saloon-design.md "The new props in order", 5-8 and 12):
the kit files of the wall bench, the handsaw, the fiddle and its bow, the beer keg and its rack, and the
kitchen's cookstove, written from the numbers here, so a change is one number and a re-run. The Blender
half (tools/blender/props/saloon_s2.py) reads the same numbers.

    python3 tools/props/saloon_s2.py [--only=wall_bench,beer_keg]   # writes assets/props/kit/<id>.json

As S1 (tools/props/saloon.py): woods from the material library (`lib:<entry>/<age>`: painted pine for
the plain pieces, never the room's floor), metal the gun way (`pbr:<model>`), the barrel's own staves
for the keg. Few members (each is a physics body while the prop stands; the valley is near Jolt's limit,
#865): small things are a prop's `dress`. References: experiments/prop_lab/refs/saloon/ ("Batch S2").
Where each goes in saloon B (room, count) and its bodies: experiments/prop_lab/README.md "Saloon B,
batch S2".
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from doctor import KIT, PINE, ROOT, member, mesh, r  # noqa: E402
from saloon import OAK_OLD, dress  # noqa: E402

PINE_OLD = "lib:furniture_painted_pine/old"
PINE_OLD_TOP = PINE_OLD + "/top"


# --- The wall bench -------------------------------------------------------------------------------
# A plain board bench of the period's halls, depots and porches (the dance hall's walls, the balcony,
# the walk): a single wide pine seat plank 6 ft long on four square legs set in from its ends, a rail
# under its front and back edges, a stretcher low at each end, and the back legs run on up into a back
# rail at shoulder-blade height (the hall's benches stood against the wall, the walk's didn't).
BENCH = {"length": 1.83, "depth": 0.34, "seat_y": 0.44, "seat_t": 0.035, "leg": 0.05, "inset": 0.12, "back_y": 0.86,
         "back": (0.13, 0.025), "rail": (0.08, 0.022), "stretcher_y": 0.13, "stretcher": 0.035, "rake": 0.03}


def wall_bench():
    c = BENCH
    L, D, sy, st, lg = c["length"], c["depth"], c["seat_y"], c["seat_t"], c["leg"]
    hx = L * 0.5 - c["inset"]
    hz = D * 0.5 - lg * 0.5 - 0.015
    h = sy - st
    ms = []
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("leg_front_" + name, "post", [lg, h, lg], [s_ * hx, h * 0.5, hz], look=PINE, blow_span=c["stretcher_y"]))
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("post_back_" + name, "post", [lg, c["back_y"], lg], [s_ * hx, c["back_y"] * 0.5, -hz], look=PINE,
                         blow_span=c["stretcher_y"]))
    ms.append(member("seat", "furniture_top", [L, st, D], [0, sy - st * 0.5, 0.01], look=PINE_OLD_TOP))
    rh, rt = c["rail"]
    for s_, name in ((1, "f"), (-1, "b")):
        ms.append(member("rail_" + name, "furniture_frame", [hx * 2 - lg, rh, rt], [0, h - rh * 0.5, s_ * (hz - lg * 0.5 + rt * 0.5)], look=PINE))
    sw = c["stretcher"]
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("stretcher_" + name, "furniture_frame", [sw, sw, hz * 2 - lg], [s_ * hx, c["stretcher_y"], 0], look=PINE))
    bh, bt = c["back"]
    ms.append(member("back", "furniture_frame", [hx * 2 + lg + 0.1, bh, bt], [0, c["back_y"] - bh * 0.5, -hz - lg * 0.5 - bt * 0.5], look=PINE_OLD))
    return {
        "_doc": "A plain wall bench (#879; refs experiments/prop_lab/refs/saloon/, batch S2): the period's hall, depot and porch bench, a single pine seat plank 6 ft long and 13 in deep at 17 in, on four square legs set in 12 cm from its ends, a rail under its front and back edges, a low stretcher at each end, the back legs run on up into a back rail at 86 cm. Saloon B's dance hall has six round its walls (the girls and the men sat out between dances), the balcony one (Balcony Ambush's men need somewhere to be), the walk one or two. Painted pine from the material library (a few years; the seat and back rail old, rubbed bare where sat on and leaned against). Seats three (`seat` is its middle). 10 physics bodies (its members). ~18 kg. Written by tools/props/saloon_s2.py.",
        "id": "wall_bench", "kind": "members", "fixture": True, "in_game": False, "wood": "weathered_pine",
        "splits_below": 0.5, "blow_wood_share": 0.5,
        "seat": {"member": "seat", "at": [0.0, sy, 0.02], "share": 0.8, "hold": 0.05, "sway": 0.03},
        "members": ms,
    }


# --- The handsaw ----------------------------------------------------------------------------------
# A carpenter's 26 in handsaw of the 1870s-80s (the Disston pattern: a taper-ground steel blade, a
# breasted back, an apple-wood handle closed round the hand, fixed by four split brass saw nuts),
# lying on its side: the blade along x (the toe at +x), the teeth toward +z, its flat on y.
SAW = {"blade": 0.66, "heel": 0.17, "toe": 0.055, "thick": 0.0011, "handle": (0.16, 0.135, 0.022), "nuts": 4}


def handsaw():
    s = SAW
    hl, hh, ht = s["handle"]
    length = s["blade"] + hl - 0.02
    return {
        "_doc": "A carpenter's handsaw (#879; refs experiments/prop_lab/refs/saloon/, batch S2): the Disston pattern of the 1870s-80s, a 26 in taper-ground steel blade breasted along its back, 7 points to the inch, an apple-wood handle closed round the hand with four split brass saw nuts. Payday Night's: carried up the outside stair to cut through the dance floor. Lying on its side (the blade along x, the toe at +x, the teeth toward +z). Steel the gun way, the blade dulled and freckled with rust, bright along its teeth, the handle's varnish worn through where the hand goes (tools/blender/props/saloon_s2.py). A loose prop (LooseProp: one physics body; a ball holes the blade, a kick or a fall bends it). ~0.9 kg. Written by tools/props/saloon_s2.py.",
        "id": "handsaw", "kind": "loose", "fixture": True, "in_game": False, "replaces": "",
        "model": "glb:handsaw", "looks": {"Blade": "pbr:handsaw", "Handle": "pbr:handsaw", "Nuts": "pbr:handsaw"},
        "shape": "box", "size": r([length, ht, s["heel"] + 0.05]), "mass": 0.9, "wall": 0.0011, "hole_radius": 0.005,
        "breaks_at": 1000.0, "shatters_kpa": 1000000000.0, "spills_below": 0.0,
        "dent": {"radius": 0.04, "shot": 0.004, "kick": 0.01, "fall": 0.004},
    }


# --- The fiddle and its bow ---------------------------------------------------------------------
# A country fiddle (a violin, the dance hall's whole band with the piano): a body 14 in long, an arched
# spruce top with its f-holes, maple ribs and back under a worn brown varnish, an ebony fingerboard,
# pegs, tailpiece and chin-side, a maple bridge and four strings to a carved scroll; lying on its back
# (its top up), the scroll at +x. Its bow apart: a pernambuco stick 75 cm with an ebony frog and a
# ribbon of white horse hair. Made to be held as well (`grips`: where the fiddler's hands go, its neck and the bow's frog; read by no code yet).
FIDDLE = {"body": 0.356, "lower": 0.205, "upper": 0.168, "waist": 0.11, "rib": 0.032, "arch": 0.015, "neck": 0.13, "scroll": 0.105,
          "board": (0.27, 0.042, 0.024), "length": 0.595}
BOW = {"length": 0.75, "stick_r": 0.0042, "frog": (0.05, 0.022, 0.012), "hair": 0.011}


def fiddle():
    f = FIDDLE
    h = f["rib"] + f["arch"] * 2 + 0.03  # the bridge and strings stand ~3 cm over the top
    m = member("body", "post", [f["length"], h, f["lower"]], [f["length"] * 0.5 - f["body"] * 0.5, h * 0.5, 0], wood="walnut",
               look="pbr:fiddle", draw=mesh("fiddle", "Body"), solid=0.05)
    m["dress"] = [dress("pbr:fiddle", "fiddle", part) for part in ("Neck", "Fittings", "Strings")]
    return {
        "_doc": "A fiddle (#879; refs experiments/prop_lab/refs/saloon/, batch S2): the dance hall's music (Payday Night's fiddler, on his chair on the platform), a plain violin of the period, a body 14 in long with an arched spruce top and its f-holes, maple ribs and back under a worn brown varnish rubbed pale where the chin and hand go, an ebony fingerboard, pegs and tailpiece, a maple bridge and four strings to a carved scroll. Lying on its back (its top up, the scroll at +x, the body's lower bout at the origin's -x). Its bow is its own prop (`fiddle_bow`). Baked the gun way (tools/blender/props/saloon_s2.py). One member (a hollow box of thin wood: `solid` 0.05, wood walnut for its burning): a ball splinters it, a fire takes it. 1 physics body. ~0.5 kg (the kit weighs it ~1.7: StructureMember.weight counts a hollow member's inside as char, #866). Written by tools/props/saloon_s2.py.",
        "id": "fiddle", "kind": "members", "fixture": True, "in_game": False, "wood": "walnut", "drawn_bounds": True,
        "splits_below": 0.2, "blow_wood_share": 0.5,
        "grips": {"neck": r([f["body"] * 0.5 + 0.1, h * 0.6, 0.0]), "chin": r([-f["body"] * 0.42, h, -0.05])},
        "members": [m],
    }


def fiddle_bow():
    b = BOW
    fw, fh, ft = b["frog"]
    m = member("stick", "post", [b["length"], fh + 0.01, 0.024], [b["length"] * 0.5, (fh + 0.01) * 0.5, 0], wood="walnut",
               look="pbr:fiddle", draw=mesh("fiddle", "Bow"), solid=0.1)
    m["dress"] = [dress("pbr:fiddle", "fiddle", "BowHair")]
    return {
        "_doc": "The fiddle's bow (#879; refs experiments/prop_lab/refs/saloon/, batch S2): a pernambuco stick 75 cm long, its ebony frog at the origin (where the hand holds it) and a white ribbon of horse hair to its tip at +x, lying on its side on a table or the fiddler's knee. Baked the gun way with the fiddle (tools/blender/props/saloon_s2.py: model `fiddle`, its parts Bow and BowHair). One member (a thin stick: `solid` 0.1). 1 physics body. ~60 g. Written by tools/props/saloon_s2.py.",
        "id": "fiddle_bow", "kind": "members", "fixture": True, "in_game": False, "wood": "walnut", "drawn_bounds": True,
        "splits_below": 0.2, "blow_wood_share": 0.5,
        "grips": {"frog": r([0.03, fh * 0.5, 0.0])},
        "members": [m],
    }


# --- The beer keg and its rack ------------------------------------------------------------------
# A wooden half-barrel keg of lager (the brewery's: 15 1/2 gallons, ~59 l), smaller and stouter-hooped
# than the whiskey barrel and built as it is (the kit's `barrel`): eight staves bulged as a cask's (the
# barrel's fourteen narrower, but a keg is a fifth its weight in bodies), six iron hoops, a head at each
# end. Full, PropContents (beer runs from a hole and soaks the boards). Its staves' outer radius
# r(y) = r_end + bulge * sin(pi y / H), as the barrel's.
KEG = {"height": 0.62, "r_end": 0.18, "bulge": 0.042, "stave_t": 0.022, "staves": 8, "head_t": 0.025, "croze": 0.035,
       "hoops": [0.04, 0.12, 0.22, 0.40, 0.50, 0.58], "hoop_w": 0.022}


def _keg_r(y):
    k = KEG
    return k["r_end"] + k["bulge"] * math.sin(math.pi * y / k["height"])


def beer_keg():
    k = KEG
    H, n, t = k["height"], k["staves"], k["stave_t"]
    seg = 8
    outer = [(_keg_r(H * i / seg), H * i / seg) for i in range(seg + 1)]
    profile = outer + [(rr - t, y) for rr, y in reversed(outer)] + [outer[0]]
    half = 180.0 / n
    r_avg = k["r_end"] + k["bulge"] * 0.5
    stave = member("stave%d", "post", [2 * r_avg * math.sin(math.pi / n), H, t], [0, H * 0.5, 0],
                   repeat={"count": n, "radius": r(r_avg - t * 0.5), "start": 0},
                   draw={"shape": "sweep", "profile": [r(p) for p in profile], "from": r(90 - half), "to": r(90 + half), "segments": 3,
                         "grain_up": True, "caps": True})
    w = k["hoop_w"] * 0.5
    stave["dress"] = [{"look": "prop:iron", "draw": {"shape": "sweep", "profile": [r([_keg_r(y - w) + 0.002, y - w]), r([_keg_r(y) + 0.006, y]),
                                                                                    r([_keg_r(y + w) + 0.002, y + w])],
                                                   "from": r(90 - half), "to": r(90 + half), "segments": 3}} for y in k["hoops"]]
    ri = k["r_end"] - t + 0.008  # the head's edge set in the croze
    side = ri * 2 * 0.86
    ht = k["head_t"]
    ms = [stave,
          member("head_top", "furniture_top", [side, ht, side], [0, H - k["croze"] + ht * 0.5, 0], look="prop:barrel_head",
                 draw={"shape": "disc", "radius": r(ri), "segments": 24}),
          member("head_bottom", "floor_board", [side, ht, side], [0, k["croze"] - ht * 0.5, 0], look="prop:barrel_head",
                 draw={"shape": "disc", "radius": r(ri), "segments": 24})]
    lo, hi = k["croze"], H - k["croze"]
    return {
        "_doc": "A beer keg (#879; refs experiments/prop_lab/refs/saloon/, batch S2): a wooden half-barrel keg of lager from the brewery, 15 1/2 gallons (~59 l), 62 cm high, stouter-hooped than a whiskey barrel; the kit's `barrel` (its look, wood and breaking, `like`) made smaller: eight oak staves bulged as a cask's, six iron hoops, a head at each end set in the croze. Full of beer (PropContents: a ball or an axe lets it run; ~59 kg of beer in a ~14 kg keg). Saloon B's store room and cellar (~12, on their racks: `keg_rack`), one in the work board's ice box, empties on the yard's pile. 10 physics bodies standing (8 staves, 2 heads): twelve are 120, so the placing session sets most of a rack's as drawn stand-ins and keeps a few real. Written by tools/props/saloon_s2.py.",
        "like": "barrel", "id": "beer_keg", "replaces": "", "in_game": False, "fixture": True,
        "holds": {"_doc": "Its inside (PropContents): from the bottom head's top to the top head's underside, the staves' inner radius at the heads and at the bulge: ~59 l, a half-barrel's.",
                  "from": r(lo), "to": r(hi), "radius": r([k["r_end"] - t, k["r_end"] + k["bulge"] - t])},
        "contents": {"liquid": "beer", "full": True},
        "members": ms,
    }


# A keg rack (the cellar's "stillage"): two tiers of heavy timber, each a pair of long rails that the
# kegs stand across, on six posts; tied low at the ends. Four kegs a tier.
RACK = {"length": 1.9, "depth": 0.5, "post": 0.09, "rail": (0.09, 0.075), "rail_z": 0.13, "tiers": [0.16, 0.88], "tie_y": 0.06}


def keg_rack():
    c = RACK
    L, D, p = c["length"], c["depth"], c["post"]
    rw, rh = c["rail"]
    top = c["tiers"][-1]
    hx, hz = L * 0.5 - p * 0.5, c["rail_z"] + rw * 0.5 + p * 0.5
    ms = []
    for i, x in enumerate((-hx, 0.0, hx)):
        for s_, name in ((-1, "b"), (1, "f")):
            ms.append(member("post%d%s" % (i, name), "post", [p, top, p], [x, top * 0.5, s_ * hz], look=OAK_OLD, blow_span=c["tiers"][0]))
    for j, y in enumerate(c["tiers"]):
        for s_, name in ((-1, "b"), (1, "f")):
            ms.append(member("rail%d%s" % (j, name), "furniture_top", [L, rh, rw], [0, y - rh * 0.5, s_ * c["rail_z"]],
                             look=OAK_OLD))
    return {
        "_doc": "A keg rack (#879; refs experiments/prop_lab/refs/saloon/, batch S2): the cellar's stillage, two tiers of heavy oak (4 in posts, 3 x 4 in rails), each tier a pair of long rails the kegs stand across, four kegs a tier (`beer_keg`, placed on it: the lower tier's rails at 16 cm, the upper's at 88), on six posts. 1.9 m long, 0.5 m deep, 0.88 m high. Old oak from the material library (a cellar's: unpainted, slopped and dark; the library's painted pine read as teal paint). Saloon B's store room and cellar: 2. 10 physics bodies (its members). ~70 kg. Written by tools/props/saloon_s2.py.",
        "id": "keg_rack", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.5, "blow_wood_share": 0.5,
        "members": ms,
    }


# --- The cookstove --------------------------------------------------------------------------------
# A cast-iron kitchen range of the 1870s-80s (the trade catalogues' "cook stove": a Charter Oak, a
# Garland, an Acorn), four cabriole legs under a firebox at the left and its oven to the right, four
# lids over them in a cooking top 29 in up, the firebox's door and its hearth (the ash lip) in front,
# the oven's door with its nickel bands and latch, a nickel towel rail along the front, the pipe
# collar at the back over the firebox and the pipe up to the flue. On a zinc-covered stove board. Its
# fire burns as the box stove's (StoveFire): lit by the hour from before breakfast to after supper.
COOK = {"board": (1.16, 0.022, 0.96), "leg_h": 0.2, "leg": 0.05, "body": (0.86, 0.48, 0.56), "plate": 0.035, "top_over": 0.03,
        "firebox_x": -0.27, "fire_door": (0.24, 0.17, 0.03), "oven_door": (0.44, 0.33, 0.03), "oven_x": 0.17,
        "lids": [(-0.31, -0.06), (-0.31, 0.15), (0.03, -0.06), (0.03, 0.15)], "lid_r": 0.093,
        "pipe_r": 0.076, "pipe": [0.6, 0.6, 0.6], "pipe_at": (-0.14, -0.22),
        "fire": {"radius": 0.4, "seconds": 300.0, "heating": 1.2, "lit_from": 5, "lit_until": 21, "glow": 0.5}}


def cookstove():
    c = COOK
    bw, bh, bd = c["board"]
    ms = [member("board", "sill", [bw, bh, bd], [0, bh * 0.5, 0.06], wood="oak", look="pbr:cookstove", draw=mesh("cookstove", "Board"))]
    bx, by, bz = c["body"]
    lh, lg = c["leg_h"], c["leg"]
    for i, (fx, fz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        ms.append(member("leg%d" % i, "post", [lg, lh, lg], [fx * (bx * 0.5 - 0.05), bh + lh * 0.5, fz * (bz * 0.5 - 0.05)], wood="iron",
                         look="pbr:cookstove", draw=mesh("cookstove", "Leg%d" % i), solid=0.5))
    y0 = bh + lh
    ms.append(member("body", "furniture_frame", [bx, by, bz], [0, y0 + by * 0.5, 0], wood="iron", look="pbr:cookstove", draw=mesh("cookstove", "Body"),
                     solid=0.12))
    ms[-1]["dress"] = [dress("pbr:cookstove", "cookstove", "Nickel")]
    fx, fy, fz = c["fire_door"]
    ms.append(member("fire_door", "trim", [fx, fy, fz], [c["firebox_x"], y0 + by - 0.06 - fy * 0.5, bz * 0.5 + fz * 0.5], wood="iron",
                     look="pbr:cookstove", draw=mesh("cookstove", "FireDoor"), solid=0.35))
    ox, oy, oz = c["oven_door"]
    ms.append(member("oven_door", "trim", [ox, oy, oz], [c["oven_x"], y0 + 0.05 + oy * 0.5, bz * 0.5 + oz * 0.5], wood="iron",
                     look="pbr:cookstove", draw=mesh("cookstove", "OvenDoor"), solid=0.35))
    pt, ov = c["plate"], c["top_over"]
    ms.append(member("top", "furniture_top", [bx + ov * 2, pt, bz + ov * 2], [0, y0 + by + pt * 0.5, 0], wood="iron", look="pbr:cookstove",
                     draw=mesh("cookstove", "Top"), solid=0.35))
    y = y0 + by + pt
    px, pz = c["pipe_at"]
    pr = c["pipe_r"]
    for k, ln in enumerate(c["pipe"]):
        ms.append(member("pipe%d" % k, "trim", [pr * 2, ln, pr * 2], [px, y + ln * 0.5, pz], wood="iron", look="pbr:cookstove",
                         draw=mesh("cookstove", "Pipe%d" % k), solid=0.013))
        y += ln
    f = c["fire"]
    return {
        "_doc": "A cast-iron cookstove (#879; refs experiments/prop_lab/refs/saloon/, batch S2): a kitchen range of the 1870s-80s (the trade catalogues' 'cook stove'), 86 cm wide, four cabriole legs under its firebox (left) and its oven (right), a cooking top 29 in up with four lids and a lifter, the firebox's door over its hearth lip, the oven's door with its nickel bands and latch, a nickel towel rail along the front, the pipe collar at the back over the firebox and three 60 cm lengths of 6 in pipe up to the flue (the placing session takes off what the ceiling doesn't want, or turns it to the wall's thimble). On a zinc-covered stove board. Saloon B's kitchen (1; the free lunch's) and the doctor's office (1, his kitchen). Iron (`wood` iron: it doesn't burn or break; balls glance); the pipe's lengths stand on each other and come down when it goes over. A fire source (`stove`, StoveFire): lit by the hour (%d:00 to %d:00: breakfast to supper), its firebox glows at its door; knocked over, its coals spill and burn on the boards for %d s (FireSystem.small_fire, %.1f times a spill's heat). Baked the gun way (tools/blender/props/saloon_s2.py: cast iron black-leaded, rubbed to the iron at its edges and lids, rust where the kettle boils over; nickel; zinc). ~180 kg of iron. 12 physics bodies (its members) standing. Written by tools/props/saloon_s2.py." % (f["lit_from"], f["lit_until"], int(f["seconds"]), f["heating"]),
        "id": "cookstove", "kind": "members", "fixture": True, "in_game": False, "wood": "iron", "look": "pbr:cookstove",
        "splits_below": 0.3, "blow_wood_share": 0.3,
        "stove": {"member": "body", "door": r([c["firebox_x"], y0 + 0.08, bz * 0.5 + 0.08]), "glow_at": r([c["firebox_x"], y0 + by - 0.14, bz * 0.5 + 0.04]),
                  "radius": f["radius"], "seconds": f["seconds"], "heating": f["heating"], "lit_from": f["lit_from"],
                  "lit_until": f["lit_until"], "glow": f["glow"]},
        "members": ms,
    }


BATCH_S2 = [wall_bench, handsaw, fiddle, fiddle_bow, beer_keg, keg_rack, cookstove]


def main():
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    for make in BATCH_S2:
        if only and make.__name__ not in only:
            continue
        d = make()
        d["factory"] = "tools/props/saloon_s2.py"
        path = os.path.join(KIT, d["id"] + ".json")
        with open(path, "w") as f:
            json.dump(d, f, indent=2)
            f.write("\n")
        print("wrote", os.path.relpath(path, ROOT), "(%d members)" % len(d.get("members", [])))


if __name__ == "__main__":
    main()
