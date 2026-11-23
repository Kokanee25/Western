"""Saloon B's props placed (#950): batches S1, S2 and S3 (#866, #879, #892) written into saloon B's spec
as its `dressing` (config/buildings/saloon_b.json), the route the doctor's office uses
(#844: SpecBuilding._dressing -> PropDressing, so the valley and every lab read one placement). Where each
goes: experiments/prop_lab/README.md "Saloon B, batch S1", "S2", "S3"; docs/briefs/saloon-design.md "The
props B needs". The stage's props (#903) are #941's, room_6 (the dressing room) and the stage #902's.

    python3 tools/props/saloon_b_dress.py      # rewrites the spec's dressing, the bar's line and the use points it moves

Spec space: x from the yard (east) wall, z back from Main Street, the dressing's y over the ground floor
(0.95 over the walk's edge); a prop faces +Z at facing 0 (facing 90: +Z turned to +X). The bar moves 0.5 m
off the back bar (x 1.75 -> 2.25) so the bartender's work board (0.56 deep) leaves him a 0.72 m aisle; the
drinkers, the bar's lamps and the use points that stood on a prop move with it (all here).
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SPEC = os.path.join(ROOT, "config/buildings/saloon_b.json")

STAGE = 4.72     # #902's stage's boards over the ground floor
UP = 3.96        # the upper floor over the ground floor (4.91 - 0.95)
CELLAR = -2.87   # the cellar's flags (-1.92) over the ground floor
JOIST_UNDER = 3.635   # the dance floor's and rooms' joists' underside over the ground floor (4.585)
TIE_UNDER = 7.31      # the trusses' ties' underside (8.26)
LAMP_FOOT = 1.01      # a hanging lamp's hook is 1.0 over its foot: 1 cm under what it hangs from
BAR_X = 2.25
BAR_Z = [3.9, 6.9, 9.9]
BACK_BAR_Z = [3.15, 5.65, 8.15, 10.65]
COUNTER = 0.99   # the back bar's counter top
SHELF0 = 1.465   # its lower shelves' top
BAR_TOP = 1.095
CARD_TOP = 0.77


def joist_z(z):
    """The nearest joist's z: they run along x at 0.305, the dance floor's from z 0.157, the upper hall's
    from 13.417, the rooms' from 15.297 (measured off the built frame)."""
    z0 = 15.297 if z > 15.24 else 13.417 if z > 13.36 else 0.157
    k = round((z - z0) / 0.305)
    return round(z0 + 0.305 * k, 3)


def e(id_, kit, at, facing=0, **kw):
    d = {"id": id_, "kit": kit, "at": [round(v, 3) for v in at], "facing": facing}
    d.update(kw)
    return d


def s1():
    out = []
    for i, z in enumerate(BAR_Z):
        # No arm rail on the bar's top (Sean, #1041: the brass rail is for the feet; the bar's own
        # foot rail is drawn with the arm rail's tube).
        out.append(e("work_board_%d" % i, "work_board", [1.665, 0.0, z], 270,
                     use="the bartender's work board, its back on the bar's back boards (x 1.96)"))
    for i, z in enumerate([2.95, 4.85, 6.75, 8.65, 10.55]):
        out.append(e("slat_mat_%d" % i, "slat_mat", [1.03, 0.0, z], 90))
    # The back bar: the till and scales by it, a decanter each end, rows of glasses at the counter's
    # front (clear of its columns' bases, x < 0.36), a row of bottles on one shelf a section.
    out.append(e("till", "till_drawer", [0.47, COUNTER, 6.2], 90, use="the till on the back bar (no cash register in 1882 Colorado)"))
    out.append(e("gold_scales", "gold_scales", [0.5, COUNTER, 7.4], 90))
    out.append(e("decanter_0", "decanter", [0.52, COUNTER, 4.6], 0))
    out.append(e("decanter_1", "decanter", [0.52, COUNTER, 9.9], 0))
    out.append({"id": "shots_back", "row": {"kits": ["shot_glass"], "count": 6, "step": [0, 0, 0.09], "jitter": [0.008, 0.008, 0]},
                "at": [0.55, COUNTER, 7.85], "facing": 0})
    out.append({"id": "schooners_back", "row": {"kits": ["schooner"], "count": 6, "step": [0, 0, 0.11], "jitter": [0.008, 0.008, 0]},
                "at": [0.55, COUNTER, 10.2], "facing": 0})
    for i, c in enumerate(BACK_BAR_Z):
        out.append({"id": "bottles_%d" % i, "row": {"kits": ["whiskey_bottle"], "count": 5, "step": [0, 0, 0.17], "jitter": [0.01, 0.02, 30]},
                    "at": [0.3, SHELF0, c - 0.95], "facing": 90})
    # On the bar's top, where the drinkers stand (glasses on the bar for Payday Night's dust).
    for i, (kit, z) in enumerate([("shot_glass", 3.4), ("schooner", 5.0), ("schooner", 7.4), ("shot_glass", 9.0), ("shot_glass", 10.6)]):
        out.append(e("bar_glass_%d" % i, kit, [2.5, BAR_TOP, z], 0))
    out.append(e("bar_bottle", "whiskey_bottle", [2.4, BAR_TOP, 9.15], 0))
    # The hanging lamps: two rows of three under the dance floor's joists (they swing when it works and
    # fall with it: the sawn girder's panel is z 6.7-10.1), lit by the clock, no shadows (the room's
    # reflector lamps cast them).
    for i, (x, z) in enumerate([(3.4, 3.6), (3.4, 6.9), (3.4, 10.2), (8.2, 2.8), (8.2, 5.7), (8.2, 8.6)]):
        out.append(e("hanging_lamp_%d" % i, "hanging_lamp", [x, JOIST_UNDER - LAMP_FOOT, joist_z(z)], 0,
                     light=0.33, shadows=False, energy=1.0))
    # The dance hall's two, hung from a truss's tie (z 6.1) over the dancers.
    for i, x in enumerate([3.0, 8.0]):
        out.append(e("dance_lamp_%d" % i, "hanging_lamp", [x, TIE_UNDER - LAMP_FOOT, 6.1], 0,
                     light=0.33, shadows=False, energy=1.0))
    out.append(e("box_stove", "box_stove", [6.6, 0.0, 5.9], 0, use="mid-room, its door toward the card tables, its pipe short of the joists"))
    # Faro by the arch (west of it, clear of the way through) and in the gaming room; the dealer sits
    # into the cut (-z), the lookout high at his elbow.
    out.append(e("faro_bar", "faro_table", [7.0, 0.0, 12.2], 0, use="faro_bank: the bank by the arch"))
    out.append(e("faro_bar_chair", "chair", [7.0, 0.0, 11.5], 0))
    out.append(e("lookout_bar", "lookout_stool", [7.75, 0.0, 11.45], 330))
    out.append(e("faro_gaming", "faro_table", [10.0, 0.0, 17.4], 0, use="the gaming room's faro bank"))
    out.append(e("faro_gaming_chair", "chair", [10.0, 0.0, 16.7], 0))
    out.append(e("lookout_gaming", "lookout_stool", [10.8, 0.0, 16.65], 330))
    out.append(e("wheel", "wheel_of_fortune", [6.165, 1.9, 18.4], 90, use="wheel: on the store room's wall, its middle at 1.9 m"))
    for i, (x, z) in enumerate([(10.0, 17.4), (7.6, 17.1)]):
        out.append(e("shaded_lamp_%d" % i, "hanging_lamp_shaded", [x, JOIST_UNDER - LAMP_FOOT, joist_z(z)], 0,
                     light=0.33, shadows=False, energy=1.2))
    # The piano on the back wall between the arch and the stair hall's door, its stool before it.
    out.append(e("piano", "upright_piano", [12.4, 0.0, 12.98], 180, use="the bar room's upright, its back to the back wall"))
    out.append(e("piano_stool", "piano_stool", [12.4, 0.0, 12.3], 0, use="piano"))
    # Cards and chips on the tables in play; No Law's (13.1, 7.3) set for the game: glasses and a bottle.
    for i, (x, z) in enumerate([(13.1, 7.3), (13.2, 10.5), (8.23, 2.8), (8.23, 8.6)]):
        out.append(e("deck_%d" % i, "card_deck", [x - 0.12, CARD_TOP, z - 0.1], 20 + 35 * i))
        out.append(e("chips_%d" % i, "chip_stacks", [x + 0.18, CARD_TOP, z + 0.14], 10 * i))
    out.append(e("no_law_glass_0", "shot_glass", [12.82, CARD_TOP, 7.5], 0))
    out.append(e("no_law_glass_1", "shot_glass", [13.38, CARD_TOP, 7.05], 0))
    out.append(e("no_law_bottle", "whiskey_bottle", [13.12, CARD_TOP, 7.38], 0))
    return out


# --- S5 (#1030): the walls -------------------------------------------------------------------------

SHELF1 = 1.965   # the back bar's upper shelves' top
# The bar-room nude's place (#1030 step 8, from #1032's pictures): beside the back bar, on the yard wall's
# front corner (z 0.1 to 1.9: no window, the room's whole width to see it across), its middle 2.3 m up.
# Over the back bar there's 0.56 m to the joists: no room above it.
NUDE_PLACE = [0.11, 2.3, 1.0]


def s5_back_bar():
    """The back bar stocked as a bar's was: every bay's two shelves (S1 filled one shelf a section),
    a row of whiskey on the lower, and on the upper the house's decanter among more bottles."""
    out = []
    for i, c in enumerate(BACK_BAR_Z):
        # The right bay's lower shelf (S1's row is the left's).
        out.append({"id": "bottles_r%d" % i, "row": {"kits": ["whiskey_bottle"], "count": 5, "step": [0, 0, 0.17], "jitter": [0.012, 0.02, 40]},
                    "at": [0.3, SHELF0, c + 0.24], "facing": 90})
        for side, z0 in (("l", c - 0.95), ("r", c + 0.24)):
            out.append({"id": "bottles_up%s%d" % (side, i), "row": {"kits": ["whiskey_bottle"], "count": 2, "step": [0, 0, 0.15], "jitter": [0.012, 0.02, 40]},
                        "at": [0.29, SHELF1, z0], "facing": 90})
            out.append(e("decanter_up%s%d" % (side, i), "decanter", [0.3, SHELF1, z0 + 0.36], 0))
            out.append({"id": "bottles_up%s%d_b" % (side, i), "row": {"kits": ["whiskey_bottle"], "count": 2, "step": [0, 0, 0.15], "jitter": [0.012, 0.02, 40]},
                        "at": [0.29, SHELF1, z0 + 0.53], "facing": 90})
    return out


def s5():
    """S5 (#1030): what hangs on saloon B's walls, and the stage's and dressing room's props (#903)."""
    out = s5_back_bar()
    # The regulator on the bar room's back wall by the bar's end, its dial ~1.87 m up, where the bartender
    # and the drinkers read it (between the store room's door, x 0.82-1.73, and the lamp at 4.5).
    out.append(e("clock", "wall_clock", [2.9, 1.2, 13.36], 180, use="the bar room's clock: the town's time (#789)"))
    # Trophies: a deer's head over the store room's door, a longhorn's skull over the arch to the gaming
    # room (the Studio's of 2026-10-24, the porch's twin), another head on the front wall's pier between
    # the first two windows (x 3.96-6.86, its lamp at 5.95).
    out.append(e("deer_head_door", "deer_head", [1.27, 2.72, 13.36], 180))
    out.append(e("steer_skull_arch", "steer_skull", [9.2, 3.28, 13.36], 180))
    out.append(e("deer_head_front", "deer_head", [4.75, 2.6, 0.1], 0))
    # The house's Winchester on pegs over the back bar, between two sections' crests.
    out.append(e("rifle", "rifle_pegs", [0.1, 3.27, 6.9], 90, use="the bartender's gun, over the back bar"))
    # Spittoons along the bar's front between the drinkers' places (3.4, 5.2, 7.4, 9.0, 10.6).
    for i, z in enumerate([4.3, 6.3, 8.2, 9.8]):
        out.append(e("spittoon_%d" % i, "spittoon", [2.82, 0.0, z], 37 * i))
    # Hat and coat pegs by the way in (the cut corner): on the side street's wall's pier past its void
    # (z 0-2.44) and before the first window (3.54).
    out.append(e("coat_pegs", "coat_pegs", [16.36, 1.7, 3.0], -90))
    # The stage's and dressing room's props (#903, README "Saloon B, the stage and dressing room"): the
    # mirror against room 6's yard wall past its window (z 18.15-19.06), the costume pegs across from it
    # with the trunk at their foot, the screen along the back wall; the wing's trunk open for the night.
    out.append(e("dressing_mirror", "dressing_mirror", [0.39, UP, 20.3], 90))
    out.append(e("costume_pegs", "costume_pegs", [2.85, UP + 1.72, 20.3], -90))
    out.append(e("trunk_room_6", "travelling_trunk", [2.42, UP, 20.3], -90))
    out.append(e("dressing_screen", "dressing_screen", [1.5, UP, 21.35], 180))
    # (Against the wing's yard wall, its lid back toward it: by the dance hall's door, x 1.58, it stood in
    # the door's way in.)
    out.append(e("trunk_wing", "travelling_trunk", [0.52, UP, 11.4], 90, open="lid"))
    for d in out:
        if d.get("use") is None:
            d.pop("use", None)
    return out


def s2():
    out = []
    # The dance hall's benches round its walls, clear of its doors to the balcony (front at x 2.74 and
    # 8.23), its windows (yard at z 3.66 and 9.14) and the stage's end (z > 10.9, #902).
    for i, x in enumerate([1.15, 4.4, 6.4, 10.0]):
        out.append(e("bench_front_%d" % i, "wall_bench", [x, UP, 0.29], 0))
    for i, z in enumerate([1.7, 6.4]):
        out.append(e("bench_yard_%d" % i, "wall_bench", [0.29, UP, z], 90))
    out.append(e("bench_balcony", "wall_bench", [5.2, UP, -0.25], 180, use="the balcony over Main Street (Balcony Ambush's men)"))
    # The fiddler plays standing on #902's stage (his use point 4.3, 12.6): his fiddle and bow laid on a
    # chair at the stage's back, behind him (on the floor at his place they'd stand in it).
    out.append(e("fiddle_rest", "chair", [3.4, STAGE, 13.05], 180))
    out.append(e("fiddle", "fiddle", [3.45, 0.0, 13.05], 110, on="fiddle_rest"))
    out.append(e("fiddle_bow", "fiddle_bow", [3.45, 0.0, 13.05], 105, on="fiddle_rest", lift=0.09))
    out.append(e("handsaw", "handsaw", [3.6, 0.02, 20.9], 15, use="Payday Night's saw, in the store room till it's carried up the outside stair"))
    out.append(e("cookstove", "cookstove", [7.5, 0.0, 21.38], 180, use="the kitchen's range, its back to the back wall"))
    for i, (x, z) in enumerate([(4.6, 17.0), (5.0, 17.4), (4.6, 17.8)]):
        out.append(e("keg_%d" % i, "beer_keg", [x, 0.0, z], 20 * i, use="full kegs up from the cellar" if i == 0 else None))
    for d in out:
        if d.get("use") is None:
            d.pop("use", None)
    return out


def s3():
    out = []
    rack_slots = [[-0.865, 0.16], [-0.325, 0.16], [0.325, 0.16], [0.865, 0.16]]
    for name, x, y, z in [("store", 0.4, 0.0, 17.5), ("cellar", 0.76, CELLAR, 10.2)]:
        rid = "rack_%s" % name
        out.append(e(rid, "keg_rack", [x, y, z], 90, use="against the yard wall, tap ends out (+x)"))
        # The lower tier real kegs (12 bodies each), the rack's slots turned with it (facing 90:
        # its x along -z).
        for k, (sx, sy) in enumerate(rack_slots):
            out.append(e("%s_keg_%d" % (rid, k), "beer_keg_side", [x, y + sy, z - sx], 90))
    out.append(e("keg_floor_0", "beer_keg_side", [1.0, CELLAR, 13.0], 85))
    out.append(e("keg_floor_1", "beer_keg_side", [1.0, CELLAR, 13.7], 95))
    # The rented rooms (room_6 is the dressing room, #902): a bed each, its head to the back wall.
    for i, (room, x, kit) in enumerate([("room_3", 12.0, "plank_bed"), ("room_4", 7.7, "plank_bed"), ("room_5", 6.3, "iron_cot")]):
        bz = 21.85 - 1.01 - 0.02 if kit == "plank_bed" else 21.85 - 0.96 - 0.02
        out.append(e("bed_%s" % room[-1], kit, [x, UP, bz], 180, use="%s_bed" % room))
        out.append(e("pot_%s" % room[-1], "chamber_pot", [x + 0.75, UP, 21.4], 30 * i))
    out.append(e("wash_room_3", "washstand", [11.4, UP, 17.5], 90, use="room 3's washstand on its east wall"))
    out.append(e("basin_room_3", "wash_basin", [11.42, 0.0, 17.5], 0, on="wash_room_3"))
    out.append(e("pitcher_room_3", "wash_pitcher", [11.42, 0.0, 17.5], 200, on="basin_room_3", lift=0.014))
    # The owner's office: the desk's back to Main Street's wall between its window (x 12.5) and its door
    # onto the balcony (15.24), his chair, the strongbox, a washstand on the east wall.
    out.append(e("owner_desk", "owner_desk", [13.9, UP, 0.46], 0, use="owner_desk: his flat-top, its back to the front wall"))
    out.append(e("owner_chair", "chair", [13.9, UP, 1.2], 180))
    out.append(e("strongbox", "strongbox", [11.3, UP, 2.0], 90))
    out.append(e("wash_office", "washstand", [11.4, UP, 4.3], 90))
    out.append(e("basin_office", "wash_basin", [11.42, 0.0, 4.3], 0, on="wash_office"))
    out.append(e("pitcher_office", "wash_pitcher", [11.42, 0.0, 4.3], 160, on="basin_office", lift=0.014))
    # Storage filled (#821): barrels and crates in the store room.
    out.append(e("whiskey_barrel_0", "whiskey_barrel", [5.5, 0.0, 14.2], 0))
    out.append(e("whiskey_barrel_1", "whiskey_barrel", [5.5, 0.0, 14.9], 40))
    out.append(e("water_barrel", "water_barrel", [5.5, 0.0, 21.2], 0))
    out.append(e("crate_0", "crate", [1.0, 0.0, 20.9], 5))
    out.append(e("crate_1", "crate", [1.0, 0.6, 20.9], 80, on="crate_0"))
    return out


# Use points that now stand on a prop or by one that moved (Checks.people_fit leaves a use point's
# `prop` out of its room).
USE = {
    "barman_a": {"at": [1.03, 0.95, 4.0]},
    "barman_b": {"at": [1.03, 0.95, 8.5]},
    "drinker_1": {"at": [3.19, 0.95, 3.4]},
    "drinker_2": {"at": [3.19, 0.95, 5.2]},
    "drinker_3": {"at": [3.19, 0.95, 7.4]},
    "drinker_4": {"at": [3.19, 0.95, 9.0]},
    "drinker_5": {"at": [3.19, 0.95, 10.6]},
    "piano": {"at": [12.4, 0.95, 12.3], "facing": 0, "prop": "piano_stool"},
    "faro_bank": {"at": [7.0, 0.95, 11.5], "facing": 0, "prop": "faro_bar_chair"},
    "wheel": {"at": [7.0, 0.95, 18.4], "facing": -90},
    "stores": {"at": [1.6, 0.95, 17.5], "facing": -90},
    "cellar_kegs": {"at": [1.9, -1.92, 10.2], "facing": -90},
    "owner_desk": {"at": [13.9, 4.91, 1.2], "facing": 180, "prop": "owner_chair"},
    "room_3_bed": {"at": [12.0, 4.91, 20.82], "prop": "bed_3"},
    "room_4_bed": {"at": [7.7, 4.91, 20.82], "prop": "bed_4"},
    "room_5_bed": {"at": [6.3, 4.91, 20.87], "prop": "bed_5"},
}


def main():
    spec = json.load(open(SPEC))
    for f in spec["fixtures"]:
        if f["kit"] == "bar":
            f["at"][0] = BAR_X
    spec["lamps"]["on_bar"] = [[BAR_X + 0.05, 3.5], [BAR_X + 0.05, 9.6]]
    for u in spec["use_points"]:
        u.update(USE.get(u["id"], {}))
    dressing = spec.get("dressing", {})
    batches = dressing.get("batches", {})
    batches.update({"S1": s1(), "S2": s2(), "S3": s3(), "S5": s5()})
    spec["dressing"] = {
        "_doc": "#902: the stage's footlights and the dressing room's table, chair and lamp (`stage`). "
                "#950: saloon B's props, batches S1-S3 (#866, #879, #892), placed by the building's own build "
                "(SpecBuilding._dressing, PropDressing: the valley and every lab read this one placement). "
                "Written by tools/props/saloon_b_dress.py (edit it there and re-run). Each entry a kit prop at "
                "[x, y over the ground floor, z], turned `facing` degrees (a prop faces +Z); `on`, `lift`, `light`, "
                "`row`: PropDressing's doc. The upper floor is 3.96 over the ground floor, #902's stage 4.72. "
                "#1030: batch S5, the walls (the back bar stocked, the wall clock, trophies, the rifle, spittoons, "
                "pegs) and the stage's and dressing room's props (#903).",
        "batches": batches,
    }
    open(SPEC, "w").write(json.dumps(spec, indent="\t", ensure_ascii=False))
    n = sum(len(v) for v in spec["dressing"]["batches"].values())
    print("saloon B dressed: %d entries" % n)


if __name__ == "__main__":
    main()
