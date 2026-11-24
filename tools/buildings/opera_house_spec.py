#!/usr/bin/env python3
"""Writes config/buildings/opera_house.json (McCready's Opera House, #1143: the building lab's step 2, the spec on
its lot) and draws its two plans, so a change is one number and a re-run:

    python3 tools/buildings/opera_house_spec.py [--plans=OUT.png] [--sizing]

Sean's answers (2026-11-24, on #1143 and #1242): a new lot at Main Street's east end, north side (the front faces
south, facing 180); red brick with dressed stone quoins, base, sills and keystones; MCCREADY'S OPERA HOUSE 1881 in
the cornice; a horseshoe balcony; the sheet and plan OK'd ("Looks good let's spec it out"), three tiers on the front,
the lot kept. `status: "spec"`: written to the format, NOT BUILT (the build waits for after the slice); keys marked
NEW in their `_doc` are parts the builder doesn't have yet (experiments/building_lab/opera_house/README.md).

Sizes: 60 x 110 ft (18.29 x 33.53 m), 523 seats. The frame from period books (`sources`; `--sizing` prints each
member's check): brick walls by Kidder's rule for public halls, joists and beams by the Wood Handbook's working
stresses for yellow pine (1,200 lb/in2 in bending) at 100 lb/ft2 under a crowd standing (balcony, foyer, stairs;
Kidder's for theatres) and 70 lb/ft2 for the dance floor (saloon B's, Hatfield's hall), cast-iron columns by
Gordon's formula, the Howe trusses by the method of sections (Haupt).
Space: x along the front from its EAST corner (facing 180), z back from the front wall's outer face, y up from the
pad (the walk's street-edge ground, world -0.5). Metres.
"""
import json
import math
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
FT = 0.3048


def r3(v):
    return round(v, 3)


W, D = r3(60 * FT), r3(110 * FT)                    # 18.288 x 33.528
T_OUT = 0.43                                        # 17 in brick (four bricks): the outer walls to the upper floor
T_UP = 0.33                                         # 13 in above the set-off (Kidder: a brick less each storey up)
T_IN = 0.33                                         # 13 in: the proscenium (the stage's fire wall), the lobby's back
T_PART = 0.23                                       # 9 in: the vestibule's brick partition
CX = r3(W / 2)
IN_E, IN_W = T_OUT, r3(W - T_OUT)                   # the inside faces at the ground floor (x)

# Heights over the pad.
FLOOR = 0.45                                        # the walk's top: three steps up from the street
STAGE = r3(FLOOR + 3.5 * FT)                        # 1.517: the stage, the boxes' lower tier, the dressing block
FOYER = r3(FLOOR + 5.0)                             # 5.45: the foyer, the balcony's back aisle
ATTIC = r3(FOYER + 4.6)                             # 10.05: the scene loft over the foyer (the attic windows)
FRONT_ROOF = r3(ATTIC + 3.0)                        # 13.05: the front block's flat roof
CORNICE = 14.0                                      # the front's cornice top (46 ft)
PEDIMENT = 15.9
PLATE = r3(FLOOR + 10.0)                            # 10.45: the hall's trusses bear here
HALL_TOP = r3(PLATE + 1.0)                          # the hall's side parapets
CEILING = r3(PLATE - 0.25)                          # the hall's plaster ceiling, on joists hung from the bottom chords
GRID = r3(STAGE + 30 * FT)                          # 10.661: the stage's gridiron (roll drops hang from it)
STAGE_TOP = r3(GRID + 3.3)                          # 13.961: the stage house's walls
DRESS_UP = r3(STAGE + 10 * FT)                      # 4.565: the dressing block's upper floor
DRESS_TOP = r3(DRESS_UP + 3.6)                      # 8.165: its flat roof's parapet

# Lines along z (back from the front's outer face).
Z_VEST = 2.6                     # the vestibule's back partition (9 in brick)
Z_LOBBY = 7.0                    # the lobby's back wall (13 in brick: the balcony's back bears on it)
Z_HALL0 = r3(Z_LOBBY + T_IN)     # 7.33
Z_PIT0 = 19.8                    # the orchestra pit's rail
Z_APRON = 21.64                  # the apron's edge (4 ft out of the proscenium), the footlights
Z_PROSC = 22.86                  # the proscenium wall's hall face
Z_STAGE0 = r3(Z_PROSC + T_IN)    # 23.19
Z_DRESS = 29.9                   # the dressing block's front wall (13 in: it carries the stage house's back)
Z_DRESS0 = r3(Z_DRESS + T_IN)    # 30.23
Z_BACK = r3(D - T_UP)            # 33.198

# The lobby's stairs: straight flights of 26 along the lobby's back wall from the middle outward; the foyer's wells
# over them, a beam along their front edge (z WELL_Z) on posts at the flights' ends and middles.
ST_N, ST_GO, ST_W = 26, 0.25, 1.37
ST_RUN = r3((ST_N - 1) * ST_GO)                     # 6.25
WELL_Z = r3(Z_LOBBY - ST_W)                         # 5.63
WELL_E = [r3(CX - 0.7 - ST_RUN), r3(CX - 0.7)]      # 2.194 .. 8.444
WELL_W = [r3(CX + 0.7), r3(CX + 0.7 + ST_RUN)]      # 9.844 .. 16.094
WELL_POSTS = [WELL_E[0], r3(sum(WELL_E) / 2), WELL_E[1], WELL_W[0], r3(sum(WELL_W) / 2), WELL_W[1]]

# The parquet, the balcony, the boxes.
SEAT = r3(20 / 12 * FT)          # 0.508
ROW = r3(32 / 12 * FT)           # 0.813
BAL_ROW = r3(34 / 12 * FT)       # 0.864: a balcony row (its riser leaves less knee room)
BAL_RISE = 0.3
BAL_BACK_ROWS = 4
BAL_AISLE = 1.0                  # the balcony's back cross aisle at the foyer's level
BAL_FRONT = r3(Z_HALL0 + BAL_AISLE + BAL_BACK_ROWS * BAL_ROW)      # the back arm's rail
BAL_SIDE = r3(0.76 + 2 * BAL_ROW)                                   # the side arms (a passage, two rows)
BAL_R = 3.2                      # the corners' radius on the rail's line
BAL_END = 19.4                   # the side arms stop at the boxes
BAL_LOW = r3(FOYER - BAL_BACK_ROWS * BAL_RISE)                      # 4.25: the front row's floor
BOX_Z = [r3(BAL_END + 0.2), r3(Z_PROSC - 0.1)]

# Hall bays: the trusses on the side walls' pilasters, the windows between them.
TRUSS_Z = [r3(Z_HALL0 + 1.83 + 3.66 * k) for k in range(4)]        # 9.16 .. 20.14
WIN_Z = [r3(z + 1.83) for z in TRUSS_Z[:3]]                        # mid-bay


def window(at, sill, h, w=1.07, level="ground", arch=True, **kw):
    o = {"type": "window", "level": level, "at": r3(at), "width": r3(w), "height": r3(h), "sill": r3(sill),
         "lights": 4}
    if arch:
        o["arch"] = "round"
    o.update(kw)
    return o


def door(at, w, h, level="ground", **kw):
    o = {"type": "door", "level": level, "at": r3(at), "width": r3(w), "height": r3(h)}
    o.update(kw)
    return o


def brick(id_, a, b, out, top, thick=T_OUT, **kw):
    """A brick wall (the stone wall's format): its `profile` [from y, d_lo, d_hi] (d along `out`, the brick inward):
    the footing 8 in wider each side from 4 ft down, the wall's thickness from the pad, a set-off where it thins."""
    w = {"id": id_, "line": [[r3(a[0]), r3(a[1])], [r3(b[0]), r3(b[1])]], "out": out, "stone": True,
         "masonry": "brick", "thick": thick, "top": r3(top)}
    w.update(kw)
    part = bool(kw.get("partition", False))
    prof = [[-9, r3(-thick - 0.2), 0.2 if part else 0.0], [0.0, r3(-thick), 0.0]]
    so = kw.get("set_off")
    if so:
        prof.append([r3(so["y"] - 0.36), r3(-so["thick"]), 0.0])
    w["profile"] = prof
    w.setdefault("ends", [None, None])
    return w


# A timber partition's finish both sides: boards stand in for lath and plaster until PlasterWall (the jail's).
PLASTER = [{"side": "-", "finish": "boards"}, {"side": "+", "finish": "boards"}]


# ---------------------------------------------------------------------------------------------- walls
def walls():
    sill = r3(FLOOR + 0.75)
    front = brick("front", (0, 0), (W, 0), "-z", CORNICE, set_off={"y": FOYER, "thick": T_UP},
                  pediment={"at": CX, "width": 6.1, "top": PEDIMENT, "roundel": "1881"},
                  openings=[door(x, 1.68, 3.05, leaves=2, leaf="outward", arch="round", fanlight=0.84, glazed=True)
                            for x in (CX - 3.05, CX, CX + 3.05)]
                  + [window(2.6, sill, 3.2), window(W - 2.6, sill, 3.2)]
                  + [window(CX + k * 3.05, FOYER + 0.45, 3.35, w=1.22, level="upper") for k in (-2, -1, 0, 1, 2)]
                  + [window(CX + k * 3.05, ATTIC + 0.6, 1.3, w=0.91, level="attic") for k in (-2, -1, 0, 1, 2)])
    front["_doc"] = ("The front on Main Street: red brick in common bond on a buff sandstone base course (to the walk's "
                     "top), dressed quoins at both corners, stone sills and keystones; 17 in to the foyer's floor, 13 in "
                     "above (the set-off carries the foyer's joists). Three tiers (Sean, #1242): three arched doorways "
                     "(pairs of glazed doors opening OUT, fanlights; cast-iron columns at the middle one: `front.iron_columns`) "
                     "and an arched window either side; five tall arched foyer windows; five small arched attic "
                     "windows (the scene loft). The galvanized-iron cornice on paired brackets, its frieze MCCREADY'S "
                     "OPERA HOUSE in gilt, the pediment's roundel 1881.")

    def side(id_, x, out):
        # Four segments by their tops: the front block (its cornice returns), the hall, the stage house, the
        # dressing block. Each segment's openings by their distance from its line's start.
        e = out == "-x"
        z_dress = r3(Z_DRESS + T_IN)
        hall_ops = []
        for z in WIN_Z:
            hall_ops.append(window(z - Z_LOBBY, FLOOR + 1.0, 2.4, w=1.07, shutters="iron",
                                   _doc="a lower window, under the balcony's side arm"))
            hall_ops.append(window(z - Z_LOBBY, BAL_LOW + 0.6 + 1.0, 2.6, w=1.07, level="upper", shutters="iron",
                                   _doc="an upper window over the side arm, under the plate"))
        hall_ops.append(door(Z_HALL0 + 0.55 - Z_LOBBY, 1.07, 2.29, leaf="outward",
                             _doc="the back exit, from the cross aisle under the balcony"))
        hall_ops.append(door(Z_PIT0 - 0.6 - Z_LOBBY, 1.52, 2.44, leaves=2, leaf="outward",
                             _doc="the hall's side exit to the lane, by the boxes"))
        stage_ops = [window(5.2, STAGE + 3.6, 1.83, w=0.91, level="upper", shutters="iron")]
        if e:
            stage_ops.append(door(2.0, 2.44, 3.66, leaves=2, leaf="outward", sill=r3(STAGE - FLOOR),
                                  _doc="the scenery door at the stage's height: flats and trunks off a wagon's bed"))
        segs = [
            brick("%s_front" % id_, (x, 0), (x, Z_LOBBY), out, CORNICE, set_off={"y": FOYER, "thick": T_UP},
                  openings=[window(4.6, FOYER + 0.9, 2.4, w=0.91, level="upper"),
                            window(4.6, ATTIC + 0.6, 1.3, w=0.91, level="attic")],
                  _doc="the front block's side: the cornice returns along it (a three-storey block)"),
            brick("%s_hall" % id_, (x, Z_LOBBY), (x, Z_PROSC), out, HALL_TOP,
                  pilasters={"at": [r3(z - Z_LOBBY) for z in TRUSS_Z], "proj": 0.11, "width": 0.56,
                             "_doc": "NEW: brick piers under the trusses' bearings (the wall's stiffening)"},
                  openings=hall_ops,
                  _doc="the hall's side: pilasters under the trusses, two tiers of arched windows with iron fire "
                       "shutters, two exits (doors opening out, after the Brooklyn Theatre fire, 1876)"),
            brick("%s_stage" % id_, (x, Z_PROSC), (x, z_dress), out, STAGE_TOP, openings=stage_ops,
                  _doc="the stage house's side, 44 ft (the gridiron and roll drops in it)"),
            brick("%s_dress" % id_, (x, z_dress), (x, D), out, DRESS_TOP, thick=T_UP,
                  openings=[window(1.4, STAGE + 0.9, 1.52, w=0.76, arch=False),
                            window(1.4, DRESS_UP + 0.9, 1.52, w=0.76, arch=False, level="upper")],
                  _doc="the dressing block's side: two storeys, 13 in"),
        ]
        for s in segs:
            s["side"] = id_
        return segs

    back = brick("back", (0, D), (W, D), "+z", DRESS_TOP, thick=T_UP,
                 openings=[door(CX, 1.07, 2.29, sill=r3(STAGE - FLOOR), _doc="the stage door, up from the yard"),
                           window(2.6, STAGE + 0.9, 1.52, w=0.76, arch=False), window(W - 2.6, STAGE + 0.9, 1.52, w=0.76, arch=False),
                           window(6.0, STAGE + 0.9, 1.52, w=0.76, arch=False), window(W - 6.0, STAGE + 0.9, 1.52, w=0.76, arch=False),
                           window(2.6, DRESS_UP + 0.9, 1.52, w=0.76, arch=False, level="upper"),
                           window(W - 2.6, DRESS_UP + 0.9, 1.52, w=0.76, arch=False, level="upper"),
                           window(6.0, DRESS_UP + 0.9, 1.52, w=0.76, arch=False, level="upper"),
                           window(W - 6.0, DRESS_UP + 0.9, 1.52, w=0.76, arch=False, level="upper")])
    back["_doc"] = ("The back on the yard: the dressing block's wall, 13 in, the stage door up from the yard (its ground "
                    "~1.2 m over the pad: three steps), eight small windows.")

    ie = IN_E
    parts = [
        brick("vestibule", (ie, Z_VEST), (IN_W, Z_VEST), "-z", r3(FOYER - FLOOR - 0.35), thick=T_PART, partition=True,
              level="ground",
              openings=[door(CX - ie, 3.05, 2.9, leaves=2, leaf="swing", arch="round",
                             _doc="into the lobby: two pairs of swing doors under one arch")],
              _doc="The vestibule's back (9 in brick, plastered): the box office's and the cloak room's back walls."),
        {"id": "box_office", "line": [[4.6, ie], [4.6, Z_VEST]], "out": "-x", "partition": True, "level": "ground", "inside": PLASTER,
         "openings": [window(0.9, 1.0, 0.6, w=0.6, grille="brass", shelf="marble",
                             _doc="the ticket window, onto the vestibule"),
                      door(1.75, 0.76, 2.03, _doc="the seller's door, from the vestibule's corner")]},
        {"id": "cloak_room", "line": [[r3(W - 4.6), ie], [r3(W - 4.6), Z_VEST]], "out": "+x", "partition": True,
         "level": "ground", "inside": PLASTER, "openings": [{"type": "hatch", "at": 0.9, "width": 1.2, "height": 1.0, "sill": 0.95,
                                          "_doc": "the cloak counter"}, door(1.75, 0.76, 2.03)]},
        brick("lobby_back", (ie, Z_LOBBY), (IN_W, Z_LOBBY), "-z", HALL_TOP, thick=T_IN, partition=True, level="ground",
              bearing=True,
              openings=[door(CX - ie, 1.22, 2.29, leaves=2, leaf="swing", _doc="the middle doors, between the stairs' feet"),
                        door(CX - ie - 5.6, 1.52, 2.44, leaves=2, leaf="swing",
                             _doc="under the east stair's high end (3.4 m clear over the passage)"),
                        door(CX - ie + 5.6, 1.52, 2.44, leaves=2, leaf="swing"),
                        door(CX - ie, 1.22, 2.29, leaves=2, leaf="swing", level="upper",
                             _doc="foyer to the balcony's back aisle, over the bridge between the wells"),
                        door(1.1 - ie, 1.07, 2.29, leaf="swing", level="upper",
                             _doc="at the east stair's head: up the stair and straight into the balcony"),
                        door(W - 1.1 - ie, 1.07, 2.29, leaf="swing", level="upper")],
              _doc="The lobby's back wall, 13 in brick to the roof: the foyer's and the scene loft's joists, the "
                   "balcony's carriages and the hall's first purlins bear on it; doors into the hall's cross aisle "
                   "below, the balcony's back aisle above."),
        brick("proscenium", (ie, Z_PROSC), (IN_W, Z_PROSC), "-z", STAGE_TOP, thick=T_IN, partition=True,
              level="ground", bearing=True,
              openings=[{"type": "void", "at": r3(CX - ie), "width": r3(28 * FT), "height": r3(20 * FT),
                         "sill": r3(STAGE - FLOOR), "arch": "segmental",
                         "_doc": "NEW: the proscenium opening (a segmental arch of brick rings over 28 ft, framed "
                                 "inside in gilt plaster)"},
                        door(1.4 - ie, 0.91, 2.13, sill=r3(STAGE - FLOOR), _doc="the lower east box's passage to the wings"),
                        door(W - 1.4 - ie, 0.91, 2.13, sill=r3(STAGE - FLOOR))],
              _doc="The proscenium wall: 13 in brick from its footing through the roof (the period's fire wall "
                   "between stage and house)."),
        brick("dressing_front", (ie, Z_DRESS), (IN_W, Z_DRESS), "-z", STAGE_TOP, thick=T_IN, partition=True,
              level="ground", bearing=True,
              openings=[door(CX - ie, 1.22, 2.29, sill=r3(STAGE - FLOOR), _doc="the stage's back door to the corridor"),
                        door(IN_W - 1.0 - ie, 0.91, 2.13, sill=r3(DRESS_UP - FLOOR), level="upper",
                             _doc="the upper dressing rooms' door onto the fly gallery (west)")],
              _doc="The stage's back wall and the dressing block's front, 13 in to the stage house's top."),
        {"id": "corridor_e", "line": [[r3(CX - 0.76), Z_DRESS0], [r3(CX - 0.76), Z_BACK]], "out": "-x", "partition": True,
         "level": "ground", "bearing": True, "inside": PLASTER, "openings": [door(0.75, 0.76, 2.03), door(2.2, 0.76, 2.03)]},
        {"id": "corridor_w", "line": [[r3(CX + 0.76), Z_DRESS0], [r3(CX + 0.76), Z_BACK]], "out": "+x", "partition": True,
         "level": "ground", "bearing": True, "inside": PLASTER, "openings": [door(0.75, 0.76, 2.03), door(2.2, 0.76, 2.03)]},
        {"id": "dressing_split_e", "line": [[ie, r3(Z_DRESS0 + 1.45)], [r3(CX - 0.76), r3(Z_DRESS0 + 1.45)]],
         "out": "-z", "partition": True, "level": "ground", "inside": PLASTER, "openings": []},
        {"id": "dressing_split_w", "line": [[r3(CX + 0.76), r3(Z_DRESS0 + 1.45)], [IN_W, r3(Z_DRESS0 + 1.45)]],
         "out": "-z", "partition": True, "level": "ground", "inside": PLASTER, "openings": []},
        {"id": "office", "line": [[4.6, ie], [4.6, r3(Z_LOBBY - 1.4)]], "out": "-x", "partition": True, "level": "upper", "inside": PLASTER,
         "openings": [door(4.0, 0.91, 2.13, level="upper")], "_doc": "McCready's office off the foyer"},
    ]
    return [front] + side("east", 0.0, "-x") + side("west", W, "+x") + [back] + parts


# ---------------------------------------------------------------------------------------------- floors
def floors():
    return [
        {"id": "ground_front", "level": "ground", "rect": [IN_E, IN_E, IN_W, Z_LOBBY], "joists": "x",
         "look": "wood:int_floor",
         "_doc": "the vestibule (laid over with black and white marble tile: NEW finish) and the lobby, 2x10 at 16 in "
                 "along x on the girders"},
        {"id": "hall", "level": "ground", "rect": [IN_E, Z_HALL0, IN_W, Z_PROSC], "joists": "x", "joist": "dance_joist",
         "look": "wood:int_floor",
         "_doc": "the parquet and the pit, level (a dance floor: the front four rows on runners), 2x12 at 16 in on "
                 "five girder lines (70 lb/ft2)"},
        {"id": "foyer", "level": "upper", "rect": [IN_E, IN_E, IN_W, WELL_Z], "joists": "z", "joist": "long_joist",
         "look": "wood:int_floor",
         "_doc": "the foyer: 3x14 at 12 in front to back, from the front wall's set-off to the wells' beam (`beams` "
                 "well), 100 lb/ft2. Behind the beam the two stairs' wells (no floor), and three short floors: "
                 "the landings at the stairs' heads and the bridge between the wells (the recipe: split floors, no tail joists)"},
        {"id": "foyer_head_e", "level": "upper", "rect": [IN_E, WELL_Z, WELL_E[0], Z_LOBBY], "joists": "z", "look": "wood:int_floor"},
        {"id": "foyer_bridge", "level": "upper", "rect": [WELL_E[1], WELL_Z, WELL_W[0], Z_LOBBY], "joists": "z", "look": "wood:int_floor"},
        {"id": "foyer_head_w", "level": "upper", "rect": [WELL_W[1], WELL_Z, IN_W, Z_LOBBY], "joists": "z", "look": "wood:int_floor"},
        {"id": "scene_loft", "level": "attic", "rect": [IN_E, IN_E, IN_W, Z_LOBBY], "joists": "z",
         "joist": "long_joist", "look": "wood:int_rough",
         "_doc": "the scene painter's loft and the stores over the foyer: the attic windows' floor (40 lb/ft2)"},
        {"id": "dress_ground", "level": "stage", "rect": [IN_E, Z_DRESS0, IN_W, Z_BACK], "joists": "z",
         "look": "wood:int_floor",
         "_doc": "the dressing block's floor at the stage's height, 2x10 front to back over 2.97 m on the walls' ledges"},
        {"id": "dress_upper", "level": "dress_upper", "rect": [IN_E, Z_DRESS0, IN_W, Z_BACK], "joists": "z",
         "look": "wood:int_floor",
         "openings": [{"id": "stair", "rect": [r3(CX - 0.6), r3(Z_BACK - 3.3), r3(CX + 0.6), r3(Z_BACK - 0.1)]}]},
        {"id": "dress_roof", "level": "dress_roof", "rect": [IN_E, Z_DRESS0, IN_W, Z_BACK], "joists": "z",
         "joist": "roof_joist", "_doc": "flat, tin on boards, behind its parapet"},
        {"id": "front_roof", "level": "front_roof", "rect": [IN_E, IN_E, IN_W, Z_LOBBY], "joists": "z",
         "joist": "roof_joist", "_doc": "the front block's flat roof behind the cornice's parapet, tin on boards"},
    ]


def girders():
    return {"_doc": "Lines along z under the ground floors' joists (along x), on brick piers at 6 ft over the pad (a "
                    "crawl space: the pad is level at the street edge's height). Spans 2.9 m; the balcony's columns "
                    "stand on piers of their own between them.",
            "x": [3.33, 6.24, 9.14, 12.05, 14.96]}


def beams():
    xs = [IN_E] + WELL_POSTS + [IN_W]
    return [{"id": "well_%d" % k, "from": [r3(xs[k]), WELL_Z], "to": [r3(xs[k + 1]), WELL_Z], "level": "upper",
             "_doc": "the wells' beam, 8x12 a bay (cut over each post): the foyer's joists end on it, the landings' and "
                     "the bridge's start; ends in pockets in the side walls" if k == 0 else ""}
            for k in range(len(xs) - 1)]


def posts():
    return {"_doc": "6x6 posts under the wells' beam, cased as fluted columns, from the lobby's floor (on piers): at "
                    "each flight's foot and head (its newels) and its middle (spans 3.1 m)",
            "free": [[x, WELL_Z] for x in WELL_POSTS], "wall": []}


# ---------------------------------------------------------------------------------------------- the balcony
def balcony():
    """The horseshoe: a back arm of four rows over the cross aisle and the parquet's last rows, two side arms of two
    rows running to the boxes, joined at the back corners by quarter circles of radius BAL_R on the rail's line."""
    xr_e, xr_w = r3(IN_E + BAL_SIDE), r3(IN_W - BAL_SIDE)       # the side rails' lines
    zr = BAL_FRONT                                               # the back rail's line
    cE = (xr_e + BAL_R, zr + BAL_R)                              # the corners' centres
    cW = (xr_w - BAL_R, zr + BAL_R)
    s45 = math.sqrt(0.5)
    cols = [[r3(cE[0]), zr], [CX, zr], [r3(cW[0]), zr],
            [r3(cE[0] - BAL_R * s45), r3(cE[1] - BAL_R * s45)], [r3(cW[0] + BAL_R * s45), r3(cW[1] - BAL_R * s45)],
            [xr_e, r3(cE[1])], [xr_w, r3(cW[1])], [xr_e, BAL_END], [xr_w, BAL_END]]

    def arc(c, a0, a1):
        n = max(2, int(math.ceil(abs(a1 - a0) * BAL_R / 0.6)))
        return [[r3(c[0] + BAL_R * math.cos(a0 + (a1 - a0) * k / n)), r3(c[1] + BAL_R * math.sin(a0 + (a1 - a0) * k / n))]
                for k in range(n + 1)]
    rail = ([[xr_e, BAL_END]] + arc(cE, math.pi, 1.5 * math.pi) + [[CX, zr]]
            + arc(cW, 1.5 * math.pi, 2 * math.pi) + [[xr_w, BAL_END]])
    tiers = []
    for k in range(BAL_BACK_ROWS):           # k 0 the front row
        z0 = r3(zr - (k + 1) * BAL_ROW)
        tiers.append({"id": "back_%d" % (k + 1), "y": r3(BAL_LOW + k * BAL_RISE), "rect": [IN_E, z0, IN_W, r3(z0 + BAL_ROW)],
                      "seats": 26})
    tiers.append({"id": "back_aisle", "y": FOYER, "rect": [IN_E, Z_HALL0, IN_W, r3(Z_HALL0 + BAL_AISLE)], "seats": 0})
    for side, x_in, x_wall in (("east", xr_e, IN_E), ("west", xr_w, IN_W)):
        sgn = 1 if side == "east" else -1
        for k in range(2):
            xa = r3(x_in - sgn * k * BAL_ROW)
            xb = r3(x_in - sgn * (k + 1) * BAL_ROW)
            tiers.append({"id": "%s_%d" % (side, k + 1), "y": r3(BAL_LOW + k * BAL_RISE),
                          "rect": [min(xa, xb), zr, max(xa, xb), BAL_END], "seats": 12})
        xp = r3(x_in - sgn * 2 * BAL_ROW)
        tiers.append({"id": "%s_passage" % side, "y": r3(BAL_LOW + 2 * BAL_RISE),
                      "rect": [min(xp, x_wall), zr, max(xp, x_wall), BAL_END], "seats": 0,
                      "_doc": "the passage along the wall from the back aisle (down three steps at the corner) to the upper box"})
    return {
        "_doc": "NEW (`Balcony` kind `horseshoe`, the README's parts): the deck in tiers stepped 0.3 m (each tier a "
                "floor of its own on raking carriages: 3x12 at 16 in from the rail beam up to pockets in the brick "
                "and the lobby's back wall), the rail beam 8x12 on nine cast-iron columns (6 in, 3/4 in metal), the "
                "corners' beam as 0.6 m chords (a ball or charge brings down a segment, not the sweep); the front a "
                "panelled gilt fascia on the rail's line with a velvet-padded rail 0.75 m over the front row. 100 "
                "lb/ft2. The columns stand on brick piers through the hall's floor. Clear under the rail: 3.45 m.",
        "kind": "horseshoe", "rail": rail, "radius": BAL_R,
        "columns": {"kind": "cast_iron", "dia": 0.152, "metal": 0.019, "at": cols, "foot_y": FLOOR, "head_y": r3(BAL_LOW - 0.35)},
        "beam": {"section": [0.19, 0.29], "wood": "framing"},
        "carriage": {"section": [0.076, 0.29], "spacing": 0.406, "wood": "framing"},
        "front": {"height": 0.75, "fascia": "panelled, gilt mouldings", "rail": "velvet-padded"},
        "tiers": tiers,
        "seats": {"back": 26 * BAL_BACK_ROWS, "sides": 12 * 4},
    }


def boxes():
    out = []
    for side, x0, x1 in (("east", IN_E, r3(IN_E + 2.0)), ("west", r3(IN_W - 2.0), IN_W)):
        for tier, y in (("lower", STAGE), ("upper", r3(BAL_LOW + 2 * BAL_RISE))):
            out.append({"id": "box_%s_%s" % (side, tier), "rect": [x0, BOX_Z[0], x1, BOX_Z[1]], "y": y, "chairs": 4,
                        "front": {"curve": 0.3, "height": 0.75, "fascia": "gilt", "drapes": "red velvet, tied back"}})
    return {"_doc": "NEW (`Balcony` kind `box`): four boxes, two a side, one over the other, between the side arms' "
                    "ends and the proscenium wall: joists 3x10 in pockets in the side wall and the proscenium, the "
                    "front on a cast-iron column at its outer corner. The lower boxes' floor at the stage's height "
                    "(entered through the proscenium wall's passage doors, or four steps up from the hall's side "
                    "aisle); the upper ones off the side arms' passages.",
            "list": out}


def seats():
    z0 = r3(Z_HALL0 + 1.22)
    aisle = 1.0
    blocks = []
    x = IN_E + 0.05
    for n in (4, 22, 4):
        blocks.append([r3(x), r3(x + n * SEAT), n])
        x += n * SEAT + aisle
    return {"_doc": "The parquet: twelve rows of 30 (4-22-4), 32 in rows, 20 in folding opera chairs on cast-iron "
                    "standards (A. H. Andrews & Co.'s), screwed down; the front four rows on runners (cleared for a "
                    "ball). The two aisles run under the balcony's side columns; the back arm's five columns each "
                    "take a seat's place (`out`: the period's 'obstructed by a post'). A kit prop by the prop lab "
                    "(`opera_chair`, NEW), placed as fixtures in rows.",
            "kit": "opera_chair", "rows": 12, "row_pitch": ROW, "seat_width": SEAT, "first_row_z": z0,
            "last_row_z": r3(z0 + 11 * ROW), "blocks": blocks, "out": "a seat under each of the back arm's five columns",
            "count": 12 * 30 - 5, "runners": 4, "facing": 0}


# ---------------------------------------------------------------------------------------------- the stage
def stage():
    return {
        "_doc": "The stage (saloon B's `stage` grown up, #902's form: legs, bearers, joists, boards, a skirt): 3 ft 6 in "
                "over the hall, the full width behind the proscenium and an apron 4 ft out of it with the footlights' "
                "trough; a trap 4 x 4 ft between two joists (the church's hatch rule); the gridiron 30 ft over the "
                "stage on beams in pockets (3x8 slats, open between); the drop curtain and three roll drops on battens "
                "hung from it by ropes made off at the pin rail (the Rope part) on the west fly gallery; wings of flats "
                "either side. NEW: the apron, the trough, the gridiron, the battens, the pin rail, the gallery.",
        "level": "ground", "rect": [IN_E, Z_STAGE0, IN_W, Z_DRESS], "height": r3(STAGE - FLOOR),
        "leg": 0.15, "bearer": [0.15, 0.25], "joist": [0.05, 0.24], "spacing": 0.406, "legs_every": 1.5, "bearers": 5,
        "skirt": ["front"],
        "apron": {"rect": [r3(CX - 4.27), Z_APRON, r3(CX + 4.27), Z_PROSC], "bow": 0.4,
                  "steps": [{"id": "apron_e", "head": [r3(CX - 4.27), r3(Z_APRON + 0.3)], "dir": "+x", "width": 0.9,
                             "risers": 6, "going": 0.25, "_doc": "down to the pit's east end (acts into the house)"}]},
        "pit": {"rect": [r3(CX - 5.0), Z_PIT0, r3(CX + 5.0), Z_APRON], "rail": {"height": 0.9, "z": Z_PIT0},
                "_doc": "the band: a piano, a fiddle, a cornet; level with the hall, a brass-capped rail before the first row"},
        "footlights": {"count": 14, "trough": [r3(CX - 4.0), r3(Z_APRON + 0.05), r3(CX + 4.0), r3(Z_APRON + 0.25)],
                       "kind": "kerosene, tin reflectors", "lit": [19, 23]},
        "trap": [r3(CX - 0.61), r3(Z_STAGE0 + 2.44), r3(CX + 0.61), r3(Z_STAGE0 + 3.66)],
        "gridiron": {"y": GRID, "beams": [0.15, 0.3], "slats": [0.076, 0.2], "gap": 0.61},
        "drops": [{"id": "curtain", "z": r3(Z_STAGE0 + 0.3), "art": "a painted lake under mountains in a painted gilt frame",
                   "roll": True, "down": True},
                  {"id": "parlour", "z": r3(Z_STAGE0 + 2.0), "roll": True},
                  {"id": "forest", "z": r3(Z_STAGE0 + 3.8), "roll": True},
                  {"id": "street", "z": r3(Z_DRESS - 0.4), "roll": True, "_doc": "the back drop: a western street"}],
        "drop_width": r3(30 * FT), "drop_height": r3(22 * FT),
        "pin_rail": {"wall": "west_stage", "y": r3(DRESS_UP + 1.0), "lines": 12},
        "fly_gallery": {"wall": "west_stage", "y": DRESS_UP, "depth": 1.0, "from": Z_STAGE0, "to": Z_DRESS,
                        "_doc": "a gallery along the west wall at the dressing block's upper floor, for the flymen, on "
                                "brackets in the brick; its door to the upper dressing rooms"},
        "wings": {"flats": 6, "each_side": 3, "width": 1.5, "height": 5.5},
    }


# ---------------------------------------------------------------------------------------------- roof
def roof():
    span = r3(IN_W - IN_E + 2 * 0.3)
    return {
        "_doc": "NEW (`HoweTruss`, the README's parts): over the hall, four Howe trusses on the pilasters at 12 ft, "
                "spanning 59 ft; over the stage house two more; the front block and the dressing block flat behind "
                "their parapets (floors of level front_roof and dress_roof). Purlins 4x10 at the panel points, rafters "
                "2x8 at 24 in, 1 in boards, terne plate (tin), 3/12 to a ridge 2.1 m over the plate, under the hall's "
                "parapets' line seen from the street (the front block hides it). The hall's ceiling: 2x8 at 16 in hung "
                "from the bottom chords by iron straps, lath and plaster under them, a cove at the walls, a plaster "
                "rose round the chandelier's chain in the middle bay.",
        "pitch": "3/12", "hall": {"z": [Z_LOBBY, Z_PROSC], "trusses_at": TRUSS_Z, "bear_y": PLATE},
        "stage": {"z": [Z_PROSC, r3(Z_DRESS + T_IN)], "trusses_at": [r3(Z_STAGE0 + 2.2), r3(Z_STAGE0 + 4.6)],
                  "bear_y": r3(STAGE_TOP - 1.1)},
        "truss": {"kind": "howe", "span": span, "depth": 2.0, "panels": 8, "top_chord": [0.19, 0.29],
                  "bottom_chord": {"section": [0.14, 0.29], "count": 2}, "braces": [0.14, 0.19], "counters": [0.09, 0.14],
                  "rods": [0.041, 0.032, 0.025],
                  "_doc": "rods 1 5/8 in at the ends, 1 1/4 next, 1 in in the middle panels (wrought iron, nuts on cast "
                          "angle blocks); the bottom chord two 6x12 bolted with keys (Haupt)"},
        "purlin": [0.09, 0.24], "rafter": [0.04, 0.19], "rafter_spacing": 0.61, "boards": 0.025, "tin": True,
        "ceiling": {"y": CEILING, "joist": [0.04, 0.19], "spacing": 0.406, "finish": "plaster on lath",
                    "rose": {"at": [CX, 14.65], "dia": 1.5}, "cove": 0.6},
    }


# ---------------------------------------------------------------------------------------------- rooms, stairs, lamps
def rooms():
    g = "ground"
    return [
        {"id": "vestibule", "level": g, "rect": [4.6, IN_E, r3(W - 4.6), Z_VEST],
         "use": "a show night's crowd in out of the street; tickets bought at the window, bills on the walls"},
        {"id": "box_office", "level": g, "rect": [IN_E, IN_E, 4.6, Z_VEST],
         "use": "the ticket seller behind the grille, the cash box, the seating chart, the night's takings"},
        {"id": "cloak_room", "level": g, "rect": [r3(W - 4.6), IN_E, IN_W, Z_VEST], "use": "coats, hats and guns checked"},
        {"id": "lobby", "level": g, "rect": [IN_E, Z_VEST, IN_W, Z_LOBBY],
         "use": "the two stairs up to the foyer, the inner doors to the hall; waiting, smoking, the interval"},
        {"id": "hall", "level": g, "rect": [IN_E, Z_HALL0, IN_W, Z_PIT0],
         "use": "the parquet: 355 seats; the crowd's place; a ball with the front rows cleared"},
        {"id": "pit", "level": g, "rect": [r3(CX - 5.0), Z_PIT0, r3(CX + 5.0), Z_APRON], "use": "the band"},
        {"id": "stage", "level": "stage", "rect": [IN_E, Z_STAGE0, IN_W, Z_DRESS],
         "use": "the acts (#1143's later shows); the wings, the pin rail, roll drops and flats; a trap"},
        {"id": "apron", "level": "stage", "rect": [r3(CX - 4.27), Z_APRON, r3(CX + 4.27), Z_PROSC],
         "use": "the footlights along its edge; where a speech is made to the house"},
        {"id": "dressing_1", "level": "stage", "rect": [IN_E, Z_DRESS0, r3(CX - 0.76), r3(Z_DRESS0 + 1.45)], "use": "the star's"},
        {"id": "dressing_2", "level": "stage", "rect": [IN_E, r3(Z_DRESS0 + 1.45), r3(CX - 0.76), Z_BACK], "use": "the company's men"},
        {"id": "corridor", "level": "stage", "rect": [r3(CX - 0.76), Z_DRESS0, r3(CX + 0.76), Z_BACK],
         "use": "the stage door to the stage; the stair to the upper dressing rooms"},
        {"id": "dressing_3", "level": "stage", "rect": [r3(CX + 0.76), Z_DRESS0, IN_W, r3(Z_DRESS0 + 1.45)], "use": "the company's women"},
        {"id": "dressing_4", "level": "stage", "rect": [r3(CX + 0.76), r3(Z_DRESS0 + 1.45), IN_W, Z_BACK], "use": "trunks and costumes"},
        {"id": "foyer", "level": "upper", "rect": [4.6, IN_E, IN_W, Z_LOBBY],
         "use": "the balcony's foyer: the five tall windows over Main Street, settees, the interval's promenade"},
        {"id": "office", "level": "upper", "rect": [IN_E, IN_E, 4.6, r3(Z_LOBBY - 1.4)],
         "use": "McCready's office over the box office: the safe, the bookings, the window on the street"},
        {"id": "balcony", "level": "upper", "rect": [IN_E, Z_HALL0, IN_W, BAL_END], "use": "the horseshoe: 152 seats, the cheap ones at the back"},
        {"id": "boxes", "level": "upper", "rect": [IN_E, BOX_Z[0], IN_W, BOX_Z[1]], "use": "the four boxes: McCready's, the Baron's, the mine's, the bank's"},
        {"id": "dressing_upper", "level": "dress_upper", "rect": [IN_E, Z_DRESS0, IN_W, Z_BACK],
         "use": "four more dressing rooms, the wardrobe; the door onto the fly gallery"},
        {"id": "scene_loft", "level": "attic", "rect": [IN_E, IN_E, IN_W, Z_LOBBY],
         "use": "the scene painter's loft: a frame, pots of distemper, rolled canvas; the old drops"},
    ]


def stairs():
    n, going, run, zs = ST_N, ST_GO, ST_RUN, WELL_Z
    return [
        {"id": "lobby_east", "head": [r3(CX - 0.7 - run), zs], "dir": "+x", "width": 1.37, "from": "ground", "to": "upper",
         "risers": n, "going": going, "rail": "-z", "look": "wood:int_oak", "stringer_look": "wood:int_timber",
         "_doc": "the lobby's two stairs: straight flights of 26 risers (7.6 in on 10 in treads) along its back wall, "
                 "rising from the middle outward to the foyer at its ends (straight runs the builder makes; the "
                 "sheet's read the same from the doors); turned walnut newels at the foot, a red runner on brass rods. "
                 "Head room under the foyer's well edge: the wells run the flights' length."},
        {"id": "lobby_west", "head": [r3(CX + 0.7 + run), zs], "dir": "-x", "width": 1.37, "from": "ground", "to": "upper",
         "risers": n, "going": going, "rail": "-z", "look": "wood:int_oak", "stringer_look": "wood:int_timber"},
        {"id": "dressing", "head": [r3(CX - 0.6), r3(Z_BACK - 0.1)], "dir": "+z", "width": 1.2, "from": "stage",
         "to": "dress_upper", "risers": 16, "going": 0.2, "_doc": "a steep boxed stair at the corridor's end"},
        {"id": "loft", "head": [r3(IN_E + 0.1), 1.5], "dir": "+z", "width": 0.9, "from": "upper", "to": "attic",
         "risers": 24, "going": 0.2, "_doc": "a closed stair in McCready's office's corner up to the scene loft"},
        {"id": "stage_door", "head": [r3(CX - 0.75), r3(D + 0.95)], "dir": "-z", "width": 1.5, "from": "yard", "to": "stage",
         "risers": 3, "going": 0.3, "_doc": "three stone steps up from the yard to the stage door"},
    ]


def lamps():
    sconces = []
    for room, wall, at, h in (("vestibule", "vestibule", 4.5, 2.2), ("vestibule", "vestibule", 12.9, 2.2),
                              ("lobby", "lobby_back", 0.5, 2.4), ("lobby", "lobby_back", 16.9, 2.4),
                              ("hall", "east_hall", 3.0, 2.6), ("hall", "east_hall", 10.3, 2.6),
                              ("hall", "west_hall", 3.0, 2.6), ("hall", "west_hall", 10.3, 2.6)):
        sconces.append({"room": room, "kit": "reflector_lamp", "wall": wall, "level": "ground", "at": at, "height": h,
                        "energy": 1.0, "reach": 6.0, "lit": [18, 24]})
    return {"_doc": "Kerosene throughout (no gas in Salt Creek). The chandelier in the hall's middle bay from the "
                    "ceiling's rose on a chain to the middle truss's bottom chord (lowered on a rope to be lit: the "
                    "Rope part), 24 lamps in two tiers; brackets on the walls; the footlights (the stage's); two lamp "
                    "standards on the walk (prop lab's `lamp_standard`, NEW).",
            "chandelier": {"at": [CX, 14.65], "y": r3(CEILING - 1.6), "radius": 1.1, "lamps": 24, "truss": TRUSS_Z[1],
                           "tiers": 2},
            "kit": sconces,
            "standards": [{"kit": "lamp_standard", "at": [r3(CX + s * 4.6), -1.6], "lit": [18, 24],
                           "_doc": "on the walk before the doors (NEW: the prop lab's lamp standard, placed by the walk)"} for s in (-1, 1)]}


def use_points():
    y0, ys = FLOOR, STAGE
    return [
        {"id": "ticket_seller", "use": "work", "who": "ticket_seller", "at": [3.4, y0, 1.5], "look": [4.6, 1.5]},
        {"id": "usher_e", "use": "stand", "who": "usher", "at": [r3(CX - 3.0), y0, r3(Z_HALL0 + 0.5)], "look": [r3(CX - 3.0), 12.0]},
        {"id": "usher_w", "use": "stand", "who": "usher", "at": [r3(CX + 3.0), y0, r3(Z_HALL0 + 0.5)], "look": [r3(CX + 3.0), 12.0]},
        {"id": "doorman", "use": "stand", "who": "doorman", "at": [CX, y0, 1.0], "look": [CX, -2.0]},
        {"id": "cloak", "use": "work", "who": "cloak_girl", "at": [r3(W - 3.4), y0, 1.5], "look": [r3(W - 4.6), 1.5]},
        {"id": "piano", "use": "play", "who": "band", "at": [r3(CX - 3.5), y0, 20.4], "look": [r3(CX - 3.5), 21.0]},
        {"id": "fiddle", "use": "play", "who": "band", "at": [r3(CX - 1.0), y0, 20.9], "look": [CX, 23.0]},
        {"id": "cornet", "use": "play", "who": "band", "at": [r3(CX + 1.5), y0, 20.9], "look": [CX, 23.0]},
        {"id": "act_centre", "use": "perform", "who": "act", "at": [CX, ys, 23.8], "look": [CX, 12.0]},
        {"id": "act_apron", "use": "perform", "who": "act", "at": [CX, ys, 22.0], "look": [CX, 10.0]},
        {"id": "prompter", "use": "watch", "who": "stage_manager", "at": [2.0, ys, 23.6], "look": [CX, 24.0]},
        {"id": "flyman", "use": "work", "who": "stagehand", "at": [r3(IN_W - 0.5), DRESS_UP, 26.0], "look": [IN_W, 26.0]},
        {"id": "lamp_lighter", "use": "work", "who": "stagehand", "at": [r3(CX - 4.0), ys, 21.9], "look": [CX, 21.7]},
        {"id": "standing_room", "use": "watch", "who": "crowd", "at": [CX, y0, r3(Z_HALL0 + 0.7)], "look": [CX, 23.0]},
        {"id": "box_baron", "use": "sit", "who": "baron", "at": [1.4, r3(BAL_LOW + 2 * BAL_RISE), 21.0], "look": [CX, 24.0]},
        {"id": "box_mccready", "use": "sit", "who": "mccready", "at": [r3(W - 1.4), r3(BAL_LOW + 2 * BAL_RISE), 21.0], "look": [CX, 24.0]},
        {"id": "office_desk", "use": "work", "who": "mccready", "at": [2.4, FOYER, 3.0], "look": [2.4, 1.0]},
        {"id": "dressing_mirror", "use": "dress", "who": "act", "at": [2.0, ys, r3(Z_DRESS0 + 0.6)], "look": [2.0, Z_DRESS0]},
        {"id": "balcony_cover", "use": "cover", "who": "any", "at": [CX, BAL_LOW, r3(BAL_FRONT - 0.5)], "look": [CX, 23.0],
         "_doc": "behind the balcony's front: a gunman's place over the house"},
        {"id": "foyer_window", "use": "watch", "who": "any", "at": [CX, FOYER, 1.0], "look": [CX, -10.0]},
    ]


def spec():
    return {
        "_doc": "McCready's Opera House (#1143): the building lab's step 2, the spec on its lot, written by "
                "tools/buildings/opera_house_spec.py (edit it, not this). NOT BUILT: the build waits for after the slice; "
                "keys marked NEW are parts the builder doesn't have (experiments/building_lab/opera_house/README.md). "
                "Sizes here, the look on the sheet (experiments/building_lab/opera_house/sheet).",
        "format": 1, "id": "opera_house", "status": "spec",
        "identity": {
            "owner": "Ezra McCready, who sold his share in the Argentine lode in 1880 and built the town something to be proud of (and a stage for his wife's sister)",
            "trade": "an opera house: travelling companies, melodrama, a singer with the band, lectures, the magic lantern, the Fourth of July ball, the Miners' Union meetings",
            "means": "the only brick building in Salt Creek but the bank: freighted-in brick, plate glass, iron, 523 opera chairs from Chicago, scenery painted in Denver",
            "age_and_repair": "1 year: the brick new and sharp, the walk already worn at the doors; one lane window boarded where a drunk put a bottle through",
            "clues": ["a stack of old show bills behind the box office", "cigar ash ground into the foyer's carpet",
                      "a banjo case and a pair of dancing shoes left in a dressing room", "chalk seat numbers on the backs of the chairs",
                      "a bucket of sand and a bucket of water by the footlights"],
        },
        "lot": {
            "_doc": "valley.json town.north (NEW lot, added at the build, not before: a valley change can tip the card-game "
                    "tests): past the undertaker's (x 106-128) a lane x 128.0-130.4 (8 ft: the hall's west exits), the "
                    "lot x 130.4-149.0 by the town's 125 ft depth to Back Street; Main Street's and Back Street's x "
                    "[-125, 130] grow to 150. The East Road still leaves from (130, 0) south-east, clear of the walk. "
                    "The building's origin its EAST front corner (facing 180). The ground (ValleyTerrain.height, "
                    "2026-11-24): -0.44 (west) to -0.58 (east) at the front line, +0.18..+0.06 at 20 m back, "
                    "+0.84..+0.38 at 30 m (Back Street's bank): a pad dug level at the walk's street edge (y -0.5) under "
                    "the building and its yard, a bank left behind.",
            "valley_lot": "opera_house", "side": "north", "at": [148.84, -0.5, -10.05], "facing": 180,
            "width": W, "depth": D, "yard": [0.0, D, W, r3(38.1 - 0.3)],
            "pad": {"y": -0.5, "x": [130.0, 149.6], "z": [-9.75, -44.6], "blend": 3.0},
            "walk": {"h": FLOOR, "awning": 0, "span": [130.4, 149.0], "door_x": 139.7, "door_w": 6.0,
                     "why": "A brick front needs no awning; three wide stone-edged steps across the three doorways for a crowd and ladies' skirts."},
            "footprint": [[0, 0, W, D]],
        },
        "levels": {
            "_doc": "The hall's floor at the walk's top; the stage, the dressing block and the lower boxes 3 ft 6 in over "
                    "it; the foyer and the balcony's back aisle 5 m over it (the lobby 16 ft high); the scene loft over "
                    "the foyer; the hall's trusses on the plate 10 m over the floor, its plaster ceiling under them "
                    "(32 ft); the stage house's gridiron 30 ft over the stage. NEW levels: stage, attic, dress_upper, "
                    "dress_roof, front_roof (the builder knows cellar, ground and upper).",
            "ground": {"top": FLOOR}, "stage": {"top": STAGE}, "upper": {"top": FOYER}, "attic": {"top": ATTIC},
            "dress_upper": {"top": DRESS_UP}, "dress_roof": {"top": r3(DRESS_TOP - 0.6)}, "front_roof": {"top": FRONT_ROOF},
            "plate": PLATE, "ceiling": CEILING, "grid": GRID, "false_front": CORNICE, "pediment": PEDIMENT,
            "hall_parapet": HALL_TOP, "stage_top": STAGE_TOP, "dress_top": DRESS_TOP, "roof_pitch": 0.0, "roof_tight": True,
        },
        "frame": {
            "_doc": "A load-bearing brick building, timber floors and roof. Brick walls by Kidder (public halls: 17 in to "
                    "the upper floor, 13 in above; 13 in for the fire wall and the dressing block), lime mortar, on "
                    "sandstone footings 4 ft down (below Colorado's frost). Joists by the Wood Handbook's working "
                    "stresses (yellow pine, 1,200 lb/in2 bending; deflection L/360), 100 lb/ft2 where a crowd stands "
                    "(Kidder's for theatres), 70 the dance floor, 40 the lofts and roofs (snow). `--sizing` prints each "
                    "(the README's table). Dressed sizes, metres [width, depth].",
            "stacked": True,
            "stone_wall": {
                "_doc": "NEW use: the jail's stone walls laid as BRICK (`masonry` brick; BrickWall, the README's parts): "
                        "members as lifts of nine courses (0.6 m, the jail's course) and 1.2 m long, so the walls are "
                        "~2,000 members, not 100,000 bricks; chips by the voxel carving, a charge drops lifts. Common bond "
                        "(a header course every sixth), 8 x 4 x 2 1/4 in bricks, 3/8 in joints: the shader's. Dressed "
                        "buff sandstone: the quoins, the base course, sills, keystones over the arches, the coping.",
                "masonry": "brick", "wood": "brick", "thick": T_OUT, "course": 0.6, "piece": 1.2,
                "brick": [0.203, 0.102, 0.057], "joint": 0.0095, "bond": "common_6",
                "footing_below": 1.2, "footing_spread": 0.2, "quoin": [0.46, 0.3],
                "base": {"height": r3(FLOOR + 0.3), "stone": "buff_sandstone"},
                "lintel": {"height": 0.3, "bear": 0.23, "_doc": "square heads (the back's); arched heads are rings of brick (NEW)"},
                "arch": {"rings": 2, "keystone": [0.25, 0.4], "_doc": "NEW: a round head two brick rings deep, a stone keystone"},
                "sill": {"height": 0.12, "proj": 0.04}, "coping": {"height": 0.1, "proj": 0.04}, "pocket": 0.15},
            "pier": {"size": 0.45, "wood": "brick"},
            "girder": {"section": [0.15, 0.25], "wood": "framing", "pier_every": 1.83},
            "joist": {"section": [0.04, 0.24], "spacing": 0.406, "wood": "framing", "_doc": "2x10 at 16 in (the lobby, the dressing block)"},
            "dance_joist": {"section": [0.04, 0.29], "spacing": 0.406, "wood": "framing", "_doc": "2x12 at 16 in, the hall: 2.9 m at 70 lb/ft2"},
            "long_joist": {"section": [0.064, 0.34], "spacing": 0.305, "wood": "framing",
                           "_doc": "3x14 at 12 in: the foyer's 21 ft at 100 lb/ft2 (the scene loft's the same, at 40)"},
            "roof_joist": {"section": [0.04, 0.24], "spacing": 0.406, "wood": "framing"},
            "floor_board": {"width": 0.14, "thick": 0.022, "wood": "floor"},
            "stud": {"section": [0.05, 0.1], "spacing": 0.406, "wood": "framing",
                     "_doc": "2x4 at 16 in: the timber partitions (box office, cloak room, the dressing rooms, the office)"},
            "plate": {"height": 0.1}, "ribbon": {"section": [0.025, 0.15]}, "header": {"height": 0.15},
            "post": {"section": [0.14, 0.14], "wood": "framing"},
            "beam": {"section": [0.19, 0.29], "wood": "framing"},
            "column": {"kind": "cast_iron", "dia": 0.152, "metal": 0.019,
                       "_doc": "NEW (`IronColumn`): a hollow cast-iron column, a cap and a base plate; brittle: a "
                               "charge or a heavy blow cracks it through, it doesn't bend"},
        },
        "girders": girders(),
        "floors": floors(),
        "posts": posts(),
        "beams": beams(),
        "walls": walls(),
        "balcony": balcony(),
        "boxes": boxes(),
        "seats": seats(),
        "stage": stage(),
        "roof": roof(),
        "ceilings": {"_doc": "Plaster on lath (NEW: `PlasterWall`, the README's parts: cracks, falls in chunks off "
                             "its lath, the paper tearing with it) in every room, the hall's under the trusses (the "
                             "roof's `ceiling`), the lobby's and foyer's with a cornice and a rose.",
                     "levels": ["ground", "upper", "stage", "dress_upper"], "finish": "plaster",
                     "holes": [[WELL_E[0], WELL_Z, WELL_E[1], Z_LOBBY], [WELL_W[0], WELL_Z, WELL_W[1], Z_LOBBY]]},
        "inside_finish": {"_doc": "NEW finishes: walnut wainscot to 3 ft (the lobby, the foyer, the hall), wallpaper "
                                  "over plaster above (deep red and gold, three bands), plain plaster and whitewash "
                                  "backstage and in the dressing rooms; the brick bare in the stage house.",
                          "wainscot": {"height": 0.91, "wood": "walnut", "rooms": ["lobby", "foyer", "hall", "vestibule"]},
                          "paper": {"rooms": ["lobby", "foyer", "hall", "office", "boxes"], "pattern": "three-band, red and gold"},
                          "skirting": 0.2},
        "stairs": stairs(),
        "front": {
            "sign": "MCCREADY'S OPERA HOUSE", "sign_from": r3(CORNICE - 1.35), "sign_to": r3(CORNICE - 0.75),
            "sign_width": 13.0, "year": "1881",
            "brackets": {"spacing": 0.6, "drop": 0.45, "reach": 0.22, "width": 0.09, "pairs": True, "sides": ["east_front", "west_front"],
                         "_doc": "the hotel's paired scroll brackets, deeper (the cornice 1.1 m: galvanized iron on a timber frame)"},
            "cornice": {"kind": "bracketed", "top": CORNICE, "depth": 1.1, "material": "galvanized iron, painted stone colour"},
            "iron_columns": {"at": [r3(CX - 0.95), r3(CX + 0.95)], "height": 3.4,
                             "_doc": "NEW: a pair of cast-iron columns either side of the middle doorway (catalogue parts, bolted to the brick)"},
            "posters": [
                {"board": [r3(CX - 1.52), 1.0, 1.0, 1.4], "bill": "THE MORTGAGE ON HAZEL FARM, or a Daughter's Sacrifice: a melodrama in four acts"},
                {"board": [r3(CX + 1.52), 1.0, 1.0, 1.4], "bill": "The Hartwell Shakespearean Company: HAMLET and RICHARD III, two nights only"},
                {"board": [r3(CX - 4.6), 1.0, 1.0, 1.4], "bill": "Professor Alcott's Magic Lantern: Wonders of the Yellowstone, sixty views"},
                {"board": [r3(CX + 4.6), 1.0, 1.0, 1.4], "bill": "Miss Lottie Byrne, the Colorado Nightingale, with the Salt Creek Cornet Band"},
            ],
            "_posters_doc": "board: [x along the front, its foot over the walk, width, height]; the bills painted by the texture factory (invented acts; no minstrel shows, Sean)",
        },
        "rooms": rooms(),
        "use_points": use_points(),
        "lamps": lamps(),
        "light": {"_doc": "saloon B's dials for a big room (#867): the windows light the hall by day, the fill lifts the far walls",
                  "fill": [0.62, 0.6, 0.57], "window_day": 14.0, "day_fill": 0.32},
        "furniture": [],
        "fixtures": [],
        "props_wanted": [{"kit": "piano", "at": [r3(CX - 3.5), 20.9], "facing": 0, "_doc": "the pit's upright (prop lab, NEW)"},
                     {"kit": "safe", "at": [1.0, 4.5], "level": "upper", "facing": 90, "_doc": "McCready's (prop lab, NEW)"},
                     {"kit": "settee", "at": [r3(CX - 3.05), 1.2], "level": "upper", "facing": 0,
                      "repeat": {"count": 3, "step": [3.05, 0]}, "_doc": "the foyer's (prop lab, NEW)"},
                     {"kit": "opera_chair", "_doc": "the seats' rows (`seats`): 355 + 152 + 16 in the boxes (gilt chairs)"},
                     {"kit": "lamp_standard", "_doc": "the two on the walk (`lamps.kit`)"}],
        "_props_doc": "`props_wanted`: kit props the prop lab makes before they go in `fixtures` (none exist yet)",
        "use": {"years": 1, "paths": [
            {"id": "doors_to_hall", "who": "everyone", "level": "ground", "daily": 120, "width": 2.4,
             "points": [[CX, IN_E], [CX, Z_VEST], [CX, Z_HALL0 + 0.6]]},
            {"id": "aisle_e", "who": "everyone", "level": "ground", "daily": 50, "width": 0.9,
             "points": [[r3(IN_E + 2.55), Z_HALL0 + 0.6], [r3(IN_E + 2.55), Z_PIT0]]},
            {"id": "aisle_w", "who": "everyone", "level": "ground", "daily": 50, "width": 0.9,
             "points": [[r3(IN_W - 2.55), Z_HALL0 + 0.6], [r3(IN_W - 2.55), Z_PIT0]]},
            {"id": "stage_door", "who": "acts", "level": "stage", "daily": 15, "width": 1.0,
             "points": [[CX, Z_BACK], [CX, Z_DRESS], [CX, Z_APRON + 0.3]]}],
            "_doc": "a show a week, a ball a month (daily: passings a day averaged): the aisles and doors worn, the stage's centre and its door"},
        "materials": {"_doc": "From the material library by name when built (passing entries only); NEW: brick, buff "
                              "sandstone, plaster on lath, wallpaper, walnut (FN3 parked: the material lab first), red "
                              "plush, gilt, galvanized iron, marble tile.",
                      "wear": {"use": 0.5, "dings": 0.0, "_why": "one year of shows and balls"},
                      "floor": "wood:int_floor", "wall_boards": "int_boards", "woodwork": "wood:int_timber",
                      "timber": "wood:int_timber", "rough": "framing", "chimney": "stone",
                      "_names_doc": "the jail's names for the builder's surfaces until step 4 (the look) picks from the library"},
        "sources": [
            "F. E. Kidder, Building Construction and Superintendence (1890s eds.): brick wall thicknesses, theatre floor loads",
            "USDA Wood Handbook: working stresses for the joists and beams (the game's timber numbers)",
            "Herman Haupt, General Theory of Bridge Construction (1851) and Hatfield, The American House-Carpenter (1880): Howe trusses",
            "Gordon's formula for cast-iron columns (Trautwine's Civil Engineer's Pocket-Book, 1870s eds.)",
            "Central City Opera House (1878, stone, ~550 seats) and the Tabor Opera House, Leadville (1879, brick, three storeys): size and arrangement",
            "A. H. Andrews & Co. (Chicago) opera-chair catalogues, 1880s: 20 in seats on cast-iron standards, 30-32 in rows",
            "the Brooklyn Theatre fire (1876): doors opening outward, exits on both sides",
        ],
    }


# ---------------------------------------------------------------------------------------------- sizing
def sizing():
    """Each member's check: bending stress (lb/in2) against 1,200 for yellow pine, deflection under the live load
    against L/360 (E 1.6M), the columns by Gordon's formula, the truss's chord forces and rods."""
    E, FB = 1.6e6, 1200.0
    rows = []

    def joist(name, nominal, b_in, d_in, sp_in, span_ft, psf, dead=12):
        w = (psf + dead) * sp_in / 12.0                  # lb/ft
        M = w * span_ft ** 2 / 8 * 12                    # lb-in
        S, I = b_in * d_in ** 2 / 6, b_in * d_in ** 3 / 12
        f = M / S
        dfl = 5 * (psf * sp_in / 12 / 12) * (span_ft * 12) ** 4 / (384 * E * I)
        lim = span_ft * 12 / 360
        rows.append([name, "%s, %.1f ft, %d lb/ft2" % (nominal, span_ft, psf),
                     "%.0f lb/in2 (%.2f)" % (f, f / FB), "%.2f in of %.2f" % (dfl, lim), "ok" if f <= FB and dfl <= lim else "OVER"])

    joist("hall floor", "2x12 at 16 in", 1.5, 11.25, 16, 9.5, 70)
    joist("lobby, dressing floors", "2x10 at 16 in", 1.5, 9.25, 16, 9.75, 100)
    joist("foyer", "3x14 at 12 in", 2.5, 13.25, 12, 21.5, 100)
    joist("balcony carriage, back arm", "3x12 at 16 in", 2.5, 11.25, 16, 14.5, 100)
    joist("balcony side arm", "3x12 at 16 in", 2.5, 11.25, 16, 8.2, 100)
    joist("box floor", "3x10 at 16 in", 2.5, 9.25, 16, 6.6, 100)
    joist("dressing roof", "2x10 at 16 in", 1.5, 9.25, 16, 9.75, 40)
    joist("hall ceiling (hung)", "2x8 at 16 in", 1.5, 7.25, 16, 12.0, 10)
    joist("roof rafter", "2x8 at 24 in", 1.5, 7.25, 24, 7.4, 40)
    joist("rail beam, side bay", "8x12", 7.5, 11.25, 8.2 / 2 * 12, 14.6, 100, dead=20)
    joist("rail beam, back bay", "8x12", 7.5, 11.25, 14.5 / 2 * 12, 9.9, 100, dead=20)
    joist("wells' beam (a bay)", "8x12", 7.5, 11.25, 17.0 / 2 * 12, 10.25, 100, dead=15)
    # A cast-iron column: the back arm's middle one, 9.9 ft of rail by 7.25 ft of deck at 120 lb/ft2 all in; 12.5 ft.
    P = 9.9 * 7.25 * 120 + 2000
    A = math.pi / 4 * (6 ** 2 - 4.5 ** 2)
    L, dia = 12.5 * 12, 6.0
    f = P / A * (1 + (L / dia) ** 2 / 800)               # Gordon, cast iron, round, flat ends
    rows.append(["cast-iron column", "6 in, 3/4 in metal, 12.5 ft, %.0f lb" % P, "%.0f lb/in2 (%.2f of 10,000 working)" % (f, f / 10000),
                 "", "ok" if f < 10000 else "OVER"])
    # The Howe truss: 59 ft, 6.56 ft deep, 8 panels, 12 ft apart; roof 40 + ceiling 15 lb/ft2, the chandelier's
    # 600 lb at the middle.
    span, depth, bay = 59.0, 6.56, 12.0
    Wt = span * bay * 55 + 600
    chord = Wt * span / (8 * depth)
    rows.append(["Howe truss, chords", "59 ft span, 6.6 ft deep, %d lb a truss" % Wt,
                 "%.0f lb: bottom 2-6x12 %.0f lb/in2, top 8x12 %.0f lb/in2" % (chord, chord / (2 * 5.5 * 11.25), chord / (7.5 * 11.25)),
                 "", "ok (the joints govern: keyed and bolted)"])
    end_shear = Wt / 2 - Wt / 16
    rod = end_shear / (math.pi / 4 * 1.625 ** 2)
    rows.append(["Howe truss, end rods", "1 5/8 in wrought, %.0f lb" % end_shear, "%.0f lb/in2 (of 10,000)" % rod, "",
                 "ok" if rod < 10000 else "OVER"])
    return rows


def draw_plans(sp, out):
    """Both levels side by side (north up, the street at the bottom, east on the right: facing 180 mirrors x)."""
    from PIL import Image, ImageDraw, ImageFont
    S, M = 26, 50

    def font(n, b=False):
        try:
            return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf" % ("-Bold" if b else ""), n)
        except OSError:
            return ImageFont.load_default()
    pw, ph = int(W * S), int(D * S)
    im = Image.new("RGB", (2 * pw + 3 * M + 40, ph + 2 * M + 120), (246, 241, 230))
    d = ImageDraw.Draw(im)
    ink, red, blue, brick_c, gold = (25, 20, 15), (190, 40, 30), (40, 80, 170), (150, 62, 45), (176, 140, 40)
    d.text((M, 12), "McCready's Opera House (#1143): the plans from the spec (config/buildings/opera_house.json)",
           fill=ink, font=font(20, True))

    def P(ox, x, z):
        return (ox + (W - x) * S, M + 40 + (D - z) * S)

    def box(ox, r, **kw):
        a, b = P(ox, r[0], r[1]), P(ox, r[2], r[3])
        d.rectangle([min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1])], **kw)

    for ox, level in ((M, "ground"), (2 * M + pw + 40, "upper")):
        d.text((ox, M + 14), "GROUND FLOOR AND STAGE" if level == "ground" else "UPPER: FOYER, BALCONY, BOXES",
               fill=ink, font=font(16, True))
        box(ox, [0, 0, W, D], fill=(252, 248, 238))
        if level == "ground":
            st = sp["seats"]
            for row in range(st["rows"]):
                z = st["first_row_z"] + row * st["row_pitch"]
                for x0, x1, n in st["blocks"]:
                    for s in range(n):
                        xa = x0 + s * st["seat_width"]
                        box(ox, [xa + 0.03, z, xa + st["seat_width"] - 0.03, z + 0.45], outline=(120, 40, 40))
            sg = sp["stage"]
            box(ox, sg["pit"]["rect"], outline=ink, fill=(232, 222, 200))
            box(ox, sg["rect"], fill=(226, 206, 170), outline=ink)
            box(ox, sg["apron"]["rect"], fill=(226, 206, 170), outline=ink)
            box(ox, sg["trap"], outline=red, width=2)
            for j in range(sg["footlights"]["count"]):
                x = sg["footlights"]["trough"][0] + (j + 0.5) * 8.0 / sg["footlights"]["count"]
                c = P(ox, x, Z_APRON + 0.15)
                d.ellipse([c[0] - 2, c[1] - 2, c[0] + 2, c[1] + 2], fill=(230, 150, 30))
            for s in sp["stairs"]:
                if s["id"].startswith("lobby"):
                    hx, hz = s["head"]
                    run = (s["risers"] - 1) * s["going"]
                    x0, x1 = (hx, hx + run) if s["dir"] == "+x" else (hx - run, hx)
                    box(ox, [x0, hz, x1, hz + s["width"]], outline=ink, fill=(236, 228, 210))
                    for k in range(1, s["risers"] - 1):
                        x = x0 + k * s["going"]
                        d.line([P(ox, x, hz), P(ox, x, hz + s["width"])], fill=ink)
            for gx in sp["girders"]["x"]:
                z = IN_E
                while z < Z_PROSC:
                    d.line([P(ox, gx, z), P(ox, gx, min(z + 0.3, Z_PROSC))], fill=(150, 140, 125), width=1)
                    z += 0.6
            for c in sp["balcony"]["columns"]["at"]:
                q = P(ox, c[0], c[1])
                d.ellipse([q[0] - 4, q[1] - 4, q[0] + 4, q[1] + 4], fill=(40, 40, 50))
        else:
            b = sp["balcony"]
            for t in b["tiers"]:
                shade = 236 - int((t["y"] - BAL_LOW) / 1.2 * 40)
                box(ox, t["rect"], fill=(shade, shade - 18, shade - 32), outline=(170, 150, 130))
            d.line([P(ox, x, z) for x, z in b["rail"]], fill=gold, width=5)
            for c in b["columns"]["at"]:
                q = P(ox, c[0], c[1])
                d.ellipse([q[0] - 5, q[1] - 5, q[0] + 5, q[1] + 5], fill=(40, 40, 50))
            for bx in sp["boxes"]["list"]:
                if bx["id"].endswith("upper"):
                    box(ox, bx["rect"], fill=(200, 60, 60), outline=ink)
            for hole in sp["ceilings"]["holes"]:
                box(ox, hole, outline=ink, fill=(236, 228, 210))
            c = P(ox, CX, (Z_STAGE0 + Z_DRESS) / 2)
            d.text((c[0] - 60, c[1] - 8), "OPEN OVER THE STAGE", fill=(120, 110, 95), font=font(12, True))
            c = P(ox, CX, 16.0)
            d.text((c[0] - 60, c[1]), "OPEN TO THE HALL\n(the chandelier)", fill=(120, 110, 95), font=font(12, True))
        for r in sp["rooms"]:
            if (level == "ground") != (r["level"] in ("ground", "stage")) or r["level"] == "attic":
                continue
            if r["id"] in ("balcony", "boxes", "hall", "pit", "apron"):
                continue
            x0, z0, x1, z1 = r["rect"]
            c = P(ox, (x0 + x1) / 2, (z0 + z1) / 2)
            name = r["id"].replace("_", " ").upper()
            f = font(12 if x1 - x0 > 3 else 10, True)
            tw = d.textlength(name, font=f)
            d.text((c[0] - tw / 2, c[1] - 6), name, fill=ink, font=f)
        for w in sp["walls"]:
            wl = w.get("level", "ground")
            if w.get("partition") and ((level == "ground") != (wl == "ground")):
                continue
            (ax, az), (bx_, bz) = w["line"]
            t = float(w.get("thick", 0.12))
            o = w["out"]
            along_x = az == bz
            if w.get("partition"):
                r = [ax, az, bx_, bz + t] if (w.get("stone") and along_x) else [ax - 0.06, az - 0.06, bx_ + 0.06, bz + 0.06]
            elif o == "-z":
                r = [ax, az, bx_, az + t]
            elif o == "+z":
                r = [ax, az - t, bx_, bz]
            elif o == "-x":
                r = [ax, az, ax + t, bz]
            else:
                r = [ax - t, az, ax, bz]
            box(ox, r, fill=brick_c if w.get("stone") else ink)
            for op in w.get("openings", []):
                lv = op.get("level", "ground")
                if (level == "ground") != (lv == "ground") or lv == "attic":
                    continue
                a, hw = float(op["at"]), float(op["width"]) / 2
                col = blue if op["type"] == "window" else red if op["type"] == "door" else (246, 241, 230)
                if along_x:
                    a += ax
                    zz = az if (o == "-z" or w.get("partition")) else az - t
                    box(ox, [a - hw, zz, a + hw, zz + (t if w.get("stone") else 0.12)], fill=col)
                else:
                    a += az
                    if w.get("partition") and not w.get("stone"):
                        box(ox, [ax - 0.06, a - hw, ax + 0.06, a + hw], fill=col)
                    else:
                        xx = ax if o == "-x" else ax - t
                        box(ox, [xx, a - hw, xx + t, a + hw], fill=col)
        c = P(ox, CX, -0.6)
        d.text((c[0] - 60, c[1] + 4), "MAIN STREET (south)", fill=ink, font=font(13, True))
    n_par, n_bal = sp["seats"]["count"], sum(sp["balcony"]["seats"].values())
    n_box = sum(b["chairs"] for b in sp["boxes"]["list"])
    d.text((M, im.height - 60), "brick red: walls   blue: windows   red: doors   gold: the horseshoe's rail   dots: cast-iron "
           "columns, footlights   dashed: girders\nseats: %d parquet + %d balcony + %d in boxes = %d   (north up, east on the right)"
           % (n_par, n_bal, n_box, n_par + n_bal + n_box), fill=ink, font=font(14))
    x0, y0 = im.width - M - 20 * FT * S - 40, im.height - 30
    d.rectangle([x0, y0, x0 + 20 * FT * S, y0 + 8], fill=ink)
    d.text((x0 + 20 * FT * S + 6, y0 - 6), "20 ft", fill=ink, font=font(13))
    im.save(out)
    print(out, im.size)


if __name__ == "__main__":
    sp = spec()
    path = os.path.join(ROOT, "config", "buildings", "opera_house.json")
    with open(path, "w") as f:
        json.dump(sp, f, indent="\t")
        f.write("\n")
    print(path)
    for a in sys.argv[1:]:
        if a.startswith("--plans="):
            draw_plans(sp, a.split("=", 1)[1])
        if a == "--sizing":
            print("| Member | Size, span, load | Stress | Deflection (live) | |\n| --- | --- | --- | --- | --- |")
            for row in sizing():
                print("| " + " | ".join(row) + " |")
