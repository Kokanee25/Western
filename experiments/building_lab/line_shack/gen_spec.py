#!/usr/bin/env python3
"""The hideout's line shack (Kett's cabin, No Justice; #1091): writes config/buildings/line_shack.json
while its numbers move (the recipe's rule); keep only the JSON once they settle. Re-run it, never edit
the JSON by hand.

Sean's answers (2026-11-25, in the session): rough vertical boards (not the homestead's logs), split
shakes, one small window, a board floor, a pole lean-to beside it. Kept from the stand-in
(no_justice_hideout.gd `_build_shack`, config/moments/no_justice_hideout.json `shack`): its footprint
4.2 x 5.0 m (about 14 x 16 1/2 ft), the door in the middle of the north gable (x 2.1), the floor 0.32 m
up with the half-height stone doorstep before it (#966: you step 0.3 m at most), and the cabin's points
(no_justice_cabin.json: Kett's `corner` [0.75, 4.3], `joe_in`, `joe_back`).

The building's own space (FORMAT.md): x along the front (the north gable) from its WEST corner, z south
(back) from the front wall's outer face; facing 0 (the front to -z, valley.json's north). The lot is the
hideout's pad (valley.json `hideout`: at [-450, 2020], 30 x 20, y 86), the shack's middle the moment's
`shack.at` [7, 5] off it.

Frame: a light box frame, the cow-camp way: 4x4 corner posts and 2x4 studs at 24 in on 4x6 sills on flat
sandstone, a girt halfway up for the boards' nailing, 1x12 rough boards up and down with 1x3 battens
over the joints (Hodgson 1883, board-and-batten; Sloane, An Age of Barns), 2x6 floor sleepers at 24 in
on the sills and a mid girder, 1x8 rough floor boards; 2x4 rafters at 24 in, 8/12, collar ties, skip
boards a foot apart, split shakes 8 in to the weather. Spans: USDA Wood Handbook (FPL-GTR-282).

    python3 experiments/building_lab/line_shack/gen_spec.py
"""
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
FT = 0.3048

W, D = 4.2, 5.0              # the stand-in's footprint (the studs' outer face)
STUD = 0.1                   # 2x4 on edge (a 4 in wall; boards outside it)
FOUND_TOP = 0.08             # flat sandstone under the sills, barely out of the dirt
SILL_H = 0.14                # 4x6 sills on the flat
FLOOR = 0.32                 # the stand-in's floor_top (the doorstep's two 0.16 m steps, #966)
PLATE = 2.6                  # the walls to 2.6 m (the stand-in's 2.3 left no room for the storeroom's ledger over its door: 2.28 m clear inside)
PITCH = 33.7                 # 8/12: shakes want a steep roof
DOOR_X = W / 2               # the cabin's door point (x 2.1)
DOOR = [0.95, 1.98]          # the stand-in's door [width, height] (1.98: a man through it, checks.gd)
WIN_Z = 1.55                 # the east window, over the single bunk, clear of the lean-to's roof

# --- the cabin's points (no_justice_cabin.json), kept as they are ---------------------------------
STORE_HIGH, STORE_LOW = 2.55, 2.15  # its shed roof: the ledger under the gable over the back door's header; 1.83 m clear at its back
LEAN_HIGH, LEAN_LOW = 2.45, 2.0    # the open lean-to's: the ledger under the eave over the window's header
STORE_D = 1.5                # the back storeroom (Sean, 2026-11-25: "somewhere for Kett to hide at the back"): a closed lean-to on the south gable
BACK_DOOR_X = 1.15           # its door in the back wall, at the west lane's end
KETT_CORNER = [0.65, round(D + STORE_D - 0.4, 2)]  # where Kett hides: the storeroom's west end, behind its door's leaf (was the room's SW corner [0.75, 4.3])
JOE_IN = [3.3, 1.5]          # the cabin's joe_in: PROPOSED here to move to the west lane (below)
WALK = [[2.1, -0.5], [2.1, 0.35], [1.35, 1.3], [1.3, 3.0], [1.15, 4.6], [1.15, 5.35], [1.1, 5.75]]  # Joe's walk: the door, the lane, the storeroom's door, Kett

shack = {
    "_doc": "The hideout's line shack (#1091, Sean 2026-11-25): Kett's cabin in No Justice. Written by experiments/building_lab/line_shack/gen_spec.py (never by hand); its plan and the walk are that folder's README.",
    "format": 1,
    "id": "line_shack",
    "identity": {
        "owner": "nobody's now: an old cow-camp line shack of a range outfit that went under; Kett's crew (five men) hole up in it between jobs",
        "trade": "the gang's hideout: they sleep, eat, drink, play cards and keep their saddles and kit here",
        "means": "nothing spent on it: whatever was left, patched with what was to hand",
        "age_and_repair": "raised about 1872 of mill boards hauled in by wagon: the boards silver-grey and brown, warped, gapped, a few split; tin cans flattened and nailed over holes; shakes curled and a patch slipped",
        "clues": ["two bunks stacked and a third, more men than beds (bedrolls on the floor)", "empty bottles and cans everywhere",
                  "a deck of cards on the table", "saddles in the lean-to and one inside", "a bar and brackets on the door: they expected company"],
    },
    "lot": {
        "_doc": "The hideout's pad (valley.json `hideout`: at [-450, 2020], 30 x 20 m, y 86). `at` the west front corner's world point: the moment's `shack.at` [7, 5] off the pad's at, less half the shack. The mission (no_justice_hideout.gd `_build_shack`) loads this spec and sets it on the ground's high corner as now.",
        "at": [round(-450 + 7 - W / 2, 3), 86.0, round(2020 + 5 - D / 2, 3)], "facing": 0, "width": W, "depth": D,
        "footprint": [[0, 0, W, D], [0, D, W, round(D + STORE_D, 3)]], "_footprint": "the room and the storeroom behind it (6.5 m deep in all; its back 9.0 m south of the pad's at, inside the pad's 10)",
        "pad": "hideout", "moment": "res://config/moments/no_justice_hideout.json#shack",
    },
    "levels": {
        "_doc": "One storey: the floor 0.32 m up on sleepers over the sills; the walls to a plate at 2.6 m; an 8/12 shake roof gabled front to back (the ridge north-south), its rakes 0.3 m past the gables, the eaves 0.3 m out.",
        "ground": {"top": FLOOR}, "upper": {"top": PLATE}, "plate": PLATE, "false_front": 0.0,
        "roof_pitch": PITCH, "roof_from": -0.3, "roof_to": round(D + 0.3, 3),
    },
    "frame": {
        "_doc": "A light box frame on sills on flat stones: corner posts, studs at 24 in, a girt halfway up, rough boards and battens outside, no inside finish (the frame shows); sleepers and a girder under the floor; rafters, collars, skip boards, shakes.",
        "foundation": {"wood": "stone", "thick": 0.3, "bottom": -0.12, "top": FOUND_TOP, "piece": 0.6,
                       "_doc": "flat sandstone slabs under the corners and every 1.2 m, not a run of wall (the gaps under the sill dark)"},
        "sill": {"section": [0.15, SILL_H], "wood": "framing", "_doc": "4x6 on the flat, halved at the corners"},
        "pier": {"size": 0.3, "wood": "stone"},
        "girder": {"section": [0.1, 0.15], "wood": "framing", "pier_every": 1.2, "_doc": "a 4x6 down the middle under the sleepers (2.05 m spans either side)"},
        "joist": {"section": [0.05, 0.14], "spacing": 0.61, "wood": "framing", "_doc": "2x6 sleepers at 24 in on the sills and girder (5 crew and a crowd's check)"},
        "floor_board": {"width": 0.2, "thick": 0.025, "wood": "floor"},
        "stud": {"section": [0.05, STUD], "spacing": 0.61, "wood": "framing"},
        "plate": {"height": 0.1}, "ribbon": {"section": [0.025, 0.1]}, "header": {"height": 0.1},
        "post": {"section": [0.1, 0.1], "wood": "framing"}, "beam": {"section": [0.1, 0.15], "wood": "framing"},
        "bracket": {"reach": 0.0, "thick": 0.0}, "wall_post": {"section": [0.1, 0.1]},
        "ceiling_joist": {"section": [0.05, 0.1], "spacing": 0.61, "wood": "framing", "lap": 0.4},
        "rafters": {"rafter": [0.05, 0.14], "spacing": 0.61, "ridge": [0.025, 0.185], "collar": [0.025, 0.14],
                    "collar_every": 1, "collar_down": 0.5, "eave": 0.3,
                    "_doc": "2x4 at 24 in over 2.1 m runs, a collar on every pair 0.5 m under the ridge (no ceiling joists: the room open to the shakes)"},
        "truss": {"tie": [0.05, 0.1], "principal": [0.0, 0.0], "queen": [0.0, 0.0], "purlin": [0.0, 0.0],
                  "rafter": [0.05, 0.1], "rafter_spacing": 0.61, "at": [0.0, D], "purlins": []},
    },
    "girders": {"x": [round(W / 2, 3)]},
    "floors": [
        {"id": "ground", "level": "ground", "rect": [STUD, STUD, round(W - STUD, 3), round(D - STUD, 3)], "joists": "x", "look": "wood:int_floor",
         "_doc": "rough 1x8 boards across the sleepers; the board at the door the sill's threshold (flush: nothing to trip on)"},
    ],
    "shakes": {"exposure": 0.2, "width": 0.7, "strip": 0.14, "thick": 0.016, "lift": 0.014, "skip": 0.3, "new_share": 0.0,
               "missing": [{"side": 1, "s": [1.2, 1.7], "z": [3.4, 4.0]}],
               "_doc": "split shakes 8 in to the weather on skip boards a foot apart; a patch slipped off the west slope over Kett's corner (light through it)"},
    "walls": [
        {"id": "front", "_doc": "the north gable: the one door, in its middle (x 2.1, the stand-in's), the doorstep before it",
         "line": [[0, 0], [W, 0]], "out": "-z", "top": "gable", "ribbon": False,
         "outside": {"siding": "vertical", "battens": True, "wood": "weathered_pine"}, "inside": [],
         "openings": [{"type": "door", "level": "ground", "at": DOOR_X, "width": DOOR[0], "height": DOOR[1], "leaf": "inward", "hinge": "end",
                       "bar": {"height": 1.05, "brackets": True}, "breaks": "planks",
                       "_doc": "a batten door (four 1x10 planks on two battens and a Z-brace, strap hinges on the west jamb, swinging in to the west wall); the bar a 2x4 dropped into two iron brackets on the jambs (the cabin's `front/door_bar`); kicked in it breaks along its planks: flat 25 mm boards, nothing a man must climb (#1091's must: Joe never stalls on the sill)"}]},
        {"id": "back", "_doc": "the south gable, toward the canyon side: the storeroom's door at the lane's end, the storeroom built against it; tin patches over two holes (the storeroom's walls)",
         "line": [[0, D], [W, D]], "out": "+z", "top": "gable", "ribbon": False,
         "outside": {"siding": "vertical", "battens": True, "wood": "weathered_pine"}, "inside": [],
         "openings": [{"type": "door", "level": "ground", "at": BACK_DOOR_X, "width": 0.76, "height": 1.98, "leaf": "outward", "hinge": "start",
                       "latch": "wood", "breaks": "planks",
                       "_doc": "into the storeroom: a low plank door on leather hinges, a wooden latch, no bar (he pulls it to behind him; a kick or E opens it); swinging into the storeroom against its west wall, so Kett crouches behind its leaf"}],
         "patches": [{"at": 1.1, "y": 0.6, "size": [0.3, 0.25]}, {"at": 3.2, "y": 1.5, "size": [0.25, 0.25]}]},
        {"id": "west", "_doc": "the long side to the slope (where you come down from): no openings", "line": [[0, 0], [0, D]], "out": "-x", "top": "plate", "ribbon": False,
         "outside": {"siding": "vertical", "battens": True, "wood": "weathered_pine"}, "inside": [], "openings": []},
        {"id": "east", "_doc": "the long side to the horses: the one window over the single bunk, the lean-to against it", "line": [[W, 0], [W, D]], "out": "+x", "top": "plate", "ribbon": False,
         "outside": {"siding": "vertical", "battens": True, "wood": "weathered_pine"}, "inside": [],
         "openings": [{"type": "window", "level": "ground", "at": WIN_Z, "width": 0.6, "height": 0.6, "sill": 1.05, "lights": 4,
                       "cracked": [1], "shutter": "open_north", "_doc": "four dirty lights, one cracked; a plank shutter hung open beside it"}]},
        # The storeroom's own walls (the builder's closed lean_to: its walls are the house's list, as the farmhouse's).
        {"id": "store_west", "_doc": "the storeroom's west end", "line": [[0, D], [0, round(D + STORE_D, 3)]], "out": "-x",
         "top": [round(STORE_HIGH + 0.016, 3), round(STORE_LOW - 0.014, 3)], "ribbon": False,
         "outside": {"siding": "vertical", "battens": True, "wood": "weathered_pine"}, "inside": [], "openings": []},
        {"id": "store_back", "_doc": "the storeroom's back, no window", "line": [[0, round(D + STORE_D, 3)], [W, round(D + STORE_D, 3)]], "out": "+z",
         "top": [STORE_LOW + 0.01, STORE_LOW + 0.01], "plate": True, "boards": "under", "ribbon": False,
         "outside": {"siding": "vertical", "battens": True, "wood": "weathered_pine"}, "inside": [], "openings": []},
        {"id": "store_east", "_doc": "the storeroom's east end", "line": [[W, D], [W, round(D + STORE_D, 3)]], "out": "+x",
         "top": [round(STORE_HIGH + 0.016, 3), round(STORE_LOW - 0.014, 3)], "ribbon": False,
         "outside": {"siding": "vertical", "battens": True, "wood": "weathered_pine"}, "inside": [], "openings": []},
    ],
    "outbuildings": [
        {"id": "store", "kind": "lean_to", "wall": "back", "rect": [0.0, D, W, round(D + STORE_D, 3)], "high": STORE_HIGH, "low": STORE_LOW, "floor_look": "wood:int_floor",
         "windows": 0, "siding": {"siding": "vertical", "battens": True, "wood": "weathered_pine"},
         "_doc": "the back storeroom (Sean, 2026-11-25): a closed lean-to across the south gable, its shed roof falling south from a ledger under the gable, its floor the shack's level, no window (dark: light only through the board gaps and its door). Sacks, crates, a keg, spare tack. Kett hides here. The builder's lean_to as the farmhouse's (closed), its siding the shack's."},
        {"id": "lean_to", "kind": "lean_to", "open": True, "wall": "east", "rect": [W, 0.6, round(W + 1.8, 3), round(D - 0.4, 3)],
         "high": LEAN_HIGH, "low": LEAN_LOW, "floor": "dirt", "posts": [[round(W + 1.75, 3), 0.65], [round(W + 1.75, 3), round(D - 0.45, 3)]],
         "post_wood": "juniper", "roof": "poles_and_boards",
         "_doc": "an open pole lean-to against the east wall: a ledger on the studs under the eave, poles from it to a pole beam on two juniper posts, old boards across; dirt under; open at the north, east and south (NEW in the builder: `open`, `posts`, `floor: dirt`)"},
    ],
    "stairs": [],
    "doorstep": {"_doc": "The stand-in's flat stone before the door (#966), now a sandstone slab: half the floor's height, so two 0.16 m steps.",
                 "at": [DOOR_X, -0.25], "size": [1.1, 0.5], "top": round(FLOOR / 2, 3), "wood": "stone"},
    "chimneys": {"wood": "iron", "list": [
        {"id": "stovepipe", "kind": "stovepipe", "at": [3.55, 4.35], "size": 0.15, "over_ridge": -0.3, "over_roof": 0.9, "cap": True, "guys": 3,
         "_doc": "a 6 in tin pipe up from the box stove through a tin plate in the east slope near the ridge's back, a coolie cap, three guy wires"}]},
    "front": {"sign": ""},
    "rooms": [{"id": "store", "level": "ground", "rect": [STUD, round(D + 0.03, 3), round(W - STUD, 3), round(D + STORE_D - STUD, 3)],
               "use": "the crew's stores and spare tack; where Kett hides when the door is forced (#1091, Sean 2026-11-25)"},
              {"id": "shack", "level": "ground", "rect": [STUD, STUD, round(W - STUD, 3), round(D - STUD, 3)],
               "use": "five men sleep, eat, drink and keep their kit in the one room; Kett is barred in here at the end (No Justice, #966)"}],
    "kept_clear": [
        {"id": "kett_corner", "rect": [STUD, round(D + 0.03, 3), 2.0, round(D + STORE_D - STUD, 3)], "_doc": "the storeroom's west half bare: Kett's hiding place behind its door's leaf, nothing he or Joe or the knife can catch on (the stores stand in its east half)"},
        {"id": "west_lane", "rect": [0.75, 0.15, 1.75, round(D - STUD, 3)], "_doc": "the lane from the door to the storeroom's door: 0.9-1.0 m between the stacked bunks and the table's west bench, to the back wall; nothing stands in it"},
        {"id": "door_fall", "rect": [1.5, STUD, 2.7, 1.25], "_doc": "where the kicked-in door's planks fall (`door_falls_mps` 0.8 inward): flat boards only, the floor otherwise bare"},
    ],
    "use_points": [
        {"id": "kett_corner", "use": "cornered", "who": "kett", "at": [KETT_CORNER[0], FLOOR, KETT_CORNER[1]], "look": [BACK_DOOR_X, D],
         "_doc": "PROPOSED for no_justice_cabin.json `corner` (now [0.75, 4.3]): where Kett hides, in the storeroom behind its door's leaf, facing the door. `in_shack` must count the storeroom (the shack's depth 6.5 m, or the spec's rooms)"},
        {"id": "joe_in", "use": "stand", "who": "joe", "at": [1.35, FLOOR, 1.4], "look": [KETT_CORNER[0], KETT_CORNER[1]],
         "_doc": "PROPOSED for the cabin's `joe_in` (now [3.3, 1.5], east of the door: the table and the single bunk would stand in his way to Kett); in the west lane, past the door's fall"},
        {"id": "joe_back", "use": "stand", "who": "joe", "at": [1.6, FLOOR, 0.8], "look": [KETT_CORNER[0], KETT_CORNER[1]],
         "_doc": "PROPOSED for `joe_back` (now [2.9, 0.8]): the same, back by the door"},
        {"id": "table_west", "prop": "bench_w", "use": "sit", "who": "crew", "at": [1.95, FLOOR, 2.9], "look": [2.6, 2.9]},
        {"id": "table_east", "prop": "bench_e", "use": "sit", "who": "crew", "at": [3.25, FLOOR, 2.9], "look": [2.6, 2.9]},
        {"id": "stove", "use": "cook", "who": "crew", "at": [2.85, FLOOR, 4.25], "look": [3.65, 4.25]},
        {"id": "bunk_low", "prop": "bunks", "use": "sleep", "who": "crew", "at": [0.45, FLOOR, 1.4], "look": [0.45, 0.0]},
        {"id": "bunk_east", "prop": "bunk_east", "use": "sleep", "who": "crew", "at": [3.75, FLOOR, 1.4], "look": [3.75, 0.0]},
    ],
    "walk": {"_doc": "Joe's walk from the doorstep to Kett in the storeroom (the cabin's revenge): the shack's own space [x, z]; every leg clear of `kept_clear`'s furniture and over nothing but the door's flat planks. The build's test walks it ten times with the door kicked in (#1091's must).",
             "joe_to_kett": WALK, "clear_width": 0.7},
    "light": {"fill": [0.6, 0.56, 0.5], "window_day": 6.0, "day_fill": 0.1,
              "_doc": "dim: the one small window, the door and the cracks between the boards (the boards' gaps let light through: `siding` gaps)"},
    "lamps": {"kit": [], "on_furniture": [[2.6, 0.78, 2.6]]},
    "dressing": {"_doc": "Kit props by the prop lab (PARTS.md). NEW kit the prop lab makes first (#1091's build issue lists them): bunk_stacked, bunk, plank_bench, saddle, saddle_rack, bedroll, skillet, tin_plate, tin_cans, gun_belt, bridle. Existing: box_stove, coffeepot, table, whiskey_bottle, beer_bottle, card_deck, crate, shelves, coat_pegs, flour_sack, coffee_mill, tin_cup, oil_lamp, rope_coil, folded_blanket.",
                 "batches": {"L1": [
        {"id": "bunks", "kit": "bunk_stacked", "fit": [0.8, 1.6, 1.95], "at": [0.45, 0.0, 1.4], "facing": 0, "use": "two bunks one over the other along the west wall from the front corner: clear of the door's swing and the lane"},
        {"id": "bunk_east", "kit": "bunk", "fit": [0.75, 0.5, 1.9], "at": [3.73, 0.0, 1.4], "facing": 0, "use": "a single plank bunk along the east wall under the window"},
        {"id": "bedroll_1", "kit": "bedroll", "on": "bunks", "at": [0.45, 0.0, 1.9], "facing": 0},
        {"id": "bedroll_2", "kit": "bedroll", "at": [3.6, 0.0, 3.25], "facing": 90, "use": "a sixth man's, rolled against the east wall between the bunk and the stove"},
        {"id": "table", "kit": "table", "fit": [0.75, 0.74, 1.4], "at": [2.6, 0.0, 2.9], "facing": 0, "use": "rough plank table down the room's middle, east of the lane"},
        {"id": "bench_w", "kit": "plank_bench", "fit": [0.25, 0.44, 1.3], "at": [2.0, 0.0, 2.9], "facing": 0},
        {"id": "bench_e", "kit": "plank_bench", "fit": [0.25, 0.44, 1.3], "at": [3.2, 0.0, 2.9], "facing": 0},
        {"id": "lamp", "kit": "oil_lamp", "on": "table", "at": [2.6, 0.0, 2.6], "facing": 0, "light": 0.2, "energy": 0.8, "reach": 4.5, "shadows": True},
        {"id": "cards", "kit": "card_deck", "on": "table", "at": [2.5, 0.0, 3.1], "facing": 20},
        {"id": "bottle_1", "kit": "whiskey_bottle", "on": "table", "at": [2.75, 0.0, 3.3], "facing": 0},
        {"id": "bottle_2", "kit": "whiskey_bottle", "on": "table", "at": [2.45, 0.0, 2.35], "facing": 0, "lying": True},
        {"id": "cups", "kit": "tin_cup", "on": "table", "at": [2.7, 0.0, 2.75], "facing": 40},
        {"id": "plates", "kit": "tin_plate", "on": "table", "at": [2.55, 0.0, 3.45], "facing": 0},
        {"id": "stove", "kit": "box_stove", "at": [3.65, 0.0, 4.45], "facing": 270, "use": "the sheet-iron box stove in the SE corner on flat stones, its pipe up through the roof"},
        {"id": "coffeepot", "kit": "coffeepot", "on": "stove", "at": [3.6, 0.0, 4.35], "facing": 0},
        {"id": "skillet", "kit": "skillet", "on": "stove", "at": [3.75, 0.0, 4.6], "facing": 90},
        {"id": "shelf", "kit": "shelves", "fit": [0.3, 0.9, 1.0], "at": [2.6, 1.0, 4.75], "facing": 0, "use": "a board shelf on the back wall east of the storeroom's door (high)"},
        {"id": "coffee_mill", "kit": "coffee_mill", "on": "shelf", "at": [2.4, 1.0, 4.75], "facing": 0},
        {"id": "cans", "kit": "crate", "at": [3.0, 0.0, 4.6], "facing": 15, "use": "a crate of empty cans and bottles by the stove"},
        {"id": "cans_floor", "kit": "tin_cans", "at": [3.1, 0.0, 3.9], "facing": 0, "scatter": 5},
        {"id": "pegs_e", "kit": "coat_pegs", "at": [4.1, 1.5, 3.4], "facing": 270, "use": "a gun belt, a coat and a bridle on the east wall's pegs"},
        {"id": "gun_belt", "kit": "gun_belt", "on": "pegs_e", "at": [4.1, 1.5, 3.3], "facing": 270},
        {"id": "saddle_in", "kit": "saddle", "at": [3.8, 0.0, 2.65], "facing": 90, "use": "one saddle on the floor at the single bunk's foot (a pillow)"},
        {"id": "pegs_w", "kit": "coat_pegs", "at": [0.1, 1.6, 3.0], "facing": 90, "use": "clothes on the west wall past the bunks (high, over the lane)"},
    ], "S1": [
        {"id": "store_shelves", "kit": "shelves", "fit": [0.35, 1.4, 1.6], "at": [3.2, 0.0, round(D + STORE_D - 0.3, 3)], "facing": 90, "use": "the storeroom's back wall, east half: tins, ammunition boxes, a lantern"},
        {"id": "flour", "kit": "flour_sack", "at": [2.3, 0.0, round(D + 0.9, 3)], "facing": 10},
        {"id": "grain", "kit": "grain_sacks", "at": [3.75, 0.0, round(D + 0.4, 3)], "facing": 90},
        {"id": "keg", "kit": "nail_keg", "at": [2.55, 0.0, round(D + 0.35, 3)], "facing": 0, "use": "a keg (powder or whiskey)"},
        {"id": "store_crate", "kit": "crate", "at": [3.05, 0.0, round(D + 0.45, 3)], "facing": 10},
        {"id": "harness", "kit": "harness_rack", "at": [4.05, 1.4, round(D + 0.9, 3)], "facing": 270, "use": "spare tack on the east wall"},
    ], "L2": [
        {"id": "rack", "kit": "saddle_rack", "out": "lean_to", "at": [5.2, 0.0, 2.6], "facing": 0, "use": "in the lean-to: a pole rail with three saddles and blankets"},
        {"id": "saddle_1", "kit": "saddle", "on": "rack", "at": [5.2, 0.0, 1.9], "facing": 90},
        {"id": "saddle_2", "kit": "saddle", "on": "rack", "at": [5.2, 0.0, 2.6], "facing": 90},
        {"id": "saddle_3", "kit": "saddle", "on": "rack", "at": [5.2, 0.0, 3.3], "facing": 90},
        {"id": "bridles", "kit": "bridle", "out": "lean_to", "at": [4.25, 1.5, 2.0], "facing": 90, "scatter": 3},
        {"id": "rope", "kit": "rope_coil", "out": "lean_to", "at": [4.25, 1.4, 3.6], "facing": 90},
        {"id": "wood", "kit": "plank_stack", "out": "lean_to", "at": [4.6, 0.0, 4.2], "facing": 0, "use": "split juniper firewood (a woodpile kit if the prop lab has one by then)"},
    ]}},
    "materials": {
        "wear": {"use": 0.55, "dings": 0.0, "_why": "five rough men a year in it, boots and spurs, nothing swept"},
        "finishes": {
            "boards": {"use": {"entry": "rough_pine_batten", "age": "old", "role": "wall"}, "_why": "rough mill boards gone grey-brown (the homestead barn's rough class)"},
            "rough": {"use": {"entry": "hewn_pine_log", "age": "old", "role": "wall"}, "_why": "weathered silver-tan, as the homestead's shakes (#1160)"},
            "floor": {"use": {"entry": "rough_pine_batten", "age": "old", "role": "floor"}},
            "framing": {"use": {"entry": "rough_pine_batten", "age": "few", "role": "wall"}},
            "sandstone": {"use": {"entry": "fieldstone_rubble", "age": "few", "role": "wall"}, "_why": "the footing stones and the doorstep (a red sandstone wants its own entry later)"},
        },
        "surfaces": [["foundation/", "sandstone"], ["pier/", "sandstone"], ["doorstep", "sandstone"], ["/siding/", "boards"], ["/batten", "boards"],
                     ["roof/shake", "rough"], ["roof/board", "rough"], ["/door_", "rough"], ["/trim_", "rough"], ["lean_to/", "rough"],
                     ["floor/ground/board", "floor"], ["sill/", "framing"], ["/stud", "framing"], ["/post", "framing"]],
        "trim_outside": "weathered_pine", "roof": "weathered_pine",
        "floor": "wood:int_floor", "wall_boards": "int_boards", "woodwork": "wood:int_timber", "timber": "wood:int_timber",
    },
    "sources": [
        "Fred T. Hodgson, Practical Carpentry (1883): board-and-batten on a light frame, common rafters, shingle lath.",
        "Eric Sloane, An Age of Barns (1967): vertical board siding, battens, batten doors.",
        "USDA Forest Products Laboratory, Wood Handbook (FPL-GTR-282, 2021): spans of the sleepers and rafters.",
        "Line camps: Richard W. Slatta, Cowboys of the Americas (1990), the line rider's shack.",
    ],
    "furniture": [], "fixtures": [],
}

# Stand-ins (#1250): the prop lab's new kit isn't made yet. Each piece the kit has a fair stand-in for
# takes it and keeps `wants` (the kit the prop lab is to make: swap it back by deleting the mapping);
# a piece with none waits (`waiting`, not built). The list is the props lane's issue (#1263).
STAND_IN = {"bunk_stacked": "plank_bed", "bunk": "plank_bed", "plank_bench": "wall_bench", "bedroll": "folded_blanket",
            "saddle_rack": "trestles_short"}
WAITS = {"skillet", "tin_plate", "tin_cans", "gun_belt", "saddle", "bridle"}
# Where a stand-in (bigger than the kit it stands for) or a piece the measured kit put through a wall
# stands instead (#1250: the props' boxes measured in the lab; the lane x 1.04..1.82 kept clear).
PLACE = {"bunks": {"at": [0.55, 0.0, 1.35]}, "bunk_east": {"at": [3.65, 0.0, 1.3]},
         "bedroll_1": {"at": [0.55, 0.0, 1.9]},
         "bench_w": {"at": [2.0, 0.0, 2.92], "facing": 90, "fit": [1.3, 1.0, 0.36]},
         "bench_e": {"at": [3.2, 0.0, 2.92], "facing": 90, "fit": [1.3, 1.0, 0.36]},
         "stove": {"at": [3.65, 0.0, 4.25]}, "coffeepot": {"at": [3.6, 0.0, 4.15]},
         "shelf": {"at": [2.6, 1.0, 4.72], "facing": 90}, "coffee_mill": {"at": [2.5, 1.0, 4.72]},
         "cans": {"at": [4.65, 0.0, 1.3], "out": "lean_to", "use": "a crate of empty cans and bottles out under the lean-to (the stand-ins left no room by the stove)"},
         "keg": {"at": [2.3, 0.0, round(D + 0.35, 3)]}, "store_crate": {"at": [2.85, 0.0, round(D + 0.45, 3)]},
         "grain": {"at": [3.68, 0.0, round(D + 0.55, 3)], "facing": 0}}
_waiting = []
for _name, _batch in shack["dressing"]["batches"].items():
    _kept = []
    for _e in _batch:
        if _e["kit"] in WAITS:
            _waiting.append(_e["id"] + ": " + _e["kit"])
            continue
        if _e["id"] in PLACE:
            _e.update(PLACE[_e["id"]])
        if _e["kit"] in STAND_IN:
            _e["wants"] = _e["kit"]
            _e["kit"] = STAND_IN[_e["kit"]]
            if "fit" in _e and "fit" not in PLACE.get(_e["id"], {}):  # (the stand-in at its own size: the fit is the new kit's)
                _e["wants_fit"] = _e.pop("fit")
        _kept.append(_e)
    _batch[:] = _kept
# (what stood on a waiting piece: nothing does but the saddles on the rack, which wait too)
shack["dressing"]["waiting"] = _waiting

with open(os.path.join(ROOT, "config", "buildings", "line_shack.json"), "w") as f:
    json.dump(shack, f, indent=1)
    f.write("\n")
print("line shack %.2f x %.2f, floor %.2f, plate %.2f, pitch %.1f; lot at %s" % (W, D, FLOOR, PLATE, PITCH, shack["lot"]["at"]))
