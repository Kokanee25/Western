#!/usr/bin/env python3
"""Writes config/buildings/church.json (the church, #1142: the building lab's step 2), from the doctor's
spec as the base (a gable-front frame building: the builder's common-rafter roof, sashes, lamps, light)
and the numbers here, so a change is one number and a re-run:

    python3 tools/buildings/church_spec.py

Sizes: Sean's 28 x 44 ft nave (8.53 x 13.41 m, gable front facing the lane), a 10 ft square bell tower
over the porch (3.05 m), 10/12 roof, a 15 m steeple. The sheet (experiments/building_lab/church/sheet)
is the look; the numbers are from period carpentry (Woodward 1865, Hodgson 1883: the doctor's sources).
Space: x along the front from its EAST corner (the lot faces south, facing 180), z back from the front wall's
outer face; the tower's front is at z -3.05.
"""
import copy
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
d = json.load(open(os.path.join(ROOT, "config", "buildings", "doctor.json")))

W, D = 8.53, 13.41
CX = W / 2
TX0, TX1, TZ = CX - 1.525, CX + 1.525, -3.05
FLOOR = 0.95
PLATE = 5.55
JOIST = [0.08, 0.38]
UPPER = round(PLATE + JOIST[1] + 0.022, 3)
BELFRY_FLOOR = 7.4
BELFRY_TOP = 10.6
SPIRE = 4.4

s = {}
s["_doc"] = ("The church of Salt Creek (#1142, the building lab; tools/buildings/church_spec.py writes this file): a white frame "
             "church, 28 x 44 ft, gable front facing the lane, a three-stage bell tower over its porch with a real bell, pointed "
             "windows, pews, a chancel on a low platform. Sizes by the spec, never the sheet's pictures (experiments/building_lab/church/sheet).")
s["format"] = 1
s["id"] = "church"
s["identity"] = {
    "owner": "the town's families; a circuit preacher on alternate Sundays, the schoolmarm leads the hymns between",
    "trade": "a Protestant meeting house: Sunday services, the town's weddings and funerals, the school on weekdays when there is no schoolhouse",
    "means": "modest but proud: put up in 1880 by the families' own hands of freighted pine, the one painted building in a town of raw boards, the bell sent from St. Louis",
    "age_and_repair": "two years: the white lead chalking and peeling on the weather (west) side, rust streaks from the nail heads, the steps worn pale",
    "clues": ["a bell tower over the door", "a hymn board by the pulpit with last Sunday's numbers", "a stove in the corner with a pipe across the nave",
              "the grave dug beside it", "the children's names carved in the back pew"]}
s["lot"] = {
    "_doc": "valley.json's `church` place (the rise north-west of town, +7.5 m): the front wall's outer face on z -135.5, its east corner at world x -57.735, facing the lane (south). Placed by ValleyWorld._make_church; the pad is the lot's.",
    "valley_place": "church", "side": "north", "at": [-57.735, 7.5, -135.5], "facing": 180, "width": W, "depth": D,
    "yard": [-3.0, -6.0, W + 3.0, D + 3.0], "footprint_with_stair": [0.0, -4.4, W, D]}
s["levels"] = {
    "_doc": "The floor 3 ft up (three steps); 15 ft of wall to the plate (a church's); the ceiling joists, 3 x 15 in at 16 in, are the roof's ties across the 28 ft span and carry the boarded loft above; 9/12 roof (36.9 degrees, the doctor's).",
    "ground": {"top": FLOOR}, "upper": {"top": UPPER, "_doc": "the loft's floor, on the ceiling joists over the plates"},
    "plate": PLATE, "false_front": 0.0, "roof_pitch": 36.87, "roof_from": -0.35, "roof_to": D + 0.35}

fr = copy.deepcopy(d["frame"])
fr["_doc"] = ("The doctor's balloon frame (Bell 1858; Woodward 1865) raised to a church: 2x4 studs at 16 in from the sill to the plate (a 15 ft wall), "
              "girders at the thirds under the floor's joists, the ceiling joists 3 x 15 in across the 28 ft span as the roof's ties, 2x6 rafters at 24 in, 9/12.")
fr["ceiling_joist"] = {"_doc": "the ties: 3x15 in at 16 in across the span, spiked to every rafter's foot", "section": JOIST, "spacing": 0.406, "wood": "framing", "lap": 0.6}
s["frame"] = fr
s["girders"] = {"_doc": "At the thirds of the 28 ft width, under the floor's joists (spans of 2.8 m), on stone piers at 6 ft.", "x": [round(W / 3, 3), round(2 * W / 3, 3)]}
s["floors"] = [
    {"id": "ground", "level": "ground", "rect": [0.1, 0.1, W - 0.1, D - 0.1], "joists": "x", "look": "wood:int_floor"},
    {"id": "attic", "level": "upper", "rect": [0.02, 0.1, W - 0.02, D - 0.1], "joists": "x", "joist": "ceiling_joist", "breaks": [],
     "_doc": "the loft over the nave: the ceiling's joists, boarded"}]
s["ceilings"] = {"finish": "beaded", "rooms": "all"}
s["inside_finish"] = {"boards": "judged", "skirting": 0.2,
                      "regions": [{"rect": [0.1, 0.1, W - 0.1, D - 0.1], "y": [FLOOR, PLATE], "finish": "plaster_whitewash", "_why": "the chimney's breast"}]}


def outside():
    return {"siding": "lap", "wood": "painted_white", "exposure": 0.1}


def inside(a, b, level_up=True):
    out = [{"level": "ground", "from": a, "to": b, "finish": "boards"}]
    if level_up:
        out.append({"level": "upper", "from": a, "to": b, "finish": "rough"})
    return out


def win(at, w=0.76, h=2.2, sill=1.0, lights=4, pointed=True):
    o = {"type": "window", "level": "ground", "at": at, "width": w, "height": h, "sill": sill, "lights": lights}
    if pointed:
        o["pointed"] = True
        o["rise"] = 0.42
    return o


side_z = [2.6, 5.4, 8.2, 11.0]
walls = [
    {"_doc": "The front, to the lane: the gable over it; the tower's porch against it (its door into the nave, two leaves); a pointed window either side.",
     "id": "front", "line": [[0, 0], [W, 0]], "out": "-z", "top": "gable", "outside": outside(), "inside": inside(0.1, W - 0.1),
     "openings": [{"type": "door", "level": "ground", "at": CX, "width": 1.5, "height": 2.7, "leaf": "inward", "_doc": "the nave's doors from the tower porch"},
                  win(1.3), win(W - 1.3)], "ribbon": False},
    {"_doc": "The back, behind the pulpit: one tall pointed window over it, the gable above.",
     "id": "back", "line": [[0, D], [W, D]], "out": "+z", "top": "gable", "outside": outside(), "inside": inside(0.1, W - 0.1),
     "openings": [win(CX, 0.76, 2.0, 1.5)], "ribbon": False},
    {"_doc": "The east side, to the yard: four pointed windows.", "id": "yard", "line": [[0, 0], [0, D]], "out": "-x", "top": "plate",
     "outside": outside(), "inside": inside(0.1, D - 0.1), "openings": [win(z) for z in side_z], "ribbon": False},
    {"_doc": "The west side, to the lane: four pointed windows (the weather side: the paint is worst here).", "id": "lane", "line": [[W, 0], [W, D]], "out": "+x",
     "top": "plate", "outside": outside(), "inside": inside(0.1, D - 0.1), "openings": [win(z) for z in side_z], "ribbon": False},
    {"_doc": "The tower's front: its double doors onto the steps, clapboard to the belfry's floor.",
     "id": "tower_front", "line": [[TX0, TZ], [TX1, TZ]], "out": "-z", "top": BELFRY_FLOOR, "outside": outside(),
     "inside": inside(0.1, 2.95, False),
     "openings": [{"type": "door", "level": "ground", "at": 1.525, "width": 1.5, "height": 2.7, "leaf": "inward"}], "ribbon": False},
    {"_doc": "The tower's east side: a small window to the porch.", "id": "tower_e", "line": [[TX0, TZ], [TX0, 0.1]], "out": "-x", "top": BELFRY_FLOOR,
     "outside": outside(), "inside": inside(0.1, 3.05, False), "openings": [win(1.5, 0.6, 1.2, 1.4, 2, False)], "ribbon": False},
    {"_doc": "The tower's west side.", "id": "tower_w", "line": [[TX1, TZ], [TX1, 0.1]], "out": "+x", "top": BELFRY_FLOOR,
     "outside": outside(), "inside": inside(0.1, 3.05, False), "openings": [win(1.5, 0.6, 1.2, 1.4, 2, False)], "ribbon": False}]
s["walls"] = walls
s["tower"] = {
    "_doc": "src/structures/church_tower.gd: the tower against the front gable over the porch (10 ft square): footing, sills, floor, its walls above, the belfry floor at 7.4 m, four posts, louvres, the bell beams, a pyramidal spire of shingles on hip rafters, an iron cross. The top about 15.6 m over the ground (valley.json's bell_tower: 15 m).",
    "x": [TX0, TX1], "z": TZ, "belfry_floor": BELFRY_FLOOR, "belfry_top": BELFRY_TOP, "spire": SPIRE, "post": 0.15,
    "louvre": {"from": BELFRY_FLOOR + 0.6, "to": BELFRY_TOP - 0.3, "step": 0.13, "gap": [CX - 0.55, CX + 0.55, BELFRY_FLOOR + 0.85, BELFRY_TOP - 0.55]},
    "shingle": 0.22, "finial": 0.9}
s["stairs"] = [{"_doc": "the three plank steps to the tower's door (7 in risers, 11 in treads), as wide as the doors with room on either side", "id": "front",
                "head": [CX - 1.1, TZ], "dir": "+z", "width": 2.2, "from": 0.0, "to": "ground", "risers": 3, "going": 0.28, "wood": "painted_white"}]
s["stage"] = {
    "_doc": "the chancel's platform, a step up (a foot) across the back, with a step down at its front: legs, bearers and joists, the boards, a boarded skirt.",
    "level": "ground", "rect": [CX - 2.6, D - 2.7, CX + 2.6, D - 0.12], "height": 0.3, "leg": 0.1, "bearer": [0.1, 0.1], "joist": [0.05, 0.1],
    "spacing": 0.406, "legs_every": 1.25, "bearers": 3, "skirt": ["front", "+x", "-x"],
    "steps": [{"id": "chancel", "head": [CX - 1.0, D - 2.7], "dir": "+z", "width": 2.0, "risers": 2, "going": 0.28}]}
s["rooms"] = [
    {"id": "porch", "level": "ground", "rect": [TX0 + 0.1, TZ + 0.1, TX1 - 0.1, 0.0], "use": "the bell rope and the ladder to the belfry; where the families greet and the coffin waits"},
    {"id": "nave", "level": "ground", "rect": [0.1, 0.1, W - 0.1, 9.4], "use": "services: twelve pews either side of the aisle, the stove in the corner; weddings and funerals; the school's classes"},
    {"id": "chancel", "level": "ground", "rect": [CX - 2.6, 9.5, CX + 2.6, D - 0.12], "use": "the preacher at the pulpit on the platform, the hymn board beside it, the altar rail across the front"}]
s["chimneys"] = {"_doc": "one brick (the game's stone until a brick is made) chimney in the nave's rear east corner for the stove; its top a metre over the roof beside it.",
                 "wood": "stone", "list": [{"id": "stove", "at": [0.72, D - 0.46], "size": 0.34, "over_ridge": -1.95}]}
s["lamps"] = {"_doc": "oil lamps on brackets down both walls, hung by the clock (#824); the pulpit's, over the platform, casts shadows.",
              "kit": [
                  {"room": "chancel", "kit": "reflector_lamp", "wall": "back", "level": "ground", "at": CX - 1.7, "height": 2.0, "energy": 1.6, "reach": 7.0, "shadows": True, "lit": [17, 23]},
                  {"room": "chancel", "kit": "reflector_lamp", "wall": "back", "level": "ground", "at": CX + 1.7, "height": 2.0, "energy": 1.4, "reach": 6.0, "lit": [17, 23]},
                  {"room": "nave", "kit": "reflector_lamp", "wall": "yard", "level": "ground", "at": 4.0, "height": 2.0, "energy": 1.2, "reach": 6.0, "lit": [17, 23]},
                  {"room": "nave", "kit": "reflector_lamp", "wall": "lane", "level": "ground", "at": 4.0, "height": 2.0, "energy": 1.2, "reach": 6.0, "lit": [17, 23]},
                  {"room": "nave", "kit": "reflector_lamp", "wall": "yard", "level": "ground", "at": 9.6, "height": 2.0, "energy": 1.2, "reach": 6.0, "lit": [17, 23]},
                  {"room": "nave", "kit": "reflector_lamp", "wall": "lane", "level": "ground", "at": 9.6, "height": 2.0, "energy": 1.2, "reach": 6.0, "lit": [17, 23]}]}
s["light"] = {"_doc": "A tall room of eight long windows: the daylight comes in at them (RoomLight's window spots); the fill low and near neutral.",
              "fill": [0.62, 0.6, 0.57], "window_day": 16.0, "day_fill": 0.22}
s["ladders"] = [{"_doc": "in the tower's porch on the nave front wall's face (its outside, the porch's inside) up to the belfry's hatch", "id": "belfry", "wall": "front", "at": round(CX + 0.875, 3), "from": FLOOR, "to": BELFRY_FLOOR + 0.26, "width": 0.45, "band": 2}]

# Pews: two blocks of six, facing the back (+z), the aisle between.
pews = []
use_points = []
rows = [3.5 + 1.05 * i for i in range(6)]
for side, px in (("E", 1.95), ("W", W - 1.95)):
    for i, z in enumerate(rows):
        pid = "pew_%s%d" % (side, i)
        pews.append({"id": pid, "kit": "pew", "at": [round(px, 3), 0.0, round(z, 3)], "facing": 0})
use_points += [
    {"id": "porch_stand", "use": "stand", "who": "anyone", "at": [CX, FLOOR, -1.4], "look": [CX, -8.0]},
    {"id": "door_greet", "use": "stand", "who": "anyone", "at": [CX, FLOOR, 1.5], "look": [CX, D]},
    {"id": "preach", "prop": "pulpit", "use": "preach", "who": "preacher", "at": [CX, FLOOR + 0.3, D - 1.2 - 0.0], "look": [CX, 3.0]},
    {"id": "aisle_mid", "use": "stand", "who": "anyone", "at": [CX, FLOOR, 6.5], "look": [CX, D]},
    {"id": "sit_front_e", "prop": "pew_E5", "use": "sit", "who": "anyone", "at": [1.95, FLOOR, 8.75], "look": [1.95, D]},
    {"id": "sit_front_w", "prop": "pew_W5", "use": "sit", "who": "anyone", "at": [W - 1.95, FLOOR, 8.75], "look": [W - 1.95, D]},
    {"id": "sit_mid_e", "prop": "pew_E3", "use": "sit", "who": "anyone", "at": [1.95, FLOOR, 6.6], "look": [1.95, D]},
    {"id": "sit_mid_w", "prop": "pew_W3", "use": "sit", "who": "anyone", "at": [W - 1.95, FLOOR, 6.6], "look": [W - 1.95, D]},
    {"id": "sit_back_e", "prop": "pew_E0", "use": "sit", "who": "anyone", "at": [1.95, FLOOR, 3.5], "look": [1.95, D]},
    {"id": "sit_back_w", "prop": "pew_W0", "use": "sit", "who": "anyone", "at": [W - 1.95, FLOOR, 3.5], "look": [W - 1.95, D]},
    {"id": "tend_stove", "prop": "stove", "use": "work", "who": "anyone", "at": [1.0, FLOOR, 10.46], "look": [1.0, D - 1.8]},
    {"id": "kneel", "use": "kneel", "who": "anyone", "at": [CX, FLOOR, 9.95], "look": [CX, D]}]
s["furniture"] = []
s["fixtures"] = []
s["use_points"] = use_points
dress = pews + [
    {"id": "pulpit", "kit": "pulpit", "at": [CX, 0.3, D - 1.0], "facing": 180, "use": "preach"},
    {"id": "hymn", "kit": "hymn_stand", "at": [CX - 2.0, 0.3, D - 1.1], "facing": 180},
    {"id": "rail_a", "kit": "altar_rail", "at": [CX - 1.25, 0.0, 9.7], "facing": 0},
    {"id": "rail_b", "kit": "altar_rail", "at": [CX + 1.25, 0.0, 9.7], "facing": 0},
    {"id": "bell", "kit": "church_bell", "at": [CX, BELFRY_FLOOR + 0.26 - FLOOR, TZ * 0.5], "facing": 0, "use": "the church bell on its stand in the belfry, over the porch"},
    {"id": "stove", "kit": "box_stove", "at": [1.0, 0.0, D - 1.8], "facing": 90, "use": "tend_stove"}]
s["dressing"] = {"_doc": "the prop lab's church batch (tools/props/church.py): pews in two blocks of six, the pulpit and hymn stand on the chancel's platform, the altar rail in two halves with the gate between, the stove; placed by the build (SpecBuilding._dressing).",
                 "batches": {"C1": dress}}
mat = copy.deepcopy(d["materials"])
mat["wear"] = {"use": 0.55, "dings": 0.0, "_why": "a Sunday crowd and a weekday school: the aisle and the pews' ends worn; kept clean"}
mat["finishes"]["roof"] = {"use": {"entry": "common_pine_lap", "age": "old", "role": "wall"},
                           "_why": "silver-grey weathered shingle (the library has no shingle yet: the old pine's grey)"}
mat["trim_outside"] = "painted_white"
mat["fence"] = "painted_white"
mat["finishes"]["exterior"] = {"want": {"entry": "painted_white_lap", "age": "old"}, "use": {"entry": "common_pine_lap", "age": "old", "role": "wall"},
                               "_why": "white lead on clapboard, two weathered years: chalked, peeling on the west"}
mat["finishes"]["trim"] = {"want": {"entry": "painted_white_lap", "age": "old"}, "use": {"entry": "common_pine_lap", "age": "old", "role": "wall"},
                           "_why": "all white: casings, corner boards, sashes, doors"}
mat["finishes"]["floor"] = {"want": {"entry": "floor_fir_worn", "age": "old", "role": "floor"}, "use": {"entry": "fine_walnut_tg", "age": "few", "role": "floor"},
                            "_why": "worn pine boards, the aisle paler (traffic map), dark under the pews"}
surf = [x for x in mat["surfaces"] if not x[0].startswith(("front/door_", "back/door_", "yard/door_", "lane/door_", "floor/attic", "back_porch"))]
surf = [["floor/tower/board", "floor"], ["tower_front/door_", "trim"], ["front/door_", "trim"], ["tower/", "exterior"], ["stage/", "rough"]] + surf
surf.insert(0, ["tower/belfry/louvre", "trim"])
surf.insert(0, ["tower/spire/shingle", "roof"])
surf.insert(0, ["tower/belfry/skirt", "roof"])
surf.insert(0, ["roof/board", "roof"])
surf += [["floor/attic/board", "floor"]]
mat["surfaces"] = surf
s["materials"] = mat
s["sources"] = d["sources"]

out = os.path.join(ROOT, "config", "buildings", "church.json")
json.dump(s, open(out, "w"), indent=1)
print("wrote", out, os.path.getsize(out), "bytes")
