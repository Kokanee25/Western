#!/usr/bin/env python3
"""Harlan's homestead (#1126): writes the cabin's and the barn's specs (config/buildings/harlan_cabin.json,
harlan_barn.json) while their numbers move (the recipe's rule, from saloon B); keep only the JSON once
they settle. The site (where each stands, the corral, the yard things, the spring) is
config/buildings/harlan_homestead.json, written here too.

Sizes: Sean's 14 x 16 ft room (#1126) inside 6 1/2 in hewn logs; 9 in logs with 2 in chinking
(Weslager 1969, "The Log Cabin in America"; Kniffen and Glassie 1966); a 10/12 shake roof on 2x6 rafters
at 24 in, skip sheathing (Hodgson 1883's shingle lath). Everything in metres, the building's own space
(FORMAT.md): x along the chimney gable (its `front`, z 0) from its west corner, z back to the door
gable (its `back`, which faces the yard and the lane).

    python3 experiments/building_lab/homestead/gen_spec.py
"""
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
FT = 0.3048

# --- the cabin -------------------------------------------------------------------------------------
T = 0.17                     # the logs hewn to 6 1/2 in
IN_W, IN_D = 14 * FT, 16 * FT  # Sean's room, inside the logs
W = round(IN_W + 2 * T, 3)   # 4.607
D = round(IN_D + 2 * T, 3)   # 5.217
FOUND_TOP = 0.4
SILL_H = 0.2
SILL_TOP = FOUND_TOP + SILL_H
COURSE = 0.27                # a 9 in log and 2 in of chinking
COURSES = 9
PLATE = round(SILL_TOP + COURSE * COURSES, 3)   # 2.88: 2.4 m clear under the loft's joists
JOIST = [0.1, 0.235]         # hewn loft joists, 4 x 9 in at 16 in across the 14 ft room (a crowd in the loft: 2x10 failed at 1.19)
BT = 0.022
FLOOR = round(SILL_TOP + 0.03, 3)   # 0.48: the floor's joists notched into the sills, a step up
UPPER = round(PLATE + JOIST[1] + BT, 3)
PITCH = 39.8                 # 10/12
PORCH_D = 1.8
DOOR_Z = round(5.217 / 2 - 0.4, 3)   # the door a little east of the long side's middle (the porch's middle post clear)
DECK = round(FLOOR - 0.1, 3)  # the deck's ledger on the footing's stones

cabin = {
    "_doc": "Thomas Harlan's cabin (#1126, Sean 2026-11-21): one room of hewn logs, worn and half fixed. Written by experiments/building_lab/homestead/gen_spec.py; FORMAT.md 'A log building's parts'.",
    "format": 1,
    "id": "harlan_cabin",
    "identity": {
        "owner": "Thomas Harlan, ex-army hospital steward, forties, alone",
        "trade": "his homestead: he sleeps, cooks, washes and keeps his kit here; the claim's worth is the spring",
        "means": "a man with a little saved: bought the place worn from its last owner this spring",
        "age_and_repair": "the last owner raised it about 1874: the logs silver-grey, the chinking cracked and patched, the shakes curled; Harlan has started on it (a new log at the east wall's foot, a patch of new shakes) and left the rest for later: a patch of shakes missing, a porch board sprung, a rotten step",
        "clues": ["his army trunk at the bed's foot", "a shaving mirror and basin on the porch", "boards and shakes bought and stacked in the barn",
                  "one chair", "a new pale log among grey ones"],
    },
    "lot": {
        "_doc": "Placed by the site (config/buildings/harlan_homestead.json) on the harlan_homestead pad (valley.json), its door gable to the yard (north).",
        "at": [0.0, 0.0, 0.0], "facing": 0, "width": W, "depth": D,
    },
    "levels": {
        "_doc": "One storey: the floor a step up on the sills, nine courses of logs to the plate (2.4 m clear), the loft's joists on the side walls' top logs, a 10/12 roof gabled front to back, its rakes 0.35 m past the gables.",
        "ground": {"top": FLOOR}, "upper": {"top": UPPER}, "plate": PLATE, "false_front": 0.0,
        "roof_pitch": PITCH, "roof_from": -0.35, "roof_to": round(D + 0.35, 3),
    },
    "frame": {
        "_doc": "Hewn logs on hewn sills on a fieldstone footing; the floor's joists between the sills on a girder down the middle; the loft's joists across on the side walls' top logs; common rafters on them, skip sheathing, split shakes.",
        "foundation": {"wood": "stone", "thick": T, "bottom": -0.35, "top": FOUND_TOP, "piece": 1.2, "_doc": "dry fieldstone under the sills, a foot into the ground"},
        "sill": {"section": [T, SILL_H], "wood": "framing", "_doc": "hewn sill logs, the front and back's through the corners"},
        "log_wall": {"thick": T, "course": COURSE, "chink": 0.06, "inset": 0.012, "over": 0.14, "piece": 6.5,
                     "buck": 0.05, "wood": "framing", "chink_wood": "painted_white", "lap": 0.06, "gable_wood": "weathered_pine",
                     "_doc": "LogWall (src/structures/log_wall.gd): 6 1/2 in hewn faces, 9 in logs, 2 1/2 in of lime chinking (whitewash pale) set 1/2 in back, the ends 5 1/2 in past the corners"},
        "pier": {"size": 0.3, "wood": "stone"},
        "girder": {"section": [0.15, 0.15], "wood": "framing", "pier_every": 1.5},
        "joist": {"section": [0.05, 0.14], "spacing": 0.61, "wood": "framing", "_doc": "2x6 at 24 in, 7 ft spans either side of the girder"},
        "floor_board": {"width": 0.2, "thick": BT, "wood": "floor"},
        "stud": {"section": [0.05, 0.1], "spacing": 0.61, "wood": "framing"},
        "plate": {"height": 0.1}, "ribbon": {"section": [0.025, 0.15]}, "header": {"height": 0.15},
        "post": {"section": [0.12, 0.12], "wood": "framing"}, "beam": {"section": [0.12, 0.15], "wood": "framing"},
        "bracket": {"reach": 0.3, "thick": 0.08}, "wall_post": {"section": [0.15, 0.1]},
        "ceiling_joist": {"section": JOIST, "spacing": 0.406, "wood": "framing", "lap": 0.6, "_doc": "hewn 4 x 9 in at 16 in on the side walls' top logs, each spiked to a rafter's foot"},
        "rafters": {"rafter": [0.05, 0.14], "spacing": 0.61, "ridge": [0.025, 0.185], "collar": [0.025, 0.14],
                    "collar_every": 2, "collar_down": 0.25, "eave": 0.3},
        "truss": {"tie": [0.05, 0.14], "principal": [0.0, 0.0], "queen": [0.0, 0.0], "purlin": [0.0, 0.0],
                  "rafter": [0.05, 0.14], "rafter_spacing": 0.61, "at": [0.0, D], "purlins": []},
    },
    "girders": {"x": [round(W / 2, 3)]}, "ceilings": [],
    "floors": [
        {"id": "ground", "level": "ground", "rect": [T + 0.005, T + 0.005, round(W - T - 0.005, 3), round(D - T - 0.005, 3)], "joists": "x", "look": "wood:int_floor"},
        {"id": "loft", "level": "upper", "rect": [0.02, T + 0.01, round(W - 0.02, 3), round(D - T - 0.01, 3)], "joists": "x", "joist": "ceiling_joist",
         "_doc": "the loft over the room on the side walls' top logs: its boards the room's ceiling (storage; a ladder later)"},
    ],
    "shakes": {"exposure": 0.25, "width": 0.8, "strip": 0.16, "thick": 0.016, "lift": 0.012, "skip": 0.3, "new_share": 0.04,
               "missing": [{"side": 0, "s": [1.05, 1.85], "z": [1.6, 2.7], "repair": "roof_patch"}],
               "new": [{"side": 0, "s": [0.55, 1.05], "z": [1.4, 3.1]}, {"side": 0, "s": [1.85, 2.3], "z": [1.4, 2.9]}],
               "_doc": "split pine shakes, 10 in to the weather, on 1x6 boards a foot apart; the patch he's started round the hole"},
    "walls": [
        {"id": "front", "_doc": "the chimney gable (east): the stone chimney outside it, the stove against it", "line": [[0, 0], [W, 0]], "out": "-z", "top": "gable", "log": True,
         "openings": []},
        {"id": "back", "_doc": "the west gable: the woodpile against it", "line": [[0, D], [W, D]], "out": "+z", "top": "gable", "log": True, "openings": []},
        {"id": "west", "_doc": "the door's long side (Sean, 2026-11-21: the door on the long side, under the eave), to the yard and the lane (north): the door, a small window either side, the porch",
         "line": [[0, 0], [0, D]], "out": "-x", "top": "plate", "log": True,
         "openings": [
             {"type": "door", "level": "ground", "at": DOOR_Z, "width": 0.81, "height": 1.98, "leaf": "inward"},
             {"type": "window", "level": "ground", "at": 1.0, "width": 0.6, "height": 0.75, "sill": 0.9, "lights": 4},
             {"type": "window", "level": "ground", "at": round(D - 1.0, 3), "width": 0.6, "height": 0.75, "sill": 0.9, "lights": 4},
         ]},
        {"id": "east", "_doc": "the back long side (south): its window over the trunk; a new log at its foot (Harlan's first repair)", "line": [[W, 0], [W, D]], "out": "+x", "top": "plate", "log": True,
         "new": [[1, 0]],
         "openings": [{"type": "window", "level": "ground", "at": 1.7, "width": 0.6, "height": 0.75, "sill": 0.9, "lights": 4}]},
    ],
    "side_porch": {"_doc": "the porch along the door's long side, a step down from the floor, its shed roof on three hewn posts under the main roof's eave",
                   "rect": [-PORCH_D, 0.0, 0.0, D], "deck_top": DECK, "roof_height": 1.98, "rise": 0.24,
                   "posts": [[round(-PORCH_D + 0.05, 3), 0.12], [round(-PORCH_D + 0.05, 3), round(D / 2 + 0.75, 3)], [round(-PORCH_D + 0.05, 3), round(D - 0.12, 3)]]},
    "stairs": [{"id": "porch", "_doc": "three plank steps from the yard up to the porch before the door", "head": [-PORCH_D, round(DOOR_Z - 0.5, 3)], "dir": "+x", "width": 1.0,
                "from": 0.0, "to": DECK, "risers": 3, "going": 0.28, "wood": "weathered_pine"}],
    "chimneys": {"wood": "stone", "list": [{"id": "stove", "at": [round(W / 2 + 0.45, 3), -0.42], "size": 0.8, "over_ridge": 0.6, "fieldstone": {"course": 0.22, "stack": 0.62, "from": 1.9},
                                            "_doc": "rough fieldstone up the outside of the east gable, the stove's pipe in through the logs"}]},
    "hung": [{"id": "mirror", "wall": "west", "side": "out", "at": round(D - 0.45, 3), "y": 1.45, "size": [0.3, 0.38], "over": "porch",
              "_doc": "his shaving mirror on a nail beside the west window, over the washstand"}],
    "front": {"sign": ""},
    "rooms": [{"id": "cabin", "level": "ground", "rect": [T, T, round(W - T, 3), round(D - T, 3)], "use": "he sleeps, cooks, eats and keeps his kit in the one room"}],
    "use_points": [
        {"id": "bed", "prop": "bed", "use": "sleep", "who": "harlan", "at": [3.94, FLOOR, 4.0], "look": [3.94, 2.0], "_doc": "the bed the save uses (sleeping, later)"},
        {"id": "bedside", "use": "stand", "who": "harlan", "at": [3.0, FLOOR, 4.1], "look": [3.94, 4.1], "_doc": "the clear spot beside the bed: where you stand to lie down"},
        {"id": "stove", "use": "cook", "who": "harlan", "at": [2.75, FLOOR, 1.45], "look": [2.75, 0.4]},
        {"id": "table", "prop": "chair", "use": "eat", "who": "harlan", "at": [1.25, FLOOR, 1.12], "look": [0.5, 1.12]},
        {"id": "trunk", "use": "kneel", "who": "harlan", "at": [3.94, FLOOR, 2.05], "look": [3.94, 2.7], "_doc": "at his army trunk (the steward's kit, the photograph: later)"},
        {"id": "wash", "use": "wash", "who": "harlan", "at": [-0.9, DECK, round(D - 0.45, 3)], "look": [0.0, round(D - 0.45, 3)], "_doc": "at the basin on the porch (washing the blood off: later)"},
    ],
    "light": {"fill": [0.62, 0.6, 0.57], "window_day": 9.0, "day_fill": 0.14},
    "lamps": {"kit": []},
    "dressing": {"batches": {"H1": [
        {"id": "bed", "kit": "plank_bed", "at": [3.94, 0.0, 4.03], "facing": 0, "use": "bed: its head against the west gable, in the back corner from the door"},
        {"id": "blanket", "kit": "folded_blanket", "on": "bed", "at": [3.94, 0.0, 3.5], "facing": 90},
        {"id": "trunk", "kit": "travelling_trunk", "at": [3.94, 0.0, 2.72], "facing": 0, "use": "his army trunk at the bed's foot"},
        {"id": "stove", "kit": "cookstove", "at": [2.75, 0.0, 0.62], "facing": 0},
        {"id": "table", "kit": "table", "fit": [1.1, 0.74, 0.7], "at": [0.55, 0.0, 1.12], "facing": 90, "use": "under the window by the door, clear of its leaf"},
        {"id": "chair", "kit": "chair", "at": [1.25, 0.0, 1.12], "facing": 270},
        {"id": "lamp", "kit": "oil_lamp", "on": "table", "at": [0.5, 0.0, 1.45], "facing": 0, "light": 0.2, "energy": 0.9, "reach": 5.0, "shadows": True},
        {"id": "cup", "kit": "tin_cup", "on": "table", "at": [0.6, 0.0, 0.9], "facing": 30},
        {"id": "shelves", "kit": "shelves", "fit": [0.32, 1.6, 1.0], "at": [1.25, 0.0, 0.36], "facing": 0},
        {"id": "washstand", "kit": "washstand", "at": [-0.3, DECK - FLOOR, round(D - 0.45, 3)], "facing": 270, "use": "on the porch, under the mirror"},
        {"id": "basin", "kit": "wash_basin", "on": "washstand", "at": [-0.3, DECK - FLOOR, round(D - 0.45, 3)], "facing": 0},
        {"id": "pitcher", "kit": "wash_pitcher", "on": "washstand", "at": [-0.25, DECK - FLOOR, round(D - 0.25, 3)], "facing": 200},
    ]}},
    "repairs": [
        {"id": "roof_patch", "what": "a patch of shakes off the west slope over the bed (the boards show; it lets the rain in)", "kind": "missing", "fix": "shakes",
         "members": "roof/shake_0/", "_doc": "shakes.missing's patch: no members; the fix lays them (the bundles in the barn)"},
        {"id": "porch_board", "what": "a porch board sprung up at one end", "kind": "loose", "member": "side_porch/board_9", "lift": 0.07},
        {"id": "rotten_step", "what": "the bottom porch step rotten through and broken", "kind": "rotten", "member": "stair/porch/tread/00", "break": True},
    ],
    "materials": {
        "wear": {"use": 0.4, "dings": 0.0, "_why": "one man, a few months, careful; the last owner's eight years under it"},
        "finishes": {
            "logs": {"use": {"entry": "rough_pine_batten", "age": "few", "role": "wall"}, "_why": "hewn pine gone silver-grey (R1 a few years: old read near black on the logs, round 0) until a hewn-log entry is judged"},
            "new_wood": {"use": {"entry": "rough_pine_batten", "age": "new", "role": "wall"}, "_why": "what Harlan has put in: pale and new"},
            "rough": {"use": {"entry": "rough_pine_batten", "age": "old", "role": "wall"}},
            "floor": {"use": {"entry": "rough_pine_batten", "age": "old", "role": "floor"}, "_why": "rough wide pine boards (the recipe's rough class)"},
            "framing": {"use": {"entry": "rough_pine_batten", "age": "few", "role": "wall"}},
        },
        "surfaces": [["_new", "new_wood"], ["/chink/", "-"], ["/log/", "logs"], ["/buck/", "logs"], ["/gable/", "rough"], ["roof/shake", "rough"],
                     ["roof/board", "rough"], ["/window_", "rough"], ["/door_", "rough"], ["side_porch/", "rough"], ["stair/", "rough"],
                     ["floor/ground/board", "floor"], ["floor/loft/board", "rough"], ["sill/", "logs"], ["hung/", "-"]],
        "trim_outside": "weathered_pine", "roof": "weathered_pine", "deck": "weathered_pine",
        "floor": "wood:int_floor", "wall_boards": "int_boards", "woodwork": "wood:int_timber", "timber": "wood:int_timber",
    },
    "sources": [
        "C. A. Weslager, The Log Cabin in America (1969): hewn logs, chinking and daubing, openings sawn and bucked, shake roofs on skip boards.",
        "Fred Kniffen and Henry Glassie, 'Building in Wood in the Eastern United States' (Geographical Review, 1966): corner timbering, hewn logs.",
        "Fred T. Hodgson, Practical Carpentry (1883): common rafters, shingle lath.",
        "USDA Forest Products Laboratory, Wood Handbook (FPL-GTR-282, 2021): spans.",
    ],
    "furniture": [], "fixtures": [],
}

# --- the barn --------------------------------------------------------------------------------------
BW, BD = round(16 * FT, 3), round(20 * FT, 3)  # 4.877 x 6.096
B_PLATE = 2.75
B_FLOOR = 0.15
B_JOIST = [0.05, 0.235]
B_UPPER = round(B_PLATE + B_JOIST[1] + BT, 3)
barn = {
    "_doc": "Harlan's barn (#1126): a small board barn for his horse, a hayloft over, the door off its top hinge. Written by experiments/building_lab/homestead/gen_spec.py.",
    "format": 1, "id": "harlan_barn",
    "identity": {"owner": "Thomas Harlan", "trade": "his horse's stall, the hay over, the repair stock", "means": "the last owner's",
                 "age_and_repair": "as old as the cabin: the boards grey and gapped, the door hanging off its top hinge",
                 "clues": ["a stack of new sawn boards and bundles of shakes inside the door", "one stall", "hay in the loft"]},
    "lot": {"at": [0.0, 0.0, 0.0], "facing": 0, "width": BW, "depth": BD},
    "levels": {"ground": {"top": B_FLOOR, "dirt": True}, "upper": {"top": B_UPPER}, "plate": B_PLATE, "false_front": 0.0, "roof_pitch": 39.8,
               "roof_from": -0.3, "roof_to": round(BD + 0.3, 3),
               "_doc": "a dirt floor inside (the ground), the sill a 6 in step at the door; the hayloft on the plates; a 10/12 shake roof"},
    "frame": {
        "_doc": "Studs at 24 in on sills on flat stones, vertical boards (barn boards, the gaps open), common rafters, the loft's joists their ties.",
        "foundation": {"wood": "stone", "thick": 0.15, "bottom": -0.2, "top": 0.05, "piece": 1.2},
        "sill": {"section": [0.15, 0.1], "wood": "framing"},
        "pier": {"size": 0.3, "wood": "stone"},
        "girder": {"section": [0.15, 0.15], "wood": "framing", "pier_every": 1.5},
        "joist": {"section": [0.05, 0.14], "spacing": 0.61, "wood": "framing"},
        "floor_board": {"width": 0.2, "thick": BT, "wood": "floor"},
        "stud": {"section": [0.05, 0.1], "spacing": 0.61, "wood": "framing"},
        "plate": {"height": 0.1}, "ribbon": {"section": [0.025, 0.15]}, "header": {"height": 0.2},
        "post": {"section": [0.12, 0.12], "wood": "framing"}, "beam": {"section": [0.12, 0.15], "wood": "framing"},
        "bracket": {"reach": 0.3, "thick": 0.08}, "wall_post": {"section": [0.15, 0.1]},
        "ceiling_joist": {"section": B_JOIST, "spacing": 0.406, "wood": "framing", "lap": 0.6},
        "rafters": {"rafter": [0.05, 0.14], "spacing": 0.61, "ridge": [0.025, 0.185], "collar": [0.025, 0.14],
                    "collar_every": 2, "collar_down": 0.25, "eave": 0.3},
        "truss": {"tie": [0.05, 0.14], "principal": [0.0, 0.0], "queen": [0.0, 0.0], "purlin": [0.0, 0.0],
                  "rafter": [0.05, 0.14], "rafter_spacing": 0.61, "at": [0.0, BD], "purlins": []},
    },
    "girders": {}, "stairs": [], "ceilings": [],
    "floors": [{"id": "loft", "level": "upper", "rect": [0.02, 0.12, round(BW - 0.02, 3), round(BD - 0.36, 3)], "joists": "x", "joist": "ceiling_joist",
                "openings": [{"id": "hay_hole", "rect": [3.4, 4.2, 4.6, 5.0], "leaves": 0}],
                "_doc": "the hayloft over the barn but a gap at the back gable the ladder comes up through, its hay hole over the stall's manger"}],
    "shakes": {"exposure": 0.25, "width": 0.8, "strip": 0.16, "thick": 0.016, "lift": 0.012, "skip": 0.3, "new_share": 0.0},
    "walls": [
        {"id": "front", "_doc": "its gable to the yard (north): the big door, off its top hinge", "line": [[0, 0], [BW, 0]], "out": "-z", "top": "gable",
         "outside": {"siding": "vertical", "wood": "weathered_pine"}, "inside": [], "ribbon": False,
         "openings": [{"type": "door", "level": "ground", "at": round(BW / 2, 3), "width": 2.13, "height": 2.29, "leaf": "outward"}]},
        {"id": "back", "line": [[0, BD], [BW, BD]], "out": "+z", "top": "gable", "outside": {"siding": "vertical", "wood": "weathered_pine"}, "inside": [], "ribbon": False,
         "openings": []},
        {"id": "west", "line": [[0, 0], [0, BD]], "out": "-x", "top": "plate", "outside": {"siding": "vertical", "wood": "weathered_pine"}, "inside": [], "ribbon": False,
         "openings": [{"type": "window", "level": "ground", "at": 3.0, "width": 0.6, "height": 0.6, "sill": 1.3, "_doc": "an open hatch for light and air"}]},
        {"id": "east", "line": [[BW, 0], [BW, BD]], "out": "+x", "top": "plate", "outside": {"siding": "vertical", "wood": "weathered_pine"}, "inside": [], "ribbon": False,
         "openings": [{"type": "window", "level": "ground", "at": 4.6, "width": 0.6, "height": 0.6, "sill": 1.3, "_doc": "over the stall, onto the corral"}]},
    ],
    "ladders": [{"id": "loft", "wall": "back", "side": "in", "at": 1.8, "from": B_FLOOR, "to": B_UPPER, "width": 0.45,
                 "_doc": "up the back gable's inside to the loft (headroom there: on the side wall its stiles came through the roof)"}],
    "front": {"sign": ""},
    "rooms": [{"id": "barn", "level": "ground", "rect": [0.1, 0.1, round(BW - 0.1, 3), round(BD - 0.1, 3)], "use": "his horse's stall, the saddle and tack, the repair stock"}],
    "use_points": [
        {"id": "stall", "use": "tend_horse", "who": "harlan", "at": [3.95, 0.02, 3.2], "look": [3.95, 5.6]},
        {"id": "stock", "use": "fetch", "who": "harlan", "at": [1.75, 0.02, 3.2], "look": [0.84, 3.2], "_doc": "at the boards and shakes pile (the repairs' stock)"},
    ],
    "light": {"fill": [0.62, 0.6, 0.57], "window_day": 9.0, "day_fill": 0.18},
    "lamps": {"kit": []},
    "dressing": {"batches": {"B1": [
        {"id": "bale_1", "kit": "hay_bale", "at": [1.2, round(B_UPPER - B_FLOOR, 3), 1.3], "facing": 0},
        {"id": "bale_2", "kit": "hay_bale", "at": [1.2, round(B_UPPER - B_FLOOR, 3), 1.9], "facing": 0},
        {"id": "bale_3", "kit": "hay_bale", "at": [2.4, round(B_UPPER - B_FLOOR, 3), 1.6], "facing": 90},
        {"id": "bale_4", "kit": "hay_bale", "at": [1.2, round(B_UPPER - B_FLOOR + 0.45, 3), 1.6], "facing": 0},
        {"id": "water", "kit": "water_barrel", "at": [4.35, 0.0, 2.5], "facing": 0},
        {"id": "sack", "kit": "feed_sack", "at": [0.5, 0.0, 5.6], "facing": 20},
    ]}},
    "repairs": [{"id": "barn_door", "what": "the big door off its top hinge, its far corner on the ground", "kind": "off_hinge", "member": "front/door_", "drop": 0.16}],
    "materials": {
        "wear": {"use": 0.4, "dings": 0.0},
        "finishes": {
            "rough": {"use": {"entry": "rough_pine_batten", "age": "old", "role": "wall"}},
            "framing": {"use": {"entry": "rough_pine_batten", "age": "few", "role": "wall"}},
        },
        "surfaces": [["/siding/", "rough"], ["roof/", "rough"], ["/door_", "rough"], ["/trim_", "rough"], ["floor/loft/board", "rough"], ["ladder/", "rough"]],
        "trim_outside": "weathered_pine", "roof": "weathered_pine",
        "floor": "wood:int_floor", "wall_boards": "int_boards", "woodwork": "wood:int_timber", "timber": "wood:int_timber",
    },
    "sources": ["Eric Sloane, An Age of Barns (1967): the small board barn.", "Fred T. Hodgson, Practical Carpentry (1883)."],
    "furniture": [], "fixtures": [],
}

for name, d in (("harlan_cabin", cabin), ("harlan_barn", barn)):
    with open(os.path.join(ROOT, "config", "buildings", name + ".json"), "w") as f:
        json.dump(d, f, indent=1)
        f.write("\n")

# --- the site: config/buildings/harlan_homestead.json (Homestead, src/structures/homestead.gd) ------
# The pad's own space: x east from its west edge (world 417), z south from its north edge (world 458),
# the lane in at its north edge's middle (x 15). valley.json's pad: 30 x 24 m at [432, 470], y 2.0.
PAD_W, PAD_D, PAD_X0, PAD_Z0 = 30.0, 24.0, 417.0, 458.0
SPRING = [480.0 - PAD_X0, 420.0 - PAD_Z0]   # valley.json's harlan_spring
site = {
    "_doc": "Harlan's homestead on its pad (#1126; Sean 2026-11-21): written by experiments/building_lab/homestead/gen_spec.py. Homestead (src/structures/homestead.gd) builds it; ValleyWorld sets it on valley.json's harlan_homestead pad (its `site`). Pad space: x east from the pad's west edge, z south from its north edge, y over the pad.",
    "id": "harlan",
    "buildings": [
        {"id": "cabin", "spec": "res://config/buildings/harlan_cabin.json", "center": [8.0, 15.4], "facing": 270,
         "_doc": "its door's long side and porch to the north (the yard, the lane), the chimney gable to the east, the woodpile's to the west"},
        {"id": "barn", "spec": "res://config/buildings/harlan_barn.json", "center": [19.5, 18.5], "facing": 0,
         "_doc": "its door to the yard (north), the corral beside it to the east"},
    ],
    "corral": {"at": [22.6, 10.0], "size": [6.8, 12.0], "post_spacing": 2.4, "height": 1.5, "gate_at": 1.0, "gate_width": 2.4,
               "rail_section": [0.11, 0.1], "broken": ["1_2_1"],
               "_doc": "peeled pine poles on posts beside the barn, its gate to the yard; one rail on the east side snapped (a repair job: corral_rail)"},
    "trough": {"at": [17.5, 8.0], "length": 2.4, "yaw": 0, "_doc": "in the yard east of the lane's way in (the ford path's walk to the place stays clear), the pipe's spout over its east end"},
    "woodpile": {"at": [5.0, 13.6], "along": "z", "length": 3.6, "height": 1.25, "depth": 0.4, "billet": 0.14,
                 "_doc": "split cordwood stacked against the cabin's west gable"},
    "chopping_block": {"at": [3.4, 12.4], "height": 0.5, "diameter": 0.45, "axe_yaw": 35, "chips": 12},
    "stock": {"at": [17.9, 19.2], "along": "z", "board_length": 3.05, "layers": 3, "per_layer": 5,
              "shakes_at": [[18.95, 20.55], [18.95, 21.0], [18.95, 20.78, 1]],
              "_doc": "in the barn along its west wall: new sawn boards on two bearers and three bundles of shakes, bought for the repairs"},
    "stall": {"from": [20.2, 17.45], "to": [20.2, 21.35], "manger": [21.05, 21.15, 1.4, 0.45], "_doc": "the horse's stall along the barn's east side"},
    "spring": {"at": SPRING, "size": 1.1, "pipe_to": [19.7, 8.32], "spout_y": 0.85, "piece": 3.0, "pipe": 0.18,
               "_doc": "valley.json's harlan_spring up the slope to the north-east: a plank box round the pool, stones on its rim; bored logs laid on the ground down to the trough, the last on a post over it"},
    "repairs": ["cabin: roof_patch, porch_board, rotten_step", "barn: barn_door", "corral: corral_rail (broken)"],
}
with open(os.path.join(ROOT, "config", "buildings", "harlan_homestead.json"), "w") as f:
    json.dump(site, f, indent=1)
    f.write("\n")
print("cabin %.3f x %.3f, plate %.2f, floor %.2f, loft %.3f; barn %.3f x %.3f" % (W, D, PLATE, FLOOR, UPPER, BW, BD))
