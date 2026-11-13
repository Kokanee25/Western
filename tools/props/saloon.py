"""Saloon B's props, batch S1 (#866; docs/briefs/saloon-design.md "The props B needs", "The new props in
order"): the kit files of the 1882 corner saloon's lamps, glasses, bar work, stove and games, written
from the numbers here, so a change is one number and a re-run. The Blender half
(tools/blender/props/saloon_s1.py) reads the same numbers.

    python3 tools/props/saloon.py [--only=hanging_lamp,faro_table]   # writes assets/props/kit/<id>.json

Woods from the material library (`lib:<entry>/<age>`, #721, #825: `furniture_oak` and
`furniture_painted_pine`, never the bar room's floor), metal and glass the gun way (`pbr:<model>`,
tools/blender/props/metal.py; glass the kit's `glass:` look). Few members: each member is a physics
body while the prop stands (the valley is near Jolt's limit, #865), so the small things on a prop are
its `dress`, not members of their own. Each prop's period reference: experiments/prop_lab/refs/saloon/.
Where each goes in saloon B (room, count) is in experiments/prop_lab/README.md "Saloon B, batch S1",
for the session that places them.
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from doctor import KIT, OAK, OAK_FRONT, OAK_TOP, PINE, PINE_FRONT, PINE_TOP, ROOT, member, mesh, r  # noqa: E402
import doctor  # noqa: E402

OAK_OLD = "lib:furniture_oak/old"
OAK_OLD_TOP = OAK_OLD + "/top"
OAK_OLD_FRONT = OAK_OLD + "/front"


def dress(look, model, part):
    return {"look": look, "draw": mesh(model, part)}


# --- The hanging lamps --------------------------------------------------------------------------
# A kerosene hanging lamp of the 1870s-80s (the saloons', stores' and halls' of the photographs):
# hung from an iron hook in a joist on a brass chain, a brass smoke bell over the chimney to keep the
# soot off the ceiling, three brass arms from the bell down to a ring, the brass font sitting in the
# ring, its burner and a plain glass chimney. The shaded one (over a gaming table) carries a dome
# shade, painted green outside and white inside, on the ring. The hook at the top of the kit's box
# (its "hangs": "hook"); the drop from the joist's underside to the lamp's foot is `drop`.
HANG = {"drop": 1.0, "ring_y": 0.21, "ring_r": 0.088, "font": (0.078, 0.13, 0.25), "flame_y": 0.33,
        "chimney": (0.268, 0.50, 0.032), "bell_y": 0.56, "bell_r": 0.08, "chain_y": 0.62,
        "shade": {"r": 0.25, "y0": 0.30, "y1": 0.47, "top_r": 0.07}}


def _hanging(kit, model, shaded):
    h = HANG
    looks = {"Chimney": "prop:chimney_glass", "Font": "pbr:" + model, "Burner": "pbr:" + model, "Frame": "pbr:" + model,
             "Bell": "pbr:" + model, "Chain": "pbr:" + model, "Hook": "pbr:" + model}
    whole = ["Font", "Burner", "Frame", "Bell", "Chain"]
    width = 0.2
    if shaded:
        looks["Shade"] = "pbr:" + model
        looks["ShadeInner"] = "pbr:" + model
        whole += ["Shade", "ShadeInner"]
        width = h["shade"]["r"] * 2
    what = ("a dome shade 50 cm across over it, painted green outside and white within (the gaming room's: over a table, its "
            "light thrown down on the cloth)" if shaded else "no shade (the bar room's: two rows of three under the dance floor's joists)")
    return {
        "_doc": "A kerosene hanging lamp (#866; refs experiments/prop_lab/refs/saloon/): an iron hook in the joist, a brass chain, a brass smoke bell over the chimney (the soot kept off the ceiling), three brass arms down to a ring, the brass font sitting in the ring with its burner and a plain glass chimney; %s. A prop that shatters (GlassProp) hung by a hook (`hangs.hook`: what's above the hook is what it hangs from, a joist or a beam): it swings when what it hangs from moves (the dance floor over it), a blast or a hand pushes it (`GlassProp.push_swing`), and falls with its joist (broken, burnt away or dropped): the chimney breaks at a walk's pace, the brass comes through whole, and a lit one's oil burns where it lands (OilLamp.smash). Its body is the lamp's box (`hit`), not the chain's: a ball through the chain passes. Its light (an OilLamp, `light_height` over its foot) swings with it. 1.0 m from the joist's underside to its foot. One physics body at rest (the frozen lamp; its swing is drawn, not simulated); broken, the chimney's shards (up to 10, GlassProp's) and the brass as one piece. Baked the gun way (tools/blender/props/saloon_s1.py). Written by tools/props/saloon.py." % what,
        "id": kit, "kind": "shatters", "fixture": True, "in_game": False, "replaces": "",
        "model": "glb:" + model, "looks": looks,
        "size": r([width, h["drop"], width]), "mass": 4.2 if shaded else 3.0, "wall": 0.0015,
        "hangs": {"hook": r([0.0, h["drop"], 0.0])},
        "hit": {"at": r([0.0, 0.29, 0.0]), "size": r([width if shaded else 0.18, 0.46, width if shaded else 0.18])},
        "swing": {"pivot": r([0.0, h["drop"], 0.0]), "length": 0.72, "damping": 0.35},
        "light_height": h["flame_y"],
        "glass": ["Chimney"], "whole": [whole],
        "piece_mass": 2.4 if shaded else 2.0, "shards": 10, "breaks_at": 1.5, "shatters_kpa": 15, "heat_seconds": 30, "cut_area": 0.04,
        "contents": {"liquid": "lamp_oil", "litres": 0.6, "flammable": True, "colour": [0.85, 0.75, 0.45]},
    }


def hanging_lamp():
    return _hanging("hanging_lamp", "hanging_lamp", False)


def hanging_lamp_shaded():
    return _hanging("hanging_lamp_shaded", "hanging_lamp_shaded", True)


# --- Glasses -------------------------------------------------------------------------------------
# Pressed and blown bar glass of the 1870s-80s: a heavy-bottomed whiskey glass (a "shot"), a beer
# schooner (tall, flared, a thick pressed foot), a back-bar decanter with a ball stopper. Profiles
# [(r, y)] of the glass's section, outside up then inside down (a lathe: thick glass all round); a
# liquid's level and its finish. Sizes from the period's bar-glass catalogues (a whiskey glass of
# 2 oz, a schooner of 12 oz, a quart decanter).
GLASSES = {
    "shot_glass": {"profile": [(0.0, 0.0), (0.022, 0.0), (0.0235, 0.004), (0.0245, 0.012), (0.027, 0.062), (0.0248, 0.062),
                               (0.0216, 0.016), (0.0, 0.0145)],
                   "inner": [(0.0216, 0.016), (0.0248, 0.062)], "floor": 0.0145, "level": 0.038, "liquid": "whiskey",
                   "litres": 0.03, "mass": 0.18, "breaks": (4.0, 50), "wall": 0.004, "what": "a heavy-bottomed whiskey glass of 2 oz, a shot of whiskey in it"},
    "schooner": {"profile": [(0.0, 0.0), (0.036, 0.0), (0.037, 0.004), (0.03, 0.008), (0.009, 0.014), (0.007, 0.03), (0.011, 0.045),
                             (0.027, 0.058), (0.040, 0.17), (0.0375, 0.17), (0.0245, 0.062), (0.0, 0.056)],
                 "inner": [(0.0245, 0.062), (0.0375, 0.17)], "floor": 0.056, "level": 0.145, "foam": 0.16, "liquid": "beer",
                 "litres": 0.33, "mass": 0.55, "breaks": (3.5, 40), "wall": 0.003, "what": "a beer schooner of 10 oz, a tall flared bowl on a short stem and a round foot (the Wainwright advertising glass's shape), a head on its beer"},
    "decanter": {"profile": [(0.0, 0.0), (0.04, 0.0), (0.044, 0.006), (0.04, 0.016), (0.05, 0.04), (0.06, 0.09), (0.062, 0.12),
                             (0.055, 0.15), (0.034, 0.18), (0.02, 0.2), (0.0175, 0.215), (0.022, 0.222), (0.0175, 0.229), (0.0165, 0.25),
                             (0.022, 0.256), (0.0, 0.258)],
                 "inner": None, "level": 0.1, "liquid": "whiskey", "stopper": (0.03, 0.25, 0.305),
                 "litres": 0.6, "mass": 0.95, "breaks": (3.5, 45), "wall": 0.004, "what": "a back-bar decanter of a quart, pressed in flutes, shouldered, a ring round its neck, a mushroom stopper, half full of whiskey"},
}


def _glass(kit):
    g = GLASSES[kit]
    top = max(y for _, y in g["profile"]) if kit != "decanter" else g["stopper"][2]
    rad = max(rr for rr, _ in g["profile"])
    looks = {"Glass": "glass:clear", "Liquid": "pbr:bar_glasses_" + kit}
    glass_parts = ["Glass", "Liquid"]
    whole = []
    if g.get("foam"):
        looks["Foam"] = "pbr:bar_glasses_" + kit
        glass_parts.append("Foam")
    if g.get("stopper"):
        looks["Stopper"] = "glass:clear"
        whole = [["Stopper"]]
    bl, kpa = g["breaks"]
    return {
        "_doc": "Bar glass (#866; refs experiments/prop_lab/refs/saloon/): %s. A prop that shatters (GlassProp), as the whiskey bottle: a ball, a fall faster than %.1f m/s (a heavy glass off the bar onto the boards: some do, some don't) or %d kPa breaks it, and what's in it goes on the floor (`Events.liquid_spilled`). The glass the kit's `glass:clear` (see-through, no shadow of its own); what's in it baked the gun way (tools/blender/props/saloon_s1.py). One physics body standing (the frozen glass; a shelf of forty is forty bodies: set a row on the back bar sparingly), its shards when it breaks. Written by tools/props/saloon.py." % (g["what"], bl, kpa),
        "id": kit, "kind": "shatters", "fixture": True, "in_game": False, "replaces": "",
        "model": "glb:bar_glasses_" + kit, "looks": looks,
        "size": r([rad * 2, top, rad * 2]), "mass": round(g["mass"] + g["litres"] * 1.0, 3), "wall": g["wall"],
        "glass": glass_parts, "whole": whole, "shards": 8 if kit == "shot_glass" else 12, "piece_mass": 0.02,
        "breaks_at": bl, "shatters_kpa": kpa, "heat_seconds": 25, "cut_area": 0.03,
        "contents": {"liquid": g["liquid"], "litres": g["litres"],
                     "colour": [0.55, 0.32, 0.1] if g["liquid"] == "whiskey" else [0.72, 0.5, 0.16]},
    }


def shot_glass():
    return _glass("shot_glass")


def schooner():
    return _glass("schooner")


def decanter():
    return _glass("decanter")


# --- The bartender's work board -----------------------------------------------------------------
# Built in behind the bar, under its top (the period's bar-fixture catalogues: "work board" or "bar
# workboard"): a painted pine counter at the bartender's working height, its top sheathed in zinc, two
# zinc sinks let into it (wash and rinse), a ribbed zinc drip board at its left end with the clean
# glasses upturned on it, a brass beer stand of two taps whose pipes go down into the ice box at its
# right end (a keg on ice in it), and a shelf under it stocked (Sean, #821: storage ships filled):
# a case of bottles, a stack of bar towels, a bucket. Its back (-z) against the bar's back boards, the
# bartender on +z. A 2.4 m section; the bar's run takes as many as it needs.
WORK = {"length": 2.4, "depth": 0.56, "top": 0.86, "board": 0.028, "leg": 0.06, "apron_h": 0.12, "apron_t": 0.022,
        "shelf_y": 0.16, "stretcher": (0.05, 0.035), "ice_x": (0.42, 1.2), "zinc": 0.003,
        "sinks": [(-0.48, 0.44), (0.0, 0.44)], "sink": (0.21, 0.36), "drip": (-1.18, -0.72), "taps_x": 0.27}


def work_board():
    w = WORK
    L, D, H = w["length"], w["depth"], w["top"]
    b, lg = w["board"], w["leg"]
    under = H - b
    hx, hz = L * 0.5 - lg * 0.5, D * 0.5 - lg * 0.5
    ms = []
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1)]):
        ms.append(member("leg%d" % i, "post", [lg, under, lg], [sx * hx, under * 0.5, sz * hz], look=OAK_OLD))
    # The ice box at the right end: its front, its partition and its back stand on the floor (its
    # corner post the front's end), its lid over them at the top's height.
    x0, x1 = w["ice_x"]
    t = w["apron_t"]
    ms.append(member("ice_front", "post", [x1 - x0, under, 0.03], [(x0 + x1) * 0.5, under * 0.5, D * 0.5 - 0.015], look=OAK_OLD_FRONT))
    ms.append(member("ice_part", "post", [0.03, under, D - 0.03], [x0 + 0.015, under * 0.5, -0.015], look=OAK_OLD))
    ms.append(member("ice_back", "post", [x1 - x0 - 0.03, under, 0.03], [(x0 + x1) * 0.5 + 0.015, under * 0.5, -D * 0.5 + 0.015], look=OAK_OLD))
    ms.append(member("ice_end", "post", [0.03, under, D - 0.06], [x1 - 0.015, under * 0.5, 0.0], look=OAK_OLD))
    ice_lid = member("ice_lid", "furniture_top", [x1 - x0, b, D], [(x0 + x1) * 0.5, H - b * 0.5, 0], look=OAK_OLD_TOP)
    ice_lid["dress"] = [dress("pbr:work_board", "work_board", "IceLid")]
    ms.append(ice_lid)
    # The counter's frame: aprons front and back under the top, from the left legs to the ice box.
    ay = under - w["apron_h"] * 0.5
    span = x0 - (-hx + lg * 0.5)
    cx = (-hx + lg * 0.5 + x0) * 0.5
    ms.append(member("apron_f", "furniture_frame", [span, w["apron_h"], t], [cx, ay, D * 0.5 - t * 0.5], look=OAK_OLD))
    ms.append(member("apron_b", "furniture_frame", [span, w["apron_h"], t], [cx, ay, -D * 0.5 + t * 0.5], look=OAK_OLD))
    sw, sh = w["stretcher"]
    for s, name in ((-1, "b"), (1, "f")):
        ms.append(member("stretcher_" + name, "furniture_frame", [span, sw, sh], [cx, w["shelf_y"] - sw * 0.5, s * (D * 0.5 - sh * 0.5)], look=OAK_OLD))
    # The top: two boards front and back from the left end to the ice box, sheathed in zinc (its sinks
    # and drip board on it), and the shelf low down, stocked.
    tl = x0 - (-L * 0.5)
    tx = (-L * 0.5 + x0) * 0.5
    front = member("top_f", "furniture_top", [tl, b, D * 0.5], [tx, H - b * 0.5, D * 0.25], look=OAK_OLD_TOP)
    front["dress"] = [dress("pbr:work_board", "work_board", "Zinc"), dress("pbr:work_board", "work_board", "Sinks"),
                      dress("pbr:work_board", "work_board", "Drip"), dress("glass:clear", "work_board", "DripGlasses")]
    ms.append(front)
    ms.append(member("top_b", "furniture_top", [tl, b, D * 0.5], [tx, H - b * 0.5, -D * 0.25], look=OAK_OLD_TOP))
    shelf = member("shelf", "furniture_top", [span, 0.022, D - 0.01], [cx, w["shelf_y"] + 0.011, 0], look=OAK_OLD)
    shelf["dress"] = [dress("pbr:work_board", "work_board", "Stock"), dress("pbr:work_board", "work_board", "StockTowels"),
                      dress("pbr:work_board", "work_board", "StockBucket"), dress("glass:green", "work_board", "StockGlass")]
    ms.append(shelf)
    taps = member("taps", "trim", [0.2, 0.42, 0.12], [w["taps_x"], H + 0.21 + w["zinc"], -0.12], wood="iron", look="pbr:work_board",
                  draw=mesh("work_board", "Taps"), solid=0.06)
    taps["dress"] = [dress("pbr:work_board", "work_board", "TapHandles")]
    ms.append(taps)
    return {
        "_doc": "The bartender's work board (#866; refs experiments/prop_lab/refs/saloon/: the period's bar-fixture catalogues): built in behind the bar under its top, an oak counter 2.4 m long (oak as the bar it's built into, old: worked hard) at his working height (0.86 m), its top sheathed in zinc with two zinc sinks let into it (wash and rinse) and a ribbed zinc drip board at its left end, the clean glasses upturned on it; two beer pumps (brass, tall turned handles) whose pipes run down into the ice box at its right end (a keg on ice in it, under a zinc-lined lid); the shelf under it stocked (Sean, #821: storage ships filled): a case of bottles, bar towels, a bucket. Its back (-z) against the bar's back boards; the bartender on +z. Oak from the material library (old; never the floor's fir: round 1's critic read the painted pine as a navy kitchen counter); the zinc, brass and the stock baked the gun way (tools/blender/props/saloon_s1.py). The sinks, drip board, glasses and stock are the top's and the shelf's dress (drawn on them, gone with them), so it stands as 17 physics bodies (its members) and breaks into its members; the beer stand is iron (`wood` iron: it doesn't burn). ~70 kg. Written by tools/props/saloon.py.",
        "id": "work_board", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.4, "blow_wood_share": 0.5,
        "members": ms,
    }


# --- The box stove ------------------------------------------------------------------------------
# A long cast-iron box stove (the wood-burning box stoves of the 1860s-80s that heated saloons, stores
# and depots: a long firebox on four short cast legs, a hinged door at its end with a draught, a
# collar on its top at the back for the pipe), standing on a box of sand (the floor kept from its
# heat and its coals), its pipe straight up to the flue (the placing session trims its top section
# to the ceiling's thimble or a wall's). Its firebox burns: lit (by the hour, as the lamps), it glows
# at its draught; knocked over or dropped, its coals spill and burn on the boards
# (FireSystem.small_fire), the room's fire source.
STOVE = {"sand": (1.2, 0.09, 0.9), "rim": 0.035, "leg_h": 0.2, "leg": 0.05, "body": (0.84, 0.42, 0.46), "plate": 0.03,
         "door": (0.03, 0.30, 0.34), "pipe_r": 0.076, "pipe": [0.62, 0.62, 0.62, 0.62], "pipe_x": -0.27,
         "fire": {"radius": 0.45, "seconds": 300.0, "heating": 1.4, "lit_from": 17, "lit_until": 7, "glow": 0.7}}


def box_stove():
    s = STOVE
    sx, sy, sz = s["sand"]
    rim = s["rim"]
    ms = []
    # The sand box: four boards round a bed of sand, on the floor.
    for k, (size, at) in enumerate([([sx, sy + 0.02, rim], [0, (sy + 0.02) * 0.5, sz * 0.5 - rim * 0.5]),
                                    ([sx, sy + 0.02, rim], [0, (sy + 0.02) * 0.5, -sz * 0.5 + rim * 0.5]),
                                    ([rim, sy + 0.02, sz - rim * 2], [sx * 0.5 - rim * 0.5, (sy + 0.02) * 0.5, 0]),
                                    ([rim, sy + 0.02, sz - rim * 2], [-sx * 0.5 + rim * 0.5, (sy + 0.02) * 0.5, 0])]):
        ms.append(member("sand_box%d" % k, "sill", size, at, wood="oak", look=OAK_OLD))
    # (Sand is ~1,600 kg/m3 to the game's stone's 2,300.)
    ms.append(member("sand", "sill", [sx - rim * 2, sy, sz - rim * 2], [0, sy * 0.5, 0], wood="stone", look="pbr:box_stove",
                     draw=mesh("box_stove", "Sand"), solid=0.7))
    bx, by, bz = s["body"]
    lh, lg = s["leg_h"], s["leg"]
    for i, (fx, fz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        ms.append(member("leg%d" % i, "post", [lg, lh, lg], [fx * (bx * 0.5 - 0.06), sy + lh * 0.5, fz * (bz * 0.5 - 0.05)], wood="iron",
                         look="pbr:box_stove", draw=mesh("box_stove", "Leg%d" % i), solid=0.5))
    y0 = sy + lh
    # Hollow castings (`solid`, the share of each box that's iron): the firebox's walls ~12 mm, the
    # door's and top's ~10, the pipe's sheet 0.6 mm.
    body = member("body", "furniture_frame", [bx, by, bz], [0, y0 + by * 0.5, 0], wood="iron", look="pbr:box_stove", draw=mesh("box_stove", "Body"),
                  solid=0.12)
    ms.append(body)
    door = member("door", "trim", list(s["door"]), [bx * 0.5 + s["door"][0] * 0.5, y0 + by * 0.5, 0], wood="iron", look="pbr:box_stove",
                  draw=mesh("box_stove", "Door"), solid=0.35)
    ms.append(door)
    pt = s["plate"]
    top = member("top", "furniture_top", [bx + 0.04, pt, bz + 0.04], [0, y0 + by + pt * 0.5, 0], wood="iron", look="pbr:box_stove",
                 draw=mesh("box_stove", "Top"), solid=0.35)
    ms.append(top)
    y = y0 + by + pt
    pr = s["pipe_r"]
    for k, ln in enumerate(s["pipe"]):
        ms.append(member("pipe%d" % k, "trim", [pr * 2, ln, pr * 2], [s["pipe_x"], y + ln * 0.5, 0], wood="iron", look="pbr:box_stove",
                         draw=mesh("box_stove", "Pipe%d" % k), solid=0.013))
        y += ln
    f = s["fire"]
    return {
        "_doc": "A cast-iron box stove (#866; refs experiments/prop_lab/refs/saloon/): the long wood-burning box stove of the 1860s-80s that heated saloons, stores and depots, a firebox 84 cm long on four short cast legs, a door at its +x end with a sliding draught, a collar on its top at the back for the pipe; on a box of sand (old oak boards round it) that keeps the floor from its heat and its coals; its pipe (four 62 cm lengths of 6 in pipe) straight up to the flue: the placing session takes off the lengths the ceiling doesn't want. Iron (`wood` iron: it doesn't burn or break; balls glance); the pipe's lengths stand on each other and come down when the stove goes over. A fire source (`stove`, StoveFire): lit by the hour (as the lamps, %d:00 to %d:00) it glows at its draught; knocked over, or its sand box burnt out from under it, its coals spill round its door and burn on the boards for %d s (FireSystem.small_fire, %.1f times a spill's heat). Baked the gun way (tools/blender/props/saloon_s1.py: cast iron black-leaded, rubbed to the iron at its edges, rust where the wet mop has been). ~170 kg of iron and ~135 kg of sand. 14 physics bodies (its members) standing. Written by tools/props/saloon.py." % (f["lit_from"], f["lit_until"], int(f["seconds"]), f["heating"]),
        "id": "box_stove", "kind": "members", "fixture": True, "in_game": False, "wood": "iron", "look": "pbr:box_stove",
        "splits_below": 0.3, "blow_wood_share": 0.3,
        "stove": {"member": "body", "door": r([bx * 0.5 + 0.05, y0 + 0.08, 0.0]), "glow_at": r([bx * 0.5 + 0.04, y0 + by * 0.35, 0.0]),
                  "radius": f["radius"], "seconds": f["seconds"], "heating": f["heating"], "lit_from": f["lit_from"],
                  "lit_until": f["lit_until"], "glow": f["glow"]},
        "members": ms,
    }


# --- The faro table and its lookout's stool -----------------------------------------------------
# The period's main game (Bob's "faro bank"): an oak table 54 x 36 in at a table's height, the dealer's
# side cut back so he sits into it (-z), its top covered in green baize with the layout enamelled on it
# (a suit of spades, ace to six along the near row, eight to king along the far, the seven at the
# end, the "high card" bar along the player's edge), the dealing box (a German-silver box, open-topped,
# the cards dealt through its slot) at the dealer's place and the case-keeper (an abacus of thirteen
# spindles with its beads, kept by the "case-keeper") beside it, and the players' chips. The lookout
# sits on a high stool at the dealer's elbow, to watch the bets.
FARO = {"length": 1.37, "width": 0.91, "top": 0.76, "board": 0.028, "boards": 3, "leg": 0.07, "inset": 0.07,
        "apron_h": 0.11, "apron_t": 0.024, "cut": (0.56, 0.12)}


def faro_table():
    f = FARO
    L, W, H = f["length"], f["width"], f["top"]
    b = f["board"]
    under = H - b
    lx, lz = L * 0.5 - f["inset"], W * 0.5 - f["inset"]
    hl = f["leg"] * 0.5
    ms = []
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        ms.append(member("leg%d" % i, "post", [f["leg"], under, f["leg"]], [sx * lx, under * 0.5, sz * lz], look=OAK, blow_span=under * 0.7))
    t = f["apron_t"]
    ay = under - f["apron_h"] * 0.5
    cw, cd = f["cut"]
    for s, name in ((-1, "b"), (1, "f")):
        ms.append(member("apron_" + ("l" if s < 0 else "r"), "furniture_frame", [t, f["apron_h"], lz * 2 - f["leg"]],
                         [s * (lx + hl - t * 0.5), ay, 0], look=OAK))
    ms.append(member("apron_f", "furniture_frame", [lx * 2 - f["leg"], f["apron_h"], t], [0, ay, lz + hl - t * 0.5], look=OAK))
    # The dealer's side: its apron follows the cut (either side of it, and across its back).
    zb = -(lz + hl - t * 0.5)
    seg = lx - hl - cw * 0.5
    for s, name in ((-1, "bl"), (1, "br")):
        ms.append(member("apron_" + name, "furniture_frame", [seg, f["apron_h"], t], [s * (cw * 0.5 + seg * 0.5), ay, zb], look=OAK))
    # (its sides on the segments' ends, its back on its sides: each a tier up, so each rests on the one before)
    zc = -W * 0.5 + cd + t * 0.5
    for s, name in ((-1, "l"), (1, "r")):
        ms.append(member("apron_cut_" + name, "cripple", [t, f["apron_h"], zc - zb + t], [s * (cw * 0.5 + t * 0.5), ay, (zb + zc) * 0.5], look=OAK))
    ms.append(member("apron_cut", "board", [cw, f["apron_h"], t], [0, ay, zc], look=OAK))
    # The top: three boards along it; the dealer's (-z) cut back in its middle for him to sit into.
    bw = W / f["boards"]
    for k in range(2):
        z = -W * 0.5 + bw * (k + 0.5)
        if k == 1:
            # The rest of the top one wide member under the cloth (only its edge shows, under the
            # rim): fewer bodies.
            m = member("top1", "furniture_top", [L, b, W - bw], [0, H - b * 0.5, -W * 0.5 + bw + (W - bw) * 0.5], look=OAK_TOP)
        if k == 0:
            # The dealer's board in two, the cut between them (and a short one behind the cut).
            side = (L - cw) * 0.5
            for s, name in ((-1, "l"), (1, "r")):
                ms.append(member("top0" + name, "furniture_top", [side, b, bw], [s * (cw * 0.5 + side * 0.5), H - b * 0.5, z], look=OAK_TOP))
            ms.append(member("top0m", "furniture_top", [cw, b, bw - cd], [0, H - b * 0.5, z + cd * 0.5], look=OAK_TOP))
            continue
        if k == 1:
            # The cloth over all three, its layout, and the game on it, drawn on the middle board.
            m["dress"] = [dress("pbr:faro_layout", "faro_table", "Cloth"), dress("pbr:faro_table", "faro_table", "Rim"),
                          dress("pbr:faro_table", "faro_table", "DealingBox"), dress("pbr:faro_table", "faro_table", "CaseKeeper"),
                          dress("pbr:faro_table", "faro_table", "CaseBeads"), dress("pbr:faro_table", "faro_table", "ChipsW"),
                          dress("pbr:faro_table", "faro_table", "ChipsR")]
        ms.append(m)
    return {
        "_doc": "A faro table (#866; refs experiments/prop_lab/refs/saloon/; the period's main game): oak, 54 x 36 in at 30 in, the dealer's side (-z) cut back 12 in for him to sit into, the top covered in green baize with the layout enamelled on it (a suit of spades: ace to six along the near row, eight to king along the far, the seven at the end; the high-card bar along the players' edge), a rounded oak rim, the German-silver dealing box at the dealer's place, the case-keeper (thirteen spindles of beads) beside it, a few stacks of chips on the cards. Oak from the material library (a few years; the top worn); the legs square (a country maker's); the cloth printed and the box, case-keeper and chips baked the gun way (tools/blender/props/saloon_s1.py). The cloth, rim and the game are the middle board's dress (gone with it), so it stands as 16 physics bodies (its members). ~45 kg. The bar room has one, the gaming room another. Written by tools/props/saloon.py.",
        "id": "faro_table", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.3, "blow_wood_share": 0.5,
        "members": ms,
    }


# The lookout's stool: a high stool (a seat at 34 in, so he sees over the players' shoulders),
# four splayed legs, a ring of rungs for his feet, a square seat.
LOOKOUT = {"seat_y": 0.86, "seat": 0.36, "seat_t": 0.035, "leg": 0.042, "splay": 5.5, "foot": 0.21, "rung_y": 0.32, "rung": 0.03}


def lean(a, slope):
    """A leg's rot (degrees, the kit's YXZ) leaning its top in toward the middle from a foot out along
    angle `a` (radians in x/z), `slope` its run over its rise."""
    tx = math.atan(-math.sin(a) * slope)
    tz = math.atan(math.cos(a) * slope * math.cos(tx))
    return r([math.degrees(tx), 0.0, math.degrees(tz)])


def lookout_stool():
    c = LOOKOUT
    sy, st, lg = c["seat_y"], c["seat_t"], c["leg"]
    h = sy - st
    slope = math.tan(math.radians(c["splay"]))
    ln = h / math.cos(math.radians(c["splay"]))
    mid = c["foot"] - slope * h * 0.5  # the leg's middle's distance out (along its diagonal)
    ms = [member("leg%d", "post", [lg, ln, lg], [0, h * 0.5, 0], look=OAK, rot=r([-c["splay"], 0, 0]),
                 repeat={"count": 4, "radius": r(mid), "start": 45}, blow_span=c["rung_y"])]
    # Rungs at two heights, front and back lower (his feet), the sides higher: each from leg to leg
    # (a leg's diagonal distance out at that height over root 2).
    def half(y):
        return (c["foot"] - slope * y) / math.sqrt(2.0)
    y = c["rung_y"]
    for s, name in ((-1, "b"), (1, "f")):
        ms.append(member("rung_" + name, "furniture_frame", [half(y) * 2, c["rung"], c["rung"]], [0, y, s * half(y)], look=OAK))
    y2 = y + 0.12
    for s, name in ((-1, "l"), (1, "r")):
        ms.append(member("rung_" + name, "furniture_frame", [c["rung"], c["rung"], half(y2) * 2], [s * half(y2), y2, 0], look=OAK))
    ms.append(member("seat", "furniture_top", [c["seat"], st, c["seat"]], [0, sy - st * 0.5, 0], look=OAK_TOP))
    return {
        "_doc": "The faro lookout's high stool (#866; refs experiments/prop_lab/refs/saloon/): the man who watches the bets for the house sits at the dealer's elbow, higher than the players: a square oak seat at 34 in on four splayed legs, two rungs low front and back for his feet and two higher at the sides. Oak from the material library (a few years; the seat worn). 9 physics bodies (its members). ~7 kg. Written by tools/props/saloon.py.",
        "id": "lookout_stool", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.5, "blow_wood_share": 0.5,
        "seat": {"member": "seat", "at": [0.0, sy, 0.0], "share": 0.85, "hold": 0.05, "sway": 0.04},
        "members": ms,
    }


# --- The piano stool ----------------------------------------------------------------------------
# A revolving piano stool of the 1870s-80s: a round seat covered in plush on a screw, a turned and
# ebonised column, four splayed legs ending in brass claws holding glass balls.
PIANO_STOOL = {"seat_y": 0.52, "seat_r": 0.17, "seat_t": 0.06, "column": (0.07, 0.2), "legs_top": 0.26, "foot": 0.24, "leg": 0.04}


def piano_stool():
    c = PIANO_STOOL
    ms = []
    lt, ft, lg = c["legs_top"], c["foot"], c["leg"]
    for i in range(4):
        a = math.radians(45 + 90 * i)
        run = ft - 0.035  # from the column's foot out to its claw
        ln = math.hypot(lt, run)
        mid = 0.035 + run * 0.5
        ms.append(member("leg%d" % i, "post", [lg, ln, lg], [math.cos(a) * mid, lt * 0.5, math.sin(a) * mid], wood="walnut",
                         look="pbr:piano_stool", rot=lean(a, run / lt), draw=mesh("piano_stool", "Leg%d" % i), blow_span=lt))
        if i == 0:
            # The four brass claws and their glass balls, drawn on the first leg.
            ms[-1]["dress"] = [dress("pbr:piano_stool", "piano_stool", "Claws"), dress("glass:clear", "piano_stool", "Balls")]
    cw, ch = c["column"]
    ms.append(member("column", "furniture_frame", [cw, ch + 0.03, cw], [0, lt - 0.02 + (ch + 0.03) * 0.5, 0], wood="walnut", look="pbr:piano_stool",
                     draw=mesh("piano_stool", "Column")))
    st = c["seat_t"]
    ms.append(member("seat", "furniture_top", [c["seat_r"] * 2, st, c["seat_r"] * 2], [0, c["seat_y"] - st * 0.5, 0], wood="walnut",
                     look="pbr:piano_stool", draw=mesh("piano_stool", "Seat")))
    ms[-1]["dress"] = [dress("pbr:piano_stool", "piano_stool", "SeatRim")]
    return {
        "_doc": "The piano's stool (#866; refs experiments/prop_lab/refs/saloon/): a revolving piano stool of the 1870s-80s, a round seat covered in worn red plush on its screw, a turned ebonised column, four splayed legs ending in brass claws holding glass balls; the seat at 52 cm (it turns up or down: not yet). Turned work stays on its own look (the recipe: a library board is a box): ebonised walnut, plush and brass baked the gun way (tools/blender/props/saloon_s1.py). Wood `walnut` for its weight and burning. 6 physics bodies (its members). ~6 kg. Before the bar room's upright piano. Written by tools/props/saloon.py.",
        "id": "piano_stool", "kind": "members", "fixture": True, "in_game": False, "wood": "walnut",
        "splits_below": 0.5, "blow_wood_share": 0.5,
        "seat": {"member": "seat", "at": [0.0, c["seat_y"], 0.0], "share": 0.85, "hold": 0.05, "sway": 0.03},
        "members": ms,
    }


# --- The wheel of fortune -----------------------------------------------------------------------
# A gambling wheel on the gaming room's wall (the period's "wheel of fortune" or "big six"): a wheel
# 36 in across of painted segments, numbered, a peg between each at its rim, turning on an iron axle
# in an old oak backboard; a leather clapper on a block over it stops on a number.
WHEEL = {"board": (1.04, 1.14, 0.03), "radius": 0.46, "thick": 0.045, "segments": 24, "axle_y": -0.04, "clapper_y": 0.47}


def wheel_of_fortune():
    w = WHEEL
    bx, by, bt = w["board"]
    ms = [member("board", "board", [bx, by, bt], [0, 0, bt * 0.5], look=OAK_OLD)]
    R, th = w["radius"], w["thick"]
    ms.append(member("wheel", "trim", [R * 2, R * 2, th], [0, w["axle_y"], bt + 0.02 + th * 0.5], wood="weathered_pine", look="pbr:wheel_face",
                     draw=mesh("wheel_of_fortune", "Face")))
    ms[-1]["dress"] = [dress("pbr:wheel_of_fortune", "wheel_of_fortune", "Rim"), dress("pbr:wheel_of_fortune", "wheel_of_fortune", "Hub")]
    ms.append(member("clapper", "trim", [0.08, 0.1, 0.07], [0, w["clapper_y"], bt + 0.035], wood="oak", look="pbr:wheel_of_fortune",
                     draw=mesh("wheel_of_fortune", "Clapper")))
    return {
        "_doc": "A wheel of fortune (#866; refs experiments/prop_lab/refs/saloon/): the gaming room's wall wheel (the period's 'big six'), 36 in across, 24 painted segments numbered in red, black and cream, a brass peg between each at its rim, on an iron axle in an old oak backboard; a leather clapper on a block over it that stops on a number. Hung (KitProp `hangs`: two nails through its board into the wall: it falls when its wall board goes); the wheel and the clapper are members on the board (a ball through the face splinters it; the face burns). The board from the material library (oak, old); the face printed and its rim, pegs, hub and clapper baked the gun way (tools/blender/props/saloon_s1.py). It doesn't turn yet. The wall's face at z = 0, the wheel toward +z, the board's middle the origin (hang it at ~1.9 m). 3 physics bodies. ~18 kg. Written by tools/props/saloon.py.",
        "id": "wheel_of_fortune", "kind": "members", "fixture": True, "in_game": False, "wood": "oak", "anchor": "wall",
        "drawn_bounds": True, "splits_below": 0.4, "blow_wood_share": 0.5,
        "hangs": {"nails": [r([-bx * 0.5 + 0.08, by * 0.5 - 0.08, 0.004]), r([bx * 0.5 - 0.08, by * 0.5 - 0.08, 0.004])]},
        "members": ms,
    }


# --- Small things on the bars and the tables ----------------------------------------------------
# The gold scales (no cash register in 1882 Colorado: dust and coin were weighed): the doctor's brass
# balance (#805, its glb:scales) out of its case on an oak base with a drawer for the weights.
def gold_scales():
    c = doctor.SCALES
    bx, by, bz = c["base"]
    nb = (0.30, by, 0.17)
    ms = [member("base", "post", [nb[0], by, nb[2]], [0, by * 0.5, -0.02], look=OAK_TOP)]
    d = member("drawer", "trim", [0.2, c["drawer"][1], 0.012], [0, by * 0.5, nb[2] * 0.5 - 0.02 + 0.006], look=OAK_FRONT)
    d["dress"] = [{"look": "pbr:scales", "draw": dict(mesh("scales", "Knob"), at=r([0, 0, nb[2] * 0.5 - 0.02 - bz * 0.5]))}]
    ms.append(d)
    pw, ph2 = c["pillar"]
    ms.append(member("pillar", "stud", [pw, ph2, pw], [0, by + ph2 * 0.5, -0.02], wood="iron", look="pbr:scales", draw=mesh("scales", "Pillar")))
    lx, ly, lz = c["beam"]
    ms.append(member("beam", "cripple", [lx, ly, lz], [0, c["beam_y"], -0.02], wood="iron", look="pbr:scales", draw=mesh("scales", "Beam")))
    p = c["pan"]
    hang = c["beam_y"] - p["y"]
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("pan_" + name, "trim", [p["wire"], hang, p["wire"]], [s_ * lx * 0.5, p["y"] + hang * 0.5, -0.02], wood="iron",
                         look="pbr:scales", draw=mesh("scales", "Pan" + name.upper())))
    return {
        "_doc": "The bar's gold scales (#866; refs experiments/prop_lab/refs/saloon/; no cash register in 1882 Colorado: dust and coin were weighed): a brass balance, a turned pillar, a beam on its knife edge with its pointer, two pans on stirrups, on an oak base with a drawer for the weights (its brass knob). The doctor's balance (#805, glb:scales) out of its glass case: the same parts on a smaller base. Stands on the back bar by the till. 6 physics bodies. ~5 kg. Written by tools/props/saloon.py.",
        "id": "gold_scales", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.4, "blow_wood_share": 0.5,
        "members": ms,
    }


# The till: an oak cash drawer of the period's bars (a box with a till drawer, a bell to its catch),
# coin and notes in it.
TILL = {"size": (0.42, 0.13, 0.36), "drawer": (0.36, 0.085)}


def till_drawer():
    sx, sy, sz = TILL["size"]
    dw, dh = TILL["drawer"]
    ms = [member("case", "post", [sx, sy, sz], [0, sy * 0.5, 0], look=OAK_TOP, solid=0.3)]  # (a box: its boards ~0.3 of it)
    d = member("drawer", "trim", [dw, dh, 0.016], [0, 0.012 + dh * 0.5, sz * 0.5 + 0.008], look=OAK_FRONT)
    d["dress"] = [dress("pbr:till_drawer", "till_drawer", "Pull"), dress("pbr:till_drawer", "till_drawer", "Bell")]
    ms.append(d)
    return {
        "_doc": "The bar's till (#866; refs experiments/prop_lab/refs/saloon/): an oak cash box of the period's bars, 42 cm wide, its till drawer in front with a brass pull and the little bell that rings as it opens. It holds the house's coin and notes (not yet a prop of their own). Oak from the material library (a few years; the top worn); its brass baked the gun way (tools/blender/props/saloon_s1.py). On the back bar by the scales. 2 physics bodies. ~6 kg. Written by tools/props/saloon.py.",
        "id": "till_drawer", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.4, "blow_wood_share": 0.5,
        "members": ms,
    }


# Slat mats behind the bar (2 ft wide duckboards: the bartender's feet out of the slops): oak slats on
# two runners.
SLAT_MAT = {"length": 1.8, "width": 0.61, "runner": (0.05, 0.03), "slat": (0.07, 0.022), "gap": 0.018}


def slat_mat():
    c = SLAT_MAT
    L, W = c["length"], c["width"]
    rw, rh = c["runner"]
    sw, sh = c["slat"]
    ms = []
    for s, name in ((-1, "b"), (1, "f")):
        ms.append(member("runner_" + name, "sill", [L, rh, rw], [0, rh * 0.5, s * (W * 0.5 - 0.09)], look=OAK_OLD))
    n = int((L + c["gap"]) / (sw + c["gap"]))
    pitch = (L - sw) / (n - 1)
    # The slats one member drawn from its model (a library board draws as one box: round 1 saw a slab).
    ms.append(member("slats", "furniture_top", [L, sh, W], [0, rh + sh * 0.5, 0], look="pbr:slat_mat",
                     draw=mesh("slat_mat", "Slats"), solid=round(n * sw / L, 3)))
    return {
        "_doc": "A slat mat (#866; refs experiments/prop_lab/refs/saloon/): the duckboard behind the bar that keeps the bartender's feet out of the slops, 6 ft long and 2 ft wide, %d oak slats on two runners, old and worn (the slats baked: worn pine, slopped and trodden). The slats one member drawn as its slats (a duckboard breaks along a slat as one piece: fine for its few bodies), the runners two. The runners oak from the material library (old), never the floor's fir. The bar's run takes one every 6 ft. 3 physics bodies. ~9 kg. Written by tools/props/saloon.py." % n,
        "id": "slat_mat", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.3, "blow_wood_share": 0.5,
        "members": ms,
    }


# A deck of cards and the players' chips (the card game's stand-ins until now, #866): square-cornered
# cards of the period (no indices; a printed back), a deck squared; three stacks of clay chips.
def card_deck():
    ms = [member("deck", "post", [0.064, 0.016, 0.089], [0, 0.008, 0], wood="paper", look="pbr:cards_chips", draw=mesh("cards_chips", "Deck"))]
    ms[0]["dress"] = [dress("pbr:cards_chips", "cards_chips", "DeckBack")]
    return {
        "_doc": "A deck of cards (#866; refs experiments/prop_lab/refs/saloon/): 52 square-cornered cards of the period (no corner indices yet in a western saloon of 1882; a blue patterned back), squared on the table. One member (it burns; a ball knocks it). The faces printed on the card game's sheet, the back baked (tools/blender/props/saloon_s1.py). 1 physics body. Written by tools/props/saloon.py.",
        "id": "card_deck", "kind": "members", "fixture": True, "in_game": False, "wood": "paper",
        "splits_below": 0.1, "blow_wood_share": 0.5,
        "members": ms,
    }


def chip_stacks():
    ms = [member("chips", "post", [0.13, 0.04, 0.07], [0, 0.02, 0], wood="stone", look="pbr:cards_chips", draw=mesh("cards_chips", "ChipsW"),
                 solid=0.25)]  # (fired clay: the stacks a quarter of their box)
    ms[0]["dress"] = [dress("pbr:cards_chips", "cards_chips", "ChipsR"), dress("pbr:cards_chips", "cards_chips", "ChipsB")]
    return {
        "_doc": "The players' chips (#866; refs experiments/prop_lab/refs/saloon/): three stacks of the period's clay chips (white, red, blue), 39 mm across, the tallest twelve high. One member (the stacks as one: a ball through them knocks the lot; fired clay doesn't burn). Baked (tools/blender/props/saloon_s1.py). 1 physics body. Written by tools/props/saloon.py.",
        "id": "chip_stacks", "kind": "members", "fixture": True, "in_game": False, "wood": "stone",
        "splits_below": 0.1, "blow_wood_share": 0.5,
        "members": ms,
    }


# --- The bar's arm rail (added to assets/props/kit/bar.json) -------------------------------------
# A 2 1/2 in brass rail along the top's front edge on brass saddles, where the arms rest; the foot rail
# and its brackets drawn from the same baked brass (no flat painted metal, the recipe's point 2).
BAR = {"top_y": 1.095, "front_z": 0.5, "rail_r": 0.0318, "rail_len": 2.9, "rail_z": 0.455, "saddle": 0.014,
       "saddles": [-1.2, -0.4, 0.4, 1.2]}


def bar_rails(bar):
    """The bar's kit file with its arm rail added and its foot rail drawn from the baked brass."""
    c = BAR
    ms = [m for m in bar["members"] if not m["id"].startswith("arm_rail")]
    rail = member("arm_rail", "trim", [c["rail_len"], c["rail_r"] * 2 + c["saddle"], c["rail_r"] * 2],
                  [0, c["top_y"] + (c["rail_r"] * 2 + c["saddle"]) * 0.5, c["rail_z"]], wood="iron", look="pbr:bar_rails",
                  draw=mesh("bar_rails", "ArmRail"), solid=0.07)  # (a brass tube, 1/16 in wall)
    ms.append(rail)
    out = []
    for m in ms:
        if m["id"] == "foot_rail":
            m["look"] = "pbr:bar_rails"
            m["draw"] = mesh("bar_rails", "FootRail")
        elif m["id"].startswith("rail_bracket"):
            # Laid out one by one (a Blender part a bracket: a repeat's copies would each draw them all).
            rep = m.pop("repeat", None)
            if rep:
                for k in range(int(rep["count"])):
                    one = dict(m, id="rail_bracket%d" % k, at=r([m["at"][0] + rep["step"][0] * k, m["at"][1], m["at"][2]]))
                    out.append(one)
                continue
        out.append(m)
    for m in out:
        if m["id"].startswith("rail_bracket"):
            m["look"] = "pbr:bar_rails"
            m["draw"] = mesh("bar_rails", "FootBracket" + m["id"][len("rail_bracket"):])
    bar["members"] = out
    if "arm rail" not in bar["_doc"]:
        bar["_doc"] += " Its arm rail (#866): a 2 1/2 in brass rail along the top's front edge on brass saddles (one member, wood iron); the foot rail, its brackets and the arm rail drawn from one baked brass (pbr:bar_rails, tools/blender/props/saloon_s1.py; tools/props/saloon.py adds them)."
    return bar


BATCH_S1 = [hanging_lamp, hanging_lamp_shaded, shot_glass, schooner, decanter, work_board, box_stove, faro_table, lookout_stool,
            piano_stool, wheel_of_fortune, gold_scales, till_drawer, slat_mat, card_deck, chip_stacks]


def main():
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    for make in BATCH_S1:
        if only and make.__name__ not in only:
            continue
        d = make()
        d["factory"] = "tools/props/saloon.py"
        path = os.path.join(KIT, d["id"] + ".json")
        with open(path, "w") as f:
            json.dump(d, f, indent=2)
            f.write("\n")
        print("wrote", os.path.relpath(path, ROOT), "(%d members)" % len(d.get("members", [])))
    if not only or "bar" in only:
        path = os.path.join(KIT, "bar.json")
        bar = bar_rails(json.load(open(path)))
        with open(path, "w") as f:
            json.dump(bar, f, indent=1)  # (the bar's own file's layout)
            f.write("\n")
        print("wrote", os.path.relpath(path, ROOT), "(the arm rail)")


if __name__ == "__main__":
    main()
