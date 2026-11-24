#!/usr/bin/env python3
"""Writes config/buildings/hotel.json (#1220, the building lab's step 2) from the numbers below.

RECIPE.md (saloon B): "write the spec with a script while its numbers move, then keep only the JSON".
The design is docs/briefs/hotel.md (Sean's calls in its section 9; the plans in docs/briefs/hotel/, whose
draw_plans.py has them in feet from the WEST corner). This spec settles every size; where it moves a room
from the drawings the README says so. The frame's common parts are saloon B's (a two-storey balloon frame,
4x4 studs sill to plate, 3x12 and 3x14 joists, Hatfield 1880, Kidder; saloon_b.json); what's the hotel's
own is here: a flat tin roof on joists behind the parapet (NEW: `frame.flat_roof`), the open gallery on
nine posts, one beam a bay, a deck a bay (the Balcony Ambush), the cellar dug under the west and middle,
and the drift under the lane to saloon B's cellar (NEW: `drift`, the cellar's secret B).
Run: python3 experiments/building_lab/hotel/make_spec.py
"""
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SB = json.loads((ROOT / "config/buildings/saloon_b.json").read_text())
FT = 0.3048


def r3(v):
    return round(v, 3)


def ft(v):
    return r3(v * FT)


# --- the shell (Sean, #1215: 80 x 50 ft, two storeys, painted clapboard) ---------------------------
# Building x runs from the EAST corner westward (a north-side lot faces south: RECIPE step 2); the
# drawings' x from the west is 80 - x here. The west wall faces the saloon lane ("lane"), the east
# the lane by the doctor's ("alley").
W = ft(80)                     # 24.384
D = ft(50)                     # 15.24 (the kitchen wing behind, 42 x 24 ft, is the next step)
FLOOR = 0.75                   # the walk's top (valley.json hotel walk.h)
BOARD = 0.025
JOIST = 0.25                   # 2x10 under the ground floor, on girders
SILL = 0.2
FOUND_TOP = r3(FLOOR - BOARD - JOIST - SILL)          # 0.275
UPPER = r3(FLOOR + ft(13.5))                          # 4.865: 13 ft 6 in floor to floor (the brief's section 3)
LONG = [0.1, 0.35]                                    # 4x14 at 12 in: the upper floor over 28 ft rooms
UJB = r3(UPPER - BOARD - LONG[1])                     # 4.49, the ground rooms' ceiling
PLATE = r3(UPPER + ft(11.5))                          # 8.37: 11 ft 6 in to the roof's joists
ROOF_J = [0.05, 0.3]                                  # 2x12 at 16 in, the flat roof's
ROOF_TOP = r3(PLATE + ROOF_J[1] + BOARD)              # 8.695
FALSE_FRONT = 9.9                                     # 32 1/2 ft over the street: the cornice and the name board
CELLAR_FLOOR = -2.0
FLAGS = r3(CELLAR_FLOOR + 0.08)
T = 0.45                                              # the foundation's thickness
# The ground under the lot (probed from the bake, 2026-11-24): the street edge about -0.08 (world), rising
# 0.5-0.6 m to the back wall and 0.15 lower at the east. A pad (valley.json) digs the lot level at the
# street edge under the building, so the yard's ground is the building's y 0.
HOTEL_Y0 = -0.08
SALOON_Y0 = 0.15                                      # saloon B's floor 0.95 over its pad (valley.json)
AT = [66.414, HOTEL_Y0, -10.05]                       # the east front corner (the west wall 3 cm inside the lot's line at 42.0)

# Girders under the ground floor (lines along x at these z: the ground floor's joists run front to back on
# them, 10 ft or less apart), and girders under the partitions that run with the joists (`girders.under`).
GZ = [2.29, 5.49, 8.53, 11.89]  # (the third under the 28 ft wall)
BAR_X = 17.68      # the bar | the lobby (the drawing's 22 ft)
PARLOUR_X = 9.14   # the lobby | the ladies' parlour (50 ft)
OFFICE_X = 14.63   # the office's corner in the lobby (behind the desk)
OFFICE_Z = 3.05
SAMPLE_X = 20.12   # the back stair hall | the sample room (14 ft from the west)
STAIR_X = 17.07    # the dining room | the back stair hall (24 ft)
BACK_Z = 8.575     # the long bearing wall across the building at 28 ft (on one board row over the girder at 8.53 and its blocking)

# The cellar: under the west and middle (the drawing's 0-48 ft), 10 ft back to the back wall.
CEL = [ft(32), ft(10), W, D]                          # [9.754, 3.048, 24.384, 15.24]
CEL_BEER_Z = 10.97                                    # the beer cellar runs back past the 28 ft wall (the drift's line)
TRAP = [22.6, r3(GZ[1] + 0.075), 23.6, r3(GZ[2] - 0.075)]   # behind the bar, girder to girder
BULK_Z = [3.6, 4.6]                                   # the bulkhead's passage through the lane wall, the beer cellar's front
DRIFT_Z = [8.85, 10.05]                               # the drift's timbers (0.9 m clear between the legs)

# The gallery (the Balcony Ambush): 80 x 8 ft over the walk, nine posts 10 ft apart at the walk's street
# edge (z -2.36, saloon B's), one beam a bay ending on the posts, a deck a bay.
POSTS = [r3(0.08 + k * (W - 0.16) / 8) for k in range(9)]
GZ_EDGE = -2.36

# The grand stair (OakStair's numbers, 190 x 270 in the material lab; here 22 risers of 187 on 270, one
# flight along the lobby's back wall rising east) and the upper hall's well over it.
G_HEAD_X = 10.25
G_RISERS = 22
G_GOING = 0.25
WELL = [10.1, 7.2, 14.15, r3(BACK_Z - 0.05)]  # (its posts clear of the ground floor's joist lines, 0.145 + 0.406 k)
# The back stair (the servants': cellar by the bar's trap; ground to upper here), along the dining room's wall.
BS_X = 17.17
BS_HEAD_Z = 15.0   # (its head at the back wall: the stringers land on its ribbon, the well wall to wall)
BS_RISERS = 22
BS_GOING = 0.28
BS_WELL = [17.12, BACK_Z, 18.42, r3(D - 0.1)]

UP_FRONT_Z = 6.1   # the upper hall's front wall: front rooms 20 ft deep, the hall 8 ft
LAP = {"siding": "lap", "wood": "painted_white", "exposure": 0.1}


def win(at, w, h, sill, level="ground", lights=2, **k):
    return dict({"type": "window", "level": level, "at": at, "width": w, "height": h, "sill": sill, "lights": lights}, **k)


def door(at, w, h, level="ground", **k):
    return dict({"type": "door", "level": level, "at": at, "width": w, "height": h}, **k)


def part(id_, a, b, level, bearing, openings, doc=None, finish=("boards", "boards")):
    # (a partition's openings take its level: an opening's own `level` would hide it from the builder)
    openings = [{k: v for k, v in o.items() if k != "level"} for o in openings]
    d = {"id": id_, "line": [a, b], "partition": True, "level": level, "bearing": bearing,
         "inside": [{"side": "-", "finish": finish[0]}, {"side": "+", "finish": finish[1]}], "openings": openings}
    if doc:
        d["_doc"] = doc
    return d


def outer_inside(a, b, ground="wainscot"):
    g = {"level": "ground", "from": a, "to": b, "finish": ground}
    if ground == "wainscot":
        g["to_y"] = r3(UJB - 0.02)  # (clear of the upper joists: they'd rest on the boards)
    return [g, {"level": "upper", "from": a, "to": b, "finish": "boards"}]


spec = {
    "_doc": "The Salt Creek Hotel (#1146 the design, docs/briefs/hotel.md; #1220 steps 2-6; Sean's calls on #1215: painted clapboard in three colours, two storeys, an open railed gallery to be blown up, the cellar's secret B). Format 1 (../../experiments/building_lab/FORMAT.md) with what a big two-storey hotel needs (each marked NEW). Target sheet: experiments/building_lab/hotel/sheet/ (Sean OK 2026-11-24): build the OPEN deck, not the sheet's roofed gallery. Sizes from this spec only, never off the pictures. Written by make_spec.py. SPACE: on its north-side lot the building faces south (facing 180), so its x runs from its EAST corner westward and its z back (north) from the front wall's outer stud face; the side walls are named by what they face, 'lane' (west, the saloon lane) and 'alley' (east). THE MAIN BLOCK ONLY: the two-storey kitchen wing behind its west half (42 x 24 ft) is the next step (README).",
    "format": 1,
    "id": "hotel",
    "identity": {
        "owner": "the landlady, a widow in her forties: her late husband built it in 1881 on the best lot on Main Street's north side and died the next winter; she runs it with a clerk, a cook, two chambermaids, a waitress and a boy",
        "trade": "the town's best hotel: eleven rooms and a suite over a lobby, a small fine bar, the ladies' parlour and a dining room laid for supper; where the railroad's men, the mine's, drummers and the Army's officers stay, and where the Baron gives his suppers",
        "means": "a frame building dressed as well as money freighted on the railroad could dress it: local walls, and the millwork, plate glass, carpets, paper and brass all off the cars",
        "age_and_repair": "a year old and well kept: the paint fresh, the walk swept at six, the lobby's carpet paler on the way to the desk and the stair; the gallery's deck already grey",
        "clues": ["SALT CREEK HOTEL in gilt on a red board over the cornice, 1881 in the pediment", "lace at every upper window: the only curtains on the street", "chairs and a rocker under the gallery, a boot scraper by the main doors", "the bar's own door on the lane side, the ladies' at the east", "a brewery's dray at the bulkhead on the saloon lane"],
        "class": "best",
        "built": 1881,
        "now": 1882,
    },
    "lot": {
        "_doc": "valley.json town.north 'hotel' (x 42.0-67.2, 25.2 m): the building's west wall 3 cm inside the lot's line on the saloon lane (world x 42.03), its east corner (the origin) at world x 66.414, 0.79 m short of the east lane; the front wall's face on the town's front line (z -10.05). Its floor at its walk's top (walk.h 0.75 over the ground at the walk's street edge, ValleyTown); `at`'s y the street edge's ground (the bake: -0.16 east to -0.01 west). The lot is dug level at that height under the building (valley.json's pad): the bake rises 0.5-0.6 m to the back wall, which would bury the sills.",
        "valley_lot": "hotel",
        "side": "north",
        "at": AT,
        "facing": 180,
        "width": W,
        "depth": D,
        "yard": [0.0, D, W, 28.0],
        "ground": {"plane": [0.0, 0.0, 0.0], "_doc": "the pad: level at the building's y 0"},
        "footprint_with_stair": [0.0, -2.44, W, r3(D + 1.4)],
        "walk_h": FLOOR,
        "walk_x": [0.0, W],
        "yard_name": "YARD",
    },
    "levels": {
        "_doc": "The floor at the walk's top (0.75: four easy steps). 13 ft 6 in floor to floor below (the lobby's height, the tall plate glass), 11 ft 6 in above to the flat roof's joists; the roof's boards at 8.70, the parapet's cornice and the name board to 9.9 (32 1/2 ft over the street, the brief's front). The cellar's floor 2.0 m under the street edge (its flags 1.92: 2.2 m clear under the girders).",
        "cellar": {"floor": CELLAR_FLOOR, "top": FLAGS},
        "ground": {"top": FLOOR},
        "upper": {"top": UPPER},
        "roof": {"top": ROOF_TOP, "_doc": "NEW: the flat roof's boards (`frame.flat_roof`)"},
        "plate": PLATE,
        "false_front": FALSE_FRONT,
        "roof_pitch": 0.0,
        "roof_tight": True,
    },
    "frame": copy.deepcopy(SB["frame"]),
}
fr = spec["frame"]
fr["_doc"] = "A balloon frame (Bell 1858; Woodward 1865): 4x4 studs sill to plate through both storeys (saloon B's, under a crowd), the upper joists on a 1x6 ribbon let into them. The ground floor's 2x10 joists front to back on four lines of girders, broken over each; the upper floor's 3x14 at 12 in front to back over the 28 ft rooms (Kidder: no wood joist over 25 ft without a reason; Hatfield 1880 for the sizes), broken over the long bearing wall at 28 ft; a flat roof of 2x12 at 16 in on the plates, the bearing partitions and a ribbon on the front's studs, boarded and tinned (terne plate on boards, the period's flat roof behind a parapet), falling to the back (drawn level). Dressed sizes, metres [width, depth]; spans to checks.gd's sizing."
fr.pop("dance_joist", None)
fr["stacked"] = True
fr["foundation"].update({"_doc": "rubble stone in lime, 18 in, 0.3 m under the pad; where it walls the cellar, down to its floor", "top": FOUND_TOP, "bottom": -0.3})
fr["long_joist"] = {"_doc": "4x14 at 12 in (3x14 bent 1.12 of its limit under a crowd): the upper floor over the front rooms' 28 ft and the back's 22 (Kidder; L/360 at 40 lb/ft2)", "section": LONG, "spacing": 0.305, "wood": "framing"}
fr["roof_joist"] = {"_doc": "2x12 at 16 in: the flat roof's, front wall to the 28 ft wall to the back wall", "section": ROOF_J, "spacing": 0.406, "wood": "framing"}
fr["flat_roof"] = {"_doc": "NEW (spec_building.gd): no trusses or rafters; the roof is a floor of its own (`floors` level 'roof') on the outer walls' plates, the front's roof ribbon (on the false front's studs) and the upper bearing partitions (full height; the others stop 2 cm short); its boards kind `board` (no crowd on them).", "board_kind": "board"}
fr["stud"]["tall"]["walls"] = ["front", "back", "lane", "alley"]
fr["stud"]["tall"]["_doc"] = "the balloon studs run 7.9 m sill to plate (8.37 under the false front's 9.9): 4x4, as saloon B's"
fr["post"]["_doc"] = "8x8 posts (the lobby's stair well), chamfered (saloon B's)"
fr["beam"]["_doc"] = "the stair well's beams: 6x12"
fr["beam"]["section"] = [0.15, 0.3]
fr.pop("truss", None)

spec["girders"] = {
    "_doc": "Four lines under the ground floor's joists (spans 3.0-3.4 m), on stone piers at 6 ft; in the cellar on its posts and its bearing walls. Under each partition that runs with the joists a girder of its own (saloon B's `under`), its piers left out where it is over the cellar (NEW): there the cellar's walls and posts carry it.",
    "z": GZ,
    "under": [
        {"_doc": "the bar's wall", "x": BAR_X, "z": [0.1, r3(BACK_Z - 0.05)]},
        {"_doc": "the ladies' parlour's wall", "x": PARLOUR_X, "z": [0.1, r3(BACK_Z - 0.05)]},
        {"_doc": "the office's side", "x": OFFICE_X, "z": [0.1, r3(OFFICE_Z - 0.05)]},
        {"_doc": "the sample room's wall", "x": SAMPLE_X, "z": [r3(BACK_Z + 0.05), r3(D - 0.1)]},
        {"_doc": "the dining room's west wall", "x": STAIR_X, "z": [r3(BACK_Z + 0.05), r3(D - 0.1)]},
    ],
}
# The cellar's posts: under the girders where no cellar wall carries them, and under the girders.under
# where they cross the cellar's passage and the beer cellar.
spec["cellar"] = {
    "_doc": "Under the west and middle of the main block (the drawing's 0-48 ft from the west, 10 ft back to the back wall): 48 x 40 ft inside the house's foundation, rubble walls lime-washed, stone flags, 2.2 m under the girders. Its rooms are partitions on its flags: the beer cellar under the bar (kegs on stillage; the bulkhead to the lane; the trap up behind the bar; THE DRIFT out of its west wall), the stores beside it, a passage across, the coal, the ice room and the locked wine room behind. The east third is unexcavated, the floor over it on piers.",
    "rect": CEL,
    "posts": [[21.0, GZ[1]], [12.4, GZ[1]], [15.0, GZ[1]], [21.0, GZ[2]], [SAMPLE_X, 9.75], [13.4, GZ[3]], [22.3, GZ[3]]],
    "flag": 1.0,
    "dig": False,
    "_dig": "NOT YET in the valley (#1220): any dug tile in the valley's first ground chunk (x -30 to 98: ValleyGround re-cuts a chunk's collision into squares round a dug tile) moves the ground under the saloon yard's card set and fails the card-game tests (saloon B's dig alone does it too). The cellar and the drift are walked in the lab (tests/test_building_hotel.gd); CellarDig digs both and covers the drift the moment this is true, once the set is inside saloon B or the re-cut leaves the squares without a tile as they were.",
    "trap": {"rect": TRAP},
    "stair": {"head": [22.65, TRAP[1]], "dir": "-z", "width": 0.9, "risers": 14, "going": 0.2},
}
spec["bulkhead"] = {
    "_doc": "The beer cellar's outside door on the saloon lane, where the brewery's dray rolls the kegs down (the undertaker's Bulkhead: a stone areaway, its steps, the passage under a lintel, slanted doors standing open).",
    "wall": "lane",
    "z": BULK_Z,
    "out": 2.45,
    "grade": 0.0,
    "cheek": 0.3,
    "risers": 10,
    "going": 0.24,
    "high": r3(FOUND_TOP - 0.02),
    "low": 0.2,
    "lintel": 0.2,
    "open": True,
    "wood": "rough",
}
# The drift (NEW, the cellar's secret B): from the beer cellar's west wall's inner face west under the
# saloon lane and the saloon's yard to saloon B's cellar's east wall's inner face.
SALOON_INNER = 24.06 - 0.45                           # saloon B's cellar's east wall, its inner face (world x)
DRIFT_X0 = r3(W - T)
DRIFT_X1 = r3(AT[0] - SALOON_INNER)
spec["drift"] = {
    "_doc": "NEW (Drift, src/structures/drift.gd; Sean, #1215: 'b is awesome'): the landlady's husband's keg road of 1881 to the saloon he had a share in, bricked up when he died and opened again lately by the foreman's men. A timbered drift as a mine's: sets every 4 ft (a sill on the floor, two legs, a cap), lagging boards over the caps and behind the legs, a walk of planks on the sills; through an opening under a timber lintel in the hotel's foundation and in saloon B's (`foundation.passages`). 4 ft 7 in clear under the caps (the brief's 4 ft raised so a man walks it crouched: the player crouches to 1.3 m), 3 ft between the legs. It falls toward the hotel by the two cellars' floors (`fall`). In the valley the ground over it is dug to its floor and covered over again (CellarDig: the cover flush with the lane's dirt).",
    "wall": "lane",
    "x": [DRIFT_X0, DRIFT_X1],
    "z": DRIFT_Z,
    "fall": r3((SALOON_Y0 + CELLAR_FLOOR) - (HOTEL_Y0 + CELLAR_FLOOR)),
    "clear": 1.4,
    "every": ft(4),
    "leg": 0.15,
    "cap": 0.15,
    "sill": 0.1,
    "plank": 0.04,
    "lagging": 0.04,
    "wood": "rough",
    "clues": {"_doc": "the brief's: fresh oak sawdust on the beer cellar's floor, a bucksaw left in the drift, the arch's bricks stacked aside (props: the prop lab's batch)"},
}
spec["foundation_passages"] = [
    {"_doc": "NEW: the drift's arched door in the lane wall (built as a timber lintel over the gap)", "wall": "lane", "z": [r3(DRIFT_Z[0] + 0.15), r3(DRIFT_Z[1] - 0.15)], "height": r3(1.4 + 0.14 + 0.1)},
]

# --- floors ---------------------------------------------------------------------------------------
G_RUN = r3((G_RISERS - 1) * G_GOING)
spec["floors"] = [
    {"_doc": "to 0.12 short of the lane wall: its last joist 2.5 cm clear of the wall's studs (at 5 mm they stood on it)", "id": "ground", "level": "ground", "rect": [0.1, 0.1, r3(W - 0.12), r3(D - 0.1)], "joists": "z", "look": "wood:int_floor",
     "blocking": [{"z": [8.5, 8.65], "sole": True, "_doc": "the 28 ft wall's sole: one board row's width, on the girder at 8.53"}],
     "openings": [{"id": "trap", "rect": TRAP, "hatch": 2, "_doc": "behind the bar, girder to girder: kegs down to the beer cellar"}]},
    {"_doc": "the upper floor east of the stair's well, front to the 28 ft wall", "id": "up_e", "level": "upper", "joist": "long_joist", "rect": [0.1, 0.1, WELL[0], BACK_Z], "joists": "z", "look": "wood:int_floor"},
    {"_doc": "over the well's front: its joists end on the well's beam", "id": "up_well", "level": "upper", "joist": "long_joist", "rect": [WELL[0], 0.1, WELL[2], WELL[1]], "joists": "z", "look": "wood:int_floor"},
    {"id": "up_w", "level": "upper", "joist": "long_joist", "rect": [WELL[2], 0.1, r3(W - 0.12), BACK_Z], "joists": "z", "look": "wood:int_floor"},
    {"_doc": "the back half, 28 ft wall to the back wall; the back stair's well cut wall to wall (no tail joists)", "id": "up_back", "level": "upper", "joist": "long_joist", "rect": [0.1, BACK_Z, r3(W - 0.12), r3(D - 0.1)], "joists": "z", "look": "wood:int_floor",
     "blocking": [[BACK_Z, r3(BACK_Z + 0.075)]],
     "openings": [{"id": "back_stair", "rect": BS_WELL}]},
    {"_doc": "NEW: the flat roof (frame.flat_roof), its joists broken over the upper hall's back wall", "id": "roof", "level": "roof", "joist": "roof_joist", "rect": [0.1, 0.1, r3(W - 0.1), r3(D - 0.1)], "joists": "z", "breaks": [BACK_Z]},
]
spec["posts"] = {
    "_doc": "6x6 posts under the stair well's beams, through the lobby's floor on piers down to the stores' flags.",
    "free": [[WELL[0], WELL[1]], [WELL[2], WELL[1]], [WELL[0], r3(BACK_Z - 0.17)]],
    "wall": [],
}
spec["beams"] = [
    {"_doc": "the well's front edge: the upper hall's floor over it ends here", "id": "well", "from": [WELL[0], WELL[1]], "to": [WELL[2], WELL[1]], "brackets": False},
    {"_doc": "the stair's head: its stringers land on it", "id": "stair_head", "from": [WELL[0], WELL[1]], "to": [WELL[0], r3(BACK_Z - 0.06)], "brackets": False},
]
spec["ceilings"] = {
    "_doc": "Boards nailed up under the joists in every room, both floors (NEW: `levels` upper under the flat roof's joists; `holes` the stair's well, which is a gap between floors, not an opening). Plaster on lath is the next system (#1220's slice issue): these are its lath's place.",
    "levels": ["ground", "upper"],
    "holes": [WELL],
    "width": 0.14,
}
spec["inside_finish"] = copy.deepcopy(SB["inside_finish"])

# --- walls ----------------------------------------------------------------------------------------
spec["walls"] = [
    {"_doc": "Main Street: the ground floor reads as glass (the brief's section 3): the bar's tall window and its own door at the west, the lobby's two windows either side of the main doors (a glazed pair under a fanlight), the ladies' parlour's two windows and the ladies' door at the east; above, the front rooms' low sash windows onto the gallery and the suite's French doors on the axis over the main doors. The false front's studs run to the cornice (9.9).",
     "id": "front", "line": [[0, 0], [W, 0]], "out": "-z", "top": FALSE_FRONT, "outside": LAP, "inside": outer_inside(0.1, r3(W - 0.1)),
     "openings": [
         win(22.86, 1.22, 2.74, 0.6, _doc="the bar's window"),
         win(19.81, 1.22, 2.74, 0.6, _doc="the bar's second window (#1220: its street door left out: a townsman walking the walk west from the main doors was pushed in at it and stuck in the bar, tests/test_valley_folk.gd; the bar's own door can come on the lane side, with steps)"),
         win(16.76, 1.22, 2.74, 0.6, _doc="the lobby's west window (the office behind the desk)"),
         door(13.41, 1.83, 2.74, glazed=True, transom=0.55, leaves=2, _doc="the main doors: a glazed pair, the fanlight with the name in gold leaf"),
         win(10.06, 1.22, 2.74, 0.6, _doc="the lobby's east window"),
         win(5.94, 1.22, 2.74, 0.6, _doc="the ladies' parlour"),
         win(3.6, 1.22, 2.74, 0.6),
         door(1.98, 1.07, 2.44, glazed=True, transom=0.45, _doc="the ladies' entrance, to their own parlour"),
         win(22.86, 0.91, 1.83, 0.3, "upper", 4, _doc="room 1: a low sash onto the gallery (the ambush men come out of the front rooms)"),
         win(19.81, 0.91, 1.83, 0.3, "upper", 4, _doc="room 2"),
         win(16.76, 0.91, 1.83, 0.3, "upper", 4, _doc="room 3"),
         door(13.41, 1.22, 2.3, "upper", glazed=True, leaves=2, _doc="the suite's French doors onto the gallery"),
         win(10.06, 0.91, 1.83, 0.3, "upper", 4, _doc="the suite's bedroom"),
         win(5.94, 0.91, 1.83, 0.3, "upper", 4, _doc="room 4"),
         win(1.98, 0.91, 1.83, 0.3, "upper", 4, _doc="room 5"),
     ]},
    {"_doc": "The back, to the yard (the kitchen wing's place behind its west half is the next step): the back stair hall's door, the dining room's four windows; above, the back rooms'.",
     "id": "back", "line": [[0, D], [W, D]], "out": "+z", "top": "plate", "outside": LAP, "inside": outer_inside(0.1, r3(W - 0.1), "boards"),
     "openings": [
         door(19.3, 0.91, 2.13, leaf="inward", _doc="the back door: the servants' way from the yard"),
         win(2.5, 1.22, 2.44, 0.75), win(6.4, 1.22, 2.44, 0.75), win(10.2, 1.22, 2.44, 0.75), win(13.6, 1.22, 2.44, 0.75),
         win(22.2, 0.91, 1.83, 0.75, "upper", 4, _doc="room 6"), win(19.3, 0.91, 1.83, 0.75, "upper", 4, _doc="the back stair"),
         win(16.3, 0.76, 1.37, 1.0, "upper", 4, _doc="the bath"), win(13.6, 0.91, 1.83, 0.75, "upper", 4, _doc="room 7"),
         win(10.2, 0.91, 1.83, 0.75, "upper", 4, _doc="room 8"), win(6.4, 0.91, 1.83, 0.75, "upper", 4, _doc="the landlady's sitting room"),
         win(2.5, 0.91, 1.83, 0.75, "upper", 4, _doc="the landlady's bedroom"),
     ]},
    {"_doc": "The west side, to the saloon lane: the bar's window behind the trap, the sample room's window and its door for trunks off a wagon; above, room 1, the hall's end window, room 6. The bulkhead against its foundation; the drift's door through it under the lane.",
     "id": "lane", "line": [[W, 0], [W, D]], "out": "+x", "top": "plate", "outside": LAP, "inside": outer_inside(0.1, r3(D - 0.1)),
     "openings": [
         win(7.3, 1.22, 2.3, 1.05, _doc="the bar's, over the trap (its sill over the wainscot's cap)"),
         win(10.2, 1.22, 2.44, 0.75, _doc="the sample room"),
         door(13.6, 1.07, 2.44, leaves=2, _doc="the sample room's lane door (a drummer's trunks)"),
         win(3.9, 0.91, 1.83, 0.75, "upper", 4), win(7.3, 0.91, 1.83, 0.75, "upper", 4, _doc="the hall's end"), win(10.2, 0.91, 1.83, 0.75, "upper", 4),
     ]},
    {"_doc": "The east side, to the lane by the doctor's: the parlour's two windows, the dining room's two; above, room 5, the hall's end window, the landlady's bedroom.",
     "id": "alley", "line": [[0, 0], [0, D]], "out": "-x", "top": "plate", "outside": LAP, "inside": outer_inside(0.1, r3(D - 0.1)),
     "openings": [
         win(3.9, 1.22, 2.74, 0.6), win(7.3, 1.22, 2.44, 0.75), win(10.2, 1.22, 2.44, 0.75), win(13.6, 1.22, 2.44, 0.75),
         win(3.9, 0.91, 1.83, 0.75, "upper", 4), win(7.3, 0.91, 1.83, 0.75, "upper", 4), win(10.2, 0.91, 1.83, 0.75, "upper", 4),
     ]},
    # The ground floor's partitions.
    part("g_back", [0.1, BACK_Z], [r3(W - 0.1), BACK_Z], "ground", True, [
        door(4.47, 0.91, 2.29, _doc="the parlour to the dining room"),
        door(16.25, 0.91, 2.29, leaf="outward", _doc="the lobby to the dining room, past the grand stair's foot (its leaf into the dining room)"),
        door(19.2, 0.86, 2.13, _doc="the bar to the back stair hall (the barman's way)"),
    ], "the long bearing wall at 28 ft, on the girder: it carries the upper floor's joists over the front rooms and the back", ("wainscot", "wainscot")),
    part("g_bar", [BAR_X, 0.1], [BAR_X, r3(BACK_Z - 0.05)], "ground", True, [door(3.9, 0.91, 2.29, _doc="the bar to the lobby")], "the bar's wall, on its girder", ("wainscot", "wainscot")),
    part("g_parlour", [PARLOUR_X, 0.1], [PARLOUR_X, r3(BACK_Z - 0.05)], "ground", True, [door(3.8, 1.37, 2.44, leaves=2, _doc="the lobby to the ladies' parlour")], "the parlour's wall, on its girder", ("wainscot", "wainscot")),
    part("g_office_e", [OFFICE_X, 0.1], [OFFICE_X, r3(OFFICE_Z - 0.05)], "ground", True, [], "the office's corner behind the desk (the landlady's desk, the ledger, the safe)"),
    dict(part("g_office_f", [OFFICE_X, OFFICE_Z], [r3(BAR_X - 0.05), OFFICE_Z], "ground", False, [door(1.6, 0.86, 2.13, leaf="outward")]), gap=0.02),
    part("g_stair", [STAIR_X, r3(BACK_Z + 0.05)], [STAIR_X, r3(D - 0.1)], "ground", True, [door(5.5, 0.86, 2.13, _doc="the back stair hall to the dining room: the waitress's door, under the stair's high end")], "the dining room's west wall, on its girder"),
    part("g_sample", [SAMPLE_X, r3(BACK_Z + 0.05)], [SAMPLE_X, r3(D - 0.1)], "ground", True, [door(1.5, 0.86, 2.13, leaf="outward")], "the sample room's wall, on its girder"),
    # The cellar's (level 'cellar': on its flags, up to the girders; the bearing ones under them).
    part("c_beer", [BAR_X, r3(CEL[1] + 0.25)], [BAR_X, r3(CEL_BEER_Z - 0.05)], "cellar", True, [door(6.8, 0.91, 1.98, leaf="outward", _doc="the beer cellar to the passage")], "the beer cellar's wall under the bar's (it carries its girder)", ("rough", "rough")),
    part("c_stores", [r3(CEL[0] + 0.25), BACK_Z], [r3(BAR_X - 0.05), BACK_Z], "cellar", True, [door(1.2, 0.91, 1.98)], "the stores' back wall under the 28 ft girder", ("rough", "rough")),
    part("c_back", [r3(CEL[0] + 0.25), CEL_BEER_Z], [r3(W - T - 0.02), CEL_BEER_Z], "cellar", False, [
        door(2.4, 0.86, 1.98, _doc="the wine room's door (locked: the landlady's key)"),
        door(8.2, 0.86, 1.98, thick=0.1, _doc="the ice room's thick door"),
        door(12.3, 0.86, 1.98, _doc="the coal"),
    ], "the back rooms' wall, from the passage and the beer cellar", ("rough", "rough")),
    part("c_coal", [SAMPLE_X, r3(CEL_BEER_Z + 0.05)], [SAMPLE_X, r3(D - T - 0.02)], "cellar", True, [], "the coal | the ice room, under the sample room's girder", ("rough", "rough")),
    part("c_ice", [STAIR_X, r3(CEL_BEER_Z + 0.05)], [STAIR_X, r3(D - T - 0.02)], "cellar", True, [], "the ice room | the wine room, under the dining room's wall's girder: planked both sides, sawdust between", ("rough", "rough")),
    # The upper floor's.
    part("u_front", [0.1, UP_FRONT_Z], [r3(W - 0.1), UP_FRONT_Z], "upper", False, [
        door(1.9, 0.86, 2.13, "upper"), door(5.84, 0.86, 2.13, "upper"), door(13.3, 0.91, 2.13, "upper", _doc="the suite's parlour"),
        door(16.66, 0.86, 2.13, "upper"), door(19.71, 0.86, 2.13, "upper"), door(22.76, 0.86, 2.13, "upper"),
    ], "the hall's front wall: a door each front room, transoms over (the brief: air)"),
    part("u_back", [0.1, BACK_Z], [r3(W - 0.1), BACK_Z], "upper", True, [
        door(6.3, 0.86, 2.13, "upper"), door(9.4, 0.86, 2.13, "upper", _doc="room 8, short of the well"), door(14.95, 0.86, 2.13, "upper", _doc="room 7, beside the well's end"),
        door(16.25, 0.76, 2.03, "upper", _doc="the bath"), door(19.2, 0.86, 2.13, "upper", _doc="the back stair"), door(22.1, 0.86, 2.13, "upper"),
    ], "the hall's back wall over the 28 ft wall: it carries the roof's joists"),
]
for w in spec["walls"]:
    if w["id"] in ("g_back", "u_back"):
        w["stud"] = 0.1
for x in (21.34, 18.29, 15.24, 11.58, 7.92, 3.96):
    ops = [door(3.0, 0.86, 2.13, "upper", _doc="the suite's parlour to its bedroom")] if x == 11.58 else []
    spec["walls"].append(part("u_f%d" % int(x * 100), [x, 0.1], [x, r3(UP_FRONT_Z - 0.05)], "upper", False, ops))
for x in (20.12, 17.07, 15.6, 11.89, 8.53, 4.27):
    ops = [door(3.4, 0.86, 2.13, "upper", _doc="her sitting room to her bedroom")] if x == 4.27 else []
    spec["walls"].append(part("u_b%d" % int(x * 100), [x, r3(BACK_Z + 0.05)], [x, r3(D - 0.1)], "upper", False, ops))

spec["stairs"] = [
    {"_doc": "THE GRAND STAIR (the brief's 4.1: OakStair's painted dark oak, Sean's B): one flight of 22 risers of 7 3/8 in on 10 5/8 in treads up the lobby's back wall, rising east to the upper hall; its open side railed. (The brief's two flights with a landing are one here: the builder's stairs are straight runs.)", "id": "grand", "head": [G_HEAD_X, r3(WELL[1] + 0.12)], "dir": "-x", "width": r3(BACK_Z - 0.105 - WELL[1] - 0.12), "from": "ground", "to": "upper", "risers": G_RISERS, "going": G_GOING, "rail": "-z", "look": "wood:int_oak", "stringer_look": "wood:int_timber"},
    {"_doc": "The back stair (the servants'): 22 risers up the dining room's west wall from the back door's hall, rising to the back wall, to the upper back stair hall", "id": "back", "head": [BS_X, BS_HEAD_Z], "dir": "+z", "width": 1.15, "from": "ground", "to": "upper", "risers": BS_RISERS, "going": BS_GOING, "rail": "+x", "look": "wood:int_timber"},
    {"_doc": "the back door's steps to the yard", "id": "back_door", "head": [18.7, r3(D + 1.2)], "dir": "-z", "width": 1.2, "from": 0.0, "to": "ground", "risers": 4, "going": 0.28, "wood": "weathered_pine", "stoop": [18.7, D, 19.9, r3(D + 1.2)]},
]
spec["galleries"] = {
    "_doc": "The rails round the two wells upstairs (saloon B's gallery rail: a 36 in turned rail, square newels)",
    "well": WELL,
    "rails": [[[r3(G_HEAD_X + 0.1), r3(WELL[1] - 0.06)], [r3(WELL[2] + 0.06), r3(WELL[1] - 0.06)]], [[r3(WELL[2] + 0.06), r3(WELL[1] - 0.06)], [r3(WELL[2] + 0.06), r3(BACK_Z - 0.1)]],
              [[r3(BS_WELL[2] + 0.06), r3(BACK_Z + 0.15)], [r3(BS_WELL[2] + 0.06), r3(D - 0.3)]]],
    "height": 0.915,
    "look": "wood:int_oak",
}
# The gallery (the Balcony Ambush, the brief's section 6 and balcony.png).
BAYS = len(POSTS) - 1
spec["balconies"] = [{
    "_doc": "THE GALLERY (Sean, #1215: an exterior balcony to be blown up later, an open railed deck): 80 x 8 ft over the walk, its deck at the upper floor (16 ft over the street), on nine 6x6 posts 10 ft apart at the walk's street edge; ONE BEAM A BAY ending on the posts (not spliced through), so a post blown out drops exactly the two bays it carries; 2x10 joists at 16 in from a ledger through the siding into the studs to the beam; a deck a bay (its boards cut at the post lines, so the fallen bays tear free); a turned-baluster rail in spans of 1.2 m. The joists hinge on the ledger and the deck tips the men down to the walk.",
    "id": "street", "wood": "weathered_pine", "post": [0.15, 0.15], "beam": [0.15, 0.25],
    "posts": [[x, GZ_EDGE] for x in POSTS],
    "beams": [[[POSTS[k], GZ_EDGE], [POSTS[k + 1], GZ_EDGE]] for k in range(BAYS)],
    "ledgers": [{"wall": "front", "from": 0.0, "to": W}],
    "decks": [{"rect": [POSTS[k], -2.44, POSTS[k + 1], -0.05], "joists": "z"} for k in range(BAYS)],
    "rails": [[[r3(POSTS[0] + 0.05), -2.4], [r3(POSTS[-1] - 0.05), -2.4]], [[r3(POSTS[0] + 0.05), -2.4], [r3(POSTS[0] + 0.05), -0.05]], [[r3(POSTS[-1] - 0.05), -2.4], [r3(POSTS[-1] - 0.05), -0.05]]],
}]
spec["front"] = {
    "_doc": "The parapet over the upper windows: a frieze, the cornice on paired scroll brackets, the name board SALT CREEK HOTEL (gilt on deep red; the game's own letters). The side walls' eaves take the same cornice and brackets (`sides`), at the roof's edge.",
    "sign": "SALT CREEK HOTEL",
    "sign_from": 8.55,
    "sign_to": 9.45,
    "sign_width": 9.5,
    "brackets": {"spacing": 0.6, "drop": 0.38, "reach": 0.18, "width": 0.08, "sides": ["lane", "alley"], "side_top": r3(ROOF_TOP + 0.3)},
}

# --- rooms, use, light ------------------------------------------------------------------------------
R = lambda id_, lvl, x0, z0, x1, z1, use: {"id": id_, "level": lvl, "rect": [r3(x0), r3(z0), r3(x1), r3(z1)], "use": use}
spec["rooms"] = [
    R("bar", "ground", BAR_X + 0.05, 0.1, W - 0.1, BACK_Z - 0.05, "small and fine: the walnut bar down the lane wall, the back bar's mirror, a few tables; its own street door; the trap to the beer cellar behind the bar"),
    R("lobby", "ground", PARLOUR_X + 0.05, 0.1, BAR_X - 0.05, BACK_Z - 0.05, "the walnut desk facing the main doors, the register, the key board behind it in the office's wall; settee and armchairs, spittoons; the grand stair up the back wall"),
    R("office", "ground", OFFICE_X + 0.05, 0.1, BAR_X - 0.05, OFFICE_Z - 0.05, "the landlady's desk, the ledger, the safe (guests' valuables)"),
    R("parlour", "ground", 0.1, 0.1, PARLOUR_X - 0.05, BACK_Z - 0.05, "the ladies' parlour: the piano, settees and chairs in velvet, the centre table, the best carpet; the ladies' own door"),
    R("dining", "ground", 0.1, BACK_Z + 0.05, STAIR_X - 0.05, D - 0.1, "eight tables of six on white linen, two sideboards, laid for supper ('Supper's at six. Late is cold.')"),
    R("stair_hall", "ground", STAIR_X + 0.05, BACK_Z + 0.05, SAMPLE_X - 0.05, D - 0.1, "the back stair, the back door from the yard, the way to the bar"),
    R("sample", "ground", SAMPLE_X + 0.05, BACK_Z + 0.05, W - 0.1, D - 0.1, "drummers' trunks open on long tables for the town's storekeepers; the lane door"),
    R("hall", "upper", 0.1, UP_FRONT_Z + 0.05, W - 0.1, BACK_Z - 0.05, "the upper hall, 80 ft: a runner, a lamp every few doors, the grand stair's well railed"),
    R("room_1", "upper", 21.34 + 0.05, 0.1, W - 0.1, UP_FRONT_Z - 0.05, "a front room onto the gallery"),
    R("room_2", "upper", 18.29 + 0.05, 0.1, 21.34 - 0.05, UP_FRONT_Z - 0.05, "a front room onto the gallery"),
    R("room_3", "upper", 15.24 + 0.05, 0.1, 18.29 - 0.05, UP_FRONT_Z - 0.05, "a front room onto the gallery"),
    R("suite_parlour", "upper", 11.58 + 0.05, 0.1, 15.24 - 0.05, UP_FRONT_Z - 0.05, "the best suite's parlour: the French doors to the gallery, the writing table (Rourke's letter)"),
    R("suite_bed", "upper", 7.92 + 0.05, 0.1, 11.58 - 0.05, UP_FRONT_Z - 0.05, "the suite's bedroom: the carved walnut bedstead"),
    R("room_4", "upper", 3.96 + 0.05, 0.1, 7.92 - 0.05, UP_FRONT_Z - 0.05, "room 4, dressed: a brass bed, washstand, wardrobe"),
    R("room_5", "upper", 0.1, 0.1, 3.96 - 0.05, UP_FRONT_Z - 0.05, "a front room onto the gallery"),
    R("room_6", "upper", 20.12 + 0.05, BACK_Z + 0.05, W - 0.1, D - 0.1, "a back room: an iron bed, washstand, chair"),
    R("back_stair_up", "upper", 17.07 + 0.05, BACK_Z + 0.05, 20.12 - 0.05, D - 0.1, "the back stair's head"),
    R("bath", "upper", 15.6 + 0.05, BACK_Z + 0.05, 17.07 - 0.05, D - 0.1, "the bath room: a tin tub, water carried up; the linen press"),
    R("room_7", "upper", 11.89 + 0.05, BACK_Z + 0.05, 15.6 - 0.05, D - 0.1, "a back room"),
    R("room_8", "upper", 8.53 + 0.05, BACK_Z + 0.05, 11.89 - 0.05, D - 0.1, "a back room"),
    R("landlady_sit", "upper", 4.27 + 0.05, BACK_Z + 0.05, 8.53 - 0.05, D - 0.1, "her sitting room: her husband's photograph, the sewing machine, the account books"),
    R("landlady_bed", "upper", 0.1, BACK_Z + 0.05, 4.27 - 0.05, D - 0.1, "her bedroom"),
    R("beer_cellar", "cellar", BAR_X + 0.05, CEL[1] + 0.25, W - T - 0.02, CEL_BEER_Z - 0.05, "kegs on stillage, the bulkhead to the lane, the trap's stair down from behind the bar; the drift's door in the west wall"),
    R("stores", "cellar", CEL[0] + 0.25, CEL[1] + 0.25, BAR_X - 0.05, BACK_Z - 0.05, "potatoes and onions in bins, flour in barrels, hams hung, crocks, canned goods by the case"),
    R("passage", "cellar", CEL[0] + 0.25, BACK_Z + 0.05, BAR_X - 0.05, CEL_BEER_Z - 0.05, "the passage across to the back rooms"),
    R("coal", "cellar", SAMPLE_X + 0.05, CEL_BEER_Z + 0.05, W - T - 0.02, D - T - 0.02, "coal off the railroad for the range and the stoves"),
    R("ice_room", "cellar", STAIR_X + 0.05, CEL_BEER_Z + 0.05, SAMPLE_X - 0.05, D - T - 0.02, "ice cut on the creek in winter in sawdust, meat hung, the milk and butter"),
    R("wine_room", "cellar", CEL[0] + 0.25, CEL_BEER_Z + 0.05, STAIR_X - 0.05, D - T - 0.02, "locked, racked: claret, champagne, port, brandy, whisky in the wood; the Baron's own bin"),
]
UP = UPPER
C = FLAGS
P = lambda id_, use, who, x, y, z, lx, lz, **k: dict({"id": id_, "use": use, "who": who, "at": [r3(x), r3(y), r3(z)], "look": [r3(lx), r3(lz)]}, **k)
spec["use_points"] = [
    P("barman_a", "serve", "barman", 23.1, FLOOR, 2.2, 21.0, 2.2),
    P("barman_b", "serve", "barman", 23.1, FLOOR, 4.4, 21.0, 4.4),
    P("drinker_1", "drink", "anyone", 21.2, FLOOR, 2.0, 22.2, 2.0),
    P("drinker_2", "drink", "anyone", 21.2, FLOOR, 4.6, 22.2, 4.6),
    P("clerk", "serve", "clerk", 15.6, FLOOR, 3.6, 15.6, 6.0, _doc="behind the desk, in front of the office"),
    P("register", "stand", "anyone", 15.6, FLOOR, 5.0, 15.6, 3.6, _doc="a guest at the desk"),
    P("lobby_settee", "sit", "anyone", 10.0, FLOOR, 2.0, 12.5, 4.0),
    P("office_desk", "work", "landlady", 16.6, FLOOR, 1.4, 16.6, 0.4),
    P("parlour_piano", "sit", "anyone", 2.0, FLOOR, 7.6, 2.0, 8.4),
    P("parlour_window", "watch", "anyone", 5.94, FLOOR, 0.7, 5.94, -8.0),
    P("dining_1", "eat", "anyone", 4.0, FLOOR, 11.0, 4.0, 12.0),
    P("dining_2", "eat", "anyone", 11.0, FLOOR, 13.0, 11.0, 12.0),
    P("waitress", "serve", "waitress", 16.0, FLOOR, 14.3, 13.0, 12.0),
    P("back_door", "stand", "anyone", 19.3, FLOOR, 13.8, 19.3, 9.0),
    P("drummer", "work", "anyone", 22.2, FLOOR, 11.5, 22.2, 13.0),
    P("hall_end", "watch", "anyone", 23.6, UP, 7.3, 30.0, 7.3),
    P("hall_stair", "stand", "anyone", 10.0, UP, 7.0, 13.0, 7.0),
    P("room_1", "sleep", "anyone", 22.86, UP, 4.0, 22.86, 1.0),
    P("room_2", "sleep", "anyone", 19.81, UP, 4.0, 19.81, 1.0),
    P("room_3", "sleep", "anyone", 16.76, UP, 4.0, 16.76, 1.0),
    P("suite_desk", "work", "anyone", 13.4, UP, 3.0, 14.8, 3.0, _doc="the writing table: Rourke's letter (S7)"),
    P("suite_window", "shoot", "anyone", 13.41, UP, 1.3, 13.41, -10.0, _doc="at the French doors onto the gallery"),
    P("suite_bed", "sleep", "anyone", 9.7, UP, 4.0, 9.7, 1.0),
    P("room_4", "sleep", "anyone", 5.94, UP, 4.0, 5.94, 1.0),
    P("room_5", "sleep", "anyone", 1.98, UP, 4.0, 1.98, 1.0),
    P("room_6", "sleep", "anyone", 22.2, UP, 12.5, 22.2, 14.0),
    P("back_stair_up", "stand", "anyone", 19.3, UP, 9.4, 19.3, 12.0),
    P("bath", "stand", "anyone", 16.3, UP, 12.0, 16.3, 14.0),
    P("room_7", "sleep", "anyone", 13.6, UP, 12.5, 13.6, 14.0),
    P("room_8", "sleep", "anyone", 10.2, UP, 12.5, 10.2, 14.0),
    P("landlady_sit", "sit", "landlady", 6.4, UP, 11.5, 6.4, 14.0),
    P("landlady_bed", "sleep", "landlady", 2.2, UP, 12.5, 2.2, 14.0),
    P("gallery_1", "drink", "anyone", 20.0, UP, -1.4, 20.0, -9.0, _doc="the girder men's night: on the gallery (the Balcony Ambush)"),
    P("gallery_2", "drink", "anyone", 12.0, UP, -1.4, 12.0, -9.0),
    P("gallery_3", "shoot", "anyone", 6.0, UP, -1.6, 6.0, -12.0),
    P("kegs", "work", "barman", 21.0, C, 6.5, 22.6, 6.5, _doc="at the stillage"),
    P("drift_door", "stand", "anyone", 23.2, C, 9.45, 25.0, 9.45, _doc="the drift's door in the west wall: a lamp's flame leans"),
    P("stores", "work", "cook", 13.0, C, 6.0, 13.0, 4.0),
    P("passage", "stand", "anyone", 13.0, C, 9.7, 18.0, 9.7),
    P("coal", "work", "anyone", 22.2, C, 13.0, 22.2, 14.5),
    P("ice", "work", "cook", 18.6, C, 13.0, 18.6, 14.5),
    P("wine", "stand", "landlady", 13.0, C, 13.0, 13.0, 14.5),
]
K = lambda room, wall, level, at, h, **k: dict({"room": room, "kit": "reflector_lamp", "wall": wall, "level": level, "at": r3(at), "height": h, "lit": [17, 23]}, **k)
spec["lamps"] = {
    "_doc": "#824's rules: a lamp each room, kit lamps on the walls, lit by the clock (the chandeliers, the newel lamp and the brackets are the prop lab's: the brief's 7.1 layer 3). Kerosene only (the brief's section 2). Only the rooms a player is likely in cast shadows. The cellar's lit day and night.",
    "kit": [
        K("bar", "g_bar", "ground", 2.0, 1.7, side="+", energy=1.3, reach=7.0, shadows=True, lit=[16, 1]),
        K("lobby", "g_parlour", "ground", 6.4, 1.7, side="+", energy=1.4, reach=8.0, shadows=True, lit=[16, 24]),
        K("office", "g_office_e", "ground", 1.5, 1.6, side="+", energy=0.8, reach=4.0),
        K("parlour", "g_parlour", "ground", 6.4, 1.6, side="-", energy=1.2, reach=7.0),
        K("dining", "g_back", "ground", 8.0, 1.7, side="+", energy=1.4, reach=8.0, shadows=True, lit=[17, 21]),
        K("stair_hall", "g_stair", "ground", 2.0, 1.7, side="+", energy=0.8, reach=5.0),
        K("sample", "g_sample", "ground", 4.0, 1.7, side="+", energy=0.9, reach=6.0),
        K("hall", "u_front", "upper", 8.0, 1.7, side="+", energy=0.9, reach=7.0, shadows=True, lit=[17, 24]),
        K("hall", "u_front", "upper", 18.0, 1.7, side="+", energy=0.9, reach=7.0, lit=[17, 24]),
        K("suite_parlour", "u_front", "upper", 14.6, 1.6, side="-", energy=1.0, reach=5.0, shadows=True, lit=[18, 24]),
        K("room_4", "u_front", "upper", 4.6, 1.6, side="-", energy=0.8, reach=4.0, lit=[20, 23]),
        K("landlady_sit", "u_back", "upper", 7.6, 1.6, side="+", energy=0.8, reach=4.0, lit=[19, 23]),
        K("beer_cellar", "c_beer", "cellar", 3.0, 1.5, side="+", energy=1.0, reach=6.0, shadows=True, lit=[0, 24]),
        K("stores", "c_beer", "cellar", 3.0, 1.5, side="-", energy=0.8, reach=6.0, lit=[0, 24]),
        K("passage", "c_back", "cellar", 6.0, 1.5, side="-", energy=0.6, reach=5.0, lit=[0, 24]),
    ],
}
spec["light"] = copy.deepcopy(SB["light"])
spec["light"]["_doc"] = "saloon B's dials for a big two-storey frame (#867): the windows light the front rooms, the fill lifts the far walls"
spec["fixtures"] = [
    {"_doc": "The small fine bar (Sean: 'a nice small bar'): two 3 m kit sections down the lane wall, the back bar's two sections with their mirrors against it (the brief's walnut bar and back bar are the prop lab's: J. M. Brunswick & Balke on the back bar's crest)", "kit": "bar", "at": [r3(W - 2.25), 2.0], "facing": 270, "repeat": {"count": 2, "step": [0, 3.0]}},
    {"kit": "back_bar", "at": [r3(W - 0.48), 1.75], "facing": 270, "repeat": {"count": 2, "step": [0, 2.5]}},
]
spec["furniture"] = []

# --- the look (step 4: the library's entries by name) -------------------------------------------------
mt = copy.deepcopy(SB["materials"])
mt["_doc"] = "Finishes by name from the material library (spec_building.gd finish()): a finish's `want` the moment the library has it passed at that age, until then its `use` (a passed entry). Outside, Sean's three colours (#1215, the sheet): a soft blue-grey body on narrow planed lap (`painted_bluegrey_lap`), cream trim (`painted_cream_trim`: corner boards, casings, cornice, the gallery's posts, beams and rail), a deep red on the brackets, the name board and the sash (`painted_red_trim`): each NEW, a colour of an approved paint, judged in step 4; until they pass, the approved white, buff and ox-blood. Inside: walnut wainscot in the public rooms with pale boards over (wallpaper and plaster are the next system), oak for the stair, doors and rails, the worn fir floor."
mt["wear"] = {"use": 0.5, "dings": 0.0, "_why": "#901: a hotel a year old and kept: swept every morning, the lobby and the stair the most walked"}
mt["finishes"]["exterior"] = {"want": {"entry": "painted_bluegrey_lap", "age": "few"}, "use": {"entry": "painted_white_lap", "age": "few"}, "_why": "the soft blue-grey body (the set-direction brief, the sheet)"}
mt["finishes"]["trim"] = {"want": {"entry": "painted_cream_trim", "age": "few"}, "use": {"entry": "painted_buff_drop", "age": "few"}, "_why": "cream trim"}
mt["finishes"]["red"] = {"want": {"entry": "painted_red_trim", "age": "few"}, "use": {"entry": "painted_oxblood_batten", "age": "few", "role": "wall"}, "_why": "the deep red picked out: brackets, the name board, the sash"}
surf = [["front/sign", "red"], ["/cornice_bracket", "red"], ["/sash", "red"], ["floor/roof/board", "rough"], ["floor/roof/joist", "framing"],
        ["drift/", "rough"], ["foundation/", "-"], ["street/post", "trim"], ["street/beam", "trim"], ["street/rail", "trim"], ["street/ledger", "trim"],
        ["floor/street_", "rough"], ["ceiling/", "inside"], ["bulkhead/", "rough"], ["c_", "rough"]]
keep = [s for s in mt["surfaces"] if not s[0].startswith(("stage", "stair/stage", "stair/wing", "floor/dance", "floor/office", "floor/gallery", "floor/link", "floor/hall", "floor/rooms", "corner/", "street/", "landing/", "stair/outside", "front/sign"))]
floors = [["floor/%s/board" % f, "floor"] for f in ("up_e", "up_well", "up_w", "up_back")] + [["floor/%s/joist" % f, "framing"] for f in ("up_e", "up_well", "up_w", "up_back")]
mt["surfaces"] = surf + keep + floors + [["stair/grand", "oak"], ["stair/back_door", "rough"], ["stair/back", "oak"]]
spec["materials"] = mt
spec["sources"] = [
    "docs/briefs/hotel.md (#1146, the design; its section 11 the period sources: the Teller House and Hotel de Paris NRHP nominations, NPS on metal ceilings and wallpaper)",
    "docs/briefs/hotel/draw_plans.py (the plans in feet) and experiments/building_lab/hotel/sheet/ (the target: the look)",
    "saloon_b.json's frame (Hatfield 1877/1880, Kidder 1895, Bell 1858, Woodward 1869, How to Build Houses 1889)",
    "Flat roofs of tin (terne plate) on boards behind a parapet: the period's commercial blocks (Hodgson 1883, 'Tin roofing'); the fall to the back drawn level",
    "Mine timbering (the drift): three-piece sets of a cap and two legs on a sill, lagged (Peele, Mining Engineers' Handbook's 1918 summary of 1870s-80s practice; Colorado's 'drift sets' 4-5 ft apart)",
]

out = ROOT / "config/buildings/hotel.json"
out.write_text(json.dumps(spec, indent="\t") + "\n")
print("wrote", out, len(out.read_text()), "bytes")
