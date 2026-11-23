#!/usr/bin/env python3
"""The general store's spec (#858, step 2): writes config/buildings/store.json.

Kept as a script while the numbers move (RECIPE.md "Write the spec with a script"); the JSON is the
spec. Sizes in metres in the building's own space (FORMAT.md): x from its EAST front corner westward,
z back from the front wall's outer face, y up from the ground at the walk's street edge. Built on
saloon B's frame (a two-storey false front on queen-post trusses over a cellar) by the doctor's
rules (#824 light, #825 floors, #826 walls and windows). Run from the repo root.
"""
import json
import os
import sys
import copy

FT = 0.3048
W = 16.76        # 55 ft across the lot (x -54.3..-37.4 is 16.9 m): flush to the alley, 14 cm off the hardware
D = 17.07        # 56 ft deep, a back yard behind it on the 20 m lot
FLOOR = 1.10     # the loading dock's top (valley.json walk.h), wagon-bed height
UPPER = 5.00     # the upper floor's top: 12 ft storeys
PLATE = 7.90     # 9 ft 6 in upstairs
FRONT_TOP = 10.4
CELLAR = FLOOR - 2.5
T = 0.45         # the stone's thickness (frame.foundation)
BX = [round(W / 3, 3), round(2 * W / 3, 3)]     # the two bearing lines under the upper floor
PART_Z = 10.8    # the shop's back wall and the loft's
HALL_Z = 12.1    # the upper hall's south wall
CELLAR_Z = 9.5   # the cellar's back wall


def strip_doc(x):
    return x


saloon = json.load(open("config/buildings/saloon_b.json"))
frame = copy.deepcopy(saloon["frame"])
frame.pop("_doc", None)
for k in list(frame):
    if isinstance(frame[k], dict):
        frame[k].pop("_doc", None)
frame["foundation"] = {"wood": "stone", "thick": T, "bottom": -0.3, "top": round(FLOOR - 0.025 - 0.25 - 0.2, 3), "piece": 1.5}
frame["truss"]["at"] = [0.25, 3.05, 6.1, 9.14, 12.19, 15.24, round(D - 0.3, 2)]
half = W / 2
import math
plen = half / math.cos(math.radians(9.46))
frame["truss"]["purlins"] = [0.3, round(plen * 0.35, 1), round(plen * 0.67, 1), round(plen - 0.1, 1)]
frame["stud"]["tall"] = {"section": [0.1, 0.1], "walls": ["front", "back", "alley", "hardware"]}

GIRDERS = [2.9, 5.85, 8.8, 11.9, 14.9]
EVERY = frame["girder"]["pier_every"]
cellar_posts = []
for z in GIRDERS:
    if 0.2 < z < CELLAR_Z - 0.3:
        k = 1
        while EVERY * k < W - 0.4:
            cellar_posts.append([round(EVERY * k, 3), z])
            k += 1

# ---- walls ---------------------------------------------------------------------------------------

def outside():
    return {"siding": "lap", "wood": "painted_white", "exposure": 0.1}


def inside(length, upper=True):
    f = [{"level": "ground", "from": 0.1, "to": round(length - 0.1, 3), "finish": "boards"}]
    if upper:
        f.append({"level": "upper", "from": 0.1, "to": round(length - 0.1, 3), "finish": "boards"})
    return f


def win(level, at, width, height, sill, lights=4, **kw):
    d = {"type": "window", "level": level, "at": at, "width": width, "height": height, "sill": sill, "lights": lights}
    d.update(kw)
    return d


DOOR_X = round(W / 2, 3)
# The storefront (#1053): its glass from the bulkhead (0.5 m) to SF_H over the floor, the transom row its top
# SF_TRANSOM; the recess's mouth between the front's two posts (each 0.2 m, under the beams at BX), its
# kings (0.1 m, the front's tall studs) clear of them, a 10 in header over its 5.2 m (a 6 in bent past its
# limit under the false front); the show windows from 1.94 m in to the posts. The glass's head stays under the
# ribbon the loft's joists sit on.
SF_H = 3.4
SF_TRANSOM = 0.5
POST_HALF = 0.1
RECESS_W = round(BX[1] - BX[0] - 2 * (POST_HALF + 0.1 + 0.005), 3)
SHOW_W = 3.44
SHOW_X = round(BX[0] - POST_HALF - 0.1 - 0.005 - SHOW_W / 2, 3)


def show(at, **kw):
    d = {"type": "window", "show": True, "level": "ground", "at": at, "width": SHOW_W, "height": round(SF_H - 0.5, 3),
         "sill": 0.5, "transom": SF_TRANSOM, "cols": 2, "transom_lights": 4,
         # #1074 (Sean's pick on #1067): the storekeeper's name gilded on the glass, the trades under it
         # (tools/textures/gold_leaf.py, Storefront.gilt), its middle 1.45 m over the opening's foot (2 m off the floor).
         "gilt": {"id": "hollis", "y": 1.45, "width": 2.65}}
    d.update(kw)
    return d
front = {
    "id": "front", "line": [[0, 0], [W, 0]], "out": "-z", "top": FRONT_TOP, "outside": outside(),
    "inside": inside(W),
    "openings": [
        # The storefront (#1053, Sean 2026-11-17: "a real store front", the recessed entry definite): NPS
        # Preservation Brief 11's display windows on a low bulkhead, transoms over them and the door, the
        # entry recessed with the show glass angling in to it. The glass between the front's two posts
        # (x 5.49-5.69 and 11.07-11.27, under the beams) and out to 1.9 m from each corner: 70% of the width.
        {"type": "recess", "level": "ground", "at": DOOR_X, "width": RECESS_W, "height": SF_H, "depth": 1.2, "header": 0.25,
         "door": {"width": 1.22, "height": 2.4}, "bulkhead": 0.5, "transom": SF_TRANSOM,
         "_doc": "the recessed entry: the door 1.2 m in, glazed, a transom light over it; the show glass angling in from the posts to its jambs over a panelled bulkhead; a boarded ceiling at the head"},
        show(SHOW_X, _doc="the east show window, its display shelf behind"),
        show(round(W - SHOW_X, 3), _doc="the west show window"),
        win("upper", SHOW_X, 1.0, 1.7, 0.6, _doc="the stock loft's, over the show window, centred"),
        win("upper", DOOR_X, 1.0, 1.7, 0.6, _doc="over the door"),
        win("upper", round(W - SHOW_X, 3), 1.0, 1.7, 0.6),
    ],
}
alley = {
    "id": "alley", "line": [[0, 0], [0, D]], "out": "-x", "top": "plate", "outside": outside(),
    "inside": inside(D),
    "openings": [
        win("ground", 2.3, 1.0, 1.5, 0.9, _doc="the shop, by the east counter"),
        win("ground", 4.2, 1.0, 1.5, 0.9),
        win("ground", 13.9, 1.0, 1.4, 1.0, _doc="the storeroom"),
        win("upper", 2.3, 0.9, 1.5, 0.6, _doc="the loft"),
        win("upper", 5.4, 0.9, 1.5, 0.6),
        win("upper", 8.5, 0.9, 1.5, 0.6),
        win("upper", 14.5, 0.9, 1.4, 0.6, _doc="the family's first room"),
    ],
}
hardware = {
    "id": "hardware", "line": [[W, 0], [W, D]], "out": "+x", "top": "plate", "outside": outside(),
    "inside": inside(D),
    "openings": [],
    "_doc": "against the hardware store (valley.json gap_n3, 0.3 m): a blank wall, no window or door",
}
back = {
    "id": "back", "line": [[0, D], [W, D]], "out": "+z", "top": "gable", "outside": outside(),
    "inside": inside(W),
    "openings": [
        {"type": "door", "level": "ground", "at": 9.35, "width": 1.07, "height": 2.13, "glazed": False, "leaf": "outward",
         "_doc": "the storeroom's back door onto the yard, 5 steps down"},
        win("ground", 4.1, 0.9, 1.3, 1.0, _doc="the storeroom"),
        win("ground", 14.2, 0.9, 1.3, 1.0),
        win("upper", 4.1, 0.9, 1.4, 0.6, _doc="room 1"),
        win("upper", 9.35, 0.9, 1.4, 0.6, _doc="room 2, over the door"),
        win("upper", 14.2, 0.9, 1.4, 0.6, _doc="room 3"),
    ],
}


def partition(id_, line, level, bearing, openings, sides=("boards", "boards"), **kw):
    d = {"id": id_, "line": line, "partition": True, "level": level, "bearing": bearing,
         "inside": [{"side": "-", "finish": sides[0]}, {"side": "+", "finish": sides[1]}], "openings": openings}
    d.update(kw)
    return d


def pdoor(at, w=0.86, h=2.03, **kw):
    d = {"type": "door", "at": at, "width": w, "height": h}
    d.update(kw)
    return d


walls = [
    front, alley, hardware, back,
    partition("shop_back", [[0.1, PART_Z], [W - 0.1, PART_Z]], "ground", True, [pdoor(DOOR_X - 0.1, 1.1, 2.1)],
              _doc="the shop's back wall; the two bearing lines' beams butt it"),
    partition("loft_back", [[1.45, PART_Z], [W - 0.1, PART_Z]], "upper", False, [pdoor(3.0 - 1.45)],
              _doc="the loft's back wall from the stair's corner east: the stair lands in the loft's north-east corner, the door to the hall is at x 3.0"),
    partition("rooms_front", [[1.45, HALL_Z], [W - 0.1, HALL_Z]], "upper", False,
              [pdoor(4.0 - 1.45, 0.81), pdoor(9.35 - 1.45, 0.81), pdoor(14.2 - 1.45, 0.81)]),
    partition("room_1_2", [[6.9, HALL_Z + 0.05], [6.9, D - 0.1]], "upper", False, []),
    partition("room_2_3", [[11.8, HALL_Z + 0.05], [11.8, D - 0.1]], "upper", False, []),
]

# ---- floors, stairs, posts ---------------------------------------------------------------------------

TRAP = [0.5, round(GIRDERS[1] + 0.1, 3), 1.5, round(GIRDERS[2] - 0.1, 3)]
floors = [
    {"id": "ground", "level": "ground", "rect": [0.1, 0.1, W - 0.1, D - 0.1], "joists": "z", "look": "wood:int_floor",
     "openings": [{"id": "trap", "rect": TRAP, "hatch": 2}]},
    {"id": "loft", "level": "upper", "joist": "dance_joist", "end_gap": 0.012, "rect": [0.1, 0.1, W - 0.1, PART_Z - 0.05],
     "joists": "x", "breaks": BX, "look": "wood:int_floor",
     "_doc": "the stock loft over the shop, 3x12 at 12 in across the building, broken over the two beams; the stair arrives at its back edge"},
    {"id": "family", "level": "upper", "joist": "long_joist", "rect": [1.3, PART_Z - 0.05, W - 0.1, D - 0.1],
     "joists": "x", "breaks": BX, "look": "wood:int_floor",
     "_doc": "the hall and the family's rooms over the storeroom, to the stair's beam"},
]
STAIR_RISERS = 22
stairs = [
    {"id": "main", "head": [0.15, PART_Z - 0.05], "dir": "-z", "width": 1.0, "from": "ground", "to": "upper",
     "risers": STAIR_RISERS, "going": 0.25, "rail": "+x", "look": "wood:int_oak", "stringer_look": "wood:int_timber",
     "posts": [[0.2, 13.5], [1.05, 13.5]],
     "_doc": "the storeroom's stair up the alley wall to the upper hall: 22 risers of 7 in, 10 in treads (Hodgson 1884)"},
    {"id": "back_store", "head": [8.75, D + 1.0], "dir": "-z", "width": 1.2, "from": 0.0, "to": "ground", "risers": 6,
     "going": 0.28, "wood": "weathered_pine", "stoop": [8.75, D, 9.95, D + 1.0],
     "_doc": "the storeroom's back door: six steps to the yard"},
]
posts = {
    "free": [[bx, z] for bx in BX for z in (3.4, 6.4, 10.5, 11.1, 14.0)] + [[1.3, 11.0], [1.3, 14.0]],
    "wall": [[bx, 0.05] for bx in BX] + [[bx, round(D - 0.05, 3)] for bx in BX + [1.3]],
}
beams = []
for i, bx in enumerate(BX):
    beams.append({"id": "front_%d" % i, "from": [bx, 0.1], "to": [bx, PART_Z - 0.05],
                  "_doc": "carries the loft's joists both sides, butted to the shop's back wall"} if i == 0 else
                 {"id": "front_%d" % i, "from": [bx, 0.1], "to": [bx, PART_Z - 0.05]})
    beams.append({"id": "back_%d" % i, "from": [bx, PART_Z + 0.05], "to": [bx, round(D - 0.1, 3)]})
beams.append({"id": "stair", "from": [1.3, 10.93], "to": [1.3, round(D - 0.1, 3)], "_doc": "the stair's well: the upper hall's edge beside the stair"})

# ---- rooms and use points -------------------------------------------------------------------------

rooms = [
    {"id": "shop", "level": "ground", "rect": [0.1, 0.1, W - 0.1, PART_Z - 0.05],
     "use": "the long shop: a counter along each side, shelving to the ceiling, the stove, the scale, the post office pigeonholes; customers browse and queue, the storekeeper serves and writes his day-book"},
    {"id": "storeroom", "level": "ground", "rect": [0.1, PART_Z + 0.05, W - 0.1, D - 0.1],
     "use": "stock and the back door; the stair up to the family's rooms"},
    {"id": "cellar", "level": "cellar", "rect": [T + 0.05, T + 0.05, W - T - 0.05, CELLAR_Z - T - 0.05],
     "use": "the goods cellar: flour, salt pork, pickles, a keg of powder; its stair behind the east counter, its doors under the dock"},
    {"id": "loft", "level": "upper", "rect": [0.1, 0.1, W - 0.1, PART_Z - 0.05],
     "use": "stock loft over the shop: cloth, boots, hardware; windows over Main Street"},
    {"id": "hall", "level": "upper", "rect": [1.5, PART_Z + 0.05, W - 0.1, HALL_Z - 0.05], "use": "the upper hall at the stair's head"},
    {"id": "room_1", "level": "upper", "rect": [1.4, HALL_Z + 0.05, 6.85, D - 0.1], "use": "the storekeeper's and his wife's bedroom"},
    {"id": "room_2", "level": "upper", "rect": [6.95, HALL_Z + 0.05, 11.75, D - 0.1], "use": "the family's sitting room and table"},
    {"id": "room_3", "level": "upper", "rect": [11.85, HALL_Z + 0.05, W - 0.1, D - 0.1], "use": "the children's room, or a lodger's"},
]


def up(id_, use, who, at, look, level="ground", **kw):
    y = {"ground": FLOOR, "upper": UPPER, "cellar": CELLAR + 0.08}[level]
    d = {"id": id_, "use": use, "who": who, "at": [at[0], y, at[1]], "look": list(look)}
    d.update(kw)
    return d


use_points = [
    up("serve_east", "serve", "storekeeper", (1.45, 4.0), (2.3, 4.0), _doc="behind the east counter (G1, #1139: its counter at x 2.0-2.6, z 2.0-5.3, in the light of the alley windows)"),
    up("ledger", "work", "storekeeper", (13.3, 9.5), (13.3, 8.7), _doc="the day-book on the back counter; the witness's place (OUTLINE: the handsaw sold to a stranger)"),
    up("post_office", "work", "storekeeper", (15.5, 9.15), (16.3, 9.15), _doc="the pigeonholes bay, west_shelves_d (G3, #1182: the case of pigeonholes; the postmaster's desk behind him at the back wall)"),
    up("buy_1", "buy", "anyone", (3.5, 3.2), (2.6, 3.2)),
    up("buy_2", "buy", "anyone", (13.5, 3.2), (14.9, 3.2)),
    up("browse_1", "stand", "anyone", (8.4, 2.6), (8.4, 6.0)),
    up("browse_2", "stand", "anyone", (8.4, 7.4), (8.4, 9.5)),
    up("wait_1", "wait", "anyone", (6.6, 4.4), (6.6, 6.0)),
    up("stove", "stand", "anyone", (10.2, 7.6), (10.2, 9.6)),
    up("watch_street", "watch", "anyone", (6.7, 1.0), (6.7, -3.0)),
    up("store_1", "work", "anyone", (4.2, 14.2), (4.2, 15.8)),
    up("store_2", "work", "anyone", (12.6, 14.2), (12.6, 15.8)),
    up("cellar_1", "work", "anyone", (4.5, 4.4), (4.5, 6.0), level="cellar"),
    up("cellar_2", "work", "anyone", (11.0, 4.4), (11.0, 6.0), level="cellar"),
    up("loft_1", "work", "anyone", (4.2, 3.0), (4.2, 0.2), level="upper"),
    up("loft_2", "work", "anyone", (12.4, 4.4), (12.4, 6.5), level="upper"),
    up("loft_window", "shoot", "anyone", (8.4, 1.0), (8.4, -3.0), level="upper", _doc="the middle front window over Main Street"),
    up("hall_stand", "stand", "anyone", (8.4, 11.45), (8.4, 10.9), level="upper"),
    up("room1_sleep", "sleep", "storekeeper", (3.6, 15.4), (3.6, 13.0), level="upper"),
    up("room2_eat", "eat", "storekeeper", (9.35, 14.8), (9.35, 13.0), level="upper"),
    up("room3_sleep", "sleep", "anyone", (14.2, 15.4), (14.2, 13.0), level="upper"),
]

LIT = [17, 23]
lamps = {"kit": [
    {"room": "shop", "kit": "reflector_lamp", "wall": "hardware", "level": "ground", "at": 3.4, "height": 1.7, "energy": 1.5, "reach": 7.0, "shadows": True, "lit": LIT, "_doc": "by the front counter"},
    {"room": "shop", "kit": "reflector_lamp", "wall": "hardware", "level": "ground", "at": 8.0, "height": 1.7, "energy": 1.5, "reach": 7.0, "shadows": True, "lit": LIT, "_doc": "by the day-book"},
    {"room": "shop", "kit": "reflector_lamp", "wall": "alley", "level": "ground", "at": 7.0, "height": 1.7, "energy": 1.3, "reach": 6.0, "lit": LIT},
    {"room": "storeroom", "kit": "reflector_lamp", "wall": "hardware", "level": "ground", "at": 14.0, "height": 1.6, "energy": 1.2, "reach": 6.0, "lit": LIT},
    {"room": "loft", "kit": "reflector_lamp", "wall": "hardware", "level": "upper", "at": 5.0, "height": 1.6, "energy": 1.2, "reach": 6.0, "lit": LIT},
    {"room": "hall", "kit": "reflector_lamp", "wall": "loft_back", "level": "upper", "at": 8.4, "side": "+", "height": 1.6, "energy": 1.0, "reach": 5.0, "lit": LIT},
    {"room": "room_1", "kit": "reflector_lamp", "wall": "room_1_2", "level": "upper", "at": 2.4, "side": "-", "height": 1.5, "energy": 1.0, "reach": 5.0, "lit": LIT},
    {"room": "room_2", "kit": "reflector_lamp", "wall": "room_2_3", "level": "upper", "at": 2.4, "side": "-", "height": 1.5, "energy": 1.0, "reach": 5.0, "lit": LIT},
    {"room": "room_3", "kit": "reflector_lamp", "wall": "hardware", "level": "upper", "at": 14.5, "height": 1.5, "energy": 1.0, "reach": 5.0, "lit": LIT},
]}
surfaces = [
    ["/recess/ceiling", "ceiling"], ["/recess/", "trim"], ["ceiling/", "ceiling"], ["front/sign", "trim"], ["/casing", "trim"], ["/skirt", "trim"], ["/window_", "trim"], ["/siding/", "exterior"],
    ["/corner_", "trim"], ["/trim_", "trim"], ["/transom_bar", "trim"], ["/cornice", "trim"], ["front/cap", "trim"],
    ["roof/ridge_cap", "trim"], ["front/door_", "trim"], ["back/door_", "trim"], ["/door_", "inside"],
    ["/in_ground/", "inside"], ["/in_upper/", "inside"], ["/m/board/", "inside"], ["/p/board/", "inside"],
    ["floor/ground/board", "floor"], ["floor/loft/board", "floor"], ["floor/family/board", "floor"],
    ["floor/loft/joist", "joists"], ["floor/family/joist", "joists"], ["beam/", "timber"], ["bracket/", "-"],
    ["wall_post/", "timber"], ["stair/main", "oak"], ["roof/board", "rough"], ["stoop/", "rough"], ["stair/back", "rough"],
    ["post/", "timber"],
]
materials = {
    "wear": {"use": 0.8, "dings": 0.0, "_why": "#901: a busy store, a wagon's freight rolled in daily; dents off with the doctor's (Sean 2026-11-14)"},
    "floor": "wood:int_floor", "wall_boards": "int_boards", "woodwork": "wood:int_oak", "timber": "wood:int_timber",
    "trim_outside": "painted_green", "roof": "weathered_pine", "rough": "framing",
    "finishes": {
        "exterior": {"want": {"entry": "painted_buff_drop", "age": "few"}, "use": {"entry": "common_pine_lap", "age": "old", "role": "wall"},
                     "_why": "Sean 2026-11-16: painted pale buff clapboard, the sheet; the merchant's pride, two years old"},
        "trim": {"want": {"entry": "painted_green_trim", "age": "few"}, "use": {"entry": "common_pine_lap", "age": "old", "role": "wall"}},
        "inside": {"want": {"entry": "painted_pale_tg", "age": "few"}, "use": {"entry": "fine_walnut_tg", "age": "few", "role": "wall"}},
        "ceiling": {"want": {"entry": "painted_pale_tg", "age": "few"}, "use": {"entry": "fine_walnut_tg", "age": "few", "role": "wall"},
                    "_why": "#1053: beaded boards painted pale under the loft's joists, the doctor's ceiling; the shop read black overhead (#1052)"},
        "floor": {"want": {"entry": "floor_fir_worn", "age": "few", "role": "floor"}, "use": {"entry": "fine_walnut_tg", "age": "few", "role": "floor"},
                  "_why": "oiled fir, worn on his ways (door to counter, counter to shelf), never a wall's or the trim's (#825)"},
        "framing": {"use": {"entry": "rough_pine_batten", "age": "few", "role": "wall"}},
        "rough": {"use": {"entry": "rough_pine_batten", "age": "few", "role": "wall"}},
        "oak": {"use": {"entry": "fine_walnut_tg", "age": "few", "role": "wall"}},
        "timber": {"want": {"entry": "painted_pale_tg", "age": "few"}, "use": {"entry": "fine_walnut_tg", "age": "few", "role": "wall"},
                   "_why": "Sean 2026-11-18 (#1067): the shop's posts and beams painted pale, like the ceiling"},
        "joists": {"use": {"entry": "fine_walnut_tg", "age": "few", "role": "wall"},
                   "_why": "the floor joists stay dark: hidden over the shop's ceiling, bare over the storeroom"},
    },
    "surfaces": surfaces,
}

# The show windows' goods (#1074, Sean on #1067: "goods in the windows, now"): what a passer-by reads as a
# general store, from the kit's props alone (docs/PARTS.md); what's missing (bolts of cloth, boots, tins,
# tinware) is the prop lab's (the after-slice issue named in the README). Each window a low display
# platform behind the glass (the kit's table fitted to the glass's foot), the goods on it facing the street
# (180: a prop faces +z); the east window groceries and dry goods with a cracker barrel at its east end, the
# west window hardware and crockery. x from the east corner, z in from the front wall's line.
EAST_X = SHOW_X
WEST_X = round(W - SHOW_X, 3)
DZ = 0.56  # the platforms' middle: their backs 0.21 in from the wall's line, clear of the studs and lining
# G1 (#1139) replaced the stand-ins: the windows' goods and the shop's fittings come from the prop lab's
# factory (tools/props/store_g1.py), which holds the numbers and the reasons (experiments/prop_lab/store/README.md).
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "tools", "props"))
import store_g1  # noqa: E402
import store_g2  # noqa: E402  (#1172: G2, the shelves filled, boots, hats, hardware, the mill and showcase, hung lamps)
import store_g3  # noqa: E402  (#1182: G3, the post office's case, the ledger and day-book, the till's cash, goods hung from the ceiling)

dressing = {
    "_doc": "#1074 the show windows' goods, #1139 batch G1 (the counters, wall shelving and ladders, the stove and its chairs, the barrels, sacks, scales and bolts of cloth), #1172 batch G2 (the shelves' tins and boxes, boots, hats, hardware, tinware, the coffee mill and a showcase, hung lamps), #1182 batch G3 (the post office's pigeonholes and mail, the postmaster's desk, the ledger and day-book, the till's cash, hung pails, hams and lanterns): PropDressing, written by tools/props/store_g1.py, store_g2.py and store_g3.py",
    "batches": {"windows": store_g1.dressing_windows(EAST_X, WEST_X, DZ),
                # (G3's case stands in the last west bay: G1's shelving there is dropped)
                "G1": [x for x in store_g1.dressing_g1() if x["id"] != store_g3.BAY_D[0]],
                "G2": store_g2.dressing_g2(), "G3": store_g3.dressing_g3()},
}

spec = {
    "_doc": "The general store and grocer (#858; the building lab's step 2). Format 1 (../FORMAT.md). valley.json town.north 'general_store' (x -54.3..-37.4, 55 x 56 ft): a two-storey false front on queen-post trusses over a goods cellar, the shop across the ground floor, a storeroom behind it, the stock loft over the shop and the family's rooms over the storeroom. Frame from saloon B's (#848), rules from the doctor's (#824-#826). Written by experiments/building_lab/store/gen_spec.py.",
    "format": 1, "id": "store",
    "identity": {
        "owner": "the storekeeper, a merchant who freighted his stock in from the railhead, with his wife and two children",
        "trade": "a general store and grocer: dry goods, groceries, hardware, patent medicines, a post office pigeonhole counter; credit on the book",
        "means": "the best-stocked building on the street: sawn lumber in 1880, painted buff with green trim, a loading dock at wagon height",
        "age_and_repair": "two years: the paint fresh, the dock's boards already worn along the wagons' line, the cellar doors' hinges rust-stained",
        "clues": ["the day-book open on the counter", "a rolling ladder on the shelves", "barrels of crackers and pickles by the stove", "the scale on the post office counter"],
        "class": "common", "built": 1880, "now": 1882,
    },
    "lot": {
        "_doc": "valley.json town.north 'general_store' (x -54.3..-37.4, depth 20): its origin the EAST front corner 3 cm off the store alley's line (x -37.4: the siding's face is the lot's line, the alley 1.2 m), west to the hardware store 14 cm off its wall. The dock and its steps are the valley's walk (h 1.1, awning 3.0, the east end dropping into the alley).",
        "valley_lot": "general_store", "side": "north", "at": [-37.43, 0.52, -10.05], "facing": 180,
        "width": W, "depth": D, "yard": [0.0, D, W, 20.0],
        "pad": {"_doc": "valley.json's pad: the lot dug level at the walk's street edge's ground (world 0.52, the building's y 0); the ground rises 0.63 m to the back of the lot"},
        "footprint_with_stair": [-0.3, -0.3, W + 0.3, D + 1.4],
        "walk_h": FLOOR, "yard_name": "BACK YARD",
    },
    "levels": {
        "_doc": "The floor at the loading dock's top, 1.10 m (wagon-bed height); 12 ft storeys (stock to the ceiling, a rolling ladder), 9 ft 6 in upstairs; the roof a low 2/12 on queen-post trusses (the saloon's), its ridge hidden behind the false front.",
        "cellar": {"floor": round(CELLAR, 2)}, "ground": {"top": FLOOR}, "upper": {"top": UPPER},
        "plate": PLATE, "false_front": FRONT_TOP, "roof_pitch": 9.46, "roof_tight": True,
    },
    "frame": frame,
    "girders": {"z": GIRDERS, "_doc": "Lines under the ground floor's joists, a joist span 3 m; in the cellar on its posts every 1.9 m, outside it on piers."},
    "cellar": {
        "_doc": "Under the front half, 13 x 9.5 m (the valley's 13 x 9): rubble-stone walls, 2.5 m under the floor. The trap by the east counter, its stair down the east wall; the doors under the dock at the street are the valley's (bulkhead: #695).",
        "rect": [0.0, 0.0, W, CELLAR_Z], "posts": cellar_posts, "flag": 1.2,
        "trap": {"rect": TRAP},
        "stair": {"head": [0.55, TRAP[1]], "dir": "-z", "width": 0.9, "risers": 13, "going": 0.2},
    },
    "posts": posts,
    "beams": beams,
    "floors": floors,
    "walls": walls,
    "inside_finish": {"boards": "judged", "skirting": 0.2},
    "stairs": stairs,
    "front": {"sign": "GENERAL STORE", "sign_from": 4.4, "sign_to": 5.45, "sign_width": 6.0, "cornice": "dark_trim",
              "brackets": {"spacing": 0.9, "drop": 0.34, "reach": 0.16, "width": 0.09, "sides": []}},
    "rooms": rooms,
    "use_points": use_points,
    "fixtures": [], "furniture": [],
    "ceilings": {"_doc": "#1053 (Sean's pick B on #1052): beaded boards nailed up under the loft's joists over the shop (the storeroom open to its joists: its stair goes up through them), painted pale (materials.finishes.ceiling), butted to the beams that hang under them; four beads a board", "finish": "beaded", "rooms": ["shop"], "around_beams": True, "width": 0.42},
    "lamps": lamps,
    "dressing": dressing,
    "light": {"_doc": "the doctor's light (#824, #829) scaled for a room 16.8 x 10.7 m: more fill and window light than his 8 m office, less than saloon B's 22 m hall; judged by day in #1035 (the doctor's 0.1 and 7 left the shop near black): 0.55 and 26",
              "fill": [0.62, 0.6, 0.57], "window_day": 26.0, "day_fill": 0.55},
    "materials": materials,
    "sources": [
        "Saloon B's frame (#848): queen-post trusses, 3x12 joists broken over girders on posts, the stacked-opening rules.",
        "William E. Bell, Carpentry Made Easy (1858), and George Woodward, Woodward's Country Homes (1865): the balloon frame, the false front's bracing.",
        "Hodgson, Steel Square and its Uses (1884): the stair's rise and going.",
    ],
}
json.dump(spec, open("config/buildings/store.json", "w"), indent=1)
print("wrote config/buildings/store.json", len(json.dumps(spec)) // 1024, "KB;", len(cellar_posts), "cellar posts")
