"""The line shack's own props, batch L1 (#1263; the building is #1091's and #1250's,
experiments/building_lab/line_shack/README.md): a stacked bunk and a single one, the plank bench, the bedroll,
the saddle rack and the saddle, the skillet, the tin plate, a few tin cans, the gun belt and the bridle.
Written from the numbers here, so a change is one number and a re-run:

    python3 tools/props/line_shack.py [--only=bunk,saddle]   # writes assets/props/kit/<id>.json

Members only, like the undertaker's batch (tools/props/undertaker.py, whose helpers it uses): the library's
woods and the kit's bare iron, tin, leather, canvas and straw looks. A prop faces +Z (its front), x along its
width unless said, origin on the floor at its middle; a hung one has its origin on its nail, everything below.
Refs (what each is against): bunks of rough 2x4 and 1x8 as the cow camps and section houses had them, a tick
of straw under one grey blanket (Ramon Adams, Western Words; Montgomery Ward 1895 for the bunk bedstead);
the Texas/Cheyenne roper-style saddle (fork, horn, high cantle, rawhide-covered stirrups of oak; Ward's 1895
stock saddles, 14 in. seat; the Visalia and Main & Winchester catalogues); a cast-iron skillet 10 in. with its
long handle; the enamelled or tinned plate (the "tin plate" of every camp), 9 in.; a tomato can 3 in. by
4 1/2 in., a "tin" with its lid cut out; the 1880s cartridge belt of loops and a plain holster; a headstall
with a curb bit and split reins.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from doctor import KIT, PINE, ROOT, member  # noqa: E402
from undertaker import box, dress, lathe, prop, stick, IRON, RAW, TIN, CLOTH, BRASS, EBONY  # noqa: E402

LEATHER = "prop:leather"
STRAW = "prop:straw"
WOOD = "prop:dark_wood"


def _boards(w, t, L, n, gap=0.006, along="z"):
    """n boards side by side across the width w, each laid the full length L (a bunk's deck, a bench's top)."""
    bw = (w - gap * (n - 1)) / n
    out = []
    for i in range(n):
        x = -w * 0.5 + bw * 0.5 + i * (bw + gap)
        out.append(box([x, 0, 0], [bw, t, L]))
    return out


# --- The bunks ---------------------------------------------------------------------------------------
def _deck(tag, d, W, L, look, tick=True, blanket=0.0, crown=0.0):
    """One bunk deck whose top is at height d: two rails, a floor of eight boards across them (gaps a finger wide), a straw tick (a
    low rumpled pile, narrower than the frame) and, for `blanket` > 0, a grey blanket thrown over its foot end that hangs
    down the sides. The blanket stands off the tick by a hair so the bunk's frame never shows through it."""
    ms = []
    for s, n in ((-1, "l"), (1, "r")):
        ms.append(member("rail_%s_%s" % (tag, n), "furniture_frame", [0.045, 0.15, L], [s * (W * 0.5 - 0.05), d - 0.095, 0], look=RAW))
    board = member("deck_" + tag, "furniture_top", [W - 0.04, 0.025, L], [0, d - 0.0075, 0], look=RAW)
    board["draw"] = {"shape": "boxes", "boxes": _boards(W - 0.04, 0.025, L, 8)}
    ms.append(board)
    top = d + 0.005
    if tick:
        t = member("tick_" + tag, "trim", [W - 0.1, 0.09, L - 0.12], [0, top + 0.045, 0], look=STRAW, wood="hay")
        t["draw"] = {"shape": "boxes", "boxes": [box([0, -0.01, 0], [W - 0.1, 0.07, L - 0.12]), box([0.0, 0.02, -0.05 + crown], [W - 0.2, 0.05, L - 0.4]),
                                                 box([0.0, 0.035, 0.45], [W - 0.26, 0.02, 0.5])]}
        ms.append(t)
    if blanket:
        b = member("blanket_" + tag, "trim", [W - 0.06, 0.03, blanket], [0, top + 0.1, L * 0.5 - 0.1 - blanket * 0.5], look=CLOTH, wood="canvas")
        b["draw"] = {"shape": "boxes", "boxes": [box([0, 0.0, 0], [W - 0.1, 0.012, blanket]), box([0.04, 0.012, 0.03], [W - 0.34, 0.014, blanket - 0.2], [0, 6, 0])]
                     + [box([s * (W * 0.5 - 0.05), -0.07, 0.0], [0.012, 0.15, blanket - 0.04]) for s in (-1, 1)]}
        ms.append(b)
    return ms


def bunk_stacked():
    W, L, H = 0.78, 1.95, 1.62
    ms = []
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        ms.append(member("post%d" % i, "post", [0.075, H, 0.075], [sx * (W * 0.5 - 0.0375), H * 0.5, sz * (L * 0.5 - 0.0375)], look=RAW))
    ms += _deck("low", 0.42, W, L - 0.12, PINE, blanket=1.15)
    ms += _deck("up", 1.2, W, L - 0.12, PINE, blanket=0.0, crown=0.05)
    ms.append(member("head_board", "furniture_frame", [W - 0.08, 0.3, 0.025], [0, 0.78, -(L * 0.5 - 0.05)], look=RAW))
    return prop("bunk_stacked", "Two rough plank bunks, one over the other (#1263; the line shack's: five men in 4.2 by 5 m): four 3 in. posts, side rails of 2x6, a deck of eight 1x8 boards a finger apart, a straw tick on each (the upper pushed up at the head) and a grey wool blanket thrown over the lower one's foot, hanging down its sides. 0.78 m wide, 1.95 long, 1.62 high; the upper deck's top at 1.2 m (a man sits up under the rafters). Head at -z. %d physics bodies. Written by tools/props/line_shack.py." % len(ms),
                ms, wood="weathered_pine", splits_below=0.4)


def bunk():
    W, L = 0.75, 1.9
    ms = []
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        h = 0.64 if sz < 0 else 0.34
        ms.append(member("leg%d" % i, "post", [0.07, h, 0.07], [sx * (W * 0.5 - 0.035), h * 0.5, sz * (L * 0.5 - 0.035)], look=RAW))
    ms += _deck("one", 0.36, W, L - 0.1, PINE, blanket=0.7, crown=-0.08)
    ms.append(member("head_board", "furniture_frame", [W - 0.08, 0.2, 0.025], [0, 0.5, -(L * 0.5 - 0.035)], look=RAW))
    # a rolled coat for a pillow, so the single bunk isn't the stacked one's twin
    ms.append(member("coat", "trim", [0.38, 0.09, 0.22], [0.04, 0.36 + 0.005 + 0.09 + 0.045, -0.7], look=LEATHER, wood="leather"))
    return prop("bunk", "A single plank bunk (#1263; the line shack's, along the east wall under its window): four legs (the head two longer, with a board between), two rails, a deck of eight boards, a straw tick sunk toward the foot, a grey blanket across its lower half and a rolled coat for a pillow. 0.75 m wide, 1.9 long, the deck at 0.36 m. Head at -z. %d physics bodies. Written by tools/props/line_shack.py." % len(ms),
                ms, wood="weathered_pine", splits_below=0.4)


# --- Bench, bedroll ----------------------------------------------------------------------------------
def plank_bench():
    L, W, H = 1.3, 0.26, 0.44
    top = member("top", "furniture_top", [L, 0.04, W], [0, H - 0.02, 0], look=RAW)
    top["draw"] = {"shape": "boxes", "boxes": [box([0, 0, 0], [L, 0.04, W]), box([0.35, 0.021, 0.02], [0.3, 0.002, 0.14], [0, 3, 0])]}  # a worn patch where the seats are
    ms = [top]
    for s, n in ((-1, "w"), (1, "e")):
        for t, z in ((-1, "a"), (1, "b")):
            ms.append(member("leg_%s%s" % (n, z), "post", [0.06, H - 0.04, 0.05], [s * (L * 0.5 - 0.12), (H - 0.04) * 0.5, t * 0.07], look=RAW, rot=[-t * 7.0, 0, 0]))
        ms.append(member("cleat_" + n, "furniture_frame", [0.04, 0.03, W - 0.04], [s * (L * 0.5 - 0.12), 0.2, 0], look=RAW))
    return prop("plank_bench", "A plank bench for the shack's table (#1263): one 1x10 pine board 1.3 m long and 40 mm thick on two splayed pairs of legs 2x3 stock, each pair cleated across; 0.44 m high, 0.26 wide, a worn patch where the men sit. Seats one man a half metre of it. 7 physics bodies. Written by tools/props/line_shack.py.",
                ms, wood="weathered_pine", splits_below=0.4,
                seat={"member": "top", "at": [0.0, H, 0.0], "share": 0.8, "hold": 0.05, "sway": 0.03})


def bedroll():
    roll = member("roll", "post", [0.8, 0.26, 0.28], [0, 0.13, 0], look=CLOTH, wood="canvas")
    roll["draw"] = {"shape": "lathe", "profile": [[0.0, -0.4], [0.12, -0.4], [0.135, -0.38], [0.14, -0.3], [0.14, 0.3], [0.135, 0.38], [0.12, 0.4], [0.0, 0.4]], "segments": 12, "rot": [0, 0, 90]}
    roll["dress"] = [lathe(LEATHER, [[0.145, -0.24], [0.145, -0.22], [0.0, -0.22], [0.0, -0.24]], seg=12, rot=[0, 0, 90]),
                     lathe(LEATHER, [[0.145, 0.22], [0.145, 0.24], [0.0, 0.24], [0.0, 0.22]], seg=12, rot=[0, 0, 90]),
                     lathe("prop:hide_pale", [[0.1, -0.41], [0.1, -0.405], [0.0, -0.405], [0.0, -0.41]], seg=10, rot=[0, 0, 90])]  # the tarp's inner turn showing at one end
    return prop("bedroll", "A bedroll (#1263; the sixth man's, on a bunk's foot or against a wall): a grey wool blanket and a canvas tarp rolled round each other, 0.8 m by 0.28, tied with two leather thongs. The tarp's pale inner turn shows at one end. 1 physics body. Written by tools/props/line_shack.py.",
                [roll], wood="canvas")


# --- The tack ----------------------------------------------------------------------------------------
def saddle_rack():
    L, H = 2.3, 0.85
    ms = []
    for s, n in ((-1, "n"), (1, "s")):
        z = s * (L * 0.5 - 0.1)
        ms.append(member("post_" + n, "post", [0.08, H - 0.02, 0.08], [0, (H - 0.02) * 0.5, z], look=RAW))
        ms.append(member("foot_" + n, "furniture_frame", [0.55, 0.06, 0.07], [0, 0.03 + 0.0, z], look=RAW))
        ms.append(member("brace_" + n, "furniture_frame", [0.04, 0.4, 0.04], [0, 0.4, z - s * 0.12], look=RAW, rot=[-s * 28.0, 0, 0]))
    rail = member("rail", "furniture_frame", [0.1, 0.1, L], [0, H - 0.05 + 0.03, 0], look="prop:dark_wood", wood="juniper")
    rail["draw"] = {"shape": "lathe", "profile": [[0.0, -L * 0.5], [0.045, -L * 0.5], [0.05, -L * 0.5 + 0.05], [0.05, L * 0.5 - 0.05], [0.045, L * 0.5], [0.0, L * 0.5]], "segments": 10, "rot": [90, 0, 0]}
    ms.append(rail)
    return prop("saddle_rack", "A saddle rack for the lean-to (#1263): a juniper pole 2.3 m long, 0.1 thick, resting in two 3 in. posts 0.85 m high on cross feet, each post braced down to its foot. Three saddles sit astride the pole, 0.7 m apart. Along z. 8 physics bodies. Written by tools/props/line_shack.py.",
                ms, wood="juniper", splits_below=0.4)


def saddle():
    # a stock saddle set down on its blanket: front (the horn) at +z, 0.7 m skirt to skirt fore and aft
    blanket = member("blanket", "post", [0.6, 0.025, 0.82], [0, 0.0125, 0], look=CLOTH, wood="canvas")
    blanket["draw"] = {"shape": "boxes", "boxes": [box([0, 0, 0], [0.6, 0.025, 0.82]), box([0.0, 0.0125, 0.0], [0.5, 0.004, 0.7], [0, 2, 0])]}
    skirts = member("skirts", "furniture_top", [0.52, 0.035, 0.66], [0, 0.0425, 0], look=LEATHER, wood="leather")
    skirts["draw"] = {"shape": "boxes", "boxes": [box([s * 0.14, 0, 0.0], [0.24, 0.035, 0.66]) for s in (-1, 1)] + [box([0, 0.01, 0], [0.12, 0.02, 0.5])]}  # the two skirts and the gullet's bar between
    tree = member("seat", "trim", [0.34, 0.3, 0.6], [0, 0.205, 0.0], look=LEATHER, wood="leather")
    tree["draw"] = {"shape": "boxes", "boxes": [
        box([0, -0.07, -0.05], [0.3, 0.05, 0.42]),                    # the seat's leather, dished
        box([0, -0.025, 0.2], [0.26, 0.14, 0.12]),                    # the swell of the fork
        box([0, 0.03, -0.27], [0.32, 0.17, 0.05], [8, 0, 0]),         # the high cantle behind
        box([0, -0.09, -0.12], [0.36, 0.08, 0.2]),                    # the jockeys, wide at the rear
    ]}
    tree["dress"] = [dress(IRON, [stick([0, 0.0, 0.25], [0, 0.09, 0.27], 0.045), box([0, 0.12, 0.27], [0.1, 0.018, 0.1])]),   # the horn and its cap
                     dress(IRON, [box([s * 0.19, -0.06, 0.07], [0.012, 0.012, 0.03]) for s in (-1, 1)]),                       # the rings' hardware
                     dress(WOOD, [box([s * 0.2, -0.11, 0.08], [0.1, 0.012, 0.22], [0, 0, s * 20]) for s in (-1, 1)])]           # the stirrups' leathers folded up over the skirts
    return prop("saddle", "A stock saddle set down on its blanket (#1263; refs: Ward's 1895 catalogue, the Cheyenne roper): a grey blanket, two leather skirts with the gullet's bar between, a dished seat of oiled leather with a high cantle behind and a swelled fork before, an iron horn with its cap, the stirrups' leathers folded up over the skirts. Front (the horn) at +z; 0.82 m fore and aft, 0.6 wide, 0.4 high. Sits flat on the floor or astride a rail. 3 physics bodies. Written by tools/props/line_shack.py.",
                [blanket, skirts, tree], wood="leather", splits_below=0.3)


def bridle():
    head = member("headstall", "post", [0.3, 0.6, 0.03], [0, -0.3, 0.02], look=LEATHER, wood="leather")
    head["draw"] = {"shape": "boxes", "boxes": [stick([0, 0.0, 0], [-0.07, -0.2, 0], 0.022), stick([0, 0.0, 0], [0.07, -0.2, 0], 0.022),   # the crown strap's two cheek pieces
                                                 stick([-0.07, -0.2, 0], [0.07, -0.2, 0], 0.014),                                               # the throatlatch
                                                 stick([-0.07, -0.2, 0], [-0.07, -0.34, 0.01], 0.014), stick([0.07, -0.2, 0], [0.07, -0.34, 0.01], 0.014),
                                                 stick([-0.07, -0.03, 0.0], [-0.12, -0.5, 0.03], 0.012), stick([0.07, -0.03, 0.0], [0.12, -0.5, 0.03], 0.012)]}  # the split reins hanging
    head["dress"] = [dress(IRON, [box([0, -0.34, 0.02], [0.17, 0.014, 0.014]), box([-0.085, -0.38, 0.02], [0.012, 0.075, 0.012]), box([0.085, -0.38, 0.02], [0.012, 0.075, 0.012])])]  # the curb bit and its shanks
    return prop("bridle", "A bridle hung on a peg (#1263; the line shack's, in the lean-to): a leather headstall with its throatlatch, an iron curb bit with shanks, split reins hanging down. Hung by the crown strap on a nail. 1 physics body. Written by tools/props/line_shack.py.",
                [head], wood="leather", hangs={"nails": [[0.0, 0.0, 0.004]]}, drawn_bounds=True)


def gun_belt():
    belt = member("belt", "post", [0.46, 0.4, 0.05], [0, -0.2, 0.025], look=LEATHER, wood="leather")
    belt["draw"] = {"shape": "boxes", "boxes": [stick([-0.04, 0.0, 0.0], [-0.2, -0.28, 0.0], 0.04), stick([0.04, 0.0, 0.0], [0.2, -0.28, 0.0], 0.04),   # the belt's two runs from the peg, drooping
                                                 stick([-0.2, -0.28, 0.0], [0.2, -0.28, 0.0], 0.04)]}
    belt["dress"] = [dress(BRASS, [box([-0.2 + 0.04 * k, -0.28, 0.025], [0.012, 0.03, 0.012]) for k in range(1, 10)]),  # cartridge loops with their brass heads
                     dress(IRON, [box([0.04, 0.0, 0.01], [0.04, 0.03, 0.01])]),                                          # the buckle
                     dress(LEATHER, [box([0.14, -0.4, 0.02], [0.1, 0.22, 0.05], [0, 0, 6])]),                            # the holster
                     dress(EBONY, [box([0.16, -0.27, 0.03], [0.04, 0.09, 0.03], [0, 0, 24])])]                           # the pistol's grip showing above it
    return prop("gun_belt", "A gun belt hung on a peg (#1263; the gang's): a leather belt with a row of brass-headed cartridge loops, a buckle, a right-hand holster hanging low with the grip of a revolver above its mouth. The belt droops in two runs from its peg. 1 physics body. Written by tools/props/line_shack.py.",
                [belt], wood="leather", hangs={"nails": [[0.0, 0.0, 0.004]]}, drawn_bounds=True)


# --- The table's and stove's small things ------------------------------------------------------------
def skillet():
    pan = member("pan", "post", [0.46, 0.055, 0.26], [0, 0.0275, 0], look=IRON, wood="iron")
    pan["draw"] = {"shape": "lathe", "profile": [[0.0, 0.0], [0.1, 0.0], [0.13, 0.05], [0.13, 0.055], [0.12, 0.055], [0.1, 0.012], [0.0, 0.012]], "segments": 14, "at": [-0.1, 0, 0]}
    pan["dress"] = [dress(IRON, [box([0.17, 0.045, 0.0], [0.24, 0.012, 0.03]), box([0.3, 0.048, 0.0], [0.04, 0.02, 0.04])]),   # the long handle and its hanging lug
                    lathe("prop:dung", [[0.0, 0.013], [0.085, 0.013], [0.09, 0.016], [0.0, 0.016]], at=(-0.1, 0, 0), seg=12)]  # cold grease and a burnt skin in the bottom
    return prop("skillet", "A cast-iron skillet (#1263): 10 in. across, a 10 in. handle with a hanging hole, grease gone brown in the bottom. For the stove. 1 physics body. Written by tools/props/line_shack.py.",
                [pan], wood="iron", mass=1.8)


def tin_plate():
    plate = member("plates", "post", [0.24, 0.03, 0.24], [0, 0.015, 0], look=TIN, wood="tin")
    plate["draw"] = {"shape": "lathe", "profile": [[0.0, 0.0], [0.085, 0.0], [0.115, 0.018], [0.12, 0.022], [0.115, 0.022], [0.085, 0.008], [0.0, 0.008]], "segments": 14}
    plate["dress"] = [lathe(TIN, [[0.0, 0.008], [0.07, 0.008], [0.1, 0.026], [0.105, 0.03], [0.1, 0.03], [0.07, 0.016], [0.0, 0.016]], at=(0.012, 0.0, -0.01), seg=14)]  # a second plate stacked, askew
    return prop("tin_plate", "Two tin plates (#1263; the table's): 9 in. across, a rolled rim, one on the other and a little askew, dull grey. 1 physics body. Written by tools/props/line_shack.py.",
                [plate], wood="tin", mass=0.3)


def tin_cans():
    base = member("cans", "post", [0.4, 0.1, 0.3], [0, 0.05, 0], look=TIN, wood="tin")
    base["draw"] = {"shape": "lathe", "profile": [[0.0, 0.0], [0.038, 0.0], [0.04, 0.003], [0.04, 0.1], [0.0, 0.1]], "segments": 10, "at": [-0.12, 0, 0.03]}
    base["dress"] = [lathe(TIN, [[0.0, 0.0], [0.038, 0.0], [0.04, 0.003], [0.04, 0.075], [0.0, 0.075]], at=(0.06, 0, 0.05), seg=10),
                     lathe(TIN, [[0.0, -0.05], [0.04, -0.05], [0.04, 0.05], [0.0, 0.05]], at=(0.0, 0.04, -0.09), seg=10, rot=[0, 0, 90]),   # one lying on its side
                     lathe("prop:dung", [[0.0, 0.09], [0.034, 0.09], [0.034, 0.096], [0.0, 0.096]], at=(-0.12, 0, 0.03), seg=10)]            # the first's rim, dark inside: the lid cut out
    return prop("tin_cans", "Three empty tin cans (#1263; Sean's 'cans everywhere'): a 4 1/2 in. tomato can standing with its lid cut out, a shorter one beside it, a third on its side. Dull grey, a little rust. 1 physics body. Written by tools/props/line_shack.py.",
                [base], wood="tin", mass=0.3)


BATCH_L1 = [bunk_stacked, bunk, plank_bench, bedroll, saddle_rack, saddle, bridle, gun_belt, skillet, tin_plate, tin_cans]


def main():
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    for make in BATCH_L1:
        if only and make.__name__ not in only:
            continue
        d = make()
        d["factory"] = "tools/props/line_shack.py"
        path = os.path.join(KIT, d["id"] + ".json")
        with open(path, "w") as f:
            json.dump(d, f, indent=2)
            f.write("\n")
        print("wrote", os.path.relpath(path, ROOT), "(%d members)" % len(d.get("members", [])))


if __name__ == "__main__":
    main()
