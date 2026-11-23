"""The undertaker's own props, batch U1 (#1181; the building and its stand-in U0 props are #1174's;
experiments/building_lab/undertaker/README.md "Period notes"): coffins, the bier and its drape, his
bench, the cellar's embalming table and cooling board, the pump, carboys, the ice bin and corpse cooler,
the safety coffin, the posing stand, the hair wreath, the box hearse and the horse's harness. Written from
the numbers here, so a change is one number and a re-run:

    python3 tools/props/undertaker.py [--only=coffin_hex,bier]   # writes assets/props/kit/<id>.json

No Blender this batch (no `bpy` in the session that made it): everything is kit members (sweeps, lathes,
cuts and boxes), woods from the material library (`lib:` looks), iron, brass, tin and cloth the kit's bare
`prop:` looks, glass the kit's `glass:` tints. Few members each (the valley is near Jolt's limit, #865:
prop bodies are counted in the PR). A prop faces +Z (its front), x along its length, origin on the floor at
its middle. Where each goes: `experiments/building_lab/undertaker/make_spec.py` (batch U1); what each is
against, and what stands in for what was not found: `experiments/prop_lab/undertaker/README.md`.
"""
import json
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from doctor import KIT, OAK, OAK_TOP, PINE, PINE_TOP, ROOT, member, r  # noqa: E402
import wagons  # noqa: E402

WALNUT = "lib:furniture_walnut/old"
WALNUT_TOP = WALNUT + "/top"
RAW = "wood:framing"          # unplaned pine: the shop's stock and the cellar's boards
IRON = "prop:iron"
BRASS = "prop:brass"
TIN = "prop:tin"              # zinc and tin: a dull grey sheet
CLOTH = "prop:canvas"
BLACK_CLOTH = "prop:hide_dark"
EBONY = "prop:ebony"          # the hearse's black paint
GLASS = "glass:clear"


def box(at, size, rot=None):
    b = {"size": r(size), "at": r(at)}
    if rot:
        b["rot"] = r(rot)
    return b


def stick(a, b, thick):
    return {"from": r(a), "to": r(b), "thick": r(thick)}


def dress(look, boxes):
    return {"look": look, "draw": {"shape": "boxes", "boxes": boxes}}


def lathe(look, profile, at=(0, 0, 0), seg=12, rot=None):
    d = {"shape": "lathe", "profile": [r(p) for p in profile], "segments": seg, "at": r(at)}
    if rot:
        d["rot"] = r(rot)
    return {"look": look, "draw": d}


def cut_xz(outline):
    return {"shape": "cut", "plane": "xz", "outline": [r(p) for p in outline]}


def prop(id_, doc, members, kind="members", wood="oak", **kw):
    doc = re.sub(r"\d+ physics bod", "%d physics bod" % len(members), doc)  # the count is the members', whatever the prose said
    d = {"_doc": doc, "id": id_, "kind": kind, "fixture": True, "in_game": True, "wood": wood,
         "splits_below": 0.4, "blow_wood_share": 0.5, "members": members}
    d.update(kw)
    return d


# --- Coffins ----------------------------------------------------------------------------------------
# The six-sided "toe-pincher" (shoulders widest, narrowing to the feet) was the Western undertaker's
# plain coffin of the 1880s, the rectangular "casket" coming in; a child's was often white. All built the
# same way: a bottom, walls standing on its edge (one a side of the outline), and a lid or a lining. Head at
# -x. Refs: Habenstein and Lamers (1955), the Smithsonian's and the Bowers' toe-pinchers; the Renouard manual.
HEX = [(-0.975, -0.18), (-0.45, -0.29), (0.975, -0.09), (0.975, 0.09), (-0.45, 0.29), (-0.975, 0.18)]
HEX_H = 0.40
RECT = [(-1.0, -0.28), (1.0, -0.28), (1.0, 0.28), (-1.0, 0.28)]
RECT_H = 0.44
CHILD = [(-0.52, -0.16), (0.52, -0.16), (0.52, 0.16), (-0.52, 0.16)]
CHILD_H = 0.26
WALL = 0.022


def _ring(outline):
    n = len(outline)
    return [(outline[i], outline[(i + 1) % n]) for i in range(n)]


def _coffin_members(outline, h, look, top_look, lid, handles, handle_n, tag):
    xs = [p[0] for p in outline]
    zs = [p[1] for p in outline]
    L, W = max(xs) - min(xs), max(zs) - min(zs)
    ms = [member("base", "post", [L, WALL, W], [0, WALL * 0.5, 0], look=look, draw=cut_xz(outline))]
    for i, (a, b) in enumerate(_ring(outline)):
        dx, dz = b[0] - a[0], b[1] - a[1]
        ln = math.hypot(dx, dz)
        yaw = -math.degrees(math.atan2(dz, dx))
        ms.append(member("wall%d" % i, "furniture_frame", [ln + WALL, h, WALL],
                         [(a[0] + b[0]) * 0.5, WALL + h * 0.5, (a[1] + b[1]) * 0.5], look=look, rot=[0, yaw, 0]))
    if lid:
        top = member("lid", "furniture_top", [L + 0.04, 0.026, W + 0.04], [0, WALL + h + 0.013, 0], look=top_look,
                     draw=cut_xz([(x + (0.02 if x > 0 else -0.02), z + (0.02 if z > 0 else -0.02)) for x, z in outline]))
        d = []
        if handles:
            for s in (-1, 1):
                for k in range(handle_n):
                    x = (k - (handle_n - 1) * 0.5) * (L * 0.62 / max(1, handle_n - 1)) if handle_n > 1 else 0.0
                    d.append(box([x, WALL + h * 0.5, s * (_side_z(outline, x) + 0.02)], [0.12, 0.02, 0.012]))
        top["dress"] = [dress(BRASS, [box([0, WALL + h + 0.031, 0], [L * 0.55, 0.012, W * 0.55])]),
                        dress(BRASS, [box([0.0, WALL + h + 0.04, 0.0], [0.18, 0.004, 0.07])])]  # the nameplate on the lid's moulding
        ms.append(top)
        if d:
            ms[1]["dress"] = [dress(BRASS, d)]
    else:
        ms.append(member("lining", "trim", [L - 0.1, 0.02, W - 0.1], [0, WALL + 0.012, 0], wood="canvas", look=CLOTH,
                         draw=cut_xz([(x * 0.93 + (0.0), z * 0.82) for x, z in outline])))
        ms.append(member("pillow", "trim", [0.34, 0.06, min(W - 0.12, 0.3)], [min(xs) + 0.28, WALL + 0.052, 0], wood="straw", look=CLOTH))
    return ms, L, W


def _side_z(outline, x):
    """The outline's z at x on the +z side (the handles ride the wall's outer face)."""
    best = 0.0
    for a, b in _ring(outline):
        if (a[0] - x) * (b[0] - x) <= 0 and a[0] != b[0]:
            t = (x - a[0]) / (b[0] - a[0])
            best = max(best, a[1] + t * (b[1] - a[1]))
    return best


def coffin_hex():
    ms, L, W = _coffin_members(HEX, HEX_H, WALNUT, WALNUT_TOP, True, True, 3, "hex")
    return prop("coffin_hex", "A six-sided \"toe-pincher\" coffin, closed (#1181; refs: Habenstein and Lamers 1955, the Bowers Museum's and the Smithsonian's): the plain walnut-stained coffin of an 1880s Western undertaker, %.2f m long, %.2f at the shoulders (head at -x), %.2f deep, a bottom, six walls on its edge and a lid with a moulded plate and a brass name plate, brass bar handles on each side. Wood from the material library (walnut, old). 8 physics bodies. Written by tools/props/undertaker.py." % (L, W, HEX_H),
                ms, wood="walnut", splits_below=0.5)


def coffin_hex_open():
    ms, L, W = _coffin_members(HEX, HEX_H, WALNUT, WALNUT_TOP, False, False, 0, "hex_open")
    return prop("coffin_hex_open", "A toe-pincher coffin open for viewing (#1181): as `coffin_hex` with no lid (it stands beside on trestles: `coffin_lid`), a pleated white cotton lining and a pillow; for the parlour's bier. Nobody in it. 8 physics bodies. Written by tools/props/undertaker.py.",
                ms, wood="walnut", splits_below=0.5)


def coffin_lid():
    h = 0.026
    top = member("lid", "post", [L := 1.99, h, 0.62], [0, h * 0.5, 0], look=WALNUT_TOP,
                 draw=cut_xz([(x + (0.02 if x > 0 else -0.02), z + (0.02 if z > 0 else -0.02)) for x, z in HEX]))
    top["dress"] = [dress(BRASS, [box([0, h + 0.006, 0], [L * 0.55, 0.012, 0.3])]), dress(BRASS, [box([0, h + 0.014, 0], [0.18, 0.004, 0.07])])]
    return prop("coffin_lid", "The toe-pincher's lid (#1181), laid on its own on trestles beside the open coffin, face up: a six-sided board with its raised moulding and brass plate. 1 physics body. Written by tools/props/undertaker.py.",
                [top], wood="walnut")


def coffin_rect():
    ms, L, W = _coffin_members(RECT, RECT_H, WALNUT, WALNUT_TOP, True, True, 3, "rect")
    return prop("coffin_rect", "A rectangular casket, closed (#1181; the new fashion of the 1880s, Habenstein and Lamers): walnut, %.2f m by %.2f, %.2f deep, a lid with a raised moulded panel and brass plate, three brass bar handles a side. 6 physics bodies. Written by tools/props/undertaker.py." % (L, W, RECT_H),
                ms, wood="walnut", splits_below=0.5)


def coffin_child():
    ms, L, W = _coffin_members(CHILD, CHILD_H, PINE, PINE_TOP, True, True, 2, "child")
    return prop("coffin_child", "A child's coffin (#1181): white-painted pine, %.2f m long, a plain lid, two small brass handles a side; a child's was often white (the undertaker's own notes). 6 physics bodies. Written by tools/props/undertaker.py." % L,
                ms, wood="weathered_pine", splits_below=0.5)


# --- Trestles, the bier and its drape --------------------------------------------------------------
TRESTLE_H = 0.56


def _trestle(x, tag):
    ms = [member("beam_" + tag, "furniture_top", [0.1, 0.07, 0.56], [x, TRESTLE_H - 0.035, 0], look=PINE)]
    for s, n in ((-1, "a"), (1, "b")):
        ms.append(member("leg_%s%s" % (tag, n), "post", [0.07, TRESTLE_H, 0.05], [x, TRESTLE_H * 0.5 - 0.02, s * 0.2], look=PINE,
                         rot=[-s * 14.0, 0, 0]))
    return ms


def trestles():
    ms = _trestle(-0.7, "w") + _trestle(0.7, "e")
    return prop("trestles", "Two sawhorse trestles (#1181) 1.4 m apart, %.2f m to the top: what a coffin stands on in the showroom and the parlour, what the lid lies on; an A of two splayed legs under a beam, painted pine. 6 physics bodies. Written by tools/props/undertaker.py." % TRESTLE_H,
                ms, wood="weathered_pine")


def trestles_short():
    ms = _trestle(-0.35, "w") + _trestle(0.35, "e")
    return prop("trestles_short", "Two sawhorse trestles 0.7 m apart (#1181), for a child's coffin (1.05 m: it would fall between `trestles`' 1.4). 6 physics bodies. Written by tools/props/undertaker.py.", ms, wood="weathered_pine")


def bier():
    ms = _trestle(-0.7, "w") + _trestle(0.7, "e")
    for k, z in enumerate((-0.2, 0.2)):
        ms.append(member("board%d" % k, "furniture_top", [2.1, 0.03, 0.38], [0, TRESTLE_H + 0.015, z], look=PINE_TOP))
    y = TRESTLE_H + 0.03
    drape = member("drape", "trim", [2.3, 0.012, 0.86], [0, y + 0.006, 0], wood="canvas", look=BLACK_CLOTH)
    drape["draw"] = {"shape": "boxes", "boxes": [box([0, 0, 0], [2.3, 0.012, 0.86])]
                     + [box([0, -0.2, s * 0.43], [2.3, 0.4, 0.012]) for s in (-1, 1)]
                     + [box([s * 1.15, -0.13, 0], [0.012, 0.26, 0.84]) for s in (-1, 1)]}
    drape["dress"] = [dress(BRASS, [box([s * 1.15, -0.27, z], [0.012, 0.016, 0.03]) for s in (-1, 1) for z in (-0.36, -0.12, 0.12, 0.36)])]  # a fringe's weights, at the hems
    ms.append(drape)
    return prop("bier", "The parlour's bier (#1181): two trestles carrying two boards, a black cloth over them hanging a hand's breadth short of the floor either side and a quarter way down the ends, weighted at the hem (the period's bier cloth was a black or purple wool or crepe). The coffin is `coffin_hex_open`, set on top (y %.2f). 9 physics bodies. Written by tools/props/undertaker.py." % (TRESTLE_H + 0.03),
                ms, wood="weathered_pine")


# --- The workroom ----------------------------------------------------------------------------------
def workbench():
    L, W, H = 2.4, 0.7, 0.86
    ms = []
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        ms.append(member("leg%d" % i, "post", [0.1, H - 0.07, 0.1], [sx * (L * 0.5 - 0.15), (H - 0.07) * 0.5, sz * (W * 0.5 - 0.1)], look=RAW))
    for s, n in ((-1, "b"), (1, "f")):
        ms.append(member("apron_%s" % n, "furniture_frame", [L - 0.4, 0.14, 0.04], [0, H - 0.07 - 0.1, s * (W * 0.5 - 0.1)], look=RAW))
    for s, n in ((-1, "w"), (1, "e")):
        ms.append(member("end_%s" % n, "furniture_frame", [0.04, 0.14, W - 0.2], [s * (L * 0.5 - 0.15), H - 0.07 - 0.1, 0], look=RAW))
    top = member("top", "furniture_top", [L, 0.07, W], [0, H - 0.035, 0], look=OAK_TOP)
    top["dress"] = [
        dress(RAW, [box([0, 0.037, -W * 0.5 + 0.06], [L - 0.1, 0.02, 0.1])]),  # the tool well's back rail
        dress(IRON, [box([-L * 0.5 + 0.2, 0.05, W * 0.5 + 0.03], [0.04, 0.04, 0.2]), box([-L * 0.5 + 0.2, 0.0, W * 0.5 + 0.12], [0.03, 0.03, 0.22])]),  # the vise's screw and its guide
        dress(IRON, [box([x, 0.04, 0.04], [0.02, 0.012, 0.02]) for x in (-0.4, 0.5)]),  # bench dogs
        dress(RAW, [box([0.0, 0.056, 0.0], [0.5, 0.036, 0.11]), box([0.04, 0.085, 0.0], [0.07, 0.04, 0.06])]),  # a jack plane
        dress(IRON, [box([-0.1, 0.07, 0.19], [0.4, 0.002, 0.07], [0, 0, 0]), box([0.12, 0.071, 0.2], [0.07, 0.03, 0.02])]),  # a handsaw's blade and grip
        dress(RAW, [box([0.5, 0.05, 0.14], [0.2, 0.03, 0.05]), box([0.6, 0.07, 0.14], [0.05, 0.1, 0.05])]),  # a mallet
    ]
    ms.append(top)
    # The vise's jaw: the bench's own front jaw, a block at the left end a hand over the top.
    ms.append(member("vise_jaw", "trim", [0.06, 0.16, 0.22], [-L * 0.5 + 0.2, H + 0.02 - 0.0, W * 0.5 + 0.04], look=OAK, wood="oak"))
    ms.append(member("shelf", "furniture_top", [L - 0.3, 0.025, W - 0.18], [0, 0.17, 0], look=RAW))
    return prop("workbench", "The cabinetmaker-undertaker's bench (#1181; refs: Roubo's and the Peterborough Museum's joiner's benches, the 1880s Sears catalogue's): 2.4 m long, 0.7 deep, 0.86 high, four stout raw pine legs, aprons, a lower shelf, a top of oak 70 mm thick with its tool well along the back, a quick-screw vise (a jaw, screw and guide) at the left end, bench dogs, and on it a jack plane, a handsaw and a mallet (drawn on). 12 physics bodies. Written by tools/props/undertaker.py.",
                ms, wood="oak", splits_below=0.4)


def tool_rack():
    W, H = 1.3, 0.55
    back = member("board", "post", [W, H, 0.03], [0, 0, 0.015], look=PINE, wood="weathered_pine")
    saw = lambda x: [box([x, -0.02, 0.05], [0.06, 0.34, 0.004], [0, 0, 0]), box([x, 0.19, 0.055], [0.09, 0.1, 0.03])]
    back["dress"] = [
        dress(IRON, saw(-0.5) + saw(-0.3) + [box([0.0, -0.05, 0.05], [0.22, 0.012, 0.012])]),  # two panel saws on pegs, a bit brace's sweep
        dress(RAW, [box([0.28, -0.04, 0.06], [0.07, 0.06, 0.4], [0, 0, 0]), box([0.46, -0.04, 0.06], [0.07, 0.06, 0.3])]),  # a jointer plane and a smoothing plane
        dress(RAW, [box([x, 0.2, 0.04], [0.025, 0.02, 0.025]) for x in (-0.5, -0.3, 0.28, 0.46)]),  # the pegs
        dress(IRON, [box([0.6, 0.0, 0.05], [0.02, 0.3, 0.012]), box([0.6, 0.15, 0.05], [0.14, 0.012, 0.012])]),  # a try square
    ]
    return prop("tool_rack", "His tool rack (#1181): a pine board with pegs hung on the workroom's wall, two panel saws, a jointer and a smoothing plane, a try square (drawn on). Hung on a nail at each end. 1 physics body. Written by tools/props/undertaker.py.",
                [back], wood="weathered_pine", hangs={"nails": [[-0.55, 0.0, 0.004], [0.55, 0.0, 0.004]]}, drawn_bounds=True)


def glue_pot():
    pot = member("pot", "post", [0.2, 0.2, 0.2], [0, 0.1, 0], look=IRON, wood="iron")
    pot["draw"] = {"shape": "lathe", "profile": [[0.0, 0.0], [0.085, 0.0], [0.1, 0.1], [0.095, 0.18], [0.07, 0.2], [0.0, 0.2]], "segments": 12}
    pot["dress"] = [lathe(IRON, [[0.115, 0.19], [0.115, 0.2], [0.07, 0.2], [0.07, 0.19]]),
                    dress(IRON, [stick([0.1, 0.17, 0.0], [0.17, 0.12, 0.0], 0.012)]),
                    dress(RAW, [box([0.0, 0.22, 0.0], [0.014, 0.1, 0.014], [0, 0, 22])])]  # its bail and a brush
    return prop("glue_pot", "The glue pot (#1181; the cabinetmaker's hide glue: a cast iron pot in a water jacket, a bail, a brush in it) for the bench or the stove. 1 physics body. Written by tools/props/undertaker.py.",
                [pot], wood="iron")


def plank_stack():
    ms = []
    for k, x in enumerate((-0.7, 0.0, 0.7)):
        ms.append(member("sticker%d" % k, "post", [0.04, 0.04, 0.34], [x, 0.02, 0], look=RAW))
    for k, kind in enumerate(("furniture_frame", "furniture_top", "trim")):
        y = 0.04 + 0.03 * (2 * k + 1)
        m = member("layer%d" % k, kind, [2.0, 0.06, 0.34], [0, y, 0], look=RAW)
        m["draw"] = {"shape": "boxes", "boxes": [box([0, -0.015, 0], [2.0, 0.026, 0.34]), box([0, 0.015, 0], [1.9 - 0.1 * k, 0.026, 0.3])]}
        ms.append(m)
    return prop("plank_stack", "A stack of seasoning boards (#1181): raw pine planks 2 m by 34 cm in three layers of two on stickers, his coffin stock. 6 physics bodies. Written by tools/props/undertaker.py.",
                ms, wood="weathered_pine")


# --- The cellar: embalming --------------------------------------------------------------------------
def embalming_table():
    L, W, H = 1.9, 0.62, 0.84
    ms = []
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        ms.append(member("leg%d" % i, "post", [0.07, H - 0.05, 0.07], [sx * (L * 0.5 - 0.08), (H - 0.05) * 0.5, sz * (W * 0.5 - 0.06)], look=PINE))
    for s, n in ((-1, "b"), (1, "f")):
        ms.append(member("apron_%s" % n, "furniture_frame", [L - 0.2, 0.11, 0.025], [0, H - 0.05 - 0.07, s * (W * 0.5 - 0.06)], look=PINE))
    for s_, n in ((-1, "b"), (1, "f")):
        ms.append(member("stretcher_" + n, "furniture_frame", [L - 0.16, 0.05, 0.04], [0, 0.22, s_ * (W * 0.5 - 0.06)], look=PINE))
    top = member("top", "furniture_top", [L, 0.05, W], [0, H - 0.025, 0], look=PINE_TOP)
    slope = -1.0  # degrees: the zinc dips to the drain at the foot (+x)
    liner = [box([0, 0.03, 0], [L - 0.06, 0.006, W - 0.06], [0, 0, slope])]
    rim = [box([0, 0.045, s * (W * 0.5 - 0.02)], [L - 0.04, 0.03, 0.014], [0, 0, slope]) for s in (-1, 1)] + \
          [box([-L * 0.5 + 0.03, 0.05, 0], [0.014, 0.04, W - 0.04]), box([L * 0.5 - 0.03, 0.035, 0], [0.014, 0.02, W - 0.04])]
    streaks = [box([-0.5 + 0.22 * k, 0.037, -0.2 + 0.13 * (k % 4)], [0.7, 0.002, 0.03 + 0.012 * (k % 3)], [0, 0, slope]) for k in range(7)]
    top["dress"] = [dress(TIN, liner + rim),
                    dress("prop:plate_iron", streaks[::2]),    # dark streaks where the fluids ran to the drain
                    dress("prop:hide_pale", streaks[1::2]),    # pale bloom where it dried

                    lathe(IRON, [[0.0, -0.04], [0.04, -0.04], [0.04, 0.0], [0.0, 0.0]], at=[L * 0.5 - 0.08, 0.036, 0], seg=8),  # the drain's rose
                    dress(TIN, [box([L * 0.5 - 0.08, -0.17, 0.0], [0.045, 0.3, 0.045])])]  # the drain pipe down to the pail
    ms.append(top)
    return prop("embalming_table", "The embalming table (#1181; the period note: 1880s tables were wood, porcelain is 1890s on): 1.9 m by 0.62, 0.84 high, planed pine boards, a top lined with sheet zinc and sloped a degree to a drain at the foot (+x), a zinc rim along the sides and head (the zinc dull, streaked dark and pale: it has been used),  a drain pipe down to where a pail stands (`zinc_pail`). Head at -x. 10 physics bodies. Written by tools/props/undertaker.py.",
                ms, wood="weathered_pine", splits_below=0.4)


def zinc_pail():
    p = member("pail", "post", [0.28, 0.26, 0.28], [0, 0.13, 0], look=TIN, wood="iron")
    p["draw"] = {"shape": "lathe", "profile": [[0.0, 0.0], [0.11, 0.0], [0.14, 0.26], [0.125, 0.26], [0.0, 0.01]], "segments": 12}
    p["dress"] = [lathe(IRON, [[0.145, 0.25], [0.145, 0.265], [0.13, 0.265], [0.13, 0.25]], seg=12),
                  lathe("prop:hide_dark", [[0.0, 0.03], [0.1, 0.035], [0.128, 0.2], [0.13, 0.215], [0.12, 0.215], [0.0, 0.07]], seg=12),  # stained inside: a dark tide-line and a brown skin at the bottom
                  lathe("prop:hide_pale", [[0.0, 0.075], [0.105, 0.075], [0.105, 0.08], [0.0, 0.08]], seg=12),  # the pinkish dregs
                  dress(IRON, [stick([-0.14, 0.26, 0], [0.0, 0.36, 0], 0.01), stick([0.0, 0.36, 0], [0.14, 0.26, 0], 0.01)])]
    return prop("zinc_pail", "A zinc pail (#1181) under the embalming table's drain, a bail over its rim, stained brown inside with a tide-line and a pinkish dregs at the bottom (Sean's add-on). 1 physics body. Written by tools/props/undertaker.py.",
                [p], wood="iron")


def _board_legs(L, H, W, tag, look=RAW):
    ms = []
    for k, x in enumerate((-L * 0.5 + 0.25, L * 0.5 - 0.25)):
        for s, n in ((-1, "a"), (1, "b")):
            ms.append(member("leg_%s%d%s" % (tag, k, n), "post", [0.06, H, 0.05], [x, H * 0.5 - 0.02, s * (W * 0.5 - 0.03)], look=look, rot=[-s * 9.0, 0, 0]))
        ms.append(member("cross_%s%d" % (tag, k), "furniture_frame", [0.05, 0.04, W + 0.04], [x, H - 0.05, 0], look=look))
    return ms


def cooling_board(sheet=False, tag="cooling_board"):
    L, W, H = 1.9, 0.42, 0.7
    ms = _board_legs(L, H, W, "c")
    boards = member("slats", "furniture_top", [L, 0.03, W], [0, H, 0], look=PINE_TOP)
    boards["draw"] = {"shape": "boxes", "boxes": [box([-L * 0.5 + 0.075 + k * (L - 0.15) / 12.0, 0, 0], [0.11, 0.03, W]) for k in range(13)]}
    ms.append(boards)
    ms.append(member("head_block", "trim", [0.2, 0.07, 0.3], [-L * 0.5 + 0.2, H + 0.05, 0], look=PINE, wood="weathered_pine"))
    if sheet:
        y = H + 0.015
        s = member("sheet", "trim", [1.8, 0.2, 0.5], [0.05, y + 0.1, 0], wood="canvas", look=CLOTH)
        # A sheet over a long form: the hump of head, chest, hips, knees and feet (a form, not a figure: the sheet's lumps).
        s["draw"] = {"shape": "boxes", "boxes": [box([-0.78, 0.09, 0], [0.26, 0.15, 0.24]), box([-0.45, 0.1, 0], [0.42, 0.16, 0.46]),
                                                  box([0.02, 0.08, 0], [0.5, 0.11, 0.34]), box([0.5, 0.09, 0], [0.5, 0.13, 0.28]),
                                                  box([0.92, 0.08, 0], [0.24, 0.1, 0.22]), box([0, 0.005, 0], [1.9, 0.01, 0.56])]}
        s["dress"] = [dress("prop:hide_dark", [box([-0.45, 0.185, 0.0], [0.16, 0.004, 0.14]), box([0.05, 0.145, 0.06], [0.2, 0.004, 0.12]),
                                                box([0.5, 0.165, -0.03], [0.12, 0.004, 0.16]), box([-0.1, 0.17, -0.12], [0.07, 0.004, 0.1])]),
                      dress("prop:hide_pale", [box([-0.42, 0.188, 0.02], [0.3, 0.003, 0.26]), box([0.52, 0.168, 0.0], [0.26, 0.003, 0.24])])]  # stained through in patches, pinkish at the edges
        ms.append(s)
    doc = "The cooling board (#1181; the period's: a board of slats on folding legs a body lay on to be cooled and washed before the coffin; refs Renouard 1878): %.1f m by %.2f, %.2f high, thirteen slats of pine on four splayed legs, a head block. " % (L, W, H)
    if sheet:
        doc += "A body under a sheet, the sheet stained through in patches: only the sheet, a form of lumps over the slats (nothing under it). "
    return prop(tag, doc + "%d physics bodies. Written by tools/props/undertaker.py." % len(ms), ms, wood="weathered_pine")


def sheeted_board():
    return cooling_board(True, "sheeted_board")


def embalming_pump():
    ms = []
    for sx, sz in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        ms.append(member("leg%d" % len(ms), "post", [0.045, 0.62, 0.045], [sx * 0.22, 0.31, sz * 0.17], look=RAW))
    ms.append(member("top", "furniture_top", [0.56, 0.03, 0.44], [0, 0.635, 0], look=PINE_TOP))
    pump = member("pump", "trim", [0.09, 0.3, 0.09], [-0.12, 0.8, 0.02], look=IRON, wood="iron")
    pump["draw"] = {"shape": "lathe", "profile": [[0.0, -0.15], [0.045, -0.15], [0.045, 0.1], [0.03, 0.15], [0.0, 0.15]], "segments": 10}
    pump["dress"] = [dress(IRON, [stick([-0.12, 0.2, 0.02], [0.0, 0.23, 0.02], 0.014), stick([0.0, 0.23, 0.02], [0.12, 0.36, 0.02], 0.014)]),  # the handle's lever
                     dress("prop:leather", [stick([-0.06, -0.12, 0.04], [0.1, -0.15, 0.1], 0.016), stick([0.1, -0.15, 0.1], [0.2, -0.1, 0.1], 0.016)])]  # the red rubber tubes
    ms.append(pump)
    jar = member("jar", "glass", [0.16, 0.26, 0.16], [0.14, 0.78, 0.0], look="glass:aqua", wood="glass")
    jar["draw"] = {"shape": "lathe", "profile": [[0.0, -0.13], [0.07, -0.13], [0.08, -0.08], [0.08, 0.08], [0.05, 0.12], [0.045, 0.13], [0.0, 0.13]], "segments": 12}
    ms.append(jar)
    jar2 = member("bottle", "glass", [0.1, 0.22, 0.1], [0.2, 0.75, 0.16], look="glass:amber", wood="glass")
    jar2["draw"] = {"shape": "lathe", "profile": [[0.0, -0.11], [0.045, -0.11], [0.05, 0.02], [0.02, 0.07], [0.02, 0.11], [0.0, 0.11]], "segments": 10}
    ms.append(jar2)
    return prop("embalming_pump", "The embalmer's stand (#1181; arterial embalming by hand pump spread after the Civil War, Renouard 1878): a small pine table 0.64 high with a hand force-pump on it (an iron barrel, a lever handle, red rubber tubes), a glass jar of fluid and an amber bottle. The glass breaks as a member. 8 physics bodies. Written by tools/props/undertaker.py.",
                ms, wood="weathered_pine")


def carboy():
    base = member("cradle", "post", [0.36, 0.09, 0.36], [0, 0.045, 0], look=RAW, wood="weathered_pine")
    base["dress"] = [dress(RAW, [box([s * 0.15, 0.2, z * 0.15], [0.02, 0.28, 0.02]) for s in (-1, 1) for z in (-1, 1)])]
    c = member("carboy", "glass", [0.36, 0.5, 0.36], [0, 0.34, 0], look="glass:green", wood="glass")
    c["draw"] = {"shape": "lathe", "profile": [[0.0, -0.25], [0.14, -0.25], [0.18, -0.12], [0.18, 0.08], [0.1, 0.2], [0.05, 0.22], [0.05, 0.25], [0.0, 0.25]], "segments": 12}
    c["dress"] = [dress(RAW, [box([0.0, 0.26, 0.0], [0.06, 0.03, 0.06])])]  # its stopper
    return prop("carboy", "A carboy (#1181): a green glass demijohn of embalming fluid (arsenic or zinc chloride in the 1880s), 36 cm across, set in a wooden cradle with slat posts. Breaks as a member and the fluid is lost. 2 physics bodies. Written by tools/props/undertaker.py.",
                [base, c], wood="weathered_pine")


def _shelf_unit(tag, contents):
    W, D, H = 1.0, 0.34, 1.9
    ms = []
    for s, n in ((-1, "l"), (1, "r")):
        ms.append(member("side_" + n, "post", [0.04, H, D], [s * (W * 0.5 - 0.02), H * 0.5, 0], look=RAW))
    ys = [0.1, 0.65, 1.2, 1.75]
    for k, y in enumerate(ys):
        ms.append(member("shelf%d" % k, "furniture_top", [W - 0.04, 0.03, D], [0, y, 0], look=RAW))
    ms += contents(ys, W, D)
    return ms


def fluids_shelf():
    def jars(ys, W, D):
        ms = []
        for k, y in enumerate(ys[1:3]):
            for i, (tint, x) in enumerate((("aqua", -0.3), ("amber", 0.0), ("clear", 0.28))):
                j = member("jar%d_%d" % (k, i), "glass", [0.14, 0.26 if k else 0.2, 0.14], [x, y + 0.015 + (0.13 if k else 0.1), 0.0], look="glass:" + tint, wood="glass")
                j["draw"] = {"shape": "lathe", "profile": [[0.0, -0.1], [0.06, -0.1], [0.07, -0.05], [0.07, 0.05], [0.04, 0.09], [0.04, 0.1], [0.0, 0.1]], "segments": 10}
                ms.append(j)
        return ms
    return prop("fluids_shelf", "The embalmer's shelf (#1181): raw pine uprights and four boards, glass jars and bottles of fluids, aqua, amber and clear flint, on the middle two. 16 physics bodies; the jars break. Written by tools/props/undertaker.py.",
                _shelf_unit("fluids", jars), wood="weathered_pine")


def shroud_shelf():
    def shrouds(ys, W, D):
        ms = []
        for k, y in enumerate((ys[1], ys[2])):
            for i, x in enumerate((-0.2, 0.22)):
                for j, kind in enumerate(("post", "furniture_top")):
                    ms.append(member("shroud%d_%d_%d" % (k, i, j), "trim", [0.4, 0.07, 0.3], [x, y + 0.015 + 0.035 + 0.07 * j, 0], wood="canvas", look=CLOTH))
        return ms
    ms = _shelf_unit("shroud", shrouds)
    return prop("shroud_shelf", "The shroud shelf (#1181): pine uprights and four boards, shrouds of white muslin folded in pairs on the middle two (the burial shroud was the undertaker's stock: a plain white gown folded flat). 16 physics bodies. Written by tools/props/undertaker.py.",
                ms, wood="weathered_pine")


# --- Ice and the corpse cooler ---------------------------------------------------------------------
def _ice(id_, size, at, kind="trim"):
    return member(id_, kind, size, at, wood="stone", look="glass:aqua")


def ice_bin():
    L, W, H = 1.3, 0.9, 0.72
    ms = [member("floor", "post", [L, 0.04, W], [0, 0.02, 0], look=RAW)]
    for s, n in ((-1, "b"), (1, "f")):
        ms.append(member("wall_" + n, "furniture_frame", [L, H, 0.04], [0, 0.04 + H * 0.5, s * (W * 0.5 - 0.02)], look=RAW))
    for s, n in ((-1, "w"), (1, "e")):
        ms.append(member("end_" + n, "furniture_frame", [0.04, H, W - 0.08], [s * (L * 0.5 - 0.02), 0.04 + H * 0.5, 0], look=RAW))
    ms.append(member("sawdust", "furniture_top", [L - 0.12, 0.2, W - 0.12], [0, 0.04 + 0.1, 0], wood="hay", look="prop:straw"))
    for k, (x, z) in enumerate(((-0.3, -0.2), (0.15, -0.2), (-0.3, 0.2), (0.15, 0.2))):
        ms.append(_ice("block%d" % k, [0.4, 0.36, 0.36], [x, 0.24 + 0.18, z], "trim"))
    ms.append(_ice("chip", [0.4, 0.2, 0.3], [0.2, 0.24 + 0.36 + 0.1, 0.0]))
    return prop("ice_bin", "The ice bin (#1181; ice cut in winter and kept in sawdust, the period note): a pine box 1.3 by 0.9 by 0.72, a bed of sawdust, blocks of ice 40 by 36 by 36 cm packed in it and a block on top; wet through the planks. The ice is members (they don't burn). 10 physics bodies. Written by tools/props/undertaker.py.",
                ms, wood="weathered_pine")


def corpse_cooler():
    L, W, H = 2.15, 0.66, 0.42
    y0 = 0.46
    ms = []
    for k, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        ms.append(member("leg%d" % k, "post", [0.07, y0, 0.07], [sx * (L * 0.5 - 0.06), y0 * 0.5, sz * (W * 0.5 - 0.06)], look=PINE))
    ms.append(member("floor", "furniture_frame", [L, 0.04, W], [0, y0 + 0.02, 0], look=PINE))
    for s, n in ((-1, "b"), (1, "f")):
        ms.append(member("wall_" + n, "furniture_top", [L, H, 0.03], [0, y0 + 0.04 + H * 0.5, s * (W * 0.5 - 0.015)], look=PINE, wood="weathered_pine"))
    for s, n in ((-1, "w"), (1, "e")):
        ms.append(member("end_" + n, "furniture_top", [0.03, H, W - 0.06], [s * (L * 0.5 - 0.015), y0 + 0.04 + H * 0.5, 0], look=PINE, wood="weathered_pine"))
    pan = member("ice_pan", "trim", [0.8, 0.06, 0.5], [0.15, y0 + 0.04 + 0.03, 0], look=TIN, wood="iron")
    pan["dress"] = [dress(TIN, [box([0, 0.03, s * 0.25], [0.8, 0.1, 0.012]) for s in (-1, 1)] + [box([s * 0.4, 0.03, 0], [0.012, 0.1, 0.5]) for s in (-1, 1)])]
    ms.append(pan)
    ms.append(_ice("ice1", [0.34, 0.18, 0.4], [-0.02, y0 + 0.04 + 0.06 + 0.09, 0.0]))
    ms.append(_ice("ice2", [0.3, 0.16, 0.38], [0.34, y0 + 0.04 + 0.06 + 0.08, 0.0]))
    ms[4]["dress"] = [dress(TIN, [box([L * 0.5 - 0.3, -y0 * 0.5, 0.0], [0.04, y0 - 0.1, 0.04])])]  # the drain pipe, down from the floor's board
    return prop("corpse_cooler", "The corpse cooler (#1181; sold from the 1870s, the period note: a box with an ice pan over the chest): a pine case 2.15 m by 0.66 raised on four legs, lined with zinc (the sheet drawn as the pan and its rim), a tin pan on the chest and two blocks of ice in it, a drain at the foot (+x). Open, its lid off. 18 physics bodies. Written by tools/props/undertaker.py.",
                ms, wood="weathered_pine")


# --- Coffin racks, the safety coffin, the posing stand, the wreath ----------------------------------
def coffin_rack():
    L, D = 2.3, 0.78
    ms = []
    for sx in (-1, 1):
        for sz in (-1, 1):
            ms.append(member("post%d%d" % (sx > 0, sz > 0), "post", [0.08, 1.55, 0.08], [sx * (L * 0.5 - 0.04), 0.775, sz * (D * 0.5 - 0.04)], look=RAW))
    for j, y in enumerate((0.3, 1.0)):
        for s, n in ((-1, "b"), (1, "f")):
            ms.append(member("rail%d%s" % (j, n), "furniture_frame", [L - 0.16, 0.08, 0.05], [0, y - 0.04, s * (D * 0.5 - 0.04)], look=RAW))
        for k, x in enumerate((-0.7, 0.7)):
            ms.append(member("bearer%d%d" % (j, k), "furniture_top", [0.08, 0.04, D - 0.08], [x, y + 0.02, 0], look=RAW))
    return prop("coffin_rack", "A coffin rack (#1181): four 8 cm posts, two tiers of side rails with two bearers across each, its tiers' tops at 0.34 and 1.04 m for coffins lying along it; raw pine. Under the cellar's 2.26 m. 16 physics bodies. Written by tools/props/undertaker.py.",
                ms, wood="weathered_pine")


def safety_coffin():
    ms, L, W = _coffin_members(RECT, RECT_H, WALNUT, WALNUT_TOP, True, True, 3, "safety")
    px = -1.2
    for s, n in ((-1, "a"), (1, "b")):
        ms.append(member("post_" + n, "post", [0.06, 1.3, 0.06], [px, 0.65, s * 0.38], look=RAW, wood="weathered_pine"))
    ms.append(member("beam", "furniture_top", [0.07, 0.07, 0.88], [px, 1.3 + 0.035, 0.0], look=RAW, wood="weathered_pine"))
    ms[-1]["dress"] = [lathe(BRASS, [[0.0, -0.0], [0.03, -0.005], [0.05, -0.04], [0.07, -0.14], [0.055, -0.14], [0.0, -0.07]], at=[0, 0, 0], seg=12),  # the bell hung under the beam
                       dress(IRON, [box([0, -0.15, 0], [0.012, 0.06, 0.012])])]
    ms[ms.index(next(m for m in ms if m["id"] == "lid"))]["dress"].append(dress(BLACK_CLOTH, [stick([-0.85, 0.5, 0.0], [px + 0.02, 1.15, 0.0], 0.008)]))  # the cord from the hand to the bell
    return prop("safety_coffin", "A safety coffin on its frame (#1181; Vester's patent 1868 and the many after: a cord from the dead man's hand up through the lid to a bell on a frame at the grave's head): a rectangular casket and, at its head (-x), a frame of two posts and a beam with a brass bell hung from it, a black cord from the lid to the clapper. The undertaker's sample (the period fear of being buried alive: plausible, not common). 15 physics bodies. Written by tools/props/undertaker.py.",
                ms, wood="walnut", splits_below=0.5)


def posing_stand():
    ms = []
    for k, a in enumerate((0, 120, 240)):
        c, s = math.cos(math.radians(a)), math.sin(math.radians(a))
        ms.append(member("foot%d" % k, "post", [0.04, 0.03, 0.3], [c * 0.14, 0.015, s * 0.14], look=IRON, wood="iron", rot=[0, -a + 90, 0]))
    ms.append(member("rod", "furniture_frame", [0.03, 1.4, 0.03], [0, 0.73, 0], look=IRON, wood="iron"))
    ms.append(member("clamp", "furniture_top", [0.18, 0.04, 0.05], [0.08, 1.35, 0.0], look=IRON, wood="iron"))
    ms.append(member("rest", "trim", [0.03, 0.1, 0.14], [0.17, 1.38, 0.0], look=IRON, wood="iron"))
    return prop("posing_stand", "The photographer's posing stand (#1181; the period note: iron stands held the living sitter still for a long exposure; never with a body): three splayed iron feet, a rod to 1.4 m, a clamp and a head rest at the back of the sitter's head. 6 physics bodies. Written by tools/props/undertaker.py.",
                ms, wood="iron")


def posing_chair():
    ms = []
    for sx, sz in ((1, -1), (1, 1)):
        ms.append(member("leg%d" % len(ms), "post", [0.045, 0.45, 0.045], [sx * 0.2, 0.225, sz * 0.2], look=WALNUT))
    for sz in (-1, 1):  # the back legs run up as the back posts
        ms.append(member("back_post%d" % (sz > 0), "post", [0.045, 1.05, 0.045], [-0.2, 0.525, sz * 0.2], look=WALNUT))
    ms.append(member("seat", "furniture_top", [0.5, 0.05, 0.5], [0, 0.475, 0], look=WALNUT_TOP))
    ms.append(member("back_rail", "furniture_frame", [0.04, 0.16, 0.36], [-0.2, 0.92, 0.0], look=WALNUT_TOP))
    drape = member("drape", "trim", [0.26, 0.46, 0.46], [-0.19, 0.84, 0.0], wood="canvas", look=BLACK_CLOTH)
    drape["draw"] = {"shape": "boxes", "boxes": [box([-0.0, 0.1, 0], [0.04, 0.46, 0.44]), box([0.06, -0.1, 0], [0.2, 0.025, 0.4])]}
    ms.append(drape)
    return prop("posing_chair", "The sitter's chair (#1181; the photographer's): a walnut parlour chair with a dark cloth thrown over its back, set before the posing stand. Empty. 9 physics bodies. Written by tools/props/undertaker.py.",
                ms, wood="walnut")


def hair_wreath():
    W = 0.5
    frame = member("frame", "post", [W, W, 0.07], [0, 0, 0.035], look=WALNUT, wood="walnut")
    frame["draw"] = {"shape": "boxes", "boxes": [box([0, W * 0.5 - 0.03, 0], [W, 0.06, 0.07]), box([0, -W * 0.5 + 0.03, 0], [W, 0.06, 0.07]),
                                                  box([-W * 0.5 + 0.03, 0, 0], [0.06, W - 0.12, 0.07]), box([W * 0.5 - 0.03, 0, 0], [0.06, W - 0.12, 0.07])]}
    wreath = member("wreath", "furniture_frame", [0.36, 0.36, 0.03], [0, 0, 0.04], wood="hay", look=BLACK_CLOTH)
    wreath["draw"] = {"shape": "lathe", "profile": [[0.12, 0.0], [0.16, 0.015], [0.19, 0.0], [0.16, -0.015]], "segments": 18, "rot": [90, 0, 0]}
    wreath["dress"] = [lathe("prop:burl", [[0.14, 0.008], [0.15, 0.02], [0.17, 0.008]], seg=10, rot=[90, 0, 0])]
    glass = member("glass", "glass", [W - 0.1, W - 0.1, 0.006], [0, 0, 0.066], look=GLASS, wood="glass")
    return prop("hair_wreath", "A hair wreath under glass (#1181; Victorian mourning work, a wreath of a family's hair woven over wire in loops and flowers, framed in a deep walnut shadow box; period-true): 50 cm square, a glass front. Hung on a nail. 3 physics bodies. Written by tools/props/undertaker.py.",
                [frame, wreath, glass], wood="walnut", hangs={"nails": [[0.0, 0.2, 0.0]]}, drawn_bounds=True)


def iron_lantern():
    ms = [member("hook", "post", [0.03, 0.12, 0.03], [0, 0.46, 0], look=IRON, wood="iron")]
    ms.append(member("frame", "furniture_frame", [0.16, 0.3, 0.16], [0, 0.25, 0], look=IRON, wood="iron",
                     draw={"shape": "boxes", "boxes": [box([sx * 0.07, 0, sz * 0.07], [0.012, 0.3, 0.012]) for sx in (-1, 1) for sz in (-1, 1)]
                           + [box([0, 0.15, 0], [0.16, 0.012, 0.16]), box([0, -0.15, 0], [0.16, 0.012, 0.16]), box([0, 0.18, 0], [0.1, 0.05, 0.1])]}))
    ms.append(member("pane", "glass", [0.13, 0.22, 0.13], [0, 0.25, 0], look="glass:amber", wood="glass"))
    return prop("iron_lantern", "A cellar lantern (#1181): a sheet-iron frame with a pierced cap and a ring, a glass chimney lamp inside; hung by its ring on the joist's hook (`hangs`: its nail at the top). Hangs still: its swing isn't simulated. 3 physics bodies. Written by tools/props/undertaker.py.",
                ms, wood="iron", hangs={"nails": [[0.0, 0.52, 0.0]]}, drawn_bounds=True)


# --- The box hearse and the stall -------------------------------------------------------------------
def hearse():
    spec = {"axles": [-1.2, 1.2], "wheels": [0.56, 0.66], "track": 1.45, "bed_y": 0.95, "bed_width": 1.2, "bed_length": 3.4,
            "floor_boards": 6, "side_boards": 1, "side_height": 0.04, "stakes": 0, "tongue": 2.6}
    ms = wagons.wagon(spec)
    # What the wagon builder put on the deck: its sideboards and ends (kept as the deck's skirt) go; the body replaces them.
    ms = [m for m in ms if not (m["id"].startswith("side_") or m["id"].endswith("_board0"))]
    top = 0.95 + 0.025
    L, W = 2.7, 1.2
    bx = 0.35
    # Black panels along the foot of the body, then the glass between corner posts to the roof's rail.
    for s, n in ((-1, "l"), (1, "r")):
        ms.append(member("skirt_" + n, "trim", [L, 0.45, 0.03], [bx, top + 0.225, s * (W * 0.5 - 0.015)], look=EBONY, wood="weathered_pine"))
    ms.append(member("skirt_rear", "trim", [0.03, 0.45, W - 0.06], [bx + L * 0.5 - 0.015, top + 0.225, 0], look=EBONY, wood="weathered_pine"))
    ms.append(member("skirt_front", "trim", [0.03, 0.45, W - 0.06], [bx - L * 0.5 + 0.015, top + 0.225, 0], look=EBONY, wood="weathered_pine"))
    H = 1.45
    for sx in (-1, 1):
        for sz in (-1, 1):
            ms.append(member("post%d%d" % (sx > 0, sz > 0), "trim", [0.07, H, 0.07], [bx + sx * (L * 0.5 - 0.035), top + 0.45 + H * 0.5, sz * (W * 0.5 - 0.035)], look=EBONY, wood="weathered_pine"))
    for k, x in enumerate((-0.45, 0.55)):
        for s, n in ((-1, "l"), (1, "r")):
            ms.append(member("glass_%s%d" % (n, k), "glass", [0.95, 1.2, 0.008], [bx + x, top + 0.45 + 0.6, s * (W * 0.5 - 0.02)], look=GLASS, wood="glass"))
    ms.append(member("glass_rear", "glass", [0.008, 1.2, W - 0.2], [bx + L * 0.5 - 0.02, top + 0.45 + 0.6, 0], look=GLASS, wood="glass"))
    roof = member("roof", "trim", [L + 0.3, 0.06, W + 0.3], [bx, top + 0.45 + H + 0.03, 0], look=EBONY, wood="weathered_pine")
    roof["dress"] = [dress(EBONY, [box([bx * 0, 0.06, 0], [L - 0.2, 0.05, W - 0.2]), box([0, 0.1, 0], [L - 0.6, 0.04, W - 0.6])]),  # the roof's crown
                     dress(BRASS, [box([x, 0.0, s * (W * 0.5 + 0.15)], [0.02, 0.04, 0.012]) for x in (-1.1, -0.35, 0.35, 1.1) for s in (-1, 1)])]  # lamps' brass drops along the fringe
    ms.append(roof)
    for sx in (-1, 1):
        for sz in (-1, 1):
            ms.append(member("plume%d%d" % (sx > 0, sz > 0), "trim", [0.14, 0.36, 0.14], [bx + sx * (L * 0.5), top + 0.45 + H + 0.06 + 0.18, sz * (W * 0.5 - 0.02)], look=BLACK_CLOTH, wood="canvas",
                             draw={"shape": "lathe", "profile": [[0.0, -0.18], [0.04, -0.18], [0.05, -0.1], [0.02, -0.05], [0.07, 0.0], [0.08, 0.1], [0.03, 0.18], [0.0, 0.18]], "segments": 8}))
    # The driver's box: a seat on two risers at the front with a dash before it.
    ms.append(member("seat", "trim", [0.45, 0.04, W - 0.1], [bx - L * 0.5 - 0.15, top + 0.52, 0], look=EBONY, wood="weathered_pine"))
    for s in (-1, 1):
        ms.append(member("riser%d" % (s > 0), "trim", [0.4, 0.5, 0.04], [bx - L * 0.5 - 0.15, top + 0.25, s * (W * 0.5 - 0.1)], look=EBONY, wood="weathered_pine"))
    ms.append(member("dash", "trim", [0.03, 0.5, W - 0.05], [bx - L * 0.5 - 0.35, top + 0.25, 0], look=EBONY, wood="weathered_pine", rot=[0, 0, -12]))
    return prop("hearse", "The box hearse (#1181; Habenstein and Lamers 1955: the glass-sided box hearse of the 1870s-80s, black, plumes at its corners, a driver's box before it; Concord and the Sayers & Scovill hearse catalogues): the buckboard's running gear stretched (12-spoke wheels with iron tyres, oak axles, bolsters, reach, tongue) under a deck of pine boards; on it a black body %.1f m by %.1f, black panels to knee height, four corner posts, glass in the sides and rear, a black roof with a crown and brass drops, a plume in a black cup at each corner, and the driver's box. Needs level ground (a kit prop's feet all sit at its origin's height: on the yard's 3.4 cm/m fall it tips loose), so it isn't placed yet. Written by tools/props/undertaker.py." % (L, W),
                ms, wood="oak", look=wagons.GEAR_LOOK, splits_below=0.4)


def harness_rack():
    back = member("board", "post", [0.9, 0.9, 0.04], [0, 0, 0.02], look=PINE, wood="weathered_pine")
    collar = member("collar", "furniture_frame", [0.46, 0.56, 0.1], [-0.18, 0.0, 0.09], look="prop:leather", wood="leather")
    collar["draw"] = {"shape": "lathe", "profile": [[0.15, 0.0], [0.2, 0.04], [0.23, 0.0], [0.2, -0.04]], "segments": 14, "rot": [90, 0, 0], "at": [0, 0, 0]}
    collar["dress"] = [dress(IRON, [stick([-0.12, 0.26, 0.0], [-0.12, 0.34, 0.0], 0.02), stick([0.12, 0.26, 0.0], [0.12, 0.34, 0.0], 0.02)])]  # the hames' tips
    bridle = member("bridle", "trim", [0.3, 0.55, 0.04], [0.25, 0.0, 0.07], look="prop:leather", wood="leather")
    bridle["draw"] = {"shape": "boxes", "boxes": [stick([0.0, 0.25, 0], [0.0, -0.1, 0], 0.025), stick([-0.1, 0.0, 0], [0.1, 0.0, 0], 0.02), stick([-0.1, 0.0, 0], [-0.1, -0.2, 0], 0.02),
                                                   stick([0.1, 0.0, 0], [0.1, -0.2, 0], 0.02), stick([-0.1, -0.2, 0], [0.1, -0.2, 0], 0.012)]}
    bridle["dress"] = [dress(IRON, [box([0, -0.2, 0], [0.2, 0.015, 0.015])])]  # the bit
    return prop("harness_rack", "The stall's harness (#1181; the horse's tack, Montgomery Ward 1880s): a pine board with a leather horse collar over its hames and a bridle with its bit hung on pegs; for the hearse shed's stall. 3 physics bodies. Written by tools/props/undertaker.py.",
                [back, collar, bridle], wood="weathered_pine", hangs={"nails": [[-0.4, 0.4, 0.004], [0.4, 0.4, 0.004]]}, drawn_bounds=True)


def sawdust(tag, size, look, wet):
    """A heap of sawdust on the cellar's flags: a low flat mound (members of kind post lie flat like a floor board),
    pale where swept into a corner, dark where fluids were soaked up. Small: the building's history (#1187) lays
    stains round the props, so the table's feet get a heap each and the floor between is left clear."""
    w, d = size
    m = member("heap", "post", [w, 0.05, d], [0, 0.025, 0], wood="hay", look=look)
    m["draw"] = {"shape": "boxes", "boxes": [box([0, 0.012, 0], [w, 0.024, d]), box([0.02, 0.032, -0.01], [w * 0.7, 0.03, d * 0.7]),
                                              box([-0.03, 0.047, 0.01], [w * 0.4, 0.02, d * 0.4])]}
    return prop(tag, "A heap of sawdust on the cellar floor (#1181, Sean's add-on): %s %.2f by %.2f m, %s. 1 physics body. Written by tools/props/undertaker.py." % (
        "dark and soaked, where fluids were mopped up under the table" if wet else "pale, swept into a corner", w, d, "three flat layers of loose sawdust, not a pile"), [m], wood="hay")


def sawdust_wet():
    return sawdust("sawdust_wet", (0.42, 0.42), "prop:dung", True)


def sawdust_pale():
    return sawdust("sawdust_pale", (0.55, 0.4), "prop:straw", False)


def rags():
    m = member("rags", "post", [0.4, 0.05, 0.3], [0, 0.025, 0], wood="canvas", look=CLOTH)
    m["draw"] = {"shape": "boxes", "boxes": [box([0, 0.012, 0], [0.36, 0.024, 0.26], [0, 8, 0]), box([0.04, 0.034, 0.02], [0.26, 0.02, 0.2], [0, -22, 0]), box([-0.05, 0.048, -0.02], [0.16, 0.018, 0.12], [0, 35, 0])]}
    m["dress"] = [dress("prop:hide_dark", [box([0.06, 0.044, 0.03], [0.1, 0.003, 0.08], [0, -22, 0])]), dress("prop:hide_pale", [box([-0.09, 0.058, -0.02], [0.1, 0.003, 0.07], [0, 35, 0])])]
    return prop("rags", "Rags (#1181, Sean's add-on): three cotton cloths dropped in a heap by the embalming table's pail, one stained brown, one pink at the edge. 1 physics body. Written by tools/props/undertaker.py.", [m], wood="canvas")


def mop_pail():
    p = member("pail", "post", [0.34, 0.3, 0.34], [0, 0.15, 0], look="prop:dark_wood", wood="oak")
    p["draw"] = {"shape": "lathe", "profile": [[0.0, 0.0], [0.13, 0.0], [0.16, 0.3], [0.145, 0.3], [0.0, 0.015]], "segments": 12}
    p["dress"] = [lathe("prop:hide_pale", [[0.0, 0.2], [0.15, 0.2], [0.15, 0.205], [0.0, 0.205]], seg=12),  # the water, pinkish
                  dress(IRON, [box([0, 0.08, 0], [0.34, 0.012, 0.34]), box([0, 0.24, 0], [0.33, 0.012, 0.33])]),  # two hoops
                  dress("prop:dark_wood", [stick([0.02, 0.1, 0.0], [0.05, 1.3, 0.02], 0.026)]),  # the mop's handle, standing in it
                  dress(CLOTH, [box([0.015 + 0.02 * k, 0.17, 0.0 + 0.02 * k], [0.03, 0.22, 0.03], [0, 30 * k, 0]) for k in range(-2, 3)])]  # its head's strands in the water
    return prop("mop_pail", "A mop standing in a bucket of pinkish water (#1181, Sean's add-on): a hooped oak pail, the water pale rose-brown (the mop's been through the embalming room's floor), a mop's handle upright in it and its cloth strands under the surface. Stands by the embalming table. 1 physics body. Written by tools/props/undertaker.py.",
                [p], wood="oak")


BATCH_U1 = [trestles_short, sawdust_wet, sawdust_pale, rags, mop_pail, coffin_hex, coffin_hex_open, coffin_lid, coffin_rect, coffin_child, trestles, bier, workbench, tool_rack, glue_pot,
            plank_stack, embalming_table, zinc_pail, cooling_board, sheeted_board, embalming_pump, carboy, fluids_shelf,
            shroud_shelf, ice_bin, corpse_cooler, coffin_rack, safety_coffin, posing_stand, posing_chair, hair_wreath,
            iron_lantern, hearse, harness_rack]


def main():
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    for make in BATCH_U1:
        if only and make.__name__ not in only:
            continue
        d = make()
        d["factory"] = "tools/props/undertaker.py"
        path = os.path.join(KIT, d["id"] + ".json")
        with open(path, "w") as f:
            json.dump(d, f, indent=2)
            f.write("\n")
        print("wrote", os.path.relpath(path, ROOT), "(%d members)" % len(d.get("members", [])))


if __name__ == "__main__":
    main()
