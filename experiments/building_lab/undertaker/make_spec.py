#!/usr/bin/env python3
"""Writes config/buildings/undertaker.json (#1174, the building lab's step 2) from the numbers below.

RECIPE.md (saloon B): "write the spec with a script while its numbers move, then keep only the JSON".
The frame's common parts (sill, joists, studs, plates, rafters) are the doctor's (a one-storey balloon
frame under common rafters, Bell 1858, Woodward 1865, Hodgson 1883); what's the undertaker's own is
here. Run: python3 experiments/building_lab/undertaker/make_spec.py
"""
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DOC = json.loads((ROOT / "config/buildings/doctor.json").read_text())
FT = 0.3048

# --- the shell (Sean, #1171: 32 x 50 ft, one storey, low loft, a false front) -----------------------
W = round(32 * FT, 3)          # 9.754 across the front (building x from its EAST corner westward)
D = round(50 * FT, 3)          # 15.24 front to back
FLOOR = 1.15                   # the walk's top (valley.json undertaker walk.h)
BOARD = 0.022
JOIST = 0.235
SILL = 0.15
FOUND_TOP = round(FLOOR - BOARD - JOIST - SILL, 3)   # 0.743
PLATE = round(FLOOR + 11 * FT, 3)                     # 11 ft to the ceiling: 4.503
UPPER = round(PLATE + JOIST + BOARD, 3)               # the loft's boards
PITCH = 26.57                                         # 6/12: a low loft
FALSE_FRONT = 7.6
CELLAR_FLOOR = -1.6                                   # its flags' top at -1.52 (2.41 m clear to the joists)
FLAGS_TOP = round(CELLAR_FLOOR + 0.08, 3)
CEL_Z0 = round(25 * FT, 3)                            # 7.62: the cellar under the back half
T = 0.45                                              # the foundation's thickness
GIRDERS = [3.25, 6.47]  # each on a floor board's middle (the posts' slots)
WORK_Z0, WORK_Z1 = 5.45, 11.95                        # the workroom's partitions (front, back)
SPLIT_X = 3.25                                        # parlour (east, by the yard) | showroom (west)
OFFICE_Z = 3.0
CROSS_Z = 11.1                                        # the cellar's cross wall
HATCH = [3.33, 9.35, 6.39, 10.25]  # the girders' faces
SIDE_DOOR_Z = 10.9
BULK_Z = [8.1, 9.1]                                   # the bulkhead's passage through the east wall
# The yard's ground over the lot (README's probe: falls east ~0.12 m in 22 m, rises 0.6 m front to
# back), as a plane in the building's space: y = a + b x + c z (x west, z back), y 0 the walk's street edge.
PLANE = [0.0, 0.0055, 0.034]


def gy(x, z):
    return PLANE[0] + PLANE[1] * x + PLANE[2] * z


def r3(v):
    return round(v, 3)


def boards(level="ground"):
    return {"level": level, "finish": "boards"}


spec = {
    "_doc": "The undertaker and cabinetmaker's (#1141, Sean's brief; #1174 steps 2-6; the building lab's fifth). Format 1 (../../experiments/building_lab/FORMAT.md) with what a cellar of rooms needs (each marked NEW, built in step 3). Target sheet: experiments/building_lab/undertaker/sheet/ (Sean OK 2026-11-23, #1173); Sean's answers on #1171: white clapboard, near-black trim; a 32 x 50 ft one-storey false-front shop with a low loft on the lot's WEST half, the yard east with a wagon gate and the hearse shed at its back; the cellar under the back half by a steep stair through a hatch in the workroom and by bulkhead doors in the yard against the east wall. Sizes from this spec only, never off the pictures (README's list of where the sheet strays). Written by make_spec.py. SPACE: on its north-side lot the building faces south (facing 180), so its x runs from its EAST corner (the yard's) westward, its z back (north) from the front wall's outer stud face; the side walls are named by what they face, 'yard' (east) and 'alley' (west).",
    "format": 1,
    "id": "undertaker",
    "identity": {
        "owner": "the town's undertaker and cabinetmaker, a quiet careful man who came up from Denver with a wagon of tools in 1880; he makes the town's furniture and its coffins, and buries its dead",
        "trade": "an undertaker and cabinetmaker (undertakers made the coffins): he sells coffins and furniture from the showroom, lays out the dead in the front parlour for viewing, builds coffins in the workroom, keeps and embalms the bodies in the cellar (an ice room, the embalming room, the coffin store), drives the hearse, and lives in the back room",
        "means": "modest and steady: a frame shop of sawn lumber put up by himself in 1880, painted white with black trim as his trade wants, the cellar dug and walled before the frame went up",
        "age_and_repair": "two years: the paint fresh in front and dusty at the foot, the yard side splashed; the workroom floor worn pale to the side door and the hatch; the cellar's lime wash stained with damp",
        "clues": ["a small polished pine coffin on a stand in the window, black blinds half drawn", "planks seasoning in the loft and against the workroom wall", "a short plank ramp from the side door to the yard: coffins go out that way", "sawdust trodden up from the cellar's stair onto the workroom floor", "the hearse's shed door hanging open on the yard, the horse in its stall"],
        "class": "common",
        "built": 1880,
        "now": 1882,
    },
    "lot": {
        "_doc": "valley.json town.north 'undertaker' (x 106.0-128.0, 22 m = 72 ft, depth 18): the building on the lot's WEST 32 ft against the junk alley (alley_n8, its siding's face 3 cm inside the lot's line, world x 106.03), the yard east of it to the lot's edge (world 128.0) where Main Street ends. The front wall's face on the town's front line (z -10.05). Its floor is its walk's top (walk.h 1.15 over the ground at the walk's street edge, ValleyTown), `at`'s y the ground there. No pad (Sean's walk 'on posts 1.15 m over the dirt'): the ground under it rises ~0.6 m front to back and falls ~0.1 m west to east (`ground.plane`, README's probe, checked by the test against ValleyTerrain); the foundation shows 0.75 m at the front, ~0.25 at the back.",
        "valley_lot": "undertaker",
        "side": "north",
        "at": [115.784, -0.4, -10.05],
        "facing": 180,
        "width": W,
        "depth": D,
        "yard": [-12.2, 0.0, 0.0, 18.0],
        "ground": {"plane": PLANE, "_doc": "the yard's ground (building space): y = a + b x + c z; the side fence, the ramp, the bulkhead and the hearse shed stand on it"},
        "footprint_with_stair": [-12.2, -0.3, W, 18.0],
        "walk_h": FLOOR,
        "yard_name": "YARD",
        "yard_front": {
            "_doc": "the walk ends at the building (valley.json undertaker walk.span); a picket fence on the front line with a wagon gate 10 ft wide on 4x4 posts (the hearse out to Main Street), a board fence down the yard's east edge where the street ends",
            "fence_z": 0.0,
            "gate": [-7.6, -4.55],
            "side_fence": {"_doc": "a 6 ft board fence down the yard's east edge, from the front line to the lot's back, its posts on the rising ground (lot.ground.plane)", "x": -12.1, "z": [0.0, 18.0], "h": 1.8},
        },
    },
    "levels": {
        "_doc": "One storey: the floor at the walk's top (1.15 m: the street's low end); 11 ft to the ceiling; the loft's 2x10 joists on the plates, boarded (a low loft for seasoning coffin boards, under a 6/12 roof: 2 m at the ridge); the false front 7.6 m over the walk's street edge, hiding the gable. The cellar's floor 1.6 m under the street edge's ground (its flags' top -1.52: 2.41 m clear to the joists, 2.26 under the girders: 'cold and low').",
        "cellar": {"floor": CELLAR_FLOOR, "top": FLAGS_TOP},
        "ground": {"top": FLOOR},
        "upper": {"top": UPPER},
        "plate": PLATE,
        "false_front": FALSE_FRONT,
        "roof_pitch": PITCH,
        "roof_from": 0.05,
        "roof_to": r3(D + 0.35),
    },
    "frame": copy.deepcopy(DOC["frame"]),
    "girders": {"_doc": "Two lines front to back under the floor's joists (spans 3.25 m), on stone piers at 6 ft; in the cellar on its posts and its two bearing walls (the cross wall, the ice room's).", "x": GIRDERS},
}
fr = spec["frame"]
fr["_doc"] = "A balloon-framed one-storey shop (Bell 1858; Woodward 1865, 'Balloon Frames'): 2x4 studs at 16 in from the sill to a doubled plate, the floor's 2x10 joists on the sills and two girders, the false front's studs run up to its cornice, a roof of common rafters (Hodgson 1883) tied by the loft's joists, which break over two summer beams on posts (a 32 ft span). Dressed sizes, metres [width, depth]; spans to checks.gd's sizing (the Wood Handbook's figures, 40 lb/ft2, L/360). The cellar's walls rubble stone in lime, 18 in."
fr["foundation"].update({"_doc": "rubble stone laid in lime mortar, 18 in thick, 2 ft under the street edge's ground; where it walls the cellar, down to the cellar's floor", "top": FOUND_TOP, "bottom": -0.6})
fr["girder"]["pier_every"] = 1.83
fr["ceiling_joist"]["_doc"] = "the loft's floor joists, 2x10 at 16 in across the building on the plates, broken over the two summer beams (spans 3.25 m), each spiked to a rafter's foot: the roof's tie"
fr["rafters"].update({"_doc": "2x6 at 24 in, 6/12, birdsmouthed on the plates, against a 1x8 ridge board, a collar on every second pair; 1x6 boards across them; 12 in eaves at the sides; the front's gable behind the false front.", "collar_down": 0.1})

# --- the cellar (NEW: rooms of its own: partitions on its flags) ------------------------------------
spec["cellar"] = {
    "_doc": "Under the back half (25 ft back to the back wall), 32 x 25 ft inside the house's foundation, rubble walls lime-washed, stone flags. Posts under the girders where no wall carries them. Its rooms are partitions on its level (walls of level 'cellar'): the coffin store across its front, the embalming room and the ice room behind. The stair down through the workroom's hatch (steep: 13 risers of 8 in on 8 1/4 in goings) lands in the coffin store; the bulkhead's passage comes in through its east wall (`bulkhead`).",
    "rect": [0.0, CEL_Z0, W, D],
    "posts": [[3.25, 9.2], [6.47, 9.2], [6.47, 13.0]],
    "flag": 1.0,
    "dig": True,
    "_dig": "NEW (CellarDig): in the valley the ground under it and the bulkhead's areaway is dug to its floor (Ground's dug tiles), the cut's edge inside the walls' stone",
    "stair": {"head": [HATCH[0], 9.4], "dir": "-x", "width": 0.8, "risers": 13, "going": 0.21},
}
# The bulkhead (NEW, src/structures/bulkhead.gd): the stone areaway against the yard wall, its steps
# down from the yard to the cellar's floor and the pair of slanted doors over it, standing open.
grade = r3(gy(-1.2, sum(BULK_Z) / 2))
spec["bulkhead"] = {
    "_doc": "NEW (Bulkhead, the part): the cellar's outside door in the yard against the east wall, as the New England hatchway: a stone areaway (cheek walls and an end wall of the cellar's rubble, from its floor to a course over the yard), wooden steps down it (10 risers), a timber lintel over the passage through the foundation, and on the cheeks a pair of slanted plank doors on a frame, high at the house wall, low at the yard, hinged at the cheeks and standing open. Coffins in and out without the house's stair.",
    "wall": "yard",
    "z": BULK_Z,
    "out": 2.45,
    "grade": grade,
    "cheek": 0.3,
    "risers": 10,
    "going": 0.24,
    "high": r3(FOUND_TOP - 0.02),
    "low": r3(grade + 0.2),
    "lintel": 0.2,
    "open": True,
    "wood": "rough",
}
spec["side_ramp"] = {
    "_doc": "NEW: the workroom's side door 'at grade (a short ramp)' (Sean, #1171): a plank ramp from the door's sill down to the yard, 1 in 5 (a coffin on a hand truck), on two stringers notched over the sill and footed on a stone in the yard; cleats across it for the feet.",
    "wall": "yard",
    "at": SIDE_DOOR_Z,
    "width": 1.6,
    "run": r3((FLOOR - gy(-2.0, SIDE_DOOR_Z)) * 5.0),
    "dir": "-x",
    "wood": "rough",
}

spec["floors"] = [
    {"id": "ground", "level": "ground", "rect": [0.1, 0.1, r3(W - 0.1), r3(D - 0.1)], "joists": "x", "look": "wood:int_floor",
     "openings": [{"id": "hatch", "rect": HATCH, "hatch": 2, "_doc": "the cellar's hatch in the workroom floor, girder to girder (no tail joists), its two leaves standing open"}]},
    {"_doc": "the loft over the whole building on frame.ceiling_joist (2x10), boarded: coffin boards seasoning; its scuttle in the workroom's ceiling", "id": "attic", "level": "upper", "rect": [0.02, 0.1, r3(W - 0.02), r3(D - 0.1)], "joists": "x", "joist": "ceiling_joist",
     "openings": [{"id": "scuttle", "rect": [7.0, 10.2, 7.8, 10.8], "leaves": 1}], "breaks": GIRDERS},
]
# Posts on the girders through slots in the floor, between its joists (joists at 0.145 + 0.406 k).
GP = lambda z: {"z": z, "girder": True, "size": 0.1}
spec["summer_beams"] = [
    {"_doc": "the loft's joists break over two summer beams (6x10 cased in the ceiling) on the girders' lines: over the parlour's wall in front (it carries them there) and behind it on 4x4 posts standing through slots in the floor on the girders (between two joists, clear of the boards: their load on the girder, not the floor); one in the workroom, one by each partition, one let into the back wall", "id": "loft_e", "x": 3.25, "z": [WORK_Z0 - 0.05, r3(D - 0.1)], "section": [0.15, 0.235], "posts": [GP(5.626), GP(8.874), GP(12.122), [r3(D - 0.15), 0.1]]},
    {"id": "loft_w", "x": 6.47, "z": [0.1, r3(D - 0.1)], "section": [0.15, 0.235], "posts": [[0.05, 0.1], GP(3.19), GP(5.626), GP(8.874), GP(12.122), [r3(D - 0.15), 0.1]]},
]
spec["ceilings"] = copy.deepcopy(DOC["ceilings"])
spec["inside_finish"] = {
    "_doc": DOC["inside_finish"]["_doc"],
    "boards": "judged",
    "skirting": 0.2,
}

# --- walls ------------------------------------------------------------------------------------------
LAP = {"siding": "lap", "wood": "painted_white", "exposure": 0.1}
ins = lambda a, b: [{"level": "ground", "from": a, "to": b, "finish": "boards"}, {"level": "upper", "from": a, "to": b, "finish": "rough"}]
win = lambda at, w, h, sill, lights=4, **k: dict({"type": "window", "level": "ground", "at": at, "width": w, "height": h, "sill": sill, "lights": lights}, **k)
spec["walls"] = [
    {"_doc": "The front, to the street: the false front's studs to its cornice; a pair of glazed doors (4 ft 6 in) under a transom into the showroom, a big window either side (black blinds half drawn; the sample coffin in the showroom's).",
     "id": "front", "line": [[0, 0], [W, 0]], "out": "-z", "top": FALSE_FRONT, "outside": LAP, "inside": ins(0.1, r3(W - 0.1)),
     "openings": [
         {"type": "door", "level": "ground", "at": 5.2, "width": 1.37, "height": 2.67, "glazed": True, "transom": 0.4, "leaves": 2, "_doc": "the street doors: a glazed pair, a transom light over them"},
         win(1.65, 1.52, 2.13, 0.46, _doc="the parlour's window (its blinds drawn)"),
         win(7.95, 1.52, 2.13, 0.46, _doc="the showroom's window: the sample coffin on its stand"),
     ], "ribbon": False},
    {"_doc": "The back, to the back lot: his room's door and window; the loft's small window in the gable.",
     "id": "back", "line": [[0, D], [W, D]], "out": "+z", "top": "gable", "outside": LAP, "inside": ins(0.1, r3(W - 0.1)),
     "openings": [
         {"type": "door", "level": "ground", "at": 1.6, "width": 0.86, "height": 2.03, "leaf": "inward"},
         win(7.9, 0.76, 1.37, 0.84),
         win(4.877, 0.61, 0.76, 0.5, 2, level="upper", _doc="the loft's window over the back lot"),
     ], "ribbon": False},
    {"_doc": "The east side, to his yard: the parlour's window, the workroom's window and its wide side door (a pair of plank leaves, 5 ft) at the ramp's head, his room's window. The bulkhead against its foundation (`bulkhead`).",
     "id": "yard", "line": [[0, 0], [0, D]], "out": "-x", "top": "plate", "outside": LAP, "inside": ins(0.1, r3(D - 0.1)),
     "openings": [
         win(2.75, 0.91, 1.83, 0.66),
         win(7.0, 0.91, 1.83, 0.66),
         {"type": "door", "level": "ground", "at": SIDE_DOOR_Z, "width": 1.52, "height": 2.29, "leaves": 2, "_doc": "the workroom's side door: two plank leaves, opening in"},
         win(13.6, 0.76, 1.37, 0.84),
     ], "ribbon": False},
    {"_doc": "The west side, to the junk alley: a window a room.",
     "id": "alley", "line": [[W, 0], [W, D]], "out": "+x", "top": "plate", "outside": LAP, "inside": ins(0.1, r3(D - 0.1)),
     "openings": [win(1.8, 0.76, 1.52, 0.76), win(8.2, 0.91, 1.83, 0.66), win(13.6, 0.76, 1.37, 0.84)], "ribbon": False},
    # The ground floor's partitions.
    {"_doc": "the parlour's wall, on the east girder's line: it carries the loft's joists over the front rooms; its door near the back into the showroom", "id": "parlour_w", "line": [[SPLIT_X, 0.1], [SPLIT_X, WORK_Z0 - 0.05]], "partition": True, "level": "ground", "bearing": True,
     "inside": [{"side": "-", "finish": "boards"}, {"side": "+", "finish": "boards"}], "openings": [{"type": "door", "at": 4.4, "width": 0.91, "height": 2.13}]},
    {"_doc": "the office's corner in the showroom's back (his desk, the counter in front of it)", "id": "office_e", "line": [[6.65, OFFICE_Z], [6.65, WORK_Z0 - 0.05]], "partition": True, "level": "ground", "bearing": False,
     "inside": [{"side": "-", "finish": "boards"}, {"side": "+", "finish": "boards"}], "openings": [{"type": "door", "at": 1.3, "width": 0.81, "height": 2.03, "leaf": "outward"}]},
    {"id": "office_f", "line": [[6.7, OFFICE_Z], [r3(W - 0.1), OFFICE_Z]], "partition": True, "level": "ground", "bearing": False,
     "inside": [{"side": "-", "finish": "boards"}, {"side": "+", "finish": "boards"}], "openings": [{"type": "hatch", "at": 1.6, "width": 1.2, "height": 0.9, "sill": 1.0, "_doc": "the office's window on the showroom: the order book's counter under it"}]},
    {"_doc": "the workroom's front wall across the width: the parlour's door (a coffin's width) and the showroom's", "id": "work_f", "line": [[0.1, WORK_Z0], [r3(W - 0.1), WORK_Z0]], "partition": True, "level": "ground", "bearing": False,
     "inside": [{"side": "-", "finish": "boards"}, {"side": "+", "finish": "boards"}], "openings": [{"type": "door", "at": 1.6, "width": 1.07, "height": 2.13, "leaf": "outward"}, {"type": "door", "at": 4.9, "width": 0.91, "height": 2.13}]},
    {"_doc": "his room's wall", "id": "work_b", "line": [[0.1, WORK_Z1], [r3(W - 0.1), WORK_Z1]], "partition": True, "level": "ground", "bearing": False,
     "inside": [{"side": "-", "finish": "boards"}, {"side": "+", "finish": "boards"}], "openings": [{"type": "door", "at": 4.9, "width": 0.86, "height": 2.03}]},
    # The cellar's (NEW: level 'cellar').
    {"_doc": "NEW: the cellar's cross wall between the coffin store and the back rooms, of planks on studs from the flags to the girders (it carries both where it crosses them); the embalming room's door", "id": "cel_cross", "line": [[r3(T + 0.02), CROSS_Z], [r3(W - T - 0.02), CROSS_Z]], "partition": True, "level": "cellar", "bearing": True,
     "inside": [{"side": "-", "finish": "boards"}, {"side": "+", "finish": "boards"}], "openings": [{"type": "door", "at": 4.6, "width": 0.91, "height": 1.98}]},
    {"_doc": "NEW: the ice room's wall under the east girder (it carries it): planked both sides, sawdust packed between, the thick door (`thick`) of two layers of planks", "id": "cel_ice", "line": [[3.25, r3(CROSS_Z + 0.05)], [3.25, r3(D - T - 0.02)]], "partition": True, "level": "cellar", "bearing": True,
     "inside": [{"side": "-", "finish": "boards"}, {"side": "+", "finish": "boards"}], "openings": [{"type": "door", "at": 1.4, "width": 0.86, "height": 1.98, "thick": 0.1, "leaf": "outward", "hinge": "end"}]},
]

spec["stairs"] = [
    {"_doc": "his room's back step: three risers to the back lot", "id": "back", "head": [1.0, r3(D + 0.9)], "dir": "-z", "width": 1.2, "from": r3(gy(1.6, D + 1.0)), "to": FLOOR, "risers": 3, "going": 0.28, "wood": "painted_white", "stoop": [1.0, D, 2.2, r3(D + 0.9)], "ground_block": True},
]
spec["front"] = {
    "_doc": "the false front: a plain cornice in black, the sign board across it over the walk's awning (2.9 m over the walk): UNDERTAKER, and smaller the cabinetmaking",
    "sign": "UNDERTAKER",
    "sign_from": 4.9,
    "sign_to": 6.75,
    "sign_width": 6.4,
}
spec["rooms"] = [
    {"id": "showroom", "level": "ground", "rect": [3.35, 0.1, r3(W - 0.1), r3(WORK_Z0 - 0.05)], "use": "coffins and caskets on trestles for the bereaved to choose, chairs; his office in its back corner (the desk, the order book on the counter under the office's window); furniture for sale"},
    {"id": "parlour", "level": "ground", "rect": [0.1, 0.1, 3.15, r3(WORK_Z0 - 0.05)], "use": "the dead laid out for viewing in an open coffin on a draped bier, chairs round the walls for the mourners, the blinds drawn, one lamp"},
    {"id": "workroom", "level": "ground", "rect": [0.1, r3(WORK_Z0 + 0.05), r3(W - 0.1), r3(WORK_Z1 - 0.05)], "use": "coffins built: the long bench and its vise, planks, a lid on trestles, the glue pot on the stove; the side door to the yard and its ramp; the cellar's hatch"},
    {"id": "back_room", "level": "ground", "rect": [0.1, r3(WORK_Z1 + 0.05), r3(W - 0.1), r3(D - 0.1)], "use": "his room: his bed, a stove, a table and chair, his clothes on pegs; the back door"},
    {"id": "loft", "level": "upper", "rect": [0.1, 0.1, r3(W - 0.1), r3(D - 0.1)], "use": "coffin boards seasoning on bearers; a place to look over the yard from the back window"},
    {"id": "coffin_store", "level": "cellar", "rect": [r3(T + 0.02), r3(CEL_Z0 + T / 2), r3(W - T - 0.02), r3(CROSS_Z - 0.05)], "use": "coffins stacked on racks, a child's among them; a body under a sheet on a board; the safety coffin; the stair's foot and the bulkhead's passage; the photographer's posing stand by the stair"},
    {"id": "embalming", "level": "cellar", "rect": [3.3, r3(CROSS_Z + 0.05), r3(W - T - 0.02), r3(D - T - 0.02)], "use": "the embalming table (zinc-lined, sloped to its drain, a pail under it), the cooling board on trestles, the hand pump, tubes and jars, the carboys of fluid, shrouds on a shelf"},
    {"id": "ice_room", "level": "cellar", "rect": [r3(T + 0.02), r3(CROSS_Z + 0.05), 3.2, r3(D - T - 0.02)], "use": "ice blocks packed in sawdust in a plank bin, the corpse cooler on trestles; the thick door shut on it"},
]
C = FLAGS_TOP
spec["use_points"] = [
    {"id": "counter", "use": "serve", "who": "undertaker", "at": [7.4, FLOOR, 3.45], "look": [7.4, 2.0], "_doc": "in the office at the counter under its window: the order book"},
    {"id": "desk", "use": "work", "who": "undertaker", "at": [8.45, FLOOR, 4.4], "look": [9.6, 4.4]},
    {"id": "choose", "use": "buy", "who": "anyone", "at": [5.4, FLOOR, 2.0], "look": [4.4, 2.0], "_doc": "the bereaved among the coffins"},
    {"id": "watch_street", "use": "watch", "who": "anyone", "at": [7.95, FLOOR, 0.75], "look": [7.95, -8.0]},
    {"id": "mourn_1", "use": "sit", "who": "anyone", "at": [0.55, FLOOR, 1.2], "look": [1.6, 2.8], "_doc": "the parlour's chairs round the walls"},
    {"id": "mourn_2", "use": "sit", "who": "anyone", "at": [2.75, FLOOR, 1.0], "look": [1.6, 2.8]},
    {"id": "view", "use": "stand", "who": "anyone", "at": [2.5, FLOOR, 3.3], "look": [1.6, 3.0], "_doc": "beside the bier"},
    {"id": "bench", "use": "work", "who": "undertaker", "at": [7.8, FLOOR, 6.65], "look": [7.8, 5.6], "tool": "bench", "_doc": "planing at the long bench against the workroom's front wall"},
    {"id": "lid", "use": "work", "who": "undertaker", "at": [2.0, FLOOR, 7.6], "look": [1.0, 7.6]},
    {"id": "side_door", "use": "watch", "who": "anyone", "at": [1.0, FLOOR, 9.6], "look": [-6.0, 10.9]},
    {"id": "eat", "use": "eat", "who": "undertaker", "prop": "chair", "at": [6.9, FLOOR, 12.95], "look": [6.9, 13.8]},
    {"id": "stove", "use": "work", "who": "undertaker", "at": [5.6, FLOOR, 13.85], "look": [5.6, 15.1]},
    {"id": "bed", "use": "sleep", "who": "undertaker", "prop": "bed", "at": [8.6, FLOOR, 14.55], "look": [8.6, 13.0]},
    {"id": "loft_store", "use": "stand", "who": "anyone", "at": [4.877, UPPER, 7.5], "look": [4.877, 3.0]},
    {"id": "loft_window", "use": "shoot", "who": "anyone", "at": [4.877, UPPER, 14.6], "look": [4.877, 30.0]},
    {"id": "coffins", "use": "work", "who": "undertaker", "at": [2.0, C, 9.4], "look": [2.0, 10.4], "_doc": "at the coffin racks"},
    {"id": "stair_foot", "use": "stand", "who": "anyone", "at": [6.8, C, 9.8], "look": [5.0, 9.8]},
    {"id": "embalm", "use": "work", "who": "undertaker", "at": [7.6, C, 12.15], "look": [7.6, 13.2], "_doc": "at the embalming table"},
    {"id": "cool", "use": "work", "who": "undertaker", "at": [4.4, C, 13.55], "look": [4.4, 14.5]},
    {"id": "ice", "use": "work", "who": "undertaker", "at": [1.8, C, 12.2], "look": [1.8, 13.5], "_doc": "at the ice bin"},
]
spec["lamps"] = {
    "_doc": "kit lamps hung on the walls, a room each (#824), lit by the clock; in the cellar a lamp each room on its plank walls (the sheet's hanging iron lantern waits for the props, #1174's next step): those a player stands in cast shadows",
    "kit": [
        {"room": "showroom", "kit": "reflector_lamp", "wall": "alley", "level": "ground", "at": 3.6, "height": 1.55, "energy": 1.3, "reach": 7.0, "shadows": True, "lit": [17, 22]},
        {"room": "parlour", "kit": "reflector_lamp", "wall": "parlour_w", "side": "-", "level": "ground", "at": 2.6, "height": 1.5, "energy": 0.9, "reach": 5.0, "shadows": True, "lit": [16, 6], "_doc": "the one lamp kept lit by the dead all night"},
        {"room": "workroom", "kit": "reflector_lamp", "wall": "alley", "level": "ground", "at": 6.3, "height": 1.6, "energy": 1.4, "reach": 8.0, "shadows": True, "lit": [17, 21]},
        {"room": "workroom", "kit": "reflector_lamp", "wall": "yard", "level": "ground", "at": 8.5, "height": 1.6, "energy": 1.0, "reach": 6.0, "lit": [17, 21]},
        {"room": "back_room", "kit": "reflector_lamp", "wall": "work_b", "side": "+", "level": "ground", "at": 7.6, "height": 1.5, "energy": 0.9, "lit": [19, 23]},
        {"room": "coffin_store", "kit": "reflector_lamp", "wall": "cel_cross", "side": "-", "level": "cellar", "at": 1.8, "height": 1.5, "energy": 1.0, "reach": 6.0, "shadows": True, "lit": [0, 24]},
        {"room": "embalming", "kit": "reflector_lamp", "wall": "cel_cross", "side": "+", "level": "cellar", "at": 6.3, "height": 1.2, "energy": 0.95, "reach": 5.5, "shadows": True, "lit": [0, 24], "smoky": 0.7, "_doc": "#1187: hung low over the work, the wick high and smoking: a deeper flame, a halo in the cellar's air and soot up the boards over it"},
        {"room": "ice_room", "kit": "reflector_lamp", "wall": "cel_ice", "side": "-", "level": "cellar", "at": 2.6, "height": 1.5, "energy": 0.7, "reach": 4.0, "lit": [0, 24]},
    ],
}
spec["light"] = copy.deepcopy(DOC["light"])
spec["light"].update({"window_day": 9.0, "day_fill": 0.14})
spec["light"]["cellar_haze"] = {"density": 0.05, "albedo": [0.62, 0.6, 0.55], "_doc": "#1187: the cellar's close air, damp and the lamps' smoke (a FogVolume over its rooms, flags to joists: CellarHaze); RoomLight's gunsmoke still thickens the house's RoomHaze"}

# --- the yard: the hearse shed (NEW: outbuildings kind `shed`) -------------------------------------
SHED = [-11.7, 12.0, -5.1, 17.6]
spec["outbuildings"] = [
    {"_doc": "NEW: the hearse shed at the yard's back, board and batten on a light frame (posts, girts, rafters), a gable roof, open-floored on the yard's dirt; wide double doors to the yard (standing open) for the box hearse, a stall on its west side for the hearse horse behind a plank side (Sean, #1171: 'a glass-sided box hearse, a stall'). The hearse itself is a prop (the next step).",
     "kind": "shed", "id": "hearse_shed", "rect": SHED, "eave": 2.9, "pitch": 30.0, "door": {"at": -9.4, "width": 2.6, "height": 2.5}, "stall": {"x": -6.75, "z": [13.0, 17.4]}, "wood": "rough",
     "ground": [r3(gy(SHED[0], SHED[1])), r3(gy(SHED[2], SHED[3]))]},
]
spec["materials"] = copy.deepcopy(DOC["materials"])
mt = spec["materials"]
mt["_doc"] = "Each surface takes its finish from the library by name (spec_building.gd finish()): a finish's `want` the moment the library has it passed at that age, until then its `use`. White lead on narrow clapboard (painted_white_lap, passed); the near-black trim Sean asked for has no library entry yet (painted_black_trim wanted; drawn in dark walnut till it passes). Inside, pale painted boards in the front rooms; the workroom and cellar rough."
mt["wear"] = {"use": 0.6, "dings": 0.0, "_why": "#901 (dents off until the judges like them): a workroom's feet and hand trucks to the side door and hatch; the front rooms kept"}
mt["finishes"]["trim"] = {"want": {"entry": "painted_black_trim", "age": "few"}, "use": {"entry": "fine_walnut_tg", "age": "few", "role": "wall"}, "_why": "near-black trim (Sean, #1171): cornice, casings, corner boards, sash and doors"}
mt["finishes"]["exterior"]["_why"] = "white lead on narrow clapboard, two years old (Sean, #1171)"
mt["surfaces"] = [s for s in mt["surfaces"] if s[0] not in ("lane/door_", "floor/attic/board", "back_porch/board", "back_porch/roof_board")]
mt["surfaces"][mt["surfaces"].index(["yard/door_", "trim"]) + 1:mt["surfaces"].index(["yard/door_", "trim"]) + 1] = [["alley/door_", "trim"]]
extra = [["cel_cross/", "rough"], ["cel_ice/", "rough"], ["floor/attic/board", "floor"], ["bulkhead/", "rough"], ["side_ramp/", "rough"], ["hearse_shed/", "rough"], ["cellar/", "rough"]]
# (the yard's and cellar's own first: their doors' leaves would else take "/door_"'s pale inside paint)
mt["surfaces"] = [e for e in extra if e[0] not in ("floor/attic/board",)] + mt["surfaces"] + [["floor/attic/board", "floor"]]
mt["stone"] = {"want": {"entry": "rubble_whitewash", "age": "few"}, "inside_age": "few", "_why": "the cellar's walls lime-washed rubble (the sheet's)"}
CY = r3(CELLAR_FLOOR + 0.08 - FLOOR)  # the cellar's flags, over the ground floor
# U0: what the kit already had, kept (his desk, bed, stove, table and chair, the mourners' bench); everything of the trade's own is U1, the prop lab's batch (tools/props/undertaker.py, #1181).
U0 = [
    {"id": "desk", "kit": "roll_top_desk", "at": [9.25, 0.0, 4.4], "facing": 270, "use": "his desk in the office"},
    {"id": "mourners", "kit": "wall_bench", "at": [0.35, 0.0, 3.2], "facing": 90, "use": "the mourners' bench along the yard wall"},
    {"id": "bed", "kit": "plank_bed", "at": [8.6, 0.0, 14.55], "facing": 90, "use": "his bed along the back wall"},
    {"id": "cookstove", "kit": "cookstove", "at": [5.6, 0.0, 14.6], "facing": 180, "use": "his cookstove against the back wall"},
    {"id": "table", "kit": "table", "fit": [0.9, 0.75, 0.6], "at": [6.9, 0.0, 13.6], "facing": 0},
    {"id": "chair", "kit": "chair", "at": [6.9, 0.0, 12.95], "facing": 0},
]
TR = 0.56   # a trestle's top: what a coffin stands on
LANTERN_Y = r3(CY + 2.26 - 0.52 - 0.0)   # hung on a hook in the east girder's underside (2.26 over the flags), its ring at its top
YARD = lambda x, z: r3(gy(x, z) - FLOOR)  # the yard's dirt, in the dressing's y (over the floor)
U1 = [
    # The parlour: the bier with its black drape, the open coffin on it, the hair wreath on the wall.
    {"id": "bier", "kit": "bier", "at": [1.6, 0.0, 2.9], "facing": 90, "use": "the parlour's bier, its black drape"},
    {"id": "bier_coffin", "kit": "coffin_hex_open", "at": [1.6, r3(TR + 0.03), 2.9], "facing": 90, "use": "the coffin open for viewing (nobody in it)"},
    {"id": "wreath", "kit": "hair_wreath", "at": [3.19, 1.5, 2.0], "facing": 270, "use": "a hair wreath under glass on the parlour's wall"},
    # The showroom: coffins on trestles for the bereaved to choose, a child's white one.
    {"id": "display_1", "kit": "trestles", "at": [4.3, 0.0, 2.2], "facing": 90},
    {"id": "display_1_coffin", "kit": "coffin_rect", "at": [4.3, TR, 2.2], "facing": 90, "use": "a casket on its trestles"},
    {"id": "display_2", "kit": "trestles", "at": [6.0, 0.0, 1.5], "facing": 90},
    {"id": "display_2_coffin", "kit": "coffin_hex", "at": [6.0, TR, 1.5], "facing": 90, "use": "a toe-pincher on its trestles"},
    {"id": "display_3", "kit": "trestles_short", "at": [8.9, 0.0, 2.0], "facing": 90},
    {"id": "display_3_coffin", "kit": "coffin_child", "at": [8.9, TR, 2.0], "facing": 90, "use": "a child's coffin, white"},
    # The workroom: the bench, its tools on the wall, a lid on trestles, planks, the glue pot on the stove.
    {"id": "bench", "kit": "workbench", "at": [7.8, 0.0, 5.92], "facing": 0, "use": "his long bench with its vise, against the workroom's front wall"},
    {"id": "tool_rack", "kit": "tool_rack", "at": [7.8, 1.6, 5.5], "facing": 0, "use": "his saws, planes and square on the wall over the bench"},
    {"id": "lid_trestles", "kit": "trestles", "at": [1.0, 0.0, 7.6], "facing": 90},
    {"id": "lid", "kit": "coffin_lid", "at": [1.0, TR, 7.6], "facing": 90, "use": "a coffin lid on trestles under the yard window"},
    {"id": "planks", "kit": "plank_stack", "at": [9.3, 0.0, 8.2], "facing": 90, "use": "his seasoning boards"},
    {"id": "glue_stove", "kit": "box_stove", "at": [8.9, 0.0, 11.3], "facing": 0, "use": "the workroom's stove (the glue pot stands on it)"},
    {"id": "glue_pot", "kit": "glue_pot", "at": [8.9, 0.0, 11.3], "facing": 0, "on": "glue_stove", "use": "the glue pot on the stove"},
    # The cellar, embalming room: the table and its pail, the pump, the carboys, the fluids' and shrouds' shelves, a body under a sheet.
    {"id": "embalming_table", "kit": "embalming_table", "at": [7.6, CY, 13.4], "facing": 270, "use": "the embalming table, its drain to the pail at the back"},
    # Used and grim (Sean's add-on): wet sawdust at the table's feet and under its drain, pale in the corners, rags by the
    # pail, a mop in pinkish water. Small and few: the building's history (#1187) lays the stains and splats round them.
    {"id": "sawdust_a", "kit": "sawdust_wet", "at": [7.35, CY, 12.5], "facing": 0, "use": "soaked sawdust at the table's foot"},
    {"id": "sawdust_b", "kit": "sawdust_wet", "at": [7.85, CY, 12.55], "facing": 30},
    {"id": "sawdust_c", "kit": "sawdust_wet", "at": [7.1, CY, 14.15], "facing": 70, "use": "soaked sawdust under the drain's end"},
    {"id": "sawdust_d", "kit": "sawdust_pale", "at": [9.0, CY, 14.5], "facing": 10, "use": "sawdust swept into the corner"},
    {"id": "sawdust_e", "kit": "sawdust_pale", "at": [0.8, CY, 11.5], "facing": 80, "use": "sawdust swept into the ice room's corner"},
    {"id": "rags", "kit": "rags", "at": [8.05, CY, 14.5], "facing": 20, "use": "rags beside the pail"},
    {"id": "mop_pail", "kit": "mop_pail", "at": [6.9, CY, 13.3], "facing": 0, "use": "a mop in a bucket of pinkish water by the table"},
    {"id": "pail", "kit": "zinc_pail", "at": [7.6, CY, 14.42], "facing": 0},
    {"id": "pump", "kit": "embalming_pump", "at": [8.6, CY, 11.95], "facing": 0, "use": "the hand pump, its tubes and jars on a stand"},
    {"id": "carboy_1", "kit": "carboy", "at": [9.05, CY, 12.8], "facing": 0, "use": "a carboy of fluid"},
    {"id": "carboy_2", "kit": "carboy", "at": [9.05, CY, 13.4], "facing": 0},
    {"id": "fluids", "kit": "fluids_shelf", "at": [8.6, CY, 11.32], "facing": 0, "use": "the embalmer's shelf: jars and bottles of fluids"},
    {"id": "shrouds", "kit": "shroud_shelf", "at": [6.3, CY, 14.55], "facing": 180, "use": "shrouds folded on a shelf"},
    {"id": "cooling_board", "kit": "sheeted_board", "at": [4.6, CY, 14.35], "facing": 0, "use": "the cooling board on its legs against the back wall, a body under a sheet"},
    # The cellar, ice room: the bin of blocks in sawdust and the corpse cooler.
    {"id": "ice_bin", "kit": "ice_bin", "at": [2.25, CY, 14.3], "facing": 0, "use": "the ice bin, blocks packed in sawdust"},
    {"id": "cooler", "kit": "corpse_cooler", "at": [0.85, CY, 13.2], "facing": 90, "use": "the corpse cooler along the east wall"},
    # The cellar, coffin store: the rack with coffins on it, the safety coffin, the posing stand and its chair, the lantern.
    {"id": "rack", "kit": "coffin_rack", "at": [1.9, CY, 10.4], "facing": 0, "use": "a coffin rack along the cross wall"},
    {"id": "rack_low", "kit": "coffin_hex", "at": [1.9, r3(CY + 0.34), 10.4], "facing": 0},
    {"id": "rack_high", "kit": "coffin_rect", "at": [1.9, r3(CY + 1.04), 10.4], "facing": 0},
    {"id": "safety", "kit": "safety_coffin", "at": [8.85, CY, 8.7], "facing": 90, "use": "the safety coffin with its bell on a frame (a sample)"},
    {"id": "posing_stand", "kit": "posing_stand", "at": [7.75, CY, 10.7], "facing": 0, "use": "the photographer's posing stand by the stair"},
    {"id": "posing_chair", "kit": "posing_chair", "at": [8.35, CY, 10.7], "facing": 0},
    {"id": "lantern", "kit": "iron_lantern", "at": [6.47, LANTERN_Y, 7.95], "facing": 0, "use": "the iron lantern on a hook in the east girder"},
    # The hearse shed: the box hearse, the horse's harness in the stall.
    # The box hearse (`hearse`, made and standing on a flat floor) is NOT placed: the yard falls 3.4 cm a metre and a kit prop's
    # feet are looked for at one height (KitProp._find_footing), so its four wheels, 2.4 m by 1.45 m apart, can't all meet the
    # ground and it tips loose (CI's test_save_game found it). It wants a level pad under the shed (the valley's ground, like
    # CellarDig) before this line can come back: {"id": "hearse", "kit": "hearse", "at": [-9.4, YARD(-9.4, 15.85), 15.85], "facing": 270}
    {"id": "harness", "kit": "harness_rack", "at": [-5.9, r3(YARD(-5.9, 17.55) + 1.5), 17.58], "facing": 180, "use": "the stall's harness"},
]
spec["dressing"] = {"_doc": "His furniture and props, placed by the building's own build (SpecBuilding._dressing, PropDressing). U0: what the kit already had (his desk, bed, stoves, table and chair, the mourners' bench). U1: the trade's own, the prop lab's batch (#1181, tools/props/undertaker.py, refs experiments/prop_lab/undertaker/README.md): coffins on trestles and racks, the bier and its drape, the bench and tool rack, the embalming table, pump, carboys, shelves, cooling board, ice bin and corpse cooler, the safety coffin, the posing stand, the hair wreath, the lantern, the box hearse and the stall's harness.", "batches": {"U0": U0, "U1": U1}}

# --- the building's past (#1187, Sean 2026-11-23: "more blood stained and gross down in the basement") ---
# Fourteen years of embalming laid as old blood through the game's own Blood (dried splats: decals) and
# FloorMarks (stains soaked into the flags and treads), placed by the props (`by`: a dressing id, `off` in the
# building's x and z from it) and the ways the dead come in. Laid at build (PastStains), seeded, dark and dry;
# the mop and the rag lift them as any (Blood.take, FloorMarks.take). Points are [x, z] on `level`, or
# [x, z, y] (y over the building's 0: the stair). Sean's sawdust heaps are props: the drips go beside them.
C_TOP = FLAGS_TOP
TABLE = lambda dx, dz: {"by": "embalming_table", "off": [dx, dz]}
PAIL = lambda dx, dz: {"by": "pail", "off": [dx, dz]}
BOARD = lambda dx, dz: {"by": "cooling_board", "off": [dx, dz]}
COOLER = lambda dx, dz: {"by": "cooler", "off": [dx, dz]}
STAIR_HEAD = spec["cellar"]["stair"]["head"]
STAIR_RUN = 13 * spec["cellar"]["stair"]["going"]
STAIR_Z = r3(STAIR_HEAD[1] + spec["cellar"]["stair"]["width"] * 0.5)  # its middle (the head is its edge)
spec["past"] = [{
    "id": "embalming_years",
    "_doc": "NEW (#1187, PastStains): the undertaker's cellar since 1868. `blood`: `soak` a stain soaked into the surface (FloorMarks), `r` round a point or `width` along `points`, ml a cell's worth over the patch; `drips` dried splats (Blood) every `every` m along `points` (velocity: the way the dead were carried); `splash` n splats round a point within `r`; `smear` splats run down a wall, found by a ray from `points` (inside the room) along `toward`, `y` over the level. ml ranges are drawn from the seeded rng. Not gore: the table and its pail, the board, the carrying path, the melt.",
    "years": 14, "seed": 1882, "marks": [],
    "blood": [
        # The table: what ran off its zinc into the drain's pail, and what dripped through and round it for years.
        {"what": "soak", "level": "cellar", "at": TABLE(0, 0.78), "r": 0.26, "ml": 110, "_doc": "under the drain's end"},
        {"what": "soak", "level": "cellar", "points": [TABLE(0, 0.85), PAIL(0, -0.08)], "width": 0.16, "ml": 30, "_doc": "the drain's drip to the pail"},
        {"what": "soak", "level": "cellar", "at": PAIL(0.05, 0.02), "r": 0.3, "ml": 55, "_doc": "round the pail: spilt carrying it"},
        {"what": "soak", "level": "cellar", "at": TABLE(0, 0.1), "r": 0.34, "ml": 45, "_doc": "through the table's seams"},
        {"what": "soak", "level": "cellar", "at": TABLE(-0.55, -0.2), "r": 0.28, "ml": 14, "_doc": "where he stands, trodden"},
        {"what": "soak", "level": "cellar", "at": TABLE(0.55, 0.3), "r": 0.26, "ml": 12},
        {"what": "splash", "level": "cellar", "at": PAIL(0, 0), "r": [0.16, 0.5], "n": 6, "ml": [0.4, 3.0], "_doc": "slopped from the pail"},
        {"what": "drips", "level": "cellar", "points": [TABLE(-0.42, -0.55), TABLE(-0.42, 0.75)], "every": [0.25, 0.55], "ml": [0.3, 2.2], "_doc": "off the table's edge, between the heaps"},
        {"what": "drips", "level": "cellar", "points": [TABLE(0.42, -0.4), TABLE(0.42, 0.75)], "every": [0.3, 0.6], "ml": [0.3, 1.8]},
        # The cooling board: the dead laid out before and after.
        {"what": "soak", "level": "cellar", "at": BOARD(0.2, 0), "r": 0.42, "ml": 50, "_doc": "under the board"},
        {"what": "soak", "level": "cellar", "at": BOARD(-0.65, 0), "r": 0.24, "ml": 18},
        {"what": "drips", "level": "cellar", "points": [BOARD(-0.8, -0.32), BOARD(0.85, -0.32)], "every": [0.3, 0.7], "ml": [0.3, 2.0], "_doc": "off its front edge"},
        # The plank wall behind the table (the cross wall's embalming side, between the lamp and the fluids' shelf):
        # wiped hands and the pump's spatter, run down the boards.
        {"what": "smear", "level": "cellar", "points": [[7.15, 11.4], [8.15, 11.4]], "toward": [0, -1], "y": [0.75, 1.45], "n": 6, "ml": [2.0, 9.0]},
        # The carrying path: down the workroom's stair, across the coffin store, through the embalming room's door to the
        # table; and in from the bulkhead's passage.
        {"what": "drips", "level": "cellar", "points": [[r3(STAIR_HEAD[0] + 0.25), STAIR_Z, FLOOR - 0.2], [r3(STAIR_HEAD[0] + STAIR_RUN - 0.1), STAIR_Z, C_TOP]], "over": 0.35, "every": [0.35, 0.8], "ml": [0.4, 2.5], "carry": [1.0, 0], "_doc": "down the stair's treads"},
        {"what": "drips", "level": "cellar", "points": [[6.3, 9.8], [5.4, 10.4], [4.6, 10.95], [4.85, 11.6], [6.0, 12.1], TABLE(-0.5, -0.9)], "every": [0.45, 1.0], "ml": [0.4, 2.0], "carry": "path"},
        {"what": "drips", "level": "cellar", "points": [[0.7, 8.6], [2.2, 9.3], [3.5, 9.75], [4.5, 10.8]], "every": [0.6, 1.2], "ml": [0.3, 1.6], "carry": "path", "_doc": "in from the bulkhead"},
        # The ice room: the cooler's melt, pinkish, run to the door and under it.
        {"what": "soak", "level": "cellar", "points": [COOLER(0.25, -1.05), [1.9, 12.45], [3.25, 12.55], [3.75, 12.5]], "width": 0.2, "ml": 7, "_doc": "the melt run under the ice room's door"},
        {"what": "soak", "level": "cellar", "at": COOLER(0.2, -1.0), "r": 0.22, "ml": 14},
        {"what": "splash", "level": "cellar", "at": COOLER(0.25, 0), "r": [0.3, 0.9], "n": 3, "ml": [0.3, 1.2]},
    ],
}]
spec["furniture"] = []
spec["fixtures"] = []
spec["sources"] = DOC["sources"][:5] + [
    "A. Renouard, The Undertakers' Manual (1878): the undertaker's rooms, the cooling board, ice and the corpse cooler, arterial embalming by hand pump.",
    "R. W. Habenstein and W. M. Lamers, The History of American Funeral Directing (1955): the cabinetmaker-undertaker of the 1870s-80s, the rooms of a small-town shop, the box hearse with glass sides.",
    "Bulkhead (hatchway) cellar doors: the stone areaway and slanted plank doors of 19th-century New England and the Midwest (the Old House Journal's surveys); steps 7-8 in, the doors on cheeks.",
    "F. Vester, Burial Case, US patent 81,437 (1868): a safety coffin with a bell at the grave's head on a cord to the hand (the cellar's sample).",
    "History Colorado, 'False Front Commercial': the type.",
]
spec["sources"][0] = DOC["sources"][0]

out = ROOT / "config/buildings/undertaker.json"
out.write_text(json.dumps(spec, indent="\t") + "\n")
print("wrote", out, len(out.read_text()), "bytes")
