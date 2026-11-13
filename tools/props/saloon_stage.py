"""Saloon B's stage and dressing room props (#903; Sean 2026-11-13: a backstage "with mirrors and
shit"): the kit files of a frontier variety hall's dressing mirror, costume pegs, travelling trunk,
dressing screen and footlight, written from the numbers here, so a change is one number and a re-run.
The Blender half (tools/blender/props/saloon_stage.py) reads the same numbers.

    python3 tools/props/saloon_stage.py [--only=dressing_mirror,footlight]   # writes assets/props/kit/<id>.json

The prop lab's recipe (docs/briefs/prop-factory.md "The recipe brought up to date"): woods from the
material library (`lib:`; the plain pieces painted pine, the frames old oak), cloth, tin and brass
baked the gun way (`pbr:<model>`, tools/blender/props/metal.py), the mirror's glass the back bar's
(`prop:mirror`, a member of kind `glass`), the footlight the reflector lamp's way (a GlassProp `like`
the oil lamp). What the kit already had is extended, not made twice: the costume pegs are the
doctor's coat pegs' rail, pegs and coat (tools/props/doctor.py, doctor_d3.py) at a dressing room's
length; the trunk's lid opens on the kit's hinges (the strongbox's, #782). Period: an 1880s frontier
variety hall's, worn, bought second-hand. References: experiments/prop_lab/refs/saloon_stage/.
Where each goes in saloon B: experiments/prop_lab/README.md "Saloon B, the stage and dressing room".
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from doctor import KIT, PINE, PINE_TOP, ROOT, member, mesh, r  # noqa: E402
import doctor  # noqa: E402

OAK_OLD = "lib:furniture_oak/old"
OAK_OLD_TOP = OAK_OLD + "/top"


def dress(look, model, part):
    return {"look": look, "draw": mesh(model, part)}


# --- The dressing mirror ------------------------------------------------------------------------
# A plain painted pine dressing table (36 x 18 in, 29 in high) against the wall, and behind it, on two
# oak standards from the floor, a tall glass in a moulded frame (30 x 40 in), a narrow shelf at its
# foot for the paint: greasepaint sticks and tins, a powder box, a rouge pot, a hare's foot. On the
# table a tin candlestick, a comb and a hand glass. The kind of thing a variety hall's dressing room
# had second-hand from a hotel's sale. The wall behind at z = -0.29 (the standards' backs); x across,
# the floor at y = 0, the room toward +z.
MIRROR = {"table": (0.92, 0.74, 0.46), "board": 0.025, "leg": 0.045, "leg_x": 0.42, "leg_z": 0.19, "apron_h": 0.1, "apron_t": 0.02,
          "standard": (0.05, 1.9, 0.04), "std_z": -0.255, "rail": (0.08, 0.035), "rail_y": 0.76, "shelf": (0.018, 0.12),
          "glass": (0.75, 1.0, 0.006), "head": 0.04}


def mirror_glass_y():
    """The glass's foot and top (it stands on the shelf)."""
    m = MIRROR
    y0 = m["rail_y"] + m["rail"][0] + m["shelf"][0]
    return y0, y0 + m["glass"][1]


def dressing_mirror():
    m = MIRROR
    tw, th, td = m["table"]
    b, lg = m["board"], m["leg"]
    lx, lz = m["leg_x"], m["leg_z"]
    leg_h = th - b
    ms = []
    for i, (sx, sz) in enumerate(((-1, 1), (1, 1), (-1, -1), (1, -1))):
        ms.append(member("leg%d" % i, "post", [lg, leg_h, lg], [sx * lx, leg_h * 0.5, sz * lz], look=PINE))
    inner = (lx - lg * 0.5) * 2
    ah, at_ = m["apron_h"], m["apron_t"]
    for s, name in ((1, "f"), (-1, "b")):
        ms.append(member("apron_" + name, "furniture_frame", [inner, ah, at_], [0, leg_h - ah * 0.5, s * (lz + lg * 0.5 - at_ * 0.5)], look=PINE))
    top = member("top", "furniture_top", [tw, b, td], [0, th - b * 0.5, 0], look=PINE_TOP)
    top["dress"] = [dress("pbr:dressing_mirror", "dressing_mirror", part) for part in ("TopThings", "Candle", "HandGlass")]
    ms.append(top)
    sw, sh, sd = m["standard"]
    sz_ = m["std_z"]
    for s, name in ((-1, "l"), (1, "r")):
        st = member("standard_" + name, "post", [sw, sh, sd], [s * lx, sh * 0.5, sz_], look=OAK_OLD)
        if s < 0:
            # The glass's moulded frame and the standards' turned finials, drawn on the left one.
            st["dress"] = [dress("pbr:dressing_mirror", "dressing_mirror", "Frame")]
        ms.append(st)
    between = (lx - sw * 0.5) * 2
    rh, rt = m["rail"]
    ry = m["rail_y"]
    ms.append(member("rail", "furniture_frame", [between, rh, rt], [0, ry + rh * 0.5, sz_], look=OAK_OLD))
    sht, shd = m["shelf"]
    shelf = member("shelf", "board", [between, sht, shd], [0, ry + rh + sht * 0.5, sz_ - sd * 0.5 + shd * 0.5], look=OAK_OLD_TOP)
    shelf["dress"] = [dress("pbr:dressing_mirror", "dressing_mirror", part) for part in ("Tins", "Sticks", "Rouge", "Powder", "HareFoot")]
    ms.append(shelf)
    gw, gh, gt = m["glass"]
    y0, y1 = mirror_glass_y()
    gz = sz_ - sd * 0.5 + gt * 0.5 + 0.004
    hw, hh = gw * 0.5, gh * 0.5
    # The back bar's glass (prop:mirror, the painted room it gives back), cut square, its top corners rounded.
    corner = [(hw - 0.06 + 0.06 * math.sin(math.radians(a)), hh - 0.06 + 0.06 * math.cos(math.radians(a))) for a in (0, 30, 60, 90)]
    outline = [(-hw, -hh), (hw, -hh)] + sorted(corner, key=lambda p: -p[0]) + [(-x, y) for x, y in sorted(corner, key=lambda p: p[0])]
    ms.append(member("glass", "glass", [gw, gh, gt], [0, (y0 + y1) * 0.5, gz], wood="glass", look="prop:mirror",
                     draw={"shape": "cut", "plane": "xy", "outline": [r(list(p)) for p in outline]}))
    head = m["head"]
    ms.append(member("head", "furniture_frame", [between, head, rt], [0, sh - head * 0.5, sz_], look=OAK_OLD))
    return {
        "_doc": "A performer's dressing mirror (#903; Sean 2026-11-13, a backstage 'with mirrors and shit'; refs experiments/prop_lab/refs/saloon_stage/): a plain painted pine dressing table, 36 x 18 in and 29 in high, and behind it on two old oak standards from the floor a tall glass 30 x 40 in in a moulded frame, a narrow shelf at its foot for the paint (greasepaint sticks and tins, a powder box, a rouge pot, a hare's foot); on the table a tin candlestick, a comb and a hand glass. Second-hand, worn. The glass by the back bar's route (a member of kind `glass`, the painted mirror `prop:mirror`): a ball or a blast breaks it as a window; it stands on the shelf and comes down with it. The table, standards and rails from the material library (painted pine a few years; oak old); the frame, finials and the things on it baked the gun way (tools/blender/props/saloon_stage.py). The wall behind at z = -0.29, the room toward +z. 13 physics bodies (its members). ~25 kg. Saloon B's dressing room (room_6), against its wall. Written by tools/props/saloon_stage.py.",
        "id": "dressing_mirror", "kind": "members", "fixture": True, "in_game": False, "wood": "weathered_pine",
        "splits_below": 0.5, "blow_wood_share": 0.5,
        "members": ms,
    }


# --- The costume pegs ---------------------------------------------------------------------------
# The doctor's hall pegs (doctor.PEGS, coat_pegs) at a dressing room's length: a painted pine rail of
# six turned pegs, and hung on them a variety actress's dress (faded crimson satin, a black lace
# flounce), a showman's frock coat (the doctor's coat's cut, in worn plum velvet) and a woman's hat
# with an ostrich plume.
PEGS = {"length": 1.5, "pegs": 6, "dress": {"peg": 1, "size": (0.42, 1.34, 0.2)}, "coat": {"peg": 3}, "hat": {"peg": 5, "brim": 0.17, "crown": 0.075,
        "crown_h": 0.07, "plume": 0.34}}


def costume_peg_xs():
    p = PEGS
    span = p["length"] - 0.2
    step = span / (p["pegs"] - 1)
    return [-span * 0.5 + step * k for k in range(p["pegs"])]


def costume_pegs():
    p, d = PEGS, doctor.PEGS
    t = d["thick"]
    look = "pbr:costume_pegs"
    ms = [member("rail", "post", [p["length"], d["height"], t], [0, 0, t * 0.5], look=PINE)]
    xs = costume_peg_xs()
    for k, x in enumerate(xs):
        ms.append(member("peg%d" % k, "furniture_frame", [d["peg_r"] * 2, d["peg_r"] * 2, d["peg_len"]], [x, 0, t + d["peg_len"] * 0.5],
                         wood="oak", look=look, draw=mesh("costume_pegs", "Peg%d" % k)))
    dw, dh, dd = p["dress"]["size"]
    dx = xs[p["dress"]["peg"]]
    gown = member("dress", "trim", [dw, dh, dd], [dx, 0.012 - dh * 0.5, t + 0.03 + dd * 0.5], wood="canvas", look=look, draw=mesh("costume_pegs", "Dress"))
    gown["dress"] = [dress(look, "costume_pegs", "DressLace")]
    ms.append(gown)
    cw, ch, cd = d["coat"]["size"]
    cx = xs[p["coat"]["peg"]]
    coat = member("coat", "trim", [cw, ch, cd], [cx, 0.012 - ch * 0.5, t + 0.03 + cd * 0.5], wood="canvas", look=look, draw=mesh("costume_pegs", "Coat"))
    coat["dress"] = [dress(look, "costume_pegs", "CoatButtons")]
    ms.append(coat)
    h = p["hat"]
    hx = xs[h["peg"]]
    hat = member("hat", "trim", [h["brim"] * 2, h["brim"] * 2, 0.12], [hx, -0.05, t + 0.03 + 0.06], wood="canvas", look=look, draw=mesh("costume_pegs", "Hat"))
    hat["dress"] = [dress(look, "costume_pegs", "HatBand"), dress(look, "costume_pegs", "Plume")]
    ms.append(hat)
    return {
        "_doc": "The dressing room's costume pegs (#903; refs experiments/prop_lab/refs/saloon_stage/): the doctor's hall pegs (`coat_pegs`, its rail, turned pegs and coat, tools/props/doctor.py) at a dressing room's length, 1.5 m of painted pine with six pegs, nailed to the wall through two nails; hung on them a variety actress's dress (faded crimson satin, a black lace flounce at its hem) on the second, a showman's frock coat (the doctor's coat's cut in worn plum velvet, brass buttons) on the fourth, and a woman's felt hat with an ostrich plume on the sixth. Hung (KitProp `hangs`): it holds while a nail's in the wall and falls when its board goes; a peg shot off drops what's on it; the clothes burn (wood `canvas`). The rail from the material library (a few years); the pegs and clothes baked the gun way (tools/blender/props/saloon_stage.py). The wall's face at z = 0, the pegs toward +z, the rail's middle the origin (hang it at ~1.7 m: the dress's hem then ~0.35 m off the floor). 10 physics bodies, ~10 kg. Saloon B's dressing room (room_6), on the wall opposite the mirror. Written by tools/props/saloon_stage.py.",
        "id": "costume_pegs", "kind": "members", "fixture": True, "in_game": False, "wood": "weathered_pine", "drawn_bounds": True,
        "splits_below": 0.4, "blow_wood_share": 0.5,
        "hangs": {"nails": [r([-p["length"] * 0.5 + 0.06, 0.0, 0.004]), r([p["length"] * 0.5 - 0.06, 0.0, 0.004])]},
        "members": ms,
    }


# --- The travelling trunk -----------------------------------------------------------------------
# A touring company's flat-topped trunk of the 1870s-80s (a "Saratoga" at a player's budget): a pine
# box covered in painted canvas, bound with oak slats, tin corner clamps, a brass lock and hasp,
# leather end handles; 34 x 20 in, 24 in high, its lid 5 in deep on two hinges at the back, standing
# open on its stays; costumes folded in it. The back at -z.
TRUNK = {"length": 0.86, "depth": 0.5, "body_h": 0.47, "lid_h": 0.13, "board": 0.014, "bottom": 0.02, "open": -102.0,
         "costumes": (0.8, 0.26, 0.44)}
# Each member's own part and the parts drawn on it (one finish a part: slats, tin, brass, leather, cloth).
TRUNK_DRESS = {"Bottom": ["Skids"], "Front": ["FrontSlats", "FrontTin", "Lock"], "Back": ["BackSlats", "BackTin"],
               "EndL": ["EndLSlats", "EndLTin", "HandleL"], "EndR": ["EndRSlats", "EndRTin", "HandleR"],
               "Lid": ["LidSlats", "LidTin", "Hasp"], "Costumes": ["CostumesWhite", "CostumesDark", "Spangles"]}


def travelling_trunk():
    c = TRUNK
    L, D, bh, lh, t, bt = c["length"], c["depth"], c["body_h"], c["lid_h"], c["board"], c["bottom"]
    look = "pbr:travelling_trunk"
    wall_h = bh - bt
    ms = [member("bottom", "post", [L, bt, D], [0, bt * 0.5, 0], look=look, draw=mesh("travelling_trunk", "Bottom"))]
    ms[-1]["dress"] = [dress(look, "travelling_trunk", p) for p in TRUNK_DRESS["Bottom"]]
    for s, name, part in ((1, "front", "Front"), (-1, "back", "Back")):
        f = member(name, "board", [L, wall_h, t], [0, bt + wall_h * 0.5, s * (D * 0.5 - t * 0.5)], look=look, draw=mesh("travelling_trunk", part))
        f["dress"] = [dress(look, "travelling_trunk", p) for p in TRUNK_DRESS[part]]
        ms.append(f)
    for s, name, part in ((-1, "end_l", "EndL"), (1, "end_r", "EndR")):
        e = member(name, "board", [t, wall_h, D - 2 * t], [s * (L * 0.5 - t * 0.5), bt + wall_h * 0.5, 0], look=look, draw=mesh("travelling_trunk", part))
        e["dress"] = [dress(look, "travelling_trunk", p) for p in TRUNK_DRESS[part]]
        ms.append(e)
    lid = member("lid", "trim", [L, lh, D], [0, bh + lh * 0.5, 0], look=look, draw=mesh("travelling_trunk", "Lid"), solid=0.17)
    lid["dress"] = [dress(look, "travelling_trunk", p) for p in TRUNK_DRESS["Lid"]]
    ms.append(lid)
    cw, ch, cd = c["costumes"]
    cos = member("costumes", "trim", [cw, ch, cd], [0, bt + ch * 0.5, 0.0], wood="canvas", look=look, draw=mesh("travelling_trunk", "Costumes"), solid=0.5)
    cos["dress"] = [dress(look, "travelling_trunk", p) for p in TRUNK_DRESS["Costumes"]]
    ms.append(cos)
    return {
        "_doc": "A touring company's travelling trunk (#903; refs experiments/prop_lab/refs/saloon_stage/): a flat-topped trunk of the 1870s-80s, 34 x 20 in and 24 in high, a pine box covered in painted canvas gone dull, bound with oak slats, tin corner clamps, a brass lock and hasp, leather end handles; its lid 5 in deep on two hinges at the back (the kit's hinges, the strongbox's: `open_hinge(\"lid\")`, it stands open on its stays at 102 degrees); costumes folded in it (a red satin, a spangled bodice, white muslin, a wig). Bought second-hand, the paint worn through at the edges. Boards `weathered_pine`, the costumes `canvas` (they burn). Its box, slats and fittings baked the gun way (tools/blender/props/saloon_stage.py). The back at -z. 7 physics bodies. ~21 kg with what's in it. Saloon B: one in the dressing room (room_6) at the foot of the wall, one in the wing beside the stage (open, the night's costumes). Written by tools/props/saloon_stage.py.",
        "id": "travelling_trunk", "kind": "members", "fixture": True, "in_game": False, "wood": "weathered_pine",
        "splits_below": 0.4, "blow_wood_share": 0.5,
        "hinges": {"lid": {"members": ["lid"], "axis": [r([-L * 0.5, bh, -D * 0.5]), r([L * 0.5, bh, -D * 0.5])], "open": c["open"], "on": ["back"]}},
        "members": ms,
    }


# --- The dressing screen ------------------------------------------------------------------------
# A three-leaf folding screen (each leaf 20 x 66 in, the house's size), old oak frames with brass
# hinges, the panels a faded cretonne (a printed cotton of the 1870s-80s: stripes and sprigs) tacked
# on. The middle leaf across x at z = 0, the wings folded forward (+z) 30 degrees: a shallow bay the
# performer changes behind (its inside toward +z).
SCREEN = {"leaf": 0.49, "gap": 0.006, "height": 1.68, "stile": (0.035, 0.03), "rail": 0.05, "rail_y": 0.1, "panel": 0.006, "wing": 30.0}


def screen_leaves():
    """Each leaf's frame: (name, centre x, centre z, yaw degrees) in the screen's space."""
    s = SCREEN
    half = s["leaf"] * 0.5
    a = math.radians(s["wing"])
    hinge = half + s["gap"] * 0.5
    out = [("m", 0.0, 0.0, 0.0)]
    for sx, name in ((-1, "l"), (1, "r")):
        cx = sx * (hinge + math.cos(a) * (s["gap"] * 0.5 + half))
        cz = math.sin(a) * (s["gap"] * 0.5 + half)
        out.append((name, cx, cz, sx * -s["wing"]))
    return out


def screen_local(cx, cz, yaw, lx, lz):
    """A point in a leaf's own space (x along it, z through it) to the screen's."""
    a = math.radians(yaw)
    return cx + lx * math.cos(a) + lz * math.sin(a), cz - lx * math.sin(a) + lz * math.cos(a)


def dressing_screen():
    s = SCREEN
    sw, st = s["stile"]
    H, L = s["height"], s["leaf"]
    ms = []
    for i, (name, cx, cz, yaw) in enumerate(screen_leaves()):
        rot = r([0.0, yaw, 0.0])
        for sx, side in ((-1, "a"), (1, "b")):
            x, z = screen_local(cx, cz, yaw, sx * (L * 0.5 - sw * 0.5), 0.0)
            stile = member("stile_%s%s" % (name, side), "post", [sw, H - s["rail"], st], [x, (H - s["rail"]) * 0.5, z], look=OAK_OLD, rot=rot)
            if name == "m":
                stile["dress"] = [dress("pbr:dressing_screen", "dressing_screen", "Hinges%s" % side.upper())]
            ms.append(stile)
        inner = L - 2 * sw
        x, z = screen_local(cx, cz, yaw, 0.0, 0.0)
        ms.append(member("foot_" + name, "furniture_frame", [inner, s["rail"], st * 0.8], [x, s["rail_y"] + s["rail"] * 0.5, z], look=OAK_OLD, rot=rot))
        ms.append(member("head_" + name, "furniture_frame", [L, s["rail"], st], [x, H - s["rail"] * 0.5, z], look=OAK_OLD_TOP, rot=rot))
        p0 = s["rail_y"] + s["rail"]
        p1 = H - s["rail"]
        ms.append(member("panel_" + name, "trim", [inner, p1 - p0, s["panel"]], [x, (p0 + p1) * 0.5, z], wood="canvas", look="pbr:screen_cloth",
                         rot=rot, draw=mesh("dressing_screen", "Panel%d" % i)))
    return {
        "_doc": "A three-leaf folding dressing screen (#903; refs experiments/prop_lab/refs/saloon_stage/): each leaf 20 x 66 in, an old oak frame (two stiles, a foot and a head rail) with brass hinges between, the panels a faded cretonne (a printed cotton of the 1870s-80s, stripes and sprigs of flowers, sun-faded and stained) tacked on. The middle leaf across x at z = 0, the wings folded forward 30 degrees: a shallow bay the performer changes behind, its inside toward +z. The frames from the material library (oak, old); the cloth printed (tools/blender/props/saloon_stage.py, `screen_cloth`) and burns (wood `canvas`: a ball goes through it, a lamp's oil sets it alight); the hinges baked the gun way. It doesn't fold yet. 15 physics bodies. ~11 kg. Saloon B's dressing room (room_6), across its corner by the door; a second in the wing beside the stage for a quick change. Written by tools/props/saloon_stage.py.",
        "id": "dressing_screen", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.5, "blow_wood_share": 0.5,
        "members": ms,
    }


# --- The footlight ------------------------------------------------------------------------------
# One of a variety stage's oil footlights (before gas reached a frontier hall): a squat tin font with
# a flat-wick brass burner and a short plain chimney, on a tin foot plate, behind a curved tin
# reflector hood that hides the flame from the house and throws its light up and back onto the
# stage. A row of four or five along the stage's front edge, each its own prop (one prop repeated).
FOOT = {"font_r": 0.06, "font_h": 0.055, "burner_y": 0.075, "flame_y": 0.1, "chimney": (0.088, 0.21, 0.026), "plate": (0.2, 0.004, 0.17),
        "hood": {"width": 0.22, "height": 0.2, "z": 0.075, "dish": 0.035}}


def footlight():
    f = FOOT
    pw, _, pd = f["plate"]
    h = f["hood"]
    return {
        "_doc": "A stage footlight (#903; refs experiments/prop_lab/refs/saloon_stage/): an oil footlight of a frontier variety hall (before gas reached it): a squat tin font with a flat-wick brass burner and a short plain chimney on a tin foot plate, behind a curved tin reflector hood 22 cm across that hides the flame from the house and throws its light up and back onto the stage. A prop that shatters (GlassProp, `like` the oil lamp, as the doctor's reflector lamp: its oil, its chimney's breaking): the chimney breaks, the tin and brass come through whole, a lit one's oil burns where it's kicked over. One prop repeated: a row of four or five along the stage's front edge, ~0.9 m apart, the hood (+z) toward the house, each with its OilLamp at `light_height`. Baked the gun way (tools/blender/props/saloon_stage.py). 1 physics body. Written by tools/props/saloon_stage.py.",
        "id": "footlight", "like": "oil_lamp", "fixture": True, "in_game": False, "replaces": "",
        "model": "glb:footlight",
        "looks": {"Chimney": "prop:chimney_glass", "Font": "pbr:footlight", "Burner": "pbr:footlight", "Hood": "pbr:footlight", "Plate": "pbr:footlight"},
        "size": r([h["width"], h["height"], pd]), "mass": 0.9, "light_height": f["flame_y"],
        "glass": ["Chimney"], "whole": [["Font", "Burner", "Hood", "Plate"]],
        "contents": {"liquid": "lamp_oil", "litres": 0.15, "flammable": True, "colour": [0.85, 0.75, 0.45]},
    }


BATCH = [dressing_mirror, costume_pegs, travelling_trunk, dressing_screen, footlight]


def main():
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    for make in BATCH:
        if only and make.__name__ not in only:
            continue
        d = make()
        d["factory"] = "tools/props/saloon_stage.py"
        path = os.path.join(KIT, d["id"] + ".json")
        with open(path, "w") as fh:
            json.dump(d, fh, indent=2)
            fh.write("\n")
        print("wrote", os.path.relpath(path, ROOT), "(%d members)" % len(d.get("members", [])))


if __name__ == "__main__":
    main()
