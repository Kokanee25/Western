#!/usr/bin/env python3
"""Writes config/buildings/opera_house.json (McCready's Opera House, #1143: the building lab's step 2, the spec on
its lot) and draws its two plans, so a change is one number and a re-run:

    python3 tools/buildings/opera_house_spec.py [--plans=OUT.png] [--sizing]

Sean's answers (2026-11-24, on #1143 and #1242): a new lot at Main Street's east end, north side (the front faces
south, facing 180); red brick with dressed stone quoins, base, sills and keystones; MCCREADY'S OPERA HOUSE 1881 in
the cornice; a horseshoe balcony; the sheet and plan OK'd ("Looks good let's spec it out"), three tiers on the front,
the lot kept. `status: "spec"`: written to the format, NOT BUILT (the build waits for after the slice); keys marked
NEW in their `_doc` are parts the builder doesn't have yet (experiments/building_lab/opera_house/README.md).

Sizes (Sean, 2026-11-26, #1289): 60 x 105 ft (18.29 x 32.0 m), the hall stepped in to 42 ft between two courts, about
100 seats (56 on the floor, 36 in a two-row balcony, two private boxes of 4 reached by their own passages). The frame from period books (`sources`; `--sizing` prints each
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


W, D = r3(60 * FT), r3(105 * FT)                    # 18.288 x 32.004: the front block and the stage house
HW = r3(42 * FT)                                    # 12.802: the hall's outside width (Sean, 2026-11-26: ~100 seats)
T_OUT = 0.43                                        # 17 in brick (four bricks): the outer walls to the upper floor
T_UP = 0.33                                         # 13 in above the set-off (Kidder: a brick less each storey up)
T_IN = 0.33                                         # 13 in: the proscenium (the stage's fire wall), the lobby's back
T_PART = 0.23                                       # 9 in: the vestibule's brick partition
CX = r3(W / 2)
IN_E, IN_W = T_OUT, r3(W - T_OUT)                   # the inside faces at the ground floor (x)
# The plan is a cross (Sean, 2026-11-26): the front block 60 ft (the bar, lobby and parlour unchanged), the hall
# 42 ft between two open courts (its side exits), the stage house and dressing block 60 ft again (wider wings, a
# scene dock and a property room: "more backstage area for the opera props and scenes").
HX_E, HX_W = r3((W - HW) / 2), r3((W + HW) / 2)     # 2.743 .. 15.545: the hall's outer faces
HIN_E, HIN_W = r3(HX_E + T_OUT), r3(HX_W - T_OUT)   # 3.173 .. 15.115: the hall's inside faces (39 ft clear)

# Heights over the pad.
FLOOR = 0.45                                        # the walk's top: three steps up from the street
STAGE = r3(FLOOR + 3.5 * FT)                        # 1.517: the stage, the forestage, the dressing block
BOX_Y = r3(STAGE + 3.5)                             # 5.017: the boxes' floor, 3.5 m over the stage (#1244: a man can
                                                    # drop to it and get hurt doing it)
FOYER = r3(FLOOR + 5.0)                             # 5.45: the foyer, the balcony's back aisle
ATTIC = r3(FOYER + 4.6)                             # 10.05: the scene loft over the foyer (the attic windows)
FRONT_ROOF = r3(ATTIC + 3.0)                        # 13.05: the front block's flat roof
CORNICE = 14.0                                      # the front's cornice top (46 ft)
PEDIMENT = 15.9
PLATE = r3(FLOOR + 10.0)                            # 10.45: the hall's trusses bear here
HALL_TOP = r3(PLATE + 1.0)                          # the hall's side parapets
CEILING = r3(PLATE - 0.25)                          # the hall's plaster ceiling, on joists hung from the bottom chords
GRID = r3(STAGE + 28 * FT)                          # 10.051: the stage's gridiron (roll drops hang from it)
STAGE_TOP = r3(GRID + 3.3)                          # 13.351: the stage house's walls
DRESS_UP = r3(STAGE + 10 * FT)                      # 4.565: the dressing block's upper floor
DRESS_TOP = r3(DRESS_UP + 3.6)                      # 8.165: its flat roof's parapet

# Lines along z (back from the front's outer face).
Z_VEST = 2.6                     # the vestibule's back wall (13 in brick to the roof: the front block's middle bearing)
Z_VEST1 = r3(Z_VEST + T_IN)      # 2.93: the lobby's front face
Z_LOBBY = 10.2                   # the lobby's back wall (13 in brick: the balcony's back bears on it). Sean, 2026-11-24:
                                 # "push the lobby forward ... a bar and something else" (the ladies' parlour): 33 ft
X_BAR = 5.6                      # the bar's partition (the bar east of it, x 0.43-5.6: 17 x 24 ft)
X_PARL = r3(W - 5.6)             # the parlour's partition (the ladies' parlour west of it, the same size)
Z_HALL0 = r3(Z_LOBBY + T_IN)     # 10.53: the hall's back (and the courts' front)

# The lobby's stairs: straight flights of 26 against the bar's and the parlour's partitions, rising from the
# vestibule's side to a landing at the lobby's back wall, a door there straight into the balcony; the foyer's wells
# over them, each well's inner edge a trimmer beam (z) on two posts.
ST_N, ST_GO, ST_W = 26, 0.25, 1.37
ST_RUN = r3((ST_N - 1) * ST_GO)                     # 6.25
ST_TOP = r3(Z_LOBBY - 1.0)                          # 9.2: the flights' heads (a 1 m landing behind)
ST_FOOT = r3(ST_TOP - ST_RUN)                       # 2.95
WELL_E = [r3(X_BAR + 0.06), r3(X_BAR + 0.06 + ST_W)]        # 5.66 .. 7.03
WELL_W = [r3(X_PARL - 0.06 - ST_W), r3(X_PARL - 0.06)]      # 11.258 .. 12.628
WELL_POSTS_Z = [6.0, ST_TOP]

# The parquet, the balcony, the boxes (Sean, 2026-11-26: "about 100 seats mixed between the two": 56 on the floor,
# 36 in two balcony rows, 8 in the two boxes).
SEAT = r3(20 / 12 * FT)          # 0.508
ROW = r3(32 / 12 * FT)           # 0.813
BAL_ROW = r3(34 / 12 * FT)       # 0.864: a balcony row (its riser leaves less knee room)
BAL_RISE = 0.3
BAL_BACK_ROWS = 2
BAL_SEATS = 18                   # a balcony row, wall passage to wall passage
BAL_AISLE = 1.0                  # the balcony's back cross aisle at the foyer's level
BAL_FRONT = r3(Z_HALL0 + BAL_AISLE + BAL_BACK_ROWS * BAL_ROW)      # 13.258: the rail
BAL_LOW = r3(FOYER - BAL_BACK_ROWS * BAL_RISE)                      # 4.85: the front row's floor
PAR_ROWS = 4
PAR_BLOCK = 7                    # seats a block: two blocks either side of a middle aisle
PAR_AISLE = 1.0
Z_ROW0 = r3(BAL_FRONT + 0.15)    # the back row (standing room behind it, under the balcony)
Z_PIT0 = r3(Z_ROW0 + (PAR_ROWS - 1) * ROW + 0.45 + 0.9)            # 17.2: the band's rail
Z_APRON = r3(Z_PIT0 + 1.6)       # 18.8: the forestage's edge, the footlights
FORESTAGE = 2.4                  # the forestage, the hall's full width, 8 ft out of the proscenium: the boxes over its ends
Z_PROSC = r3(Z_APRON + FORESTAGE)                                   # 21.2: the proscenium wall's hall face
Z_STAGE0 = r3(Z_PROSC + T_IN)    # 21.53
Z_BACK = r3(D - T_UP)            # 31.674
Z_DRESS = r3(Z_BACK - 3.0 - T_IN)                                   # 28.344: the dressing block's front wall
Z_DRESS0 = r3(Z_DRESS + T_IN)    # 28.674
# The boxes (#1244, Sean 2026-11-26, "John Wilkes Booth" style; one a side): over the forestage's ends, shut off from
# the house, each reached only by its own passage along the hall's side wall from the balcony's back aisle.
BOX_W = 1.6                      # out from the side wall to the box's rail
BOX_Z = [Z_APRON, Z_PROSC]       # 18.8 .. 21.2 (8 ft)
PASS_W = 0.9                     # the passage's clear width (Ford's was about 4 ft; ours narrower)
PASS_Z = [r3(Z_HALL0 + BAL_AISLE), Z_APRON]                         # 11.53 .. 18.8
PASS_E = r3(HIN_E + PASS_W)      # 4.073: the east passage's partition (its studs to +0.1)
PASS_W_ = r3(HIN_W - PASS_W)     # 14.215: the west one's
BAL_X = [r3(PASS_E + 0.1), r3(PASS_W_ - 0.1)]                       # 4.173 .. 14.115: the balcony rows between them
BOX_DOOR = r3(HIN_E + 0.45)      # the box's door, in its back (-z) wall by the side wall

# Hall bays: the trusses on the side walls' pilasters, the windows between them.
TRUSS_Z = [r3(Z_HALL0 + (Z_PROSC - Z_HALL0) / 3 * k) for k in (1, 2)]   # 14.087, 17.643: three bays of 11.7 ft
WIN_Z = [r3((a + b) / 2) for a, b in ((Z_HALL0, TRUSS_Z[0]), (TRUSS_Z[0], TRUSS_Z[1]))]  # mid-bay (the third the boxes')


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
        # Four segments by their tops: the front block (its cornice returns), the hall (stepped in to the 42 ft
        # line, the court outside it), the stage house, the dressing block. Each segment's openings by their
        # distance from its line's start.
        e = out == "-x"
        hx = HX_E if e else HX_W
        z_dress = Z_DRESS0
        hall_ops = []
        for z in WIN_Z:
            hall_ops.append(window(z - Z_HALL0, FLOOR + 1.0, 2.4, w=1.07, shutters="iron",
                                   _doc="a lower window onto the court, under the box passage"))
            hall_ops.append(window(z - Z_HALL0, r3(BOX_Y + 2.6), 2.2, w=1.07, level="upper", shutters="iron",
                                   _doc="an upper window over the box passage's ceiling, under the plate"))
        hall_ops.append(door(0.55, 1.07, 2.29, leaf="outward",
                             _doc="the back exit to the court, from the standing room under the balcony"))
        hall_ops.append(door(Z_PIT0 - 0.6 - Z_HALL0, 1.52, 2.44, leaves=2, leaf="outward",
                             _doc="the hall's side exit to the court, by the box's column"))
        stage_ops = [window(5.2, STAGE + 3.6, 1.83, w=0.91, level="upper", shutters="iron")]
        if e:
            stage_ops.append(door(2.0, 2.44, 3.66, leaves=2, leaf="outward", sill=r3(STAGE - FLOOR),
                                  _doc="the scenery door at the stage's height into the scene dock: flats and trunks off a wagon's bed"))
        else:
            stage_ops.append(window(2.6, STAGE + 1.0, 1.52, w=0.91, arch=False, shutters="iron",
                                    _doc="the property room's window"))
        segs = [
            brick("%s_front" % id_, (x, 0), (x, Z_HALL0), out, CORNICE, set_off={"y": FOYER, "thick": T_UP},
                  openings=([door(9.45, 1.07, 2.44, leaf="inward", glazed=True,
                                  _doc="the bar's own door, onto the open ground: a drink without a ticket")] if e else
                            [window(9.3, FLOOR + 0.9, 2.4, w=0.91)])
                           + [window(4.5, FLOOR + 0.9, 2.4, w=0.91), window(6.9, FLOOR + 0.9, 2.4, w=0.91)]
                           + [window(z, FOYER + 0.9, 2.4, w=0.91, level="upper") for z in (4.5, 8.2)]
                           + [window(z, ATTIC + 0.6, 1.3, w=0.91, level="attic") for z in (4.5, 8.2)],
                  _doc="the front block's side: the cornice returns along it (a three-storey block); "
                       + ("the bar's windows and its own door" if e else "the parlour's windows on the lane")),
            brick("%s_hall" % id_, (hx, Z_HALL0), (hx, Z_PROSC), out, HALL_TOP,
                  pilasters={"at": [r3(z - Z_HALL0) for z in TRUSS_Z], "proj": 0.11, "width": 0.56,
                             "_doc": "NEW: brick piers under the trusses' bearings (the wall's stiffening)"},
                  openings=hall_ops,
                  _doc="the hall's side, 42 ft apart (Sean, 2026-11-26: ~100 seats), on the court: pilasters under "
                       "the trusses, two tiers of arched windows with iron fire shutters, two exits (doors opening "
                       "out, after the Brooklyn Theatre fire, 1876); the box passage inside along it at the box level"),
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
        brick("vestibule", (ie, Z_VEST), (IN_W, Z_VEST), "-z", FRONT_ROOF, thick=T_IN, partition=True,
              level="ground", bearing=True,
              openings=[door(CX - ie, 3.05, 2.9, leaves=2, leaf="swing", arch="round",
                             _doc="into the lobby: two pairs of swing doors under one arch"),
                        {"type": "void", "level": "upper", "at": r3(CX - ie), "width": 3.66, "height": 3.0, "arch": "round",
                         "_doc": "the foyer's arch: the front promenade (the five tall windows) to the gallery over the lobby"},
                        door(3.0 - ie, 0.91, 2.13, level="upper", _doc="McCready's office"),
                        door(W - 3.0 - ie, 0.91, 2.13, level="upper", _doc="the committee room"),
                        door(CX - ie, 0.91, 2.0, level="attic", _doc="through the scene loft")],
              _doc="The vestibule's back, 13 in brick to the roof: the front block's middle bearing line (its floors "
                   "span 2.2 m in front of it and 7.3 m behind); the box office's and the cloak room's back walls."),
        {"id": "box_office", "line": [[4.6, ie], [4.6, Z_VEST]], "out": "-x", "partition": True, "level": "ground", "inside": PLASTER,
         "openings": [window(0.9, 1.0, 0.6, w=0.6, grille="brass", shelf="marble",
                             _doc="the ticket window, onto the vestibule"),
                      door(1.75, 0.76, 2.03, _doc="the seller's door, from the vestibule's corner")]},
        {"id": "cloak_room", "line": [[r3(W - 4.6), ie], [r3(W - 4.6), Z_VEST]], "out": "+x", "partition": True,
         "level": "ground", "inside": PLASTER, "openings": [{"type": "hatch", "at": 0.9, "width": 1.2, "height": 1.0, "sill": 0.95,
                                          "_doc": "the cloak counter"}, door(1.75, 0.76, 2.03)]},
        brick("lobby_back", (ie, Z_LOBBY), (IN_W, Z_LOBBY), "-z", r3(FRONT_ROOF + 0.6), thick=T_IN, partition=True,
              level="ground", bearing=True,
              openings=[door(CX - ie, 2.44, 2.44, leaves=2, leaf="swing", _doc="the hall's doors, between the stairs"),
                        window(2.6 - ie, FLOOR + 0.9, 2.0, w=0.91, _doc="the bar's back window, on the east court"),
                        window(W - 2.6 - ie, FLOOR + 0.9, 2.0, w=0.91, _doc="the parlour's, on the west court"),
                        window(2.6 - ie, FOYER + 0.9, 2.0, w=0.91, level="upper", _doc="McCready's office, on the court"),
                        window(W - 2.6 - ie, FOYER + 0.9, 2.0, w=0.91, level="upper"),
                        door(CX - ie, 1.52, 2.29, leaves=2, leaf="swing", level="upper",
                             _doc="the foyer's gallery to the balcony's back aisle"),
                        door(sum(WELL_E) / 2 - ie, 1.07, 2.29, leaf="swing", level="upper",
                             _doc="at the east stair's landing: up the stair and straight into the balcony"),
                        door(sum(WELL_W) / 2 - ie, 1.07, 2.29, leaf="swing", level="upper")],
              _doc="The lobby's back wall, 13 in brick to the roof: the foyer's and the scene loft's joists, the "
                   "balcony's carriages and the hall's first purlins bear on it; doors into the hall's standing room "
                   "below, the balcony's back aisle above. Beyond the hall's side walls it is the front block's back "
                   "on the courts (the bar's, parlour's, office's and committee room's back windows)."),
        brick("proscenium", (ie, Z_PROSC), (IN_W, Z_PROSC), "-z", STAGE_TOP, thick=T_IN, partition=True,
              level="ground", bearing=True,
              openings=[{"type": "void", "at": r3(CX - ie), "width": r3(22 * FT), "height": r3(18 * FT),
                         "sill": r3(STAGE - FLOOR), "arch": "segmental",
                         "_doc": "NEW: the proscenium opening (a segmental arch of brick rings over 22 ft, framed "
                                 "inside in gilt plaster)"},
                        door(r3(HIN_E + 0.8 - ie), 0.91, 2.13, sill=r3(STAGE - FLOOR),
                             _doc="under the east box: the forestage's end to the wings (the getaway's first door)"),
                        door(r3(HIN_W - 0.8 - ie), 0.91, 2.13, sill=r3(STAGE - FLOOR))],
              _doc="The proscenium wall: 13 in brick from its footing through the roof (the period's fire wall "
                   "between stage and house); beyond the hall's side walls the stage house's front on the courts."),
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
        {"id": "bar", "line": [[X_BAR, Z_VEST1], [X_BAR, Z_LOBBY]], "out": "-x", "partition": True, "level": "ground",
         "bearing": True, "stud": 0.1, "inside": PLASTER,
         "openings": [door(r3(ST_TOP + 0.5 - Z_VEST1), 0.91, 2.13, _doc="from the lobby, past the east stair's head")],
         "_doc": "the bar's wall: 4x4 studs (it carries the east landing's joists), the east stair against it"},
        {"id": "parlour", "line": [[X_PARL, Z_VEST1], [X_PARL, Z_LOBBY]], "out": "+x", "partition": True, "level": "ground",
         "bearing": True, "stud": 0.1, "inside": PLASTER,
         "openings": [door(r3(ST_TOP + 0.5 - Z_VEST1), 0.91, 2.13, _doc="from the lobby, past the west stair's head")],
         "_doc": "the ladies' parlour's wall, as the bar's"},
        {"id": "office", "line": [[X_BAR, Z_VEST1], [X_BAR, Z_LOBBY]], "out": "-x", "partition": True, "level": "upper",
         "inside": PLASTER, "openings": [], "_doc": "McCready's office over the bar (its door through the vestibule wall)"},
        {"id": "committee", "line": [[X_PARL, Z_VEST1], [X_PARL, Z_LOBBY]], "out": "+x", "partition": True, "level": "upper",
         "inside": PLASTER, "openings": [], "_doc": "the committee room over the parlour: the town's and the Miners' Union's meetings"},
    ]
    for sd, xw, xp in (("e", HIN_E, PASS_E), ("w", HIN_W, PASS_W_)):
        sg = 1 if sd == "e" else -1
        xbox = r3(xw + sg * BOX_W)
        parts += [
            {"id": "passage_%s" % sd, "line": [[xp, PASS_Z[0]], [xp, PASS_Z[1]]], "out": "+x" if sd == "e" else "-x",
             "partition": True, "level": "box", "stud": 0.1, "inside": PLASTER, "openings": [],
             "_doc": "the box passage's house side: studs on its beam, lath and plaster, papered; no opening on the "
                     "house: who goes along it is unseen (#1244)"},
            {"id": "passage_door_%s" % sd, "line": [[min(xw, xp), PASS_Z[0]], [max(xw, xp), PASS_Z[0]]], "out": "-z",
             "partition": True, "level": "box", "inside": PLASTER, "top": r3(BOX_Y + 2.3),
             "openings": [door(r3(abs(xp - xw) / 2), 0.76, 2.03, level="box", leaf="inward", bar=True,
                               _doc="the vestibule door off the balcony's back aisle (two steps down inside): it "
                                    "opens in, and an iron keeper either side on the passage's face takes a bar "
                                    "(a 2x4 left standing in the corner), so a man inside can shut the house out, "
                                    "as Ford's Theatre's was in 1865")],
             "_doc": "the passage's head on the balcony's back aisle"},
            {"id": "box_%s_back" % sd, "line": [[min(xw, xbox), Z_APRON], [max(xw, xbox), Z_APRON]], "out": "-z",
             "partition": True, "level": "box", "inside": PLASTER, "top": r3(BOX_Y + 2.6),
             "openings": [door(0.45, 0.7, 2.0, level="box", leaf="inward", peephole=True,
                               _doc="the box's own door at the passage's end, by the side wall; a gimlet hole in it")],
             "_doc": "the box's back (-z) wall over the forestage's front edge: hides the door from the house"},
        ]
    parts.append({"id": "property_room", "line": [[r3(IN_W - 2.4), Z_STAGE0], [r3(IN_W - 2.4), Z_DRESS]], "out": "-x",
                  "partition": True, "level": "stage", "stud": 0.1, "inside": PLASTER,
                  "openings": [door(3.4, 1.52, 2.44, leaves=2, level="stage", _doc="wide, for the furniture of a play")],
                  "_doc": "the property room in the west wing (Sean, 2026-11-26: more backstage), 8 ft deep: the "
                          "company's props and the house's (chairs, a throne, a stuffed bear, muskets that don't fire)"})
    return [front] + side("east", 0.0, "-x") + side("west", W, "+x") + [back] + parts


# ---------------------------------------------------------------------------------------------- floors
def floors():
    return [
        {"id": "ground_front", "level": "ground", "rect": [IN_E, IN_E, IN_W, Z_LOBBY], "joists": "x",
         "look": "wood:int_floor",
         "_doc": "the vestibule (laid over with black and white marble tile: NEW finish) and the lobby, 2x10 at 16 in "
                 "along x on the girders"},
        {"id": "hall", "level": "ground", "rect": [HIN_E, Z_HALL0, HIN_W, Z_PROSC], "joists": "x", "joist": "dance_joist",
         "look": "wood:int_floor",
         "_doc": "the parquet and the pit, level (a dance floor: all four rows on runners), 2x12 at 16 in on "
                 "five girder lines (70 lb/ft2)"},
        {"id": "foyer", "level": "upper", "rect": [IN_E, IN_E, IN_W, Z_VEST], "joists": "z", "look": "wood:int_floor",
         "_doc": "the foyer's front promenade behind the five tall windows: 2x10 from the front wall's set-off to the "
                 "vestibule wall (2.2 m)"},
        {"id": "office", "level": "upper", "rect": [IN_E, Z_VEST1, X_BAR, Z_LOBBY], "joists": "z", "joist": "long_joist",
         "look": "wood:int_floor", "openings": [{"id": "loft_stair", "rect": [r3(IN_E + 0.1), 5.3, r3(IN_E + 1.0), 9.9]}],
         "_doc": "over the bar: 4x14 at 12 in, vestibule wall to the lobby's back wall (24 ft), 100 lb/ft2"},
        {"id": "gallery", "level": "upper", "rect": [WELL_E[1], Z_VEST1, WELL_W[0], Z_LOBBY], "joists": "z",
         "joist": "long_joist", "look": "wood:int_floor",
         "_doc": "the foyer's gallery over the lobby, between the stairs' wells, to the balcony's middle doors"},
        {"id": "committee", "level": "upper", "rect": [X_PARL, Z_VEST1, IN_W, Z_LOBBY], "joists": "z", "joist": "long_joist",
         "look": "wood:int_floor"},
        {"id": "landing_e", "level": "upper", "rect": [WELL_E[0], ST_TOP, WELL_E[1], Z_LOBBY], "joists": "x",
         "look": "wood:int_floor", "_doc": "the east stair's landing: 2x10 across, from the bar's stud wall to the well's trimmer"},
        {"id": "landing_w", "level": "upper", "rect": [WELL_W[0], ST_TOP, WELL_W[1], Z_LOBBY], "joists": "x",
         "look": "wood:int_floor"},
        {"id": "scene_loft", "level": "attic", "rect": [IN_E, IN_E, IN_W, Z_LOBBY], "joists": "z",
         "joist": "long_joist", "look": "wood:int_rough",
         "_doc": "the scene painter's loft and the stores over the whole front block (40 lb/ft2), on the vestibule wall"},
        {"id": "dress_ground", "level": "stage", "rect": [IN_E, Z_DRESS0, IN_W, Z_BACK], "joists": "z",
         "look": "wood:int_floor",
         "_doc": "the dressing block's floor at the stage's height, 2x10 front to back over 2.97 m on the walls' ledges"},
        {"id": "dress_upper", "level": "dress_upper", "rect": [IN_E, Z_DRESS0, IN_W, Z_BACK], "joists": "z",
         "look": "wood:int_floor",
         "openings": [{"id": "stair", "rect": [r3(CX - 0.6), r3(Z_BACK - 3.3), r3(CX + 0.6), r3(Z_BACK - 0.1)]}]},
        {"id": "dress_roof", "level": "dress_roof", "rect": [IN_E, Z_DRESS0, IN_W, Z_BACK], "joists": "z",
         "joist": "roof_joist", "_doc": "flat, tin on boards, behind its parapet"},
        {"id": "passage_e", "level": "box", "rect": [HIN_E, PASS_Z[0], BAL_X[0], PASS_Z[1]], "joists": "x",
         "joist": "passage_joist", "look": "wood:int_floor",
         "_doc": "the east box passage, 2x8 at 16 in from pockets in the brick to the passage beam (`beams`); a red "
                 "runner; its ceiling boards on 2x6 at the partition's plate (2.3 m)"},
        {"id": "passage_w", "level": "box", "rect": [BAL_X[1], PASS_Z[0], HIN_W, PASS_Z[1]], "joists": "x",
         "joist": "passage_joist", "look": "wood:int_floor"},
        {"id": "box_e", "level": "box", "rect": [HIN_E, BOX_Z[0], r3(HIN_E + BOX_W), BOX_Z[1]], "joists": "x",
         "joist": "box_joist", "look": "wood:int_floor",
         "_doc": "the east box's floor, 3x10 at 16 in from the side wall's pockets to the box's front beam; carpeted"},
        {"id": "box_w", "level": "box", "rect": [r3(HIN_W - BOX_W), BOX_Z[0], HIN_W, BOX_Z[1]], "joists": "x",
         "joist": "box_joist", "look": "wood:int_floor"},
        {"id": "front_roof", "level": "front_roof", "rect": [IN_E, IN_E, IN_W, Z_LOBBY], "joists": "z",
         "joist": "long_joist", "_doc": "the front block's flat roof behind the cornice's parapet, tin on boards"},
    ]


def girders():
    return {"_doc": "Lines along z under the ground floors' joists (along x), on brick piers at 6 ft over the pad (a "
                    "crawl space: the pad is level at the street edge's height). Spans 2.9 m; the balcony's columns "
                    "stand on piers of their own between them.",
            "x": [3.33, 6.24, 9.14, 12.05, 14.96]}


def beams():
    out = []
    for side, x in (("e", WELL_E[1]), ("w", WELL_W[0])):
        zs = [Z_VEST1] + WELL_POSTS_Z + [Z_LOBBY]
        for k in range(len(zs) - 1):
            out.append({"id": "trimmer_%s%d" % (side, k), "from": [x, r3(zs[k])], "to": [x, r3(zs[k + 1])], "level": "upper",
                        "_doc": "the well's inner edge, 8x12 a bay (cut over each post), ends in pockets in the brick: "
                                "the gallery's edge joist beside it, the landing's joists on it" if k == 0 else ""})
    return out


def box_beams():
    """The passages' and the boxes' beams: a passage beam along each passage's house side (it carries the
    partition and the joists' outer ends) on the balcony's corner column and a column mid-way, landing on the box's
    header; the header across the box's back from a pocket in the side wall to the column at the box's front corner;
    the box's front beam from that column to a pocket in the proscenium."""
    out = []
    for sd, xw in (("e", HIN_E), ("w", HIN_W)):
        sg = 1 if sd == "e" else -1
        xb = BAL_X[0] if sd == "e" else BAL_X[1]
        xf = r3(xw + sg * BOX_W)
        zm = r3((BAL_FRONT + Z_APRON) / 2)
        out += [{"id": "passage_beam_%s0" % sd, "from": [xb, BAL_FRONT], "to": [xb, zm], "level": "box", "section": [0.14, 0.24]},
                {"id": "passage_beam_%s1" % sd, "from": [xb, zm], "to": [xb, Z_APRON], "level": "box", "section": [0.14, 0.24],
                 "_doc": "lands on the box's header"},
                {"id": "passage_beam_%sb" % sd, "from": [xb, PASS_Z[0]], "to": [xb, BAL_FRONT], "level": "box", "section": [0.14, 0.24],
                 "_doc": "beside the balcony's rows: on the carriages' end (the balcony's last carriage doubled)"},
                {"id": "box_header_%s" % sd, "from": [xw, Z_APRON], "to": [xf, Z_APRON], "level": "box", "section": [0.19, 0.29],
                 "_doc": "8x12, the box's back: from the brick to the front corner's column"},
                {"id": "box_front_%s" % sd, "from": [xf, Z_APRON], "to": [xf, Z_PROSC], "level": "box", "section": [0.19, 0.29],
                 "_doc": "8x12 under the box's rail: the column to the proscenium's pocket"}]
    return out


def box_columns():
    out = []
    for sd, xw in (("e", HIN_E), ("w", HIN_W)):
        sg = 1 if sd == "e" else -1
        xb = BAL_X[0] if sd == "e" else BAL_X[1]
        out += [[xb, r3((BAL_FRONT + Z_APRON) / 2)], [r3(xw + sg * BOX_W), r3(Z_APRON - 0.05)]]
    return out


def posts():
    return {"_doc": "6x6 posts under the wells' trimmers, cased as fluted columns, from the lobby's floor (on piers): "
                    "at each flight's middle and its head (its newel)",
            "free": [[x, z] for x in (WELL_E[1], WELL_W[0]) for z in WELL_POSTS_Z], "wall": []}


# ---------------------------------------------------------------------------------------------- the balcony
def balcony():
    """A shallow balcony across the hall's back (Sean, 2026-11-26: two rows, kept small): the back aisle at the
    foyer's level, two rows stepping down 0.3 m, a straight rail on three cast-iron columns; the box passages run on
    from its ends along the side walls, shut off from it."""
    zr = BAL_FRONT
    cols = [[BAL_X[0], zr], [CX, zr], [BAL_X[1], zr]]
    tiers = []
    n_seats = BAL_SEATS
    for k in range(BAL_BACK_ROWS):           # k 0 the front row
        z0 = r3(zr - (k + 1) * BAL_ROW)
        tiers.append({"id": "row_%d" % (k + 1), "y": r3(BAL_LOW + k * BAL_RISE), "rect": [BAL_X[0], z0, BAL_X[1], r3(z0 + BAL_ROW)],
                      "seats": n_seats})
    tiers.append({"id": "back_aisle", "y": FOYER, "rect": [HIN_E, Z_HALL0, HIN_W, r3(Z_HALL0 + BAL_AISLE)], "seats": 0,
                  "_doc": "the cross aisle: the stairs' landing doors and the gallery's in its back wall, the two box "
                          "passages' doors at its ends"})
    return {
        "_doc": "NEW (`Balcony` kind `straight`, the README's parts): the deck in tiers stepped 0.3 m (each tier a floor "
                "of its own on raking carriages: 3x12 at 16 in from the rail beam up to the lobby's back wall, 9 ft), "
                "the rail beam 8x14 on three cast-iron columns (6 in, 3/4 in metal; the outer two the box passages' "
                "beams' too), a panelled gilt fascia on the rail's line with a velvet-padded rail 0.75 m over the "
                "front row; 100 lb/ft2. Each row 18 seats with a step down at either end. The columns stand in the "
                "parquet's middle and side aisles on brick piers. Clear under the rail: 4.0 m (standing room).",
        "kind": "straight", "rail": [[BAL_X[0], zr], [BAL_X[1], zr]],
        "columns": {"kind": "cast_iron", "dia": 0.152, "metal": 0.019, "at": cols + box_columns(), "foot_y": FLOOR,
                    "head_y": r3(BAL_LOW - 0.4),
                    "_doc": "the first three under the rail beam; then each passage's middle column and each box's front corner"},
        "beam": {"section": [0.19, 0.34], "wood": "framing"},
        "carriage": {"section": [0.076, 0.29], "spacing": 0.406, "wood": "framing"},
        "front": {"height": 0.75, "fascia": "panelled, gilt mouldings", "rail": "velvet-padded"},
        "tiers": tiers,
        "seats": {"rows": BAL_SEATS * BAL_BACK_ROWS},
    }


def sightlines():
    """Who sees what of a box (the east one; the west mirrors it), in plan and in height: a line from the eye to the
    target must pass the box's open front (its rail's line x, between the box's back wall and the proscenium) and
    over the rail's top. Targets: the box's door (the head of a man standing in it) and the guest's head (seated at the
    rail's back chair)."""
    xf = r3(HIN_E + BOX_W)
    rail_top = r3(BOX_Y + 0.75)
    door = (BOX_DOOR, r3(Z_APRON + 0.15), r3(BOX_Y + 1.6))      # a man standing in the doorway: his head
    guest = (r3(HIN_E + 1.05), r3(Z_APRON + 0.85), r3(BOX_Y + 1.2))
    shooter_at_guest = math.hypot(door[0] - guest[0], door[1] - guest[1])
    look = (CX - guest[0], 23.2 - guest[1])
    back = (door[0] - guest[0], door[1] - guest[1])
    ang = math.degrees(math.acos((look[0] * back[0] + look[1] * back[1]) / (math.hypot(*look) * math.hypot(*back))))
    eyes = [("parquet, back row, east block", (r3(CX - 2.3), r3(Z_ROW0 + 0.2), FLOOR + 1.2)),
            ("parquet, front row, east end", (r3(CX - 4.0), r3(Z_ROW0 + 3 * ROW + 0.2), FLOOR + 1.2)),
            ("parquet, front row, west end", (r3(CX + 4.0), r3(Z_ROW0 + 3 * ROW + 0.2), FLOOR + 1.2)),
            ("standing room, the back", (CX, r3(Z_HALL0 + 1.0), FLOOR + 1.6)),
            ("balcony, front row, middle", (CX, r3(BAL_FRONT - 0.4), r3(BAL_LOW + 1.2))),
            ("balcony, front row, west end", (r3(BAL_X[1] - 0.3), r3(BAL_FRONT - 0.4), r3(BAL_LOW + 1.2))),
            ("the band in the pit", (r3(CX + 1.5), r3(Z_PIT0 + 0.8), FLOOR + 1.2)),
            ("an actor on the forestage", (CX, r3(Z_APRON + 1.0), STAGE + 1.6)),
            ("an actor at centre stage", (CX, 23.5, STAGE + 1.6)),
            ("the west wing (prompter's side)", (r3(HIN_W - 0.5), 22.5, STAGE + 1.6)),
            ("the west box's guest", (r3(HIN_W - 1.05), r3(Z_APRON + 0.85), r3(BOX_Y + 1.2)))]

    def sees(o, t):
        if o[0] <= xf:
            return False
        f = (o[0] - xf) / (o[0] - t[0])
        z = o[1] + (t[1] - o[1]) * f
        y = o[2] + (t[2] - o[2]) * f
        if not (Z_APRON + 0.05 < z < Z_PROSC):
            return False                    # the box's back wall or the proscenium is in the way
        if y < rail_top and t[2] - BOX_Y > 0.75:
            # under the rail's top the rail (a panelled front) hides all but what stands above it
            return False
        return True
    rows = [{"who": n, "eye": list(o), "door": sees(o, door), "guest": sees(o, guest)} for n, o in eyes]
    return {"_doc": "From `sightlines()` in the spec's script: the box's door is hidden from the whole house by the "
                    "box's back wall; the stage, the wings and the other box see into it.",
            "door": list(door), "guest": list(guest), "door_to_guest": round(shooter_at_guest, 2),
            "door_behind_guest_deg": round(ang), "rail_top": rail_top, "drop": r3(BOX_Y - STAGE), "rows": rows}


def boxes():
    out = []
    for side, x0, x1 in (("east", HIN_E, r3(HIN_E + BOX_W)), ("west", r3(HIN_W - BOX_W), HIN_W)):
        out.append({"id": "box_%s" % side, "rect": [x0, BOX_Z[0], x1, BOX_Z[1]], "y": BOX_Y, "chairs": 4,
                    "front": {"side": "+x" if side == "east" else "-x", "curve": 0.3, "height": 0.75, "fascia": "gilt",
                              "rail": "velvet-padded", "drapes": "red velvet on a rod, tied back; drawn, the box is blind"},
                    "door": {"at": [BOX_DOOR if side == "east" else r3(W - BOX_DOOR), Z_APRON], "peephole": True},
                    "passage": {"rect": [x0 if side == "east" else PASS_W_, PASS_Z[0], PASS_E if side == "east" else x1, PASS_Z[1]],
                                "y": BOX_Y, "door": "barred from inside", "steps": 2}})
    return {"_doc": "NEW (`Balcony` kind `box`): two private boxes (Sean, 2026-11-26, #1244: one a side, 'John Wilkes "
                    "Booth' style for an assassination, #1287), over the forestage's ends either side of the "
                    "proscenium, floor 3.5 m over the stage. Each is shut off from the house: reached only from the "
                    "balcony's back aisle through its vestibule door (it opens in; a bar drops into iron keepers on "
                    "the passage side) and along its own passage, 0.9 m wide, plastered and papered, on the hall's "
                    "side wall, to the box's door (a gimlet hole in it) in the box's back wall. The box: 1.6 x 2.4 m, "
                    "four gilt chairs, a curtain on a rod and a padded rail on the house side; joists 3x10 from the "
                    "side wall to the front beam, its front corner on a cast-iron column. A man in the box can come "
                    "up behind the guest unseen, shoot, and go over the rail to the forestage (3.5 m: a sprain or a "
                    "broken leg), through the door under the box into the wings and out the stage door to the yard; "
                    "or back along the passage to the balcony and down the stairs.",
            "list": out, "sightlines": sightlines()}


def seats():
    # The rows from the back (standing room behind the last row, under the balcony) to the pit's rail.
    z0 = Z_ROW0
    blocks = [[r3(CX - PAR_AISLE / 2 - PAR_BLOCK * SEAT), r3(CX - PAR_AISLE / 2), PAR_BLOCK],
              [r3(CX + PAR_AISLE / 2), r3(CX + PAR_AISLE / 2 + PAR_BLOCK * SEAT), PAR_BLOCK]]
    # A column that stands in a row takes that seat's place (none does: they're in the aisles).
    out = 0
    for cx, cz in balcony()["columns"]["at"]:
        for k in range(PAR_ROWS):
            za = z0 + k * ROW
            if za - 0.05 <= cz <= za + 0.5 and any(b0 <= cx <= b1 for b0, b1, _ in blocks):
                out += 1
    n = PAR_ROWS * PAR_BLOCK * 2
    return {"_doc": "The parquet (Sean, 2026-11-26: about 100 in all, mixed): four rows of 14 in two blocks of 7 "
                    "either side of a middle aisle, 32 in rows, 20 in folding opera chairs on cast-iron standards (A. H. "
                    "Andrews & Co.'s), screwed to runners: all four rows clear for a ball. Side aisles 1.9 m along the "
                    "walls (the passages' columns in them); standing room behind the last row under the balcony. A "
                    "kit prop by the prop lab (`opera_chair`, NEW).",
            "kit": "opera_chair", "rows": PAR_ROWS, "row_pitch": ROW, "seat_width": SEAT, "first_row_z": z0,
            "last_row_z": r3(z0 + (PAR_ROWS - 1) * ROW), "blocks": blocks, "out": out,
            "count": n - out, "runners": PAR_ROWS, "facing": 0}


# ---------------------------------------------------------------------------------------------- the stage
def stage():
    return {
        "_doc": "The stage (saloon B's `stage` grown up, #902's form: legs, bearers, joists, boards, a skirt): 3 ft 6 in "
                "over the hall, the stage house's full 60 ft behind the proscenium (Sean, 2026-11-26: more backstage: "
                "wings 17 ft a side, the scene dock in the east one by the scenery door, the property room walled off "
                "in the west), and a forestage the hall's full width 8 ft out of it, the boxes over its ends, the "
                "footlights' trough along its middle; a trap 4 x 4 ft between two joists (the church's hatch rule); the gridiron 30 ft over the "
                "stage on beams in pockets (3x8 slats, open between); the drop curtain and three roll drops on battens "
                "hung from it by ropes made off at the pin rail (the Rope part) on the west fly gallery; wings of flats "
                "either side. NEW: the apron, the trough, the gridiron, the battens, the pin rail, the gallery.",
        "level": "ground", "rect": [IN_E, Z_STAGE0, IN_W, Z_DRESS], "height": r3(STAGE - FLOOR),
        "leg": 0.15, "bearer": [0.15, 0.25], "joist": [0.05, 0.24], "spacing": 0.406, "legs_every": 1.5, "bearers": 5,
        "skirt": ["front"],
        "apron": {"rect": [HIN_E, Z_APRON, HIN_W, Z_PROSC], "bow": 0.3, "_doc": "the forestage",
                  "steps": [{"id": "apron_%s" % sd, "head": [x, Z_APRON], "dir": "-z", "width": 0.9, "risers": 4,
                             "going": 0.25, "_doc": "under the box, down into the side aisle (acts into the house; "
                                                     "the house onto the stage)"}
                            for sd, x in (("e", r3(HIN_E + 0.1)), ("w", r3(HIN_W - 1.0)))]},
        "pit": {"rect": [r3(CX - 4.0), Z_PIT0, r3(CX + 4.0), Z_APRON], "rail": {"height": 0.9, "z": Z_PIT0},
                "_doc": "the band: a piano, a fiddle, a cornet; level with the hall, a brass-capped rail before the first row"},
        "footlights": {"count": 12, "trough": [r3(CX - 3.5), r3(Z_APRON + 0.05), r3(CX + 3.5), r3(Z_APRON + 0.25)],
                       "kind": "kerosene, tin reflectors", "lit": [19, 23]},
        "trap": [r3(CX - 0.61), r3(Z_STAGE0 + 2.44), r3(CX + 0.61), r3(Z_STAGE0 + 3.66)],
        "gridiron": {"y": GRID, "beams": [0.15, 0.3], "slats": [0.076, 0.2], "gap": 0.61},
        "drops": [{"id": "curtain", "z": r3(Z_STAGE0 + 0.3), "art": "a painted lake under mountains in a painted gilt frame",
                   "roll": True, "down": True},
                  {"id": "parlour", "z": r3(Z_STAGE0 + 2.0), "roll": True},
                  {"id": "forest", "z": r3(Z_STAGE0 + 3.8), "roll": True},
                  {"id": "street", "z": r3(Z_DRESS - 0.4), "roll": True, "_doc": "the back drop: a western street"}],
        "drop_width": r3(24 * FT), "drop_height": r3(20 * FT),
        "scene_dock": {"rect": [IN_E, Z_STAGE0, r3(IN_E + 2.4), Z_DRESS], "racks": 3,
                       "_doc": "racks of flats stood on edge along the east wall, behind the scenery door (NEW: `scene_rack`, prop lab)"},
        "property_room": {"rect": [r3(IN_W - 2.4), Z_STAGE0, IN_W, Z_DRESS], "wall": "property_room"},
        "pin_rail": {"wall": "west_stage", "y": r3(DRESS_UP + 1.0), "lines": 12},
        "fly_gallery": {"wall": "west_stage", "y": DRESS_UP, "depth": 1.0, "from": Z_STAGE0, "to": Z_DRESS,
                        "_doc": "a gallery along the west wall at the dressing block's upper floor, for the flymen, on "
                                "brackets in the brick; its door to the upper dressing rooms"},
        "wings": {"flats": 8, "each_side": 4, "width": 1.5, "height": 5.5},
    }


# ---------------------------------------------------------------------------------------------- roof
def roof():
    span = r3(IN_W - IN_E + 2 * 0.3)
    return {
        "_doc": "NEW (`HoweTruss`, the README's parts): over the hall, two Howe trusses on the pilasters at 11.7 ft, "
                "spanning 41 ft; over the stage house two more spanning 59 ft; the front block and the dressing block flat behind "
                "their parapets (floors of level front_roof and dress_roof). Purlins 4x10 at the panel points, rafters "
                "2x8 at 24 in, 1 in boards, terne plate (tin), 3/12 to a ridge 2.1 m over the plate, under the hall's "
                "parapets' line seen from the street (the front block hides it). The hall's ceiling: 2x8 at 16 in hung "
                "from the bottom chords by iron straps, lath and plaster under them, a cove at the walls, a plaster "
                "rose round the chandelier's chain in the middle bay.",
        "pitch": "3/12", "hall": {"z": [Z_LOBBY, Z_PROSC], "trusses_at": TRUSS_Z, "bear_y": PLATE, "span": r3(HIN_W - HIN_E + 0.6),
                                   "depth": 1.5, "panels": 6, "rods": [0.035, 0.029, 0.025],
                                   "_doc": "the hall's two: 41 ft, 6 panels, rods 1 3/8 in at the ends"},
        "stage": {"z": [Z_PROSC, r3(Z_DRESS + T_IN)], "trusses_at": [r3(Z_STAGE0 + 2.2), r3(Z_STAGE0 + 4.6)],
                  "span": span, "depth": 2.0,
                  "bear_y": r3(STAGE_TOP - 1.1)},
        "truss": {"kind": "howe", "span": span, "depth": 2.0, "panels": 8, "top_chord": [0.19, 0.29],
                  "bottom_chord": {"section": [0.14, 0.29], "count": 2}, "braces": [0.14, 0.19], "counters": [0.09, 0.14],
                  "rods": [0.041, 0.032, 0.025],
                  "_doc": "rods 1 5/8 in at the ends, 1 1/4 next, 1 in in the middle panels (wrought iron, nuts on cast "
                          "angle blocks); the bottom chord two 6x12 bolted with keys (Haupt)"},
        "purlin": [0.09, 0.24], "rafter": [0.04, 0.19], "rafter_spacing": 0.61, "boards": 0.025, "tin": True,
        "ceiling": {"y": CEILING, "joist": [0.04, 0.19], "spacing": 0.406, "finish": "plaster on lath",
                    "rose": {"at": [CX, r3(sum(TRUSS_Z) / 2)], "dia": 1.5}, "cove": 0.6},
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
        {"id": "lobby", "level": g, "rect": [X_BAR, Z_VEST1, X_PARL, Z_LOBBY],
         "use": "the two stairs up to the foyer, the hall's doors; waiting, smoking, the interval"},
        {"id": "bar", "level": g, "rect": [IN_E, Z_VEST1, X_BAR, Z_LOBBY],
         "use": "the opera house's bar (Sean, 2026-11-24): two bar sections and the back bar along its west wall, "
                "its own door onto the open ground (a drink without a ticket), the interval's crush; the men's"},
        {"id": "parlour", "level": g, "rect": [X_PARL, Z_VEST1, IN_W, Z_LOBBY],
         "use": "the ladies' parlour (the retiring room, Sean's pick): settees, a pier glass, a washstand, a stove; "
                "the windows on the lane"},
        {"id": "hall", "level": g, "rect": [HIN_E, Z_HALL0, HIN_W, Z_PIT0],
         "use": "the parquet: %d seats; the crowd's place; a ball with the front rows cleared" % seats()["count"]},
        {"id": "pit", "level": g, "rect": [r3(CX - 4.0), Z_PIT0, r3(CX + 4.0), Z_APRON], "use": "the band"},
        {"id": "court_e", "level": g, "rect": [0.0, Z_HALL0, HX_E, Z_PROSC], "outside": True,
         "use": "the east court between the front block and the stage house, open to the open ground: the hall's exits, the bar's back window"},
        {"id": "court_w", "level": g, "rect": [HX_W, Z_HALL0, W, Z_PROSC], "outside": True,
         "use": "the west court, open to the lane: the hall's exits; where the box's shooter would land if he went out a window"},
        {"id": "stage", "level": "stage", "rect": [IN_E, Z_STAGE0, IN_W, Z_DRESS],
         "use": "the acts (#1143's later shows); the wings, the pin rail, roll drops and flats; a trap"},
        {"id": "apron", "level": "stage", "rect": [HIN_E, Z_APRON, HIN_W, Z_PROSC],
         "use": "the forestage: the footlights along its edge; where a speech is made to the house; under the boxes"},
        {"id": "scene_dock", "level": "stage", "rect": [IN_E, Z_STAGE0, r3(IN_E + 2.4), Z_DRESS],
         "use": "the east wing's scene dock: flats in racks, the drops rolled, the scenery door to the open ground"},
        {"id": "property_room", "level": "stage", "rect": [r3(IN_W - 2.4), Z_STAGE0, IN_W, Z_DRESS],
         "use": "the property room: furniture of plays, a throne, a stuffed bear, stage muskets"},
        {"id": "dressing_1", "level": "stage", "rect": [IN_E, Z_DRESS0, r3(CX - 0.76), r3(Z_DRESS0 + 1.45)], "use": "the star's"},
        {"id": "dressing_2", "level": "stage", "rect": [IN_E, r3(Z_DRESS0 + 1.45), r3(CX - 0.76), Z_BACK], "use": "the company's men"},
        {"id": "corridor", "level": "stage", "rect": [r3(CX - 0.76), Z_DRESS0, r3(CX + 0.76), Z_BACK],
         "use": "the stage door to the stage; the stair to the upper dressing rooms"},
        {"id": "dressing_3", "level": "stage", "rect": [r3(CX + 0.76), Z_DRESS0, IN_W, r3(Z_DRESS0 + 1.45)], "use": "the company's women"},
        {"id": "dressing_4", "level": "stage", "rect": [r3(CX + 0.76), r3(Z_DRESS0 + 1.45), IN_W, Z_BACK], "use": "trunks and costumes"},
        {"id": "foyer", "level": "upper", "rect": [IN_E, IN_E, IN_W, Z_VEST],
         "use": "the foyer's promenade behind the five tall windows over Main Street, settees; through its arch the "
                "gallery over the lobby to the balcony"},
        {"id": "gallery", "level": "upper", "rect": [WELL_E[1], Z_VEST1, WELL_W[0], Z_LOBBY],
         "use": "the foyer's gallery between the stairs' wells, railed, looking down into the lobby"},
        {"id": "office", "level": "upper", "rect": [IN_E, Z_VEST1, X_BAR, Z_LOBBY],
         "use": "McCready's office over the bar: the safe, the bookings, the side windows; the loft stair"},
        {"id": "committee", "level": "upper", "rect": [X_PARL, Z_VEST1, IN_W, Z_LOBBY],
         "use": "the committee room over the parlour: a long table, the town's meetings and the Miners' Union's"},
        {"id": "balcony", "level": "upper", "rect": [HIN_E, Z_HALL0, HIN_W, BAL_FRONT],
         "use": "the balcony: %d seats in two rows, the cheap ones" % (BAL_SEATS * BAL_BACK_ROWS)},
        {"id": "passage_e", "level": "box", "rect": [HIN_E, PASS_Z[0], PASS_E, PASS_Z[1]],
         "use": "the east box's passage: a barred door at its head, the box's door at its end; nobody in the house sees along it"},
        {"id": "passage_w", "level": "box", "rect": [PASS_W_, PASS_Z[0], HIN_W, PASS_Z[1]], "use": "the west box's passage"},
        {"id": "box_e", "level": "box", "rect": [HIN_E, BOX_Z[0], r3(HIN_E + BOX_W), BOX_Z[1]],
         "use": "the east private box: McCready's own, lent to whoever he wants to please"},
        {"id": "box_w", "level": "box", "rect": [r3(HIN_W - BOX_W), BOX_Z[0], HIN_W, BOX_Z[1]],
         "use": "the west private box: the Baron's when he comes to town"},
        {"id": "dressing_upper", "level": "dress_upper", "rect": [IN_E, Z_DRESS0, IN_W, Z_BACK],
         "use": "four more dressing rooms, the wardrobe; the door onto the fly gallery"},
        {"id": "scene_loft", "level": "attic", "rect": [IN_E, IN_E, IN_W, Z_LOBBY],
         "use": "the scene painter's loft: a frame, pots of distemper, rolled canvas; the old drops"},
    ]


def stairs():
    n, going = ST_N, ST_GO
    return [
        {"id": "lobby_east", "head": [WELL_E[0], ST_TOP], "dir": "+z", "width": ST_W, "from": "ground", "to": "upper",
         "risers": n, "going": going, "rail": "+x", "look": "wood:int_oak", "stringer_look": "wood:int_timber",
         "_doc": "the lobby's two stairs: straight flights of 26 risers (7.6 in on 10 in treads) against the bar's and "
                 "the parlour's walls, rising from the vestibule's side to a landing at the lobby's back wall, its "
                 "door straight into the balcony (the gallery's to the foyer); turned walnut newels at the foot, a red "
                 "runner on brass rods; their open sides railed. The wells over them the flights' length."},
        {"id": "lobby_west", "head": [WELL_W[0], ST_TOP], "dir": "+z", "width": ST_W, "from": "ground", "to": "upper",
         "risers": n, "going": going, "rail": "-x", "look": "wood:int_oak", "stringer_look": "wood:int_timber"},
        {"id": "dressing", "head": [r3(CX - 0.6), r3(Z_BACK - 0.1)], "dir": "+z", "width": 1.2, "from": "stage",
         "to": "dress_upper", "risers": 16, "going": 0.2, "_doc": "a steep boxed stair at the corridor's end"},
        {"id": "loft", "head": [r3(IN_E + 0.1), 9.9], "dir": "+z", "width": 0.9, "from": "upper", "to": "attic",
         "risers": 24, "going": 0.2, "_doc": "a closed stair in McCready's office's corner up to the scene loft"},
        {"id": "stage_door", "head": [r3(CX - 0.75), r3(D + 0.95)], "dir": "-z", "width": 1.5, "from": "yard", "to": "stage",
         "risers": 3, "going": 0.3, "_doc": "three stone steps up from the yard to the stage door"},
    ]


def lamps():
    sconces = []
    for room, wall, at, h in (("vestibule", "vestibule", 4.5, 2.2), ("vestibule", "vestibule", 12.9, 2.2),
                              ("lobby", "lobby_back", r3(sum(WELL_E) / 2 - IN_E), 2.4), ("lobby", "lobby_back", r3(sum(WELL_W) / 2 - IN_E), 2.4),
                              ("bar", "east_front", 3.4, 2.2), ("bar", "east_front", 8.2, 2.2),
                              ("parlour", "west_front", 3.4, 2.0), ("parlour", "west_front", 8.2, 2.0),
                              ("hall", "east_hall", 3.0, 2.6), ("hall", "east_hall", 7.9, 2.6),
                              ("hall", "west_hall", 3.0, 2.6), ("hall", "west_hall", 7.9, 2.6)):
        sconces.append({"room": room, "kit": "reflector_lamp", "wall": wall, "level": "ground", "at": at, "height": h,
                        "energy": 1.0, "reach": 6.0, "lit": [18, 24]})
    return {"_doc": "Kerosene throughout (no gas in Salt Creek). The chandelier in the hall's middle bay from the "
                    "ceiling's rose on a chain to the middle truss's bottom chord (lowered on a rope to be lit: the "
                    "Rope part), 16 lamps in two tiers; brackets on the walls; the footlights (the stage's); two lamp "
                    "standards on the walk (prop lab's `lamp_standard`, NEW).",
            "chandelier": {"at": [CX, r3(sum(TRUSS_Z) / 2)], "y": r3(CEILING - 1.8), "radius": 0.9, "lamps": 16,
                           "between": TRUSS_Z, "tiers": 2,
                           "_doc": "16 lamps (the smaller hall), on a chain from a beam between the two trusses' bottom chords"},
            "box_lamps": [{"box": b, "kit": "reflector_lamp", "height": 1.8, "lit": [18, 24],
                           "_doc": "one bracket in each box and one in each passage: turned down in the show, the box dark"}
                          for b in ("box_e", "box_w", "passage_e", "passage_w")],
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
        {"id": "piano", "use": "play", "who": "band", "at": [r3(CX - 3.0), y0, r3(Z_PIT0 + 0.6)], "look": [r3(CX - 3.0), Z_APRON]},
        {"id": "fiddle", "use": "play", "who": "band", "at": [r3(CX - 0.8), y0, r3(Z_PIT0 + 0.8)], "look": [CX, 23.0]},
        {"id": "cornet", "use": "play", "who": "band", "at": [r3(CX + 1.5), y0, r3(Z_PIT0 + 0.8)], "look": [CX, 23.0]},
        {"id": "act_centre", "use": "perform", "who": "act", "at": [CX, ys, 23.5], "look": [CX, 12.0]},
        {"id": "act_apron", "use": "perform", "who": "act", "at": [CX, ys, r3(Z_APRON + 1.0)], "look": [CX, 10.0]},
        {"id": "prompter", "use": "watch", "who": "stage_manager", "at": [r3(HIN_W - 0.5), ys, 22.5], "look": [CX, 24.0]},
        {"id": "flyman", "use": "work", "who": "stagehand", "at": [r3(IN_W - 0.5), DRESS_UP, 25.0], "look": [IN_W, 25.0]},
        {"id": "lamp_lighter", "use": "work", "who": "stagehand", "at": [r3(CX - 3.5), ys, r3(Z_APRON + 0.4)], "look": [CX, Z_APRON]},
        {"id": "standing_room", "use": "watch", "who": "crowd", "at": [CX, y0, r3(Z_HALL0 + 0.7)], "look": [CX, 23.0]},
        {"id": "box_guest_e", "use": "sit", "who": "guest", "at": [r3(HIN_E + 1.05), BOX_Y, r3(Z_APRON + 0.85)], "look": [CX, 23.2],
         "_doc": "the box's guest of honour: the rail's back chair, his back to the door"},
        {"id": "box_guest_w", "use": "sit", "who": "baron", "at": [r3(HIN_W - 1.05), BOX_Y, r3(Z_APRON + 0.85)], "look": [CX, 23.2]},
        {"id": "box_door_e", "use": "stand", "who": "any", "at": [BOX_DOOR, BOX_Y, r3(Z_APRON + 0.3)], "look": [r3(HIN_E + 1.05), 19.65],
         "_doc": "inside the box's door: 1.1 m behind the guest's chair"},
        {"id": "passage_bar_e", "use": "work", "who": "any", "at": [r3(HIN_E + 0.45), BOX_Y, r3(PASS_Z[0] + 0.5)], "look": [r3(HIN_E + 0.45), PASS_Z[0]],
         "_doc": "barring the vestibule door from inside"},
        {"id": "box_drop_e", "use": "climb", "who": "any", "at": [r3(HIN_E + BOX_W - 0.2), BOX_Y, 20.3], "look": [r3(HIN_E + BOX_W + 1.0), 20.3],
         "_doc": "over the rail: 3.5 m down to the forestage"},
        {"id": "office_desk", "use": "work", "who": "mccready", "at": [2.4, FOYER, 4.0], "look": [0.43, 4.0]},
        {"id": "bartender", "use": "serve", "who": "bartender", "at": [4.3, y0, 6.4], "look": [1.5, 6.4]},
        {"id": "bar_rail_1", "use": "drink", "who": "any", "at": [2.6, y0, 4.4], "look": [4.3, 4.4]},
        {"id": "bar_rail_2", "use": "drink", "who": "any", "at": [2.6, y0, 6.0], "look": [4.3, 6.0]},
        {"id": "bar_rail_3", "use": "drink", "who": "any", "at": [2.6, y0, 7.6], "look": [4.3, 7.6]},
        {"id": "parlour_settee", "use": "sit", "who": "lady", "at": [r3(W - 2.0), y0, 5.5], "look": [r3(W - 4.0), 5.5]},
        {"id": "parlour_glass", "use": "dress", "who": "lady", "at": [r3(W - 1.0), y0, 8.4], "look": [IN_W, 8.4]},
        {"id": "committee_chair", "use": "sit", "who": "chairman", "at": [r3(W - 3.0), FOYER, 9.6], "look": [r3(W - 3.0), 4.0]},
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
            "means": "the only brick building in Salt Creek but the bank: freighted-in brick, plate glass, iron, a hundred opera chairs from Chicago, scenery painted in Denver",
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
                    "dress_roof, front_roof, box (the builder knows cellar, ground and upper).",
            "ground": {"top": FLOOR}, "stage": {"top": STAGE}, "upper": {"top": FOYER}, "attic": {"top": ATTIC},
            "box": {"top": BOX_Y, "_doc": "the boxes and their passages, 3.5 m over the stage"},
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
            "passage_joist": {"section": [0.04, 0.19], "spacing": 0.406, "wood": "framing", "_doc": "2x8 at 16 in: the box passages, 3 ft"},
            "box_joist": {"section": [0.064, 0.24], "spacing": 0.406, "wood": "framing", "_doc": "3x10 at 16 in: the boxes, 5.2 ft"},
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
        "beams": beams() + box_beams(),
        "walls": walls(),
        "balcony": balcony(),
        "boxes": boxes(),
        "seats": seats(),
        "stage": stage(),
        "roof": roof(),
        "ceilings": {"_doc": "Plaster on lath (NEW: `PlasterWall`, the README's parts: cracks, falls in chunks off "
                             "its lath, the paper tearing with it) in every room, the hall's under the trusses (the "
                             "roof's `ceiling`), the lobby's and foyer's with a cornice and a rose.",
                     "levels": ["ground", "upper", "stage", "box", "dress_upper"], "finish": "plaster",
                     "holes": [[WELL_E[0], ST_FOOT, WELL_E[1], ST_TOP], [WELL_W[0], ST_FOOT, WELL_W[1], ST_TOP]]},
        "inside_finish": {"_doc": "NEW finishes: walnut wainscot to 3 ft (the lobby, the foyer, the hall), wallpaper "
                                  "over plaster above (deep red and gold, three bands), plain plaster and whitewash "
                                  "backstage and in the dressing rooms; the brick bare in the stage house.",
                          "wainscot": {"height": 0.91, "wood": "walnut", "rooms": ["lobby", "foyer", "hall", "vestibule"]},
                          "paper": {"rooms": ["lobby", "foyer", "hall", "office", "box_e", "box_w", "passage_e", "passage_w"], "pattern": "three-band, red and gold"},
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
        "fixtures": [
            {"kit": "bar", "at": [r3(X_BAR - 0.06 - 2.13), 3.6], "facing": 270, "repeat": {"count": 2, "step": [0, 3.0]},
             "_doc": "the bar's counter, two 3 m kit sections (the hotel's), the customers east of it by the windows"},
            {"kit": "back_bar", "at": [r3(X_BAR - 0.06 - 0.36), 3.4], "facing": 270, "repeat": {"count": 2, "step": [0, 2.5]},
             "_doc": "the back bar against the bar's wall (the east stair behind it)"}],
        "props_wanted": [{"kit": "piano", "at": [r3(CX - 3.5), 20.9], "facing": 0, "_doc": "the pit's upright (prop lab, NEW)"},
                     {"kit": "safe", "at": [1.0, 4.5], "level": "upper", "facing": 90, "_doc": "McCready's (prop lab, NEW)"},
                     {"kit": "settee", "at": [r3(CX - 3.05), 1.2], "level": "upper", "facing": 0,
                      "repeat": {"count": 3, "step": [3.05, 0]}, "_doc": "the foyer's (prop lab, NEW)"},
                     {"kit": "opera_chair", "_doc": "the seats' rows (`seats`, the balcony's tiers) and the boxes' gilt chairs"},
                     {"kit": "settee", "room": "parlour", "_doc": "the ladies' parlour: two settees, a pier glass, a washstand (prop lab, NEW)"},
                     {"kit": "long_table", "room": "committee", "_doc": "the committee room's table and chairs (prop lab)"},
                     {"kit": "lamp_standard", "_doc": "the two on the walk (`lamps.kit`)"}],
        "_props_doc": "`props_wanted`: kit props the prop lab makes before they go in `fixtures` (none exist yet)",
        "use": {"years": 1, "paths": [
            {"id": "doors_to_hall", "who": "everyone", "level": "ground", "daily": 120, "width": 2.4,
             "points": [[CX, IN_E], [CX, Z_VEST], [CX, Z_HALL0 + 0.6]]},
            {"id": "aisle_e", "who": "everyone", "level": "ground", "daily": 50, "width": 0.9,
             "points": [[r3(HIN_E + 1.45), Z_HALL0 + 0.6], [r3(HIN_E + 1.45), Z_PIT0]]},
            {"id": "aisle_w", "who": "everyone", "level": "ground", "daily": 50, "width": 0.9,
             "points": [[r3(HIN_W - 1.45), Z_HALL0 + 0.6], [r3(HIN_W - 1.45), Z_PIT0]]},
            {"id": "aisle_mid", "who": "everyone", "level": "ground", "daily": 60, "width": 1.0,
             "points": [[CX, Z_HALL0 + 0.6], [CX, Z_PIT0]]},
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
def span_stage_extra():
    # the gridiron and the drops hung from a stage truss's bottom chord: 30 lb/ft2 over its bay, 8 ft
    return int((IN_W - IN_E) / FT * 8.0 * 30)


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
    joist("office, gallery, committee", "4x14 at 12 in", 3.5, 13.25, 12, 23.9, 100)
    joist("scene loft, front roof", "4x14 at 12 in", 3.5, 13.25, 12, 23.9, 40)
    joist("stair landing", "2x10 at 16 in", 1.5, 9.25, 16, 4.5, 100)
    car = (BAL_FRONT - Z_HALL0) / FT
    joist("balcony carriage", "3x12 at 16 in", 2.5, 11.25, 16, car, 100)
    joist("box passage floor", "2x8 at 16 in", 1.5, 7.25, 16, (BAL_X[0] - HIN_E) / FT, 100)
    joist("box floor", "3x10 at 16 in", 2.5, 9.25, 16, BOX_W / FT, 100)
    joist("dressing roof", "2x10 at 16 in", 1.5, 9.25, 16, 9.75, 40)
    joist("hall ceiling (hung)", "2x8 at 16 in", 1.5, 7.25, 16, 12.0, 10)
    joist("roof rafter", "2x8 at 24 in", 1.5, 7.25, 24, 7.4, 40)
    joist("rail beam", "8x14", 7.5, 13.25, car / 2 * 12, (CX - BAL_X[0]) / FT, 100, dead=20)
    pb = (Z_APRON - BAL_FRONT) / 2 / FT
    joist("passage beam", "6x10", 5.5, 9.25, (BAL_X[0] - HIN_E) / FT / 2 * 12 + 6, pb, 100, dead=25)
    joist("box front beam", "8x12", 7.5, 11.25, BOX_W / FT / 2 * 12, FORESTAGE / FT, 100, dead=20)
    joist("box header (the passage beam's end on it)", "8x12", 7.5, 11.25, FORESTAGE / FT / 2 * 12 + pb / 2 * 12, BOX_W / FT, 100, dead=20)
    joist("well trimmer (a bay)", "8x12", 7.5, 11.25, 4.5 / 2 * 12 + 12, 10.5, 100, dead=15)
    # A cast-iron column: the rail's middle one, a rail span each side by half the carriage at 120 lb/ft2 all in.
    P = (CX - BAL_X[0]) / FT * car / 2 * 120 + 2000
    A = math.pi / 4 * (6 ** 2 - 4.5 ** 2)
    L, dia = (BAL_LOW - 0.4 - FLOOR) / FT * 12, 6.0
    f = P / A * (1 + (L / dia) ** 2 / 800)               # Gordon, cast iron, round, flat ends
    rows.append(["cast-iron column", "6 in, 3/4 in metal, %.1f ft, %.0f lb" % (L / 12, P), "%.0f lb/in2 (%.2f of 10,000 working)" % (f, f / 10000),
                 "", "ok" if f < 10000 else "OVER"])
    # The Howe trusses: the hall's (41 ft, 4.9 ft deep, 11.7 ft apart, the chandelier's 400 lb) and the stage
    # house's (59 ft, 6.6 ft deep, ~8 ft apart, the gridiron's 30 lb/ft2 hung under it); roof 40 + ceiling 15 lb/ft2.
    for name, span, depth, bay, extra, rods in (("hall", (HIN_W - HIN_E + 0.6) / FT, 1.5 / FT, (TRUSS_Z[1] - TRUSS_Z[0]) / FT, 400, 1.375),
                                                ("stage house", (IN_W - IN_E + 0.6) / FT, 2.0 / FT, 8.0, span_stage_extra(), 1.625)):
        Wt = span * bay * 55 + extra
        chord = Wt * span / (8 * depth)
        rows.append(["Howe truss, %s, chords" % name, "%.0f ft span, %.1f ft deep, %d lb a truss" % (span, depth, Wt),
                     "%.0f lb: bottom 2-6x12 %.0f lb/in2, top 8x12 %.0f lb/in2" % (chord, chord / (2 * 5.5 * 11.25), chord / (7.5 * 11.25)),
                     "", "ok (the joints govern: keyed and bolted)"])
        end_shear = Wt / 2 - Wt / 16
        rod = end_shear / (math.pi / 4 * rods ** 2)
        rows.append(["Howe truss, %s, end rods" % name, "%s in wrought, %.0f lb" % ("1 5/8" if rods > 1.5 else "1 3/8", end_shear),
                     "%.0f lb/in2 (of 10,000)" % rod, "", "ok" if rod < 10000 else "OVER"])
    return rows


def members(sp, lift=(0.6, 1.2)):
    """A count of the members the builder will make, part by part, from the spec alone (no Godot): brick lifts of
    `lift` (course, piece) metres, timber partitions' studs and boards, floors' joists and boards (cut at the
    ground floors' girders, boards 16 ft long), stairs, the balcony's tiers, the boxes, the stage, the roofs and
    the hall's ceiling. Rough: it is calibrated against the lab's trial load of the 310-seat spec (README)."""
    course, piece = lift
    c = {}

    def add(k, n):
        c[k] = c.get(k, 0) + int(round(n))

    def flr(key, rect, joists, sp_=0.406, cut=None):
        x0, z0, x1, z1 = rect
        dx, dz = abs(x1 - x0), abs(z1 - z0)
        along, across = (dx, dz) if joists == "x" else (dz, dx)
        add(key, (across / sp_ + 1) * (math.ceil(along / cut) if cut else 1))
        add(key, along / 0.14 * math.ceil(across / 4.88))
    for w in sp["walls"]:
        (ax, az), (bx, bz) = w["line"]
        L = math.hypot(bx - ax, bz - az)
        if w.get("stone"):
            H = float(w["top"]) + 1.2
            n = math.ceil(L / piece) * math.ceil(H / course)
            for op in w.get("openings", []):
                n -= float(op["width"]) * float(op.get("height", 2.0)) / (piece * course)
            add("brick lifts", max(n, 0))
        else:
            add("partitions", L / 0.406 + 4 + 2 * L / 0.15)
    for f in sp["floors"]:
        flr("floors", f["rect"], f["joists"], cut=2.95 if f["level"] == "ground" else None)
    for s_ in sp["stairs"]:
        add("stairs", 2 * s_["risers"] + 4)
    b = sp["balcony"]
    for t in b["tiers"]:
        flr("balcony", t["rect"], "z")
    add("balcony", len(b["columns"]["at"]) * 3 + len(b["rail"]) * 3)
    for bx_ in sp["boxes"]["list"]:
        if not any(f["id"].startswith("box_") for f in sp["floors"]):
            flr("boxes", bx_["rect"], "x")
        add("boxes", 8)
    st = sp["stage"]
    for r in (st["rect"], st["apron"]["rect"]):
        flr("stage", r, "z")
        add("stage", abs(r[2] - r[0]) * abs(r[3] - r[1]) / 2.25 + 10)
    gx = abs(st["rect"][2] - st["rect"][0])
    gz = abs(st["rect"][3] - st["rect"][1])
    add("stage", gx / 0.69 * math.ceil(gz / 4.88) + gz / 1.5 + len(st["drops"]) * 3 + 20)
    rf = sp["roof"]
    for part, span in (("hall", rf["hall"].get("span", rf["truss"]["span"])), ("stage", rf["stage"].get("span", rf["truss"]["span"]))):
        z0, z1 = rf[part]["z"]
        length = abs(z1 - z0)
        panels = rf[part].get("panels", rf["truss"]["panels"])
        add("roof", len(rf[part]["trusses_at"]) * (panels * 4 + 6))
        add("roof", (panels + 1) * math.ceil(length / 4.88))
        slope = span / 2 * 1.03
        add("roof", 2 * (length / 0.61 + 1) * math.ceil(slope / 4.88))
        add("roof", 2 * slope * length / (0.15 * 4.88) + 2 * slope * length / (0.6 * 2.4))
        if part == "hall":
            add("ceiling", (span / 0.406) * math.ceil(length / 4.88) + span * length / (1.2 * 2.4))
    add("seats", sp["seats"]["count"] + sum(sp["balcony"]["seats"].values()) + sum(x["chairs"] for x in sp["boxes"]["list"]))
    return c


def trial_part(sp, lift=(0.6, 1.2)):
    """What the lab's trial built of this spec: the brick walls, the partitions, the ground and upper floors, the
    lobby's stairs (the README's 'every part the builder already has')."""
    full = members({**sp, "floors": [f for f in sp["floors"] if f["level"] in ("ground", "upper")],
                    "stairs": [s_ for s_ in sp["stairs"] if s_["from"] in ("ground", "upper")]}, lift)
    return {k: full.get(k, 0) for k in ("brick lifts", "partitions", "floors", "stairs")}


def member_report(old):
    """The member count and memory of this spec against the old one's and the hotel's (Sean, #1244: under the
    hotel's ~15.7k members and its memory, 18.6 KB a member measured, #1259)."""
    TRIAL_TOTAL, TRIAL_LIFTS = 6983, 3981
    ot = trial_part(old)
    k_lift = TRIAL_LIFTS / ot["brick lifts"]
    k_rest = (TRIAL_TOTAL - TRIAL_LIFTS) / (ot["partitions"] + ot["floors"] + ot["stairs"])
    lines = ["calibration on the 310-seat spec's trial: brick x%.2f, the rest x%.2f" % (k_lift, k_rest),
             "| Part | 310-seat spec | this spec, 0.6 x 1.2 m lifts | this spec, 1.2 x 2.4 m lifts |", "| --- | --- | --- | --- |"]
    tot = [0, 0, 0]
    rows = {}
    for i, (s_, lf) in enumerate(((old, (0.6, 1.2)), (spec(), (0.6, 1.2)), (spec(), (1.2, 2.4)))):
        m = members(s_, lf)
        for key, n in m.items():
            n = n * (k_lift if key == "brick lifts" else k_rest)
            rows.setdefault(key, [0, 0, 0])[i] = int(round(n))
            tot[i] += n
    for key, v in rows.items():
        lines.append("| %s | %d | %d | %d |" % (key, v[0], v[1], v[2]))
    lines.append("| **whole** | **%d** | **%d** | **%d** |" % tuple(int(round(t)) for t in tot))
    lines.append("| memory at 18.6 KB a member | %.0f MB | %.0f MB | %.0f MB |" % tuple(t * 18.6 / 1024 for t in tot))
    lines.append("| against the hotel (~15.7k, ~285 MB) | %.0f%% | %.0f%% | %.0f%% |" % tuple(100 * t / 15700 for t in tot))
    return lines


def draw_plans(sp, out):
    """The ground plan, the balcony and box level with the boxes' sightlines (north up, the street at the bottom,
    east on the right: facing 180 mirrors x), and two sections: A-A across the hall through the boxes looking at the
    stage, B-B along the east box's passage from the lobby to the yard (the way in and the getaway)."""
    from PIL import Image, ImageDraw, ImageFont
    S, M = 24, 46

    def font(n, b=False):
        try:
            return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf" % ("-Bold" if b else ""), n)
        except OSError:
            return ImageFont.load_default()
    pw, ph = int(W * S), int(D * S)
    HS = 17.0                                                # the sections' height in metres
    sec_w = int(D * S)
    body = max(ph + 40, int(2 * HS * S) + 40 + 60 + 50)
    im = Image.new("RGB", (2 * pw + sec_w + 5 * M + 40, M + body + 150), (246, 241, 230))
    d = ImageDraw.Draw(im)
    ink, red, blue, brick_c, gold = (25, 20, 15), (190, 40, 30), (40, 80, 170), (150, 62, 45), (176, 140, 40)
    green, grey, wood = (40, 140, 60), (150, 140, 125), (226, 206, 170)
    ns = sp["seats"]["count"]
    nb = sum(sp["balcony"]["seats"].values())
    nx = sum(b["chairs"] for b in sp["boxes"]["list"])
    d.text((M, 10), "McCready's Opera House (#1289): %d seats (%d floor, %d balcony, %d in two private boxes). "
           "Drawn from the spec (config/buildings/opera_house.json)" % (ns + nb + nx, ns, nb, nx), fill=ink, font=font(20, True))
    GROUND = ("ground", "stage")

    def P(ox, x, z):
        return (ox + (W - x) * S, M + 40 + (D - z) * S)

    def box(ox, r, **kw):
        a, b = P(ox, r[0], r[1]), P(ox, r[2], r[3])
        d.rectangle([min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1])], **kw)

    def dot(q, r, c):
        d.ellipse([q[0] - r, q[1] - r, q[0] + r, q[1] + r], fill=c)

    def label(q, text, size=12, c=ink):
        f = font(size, True)
        lines = text.split("\n")
        for k, ln in enumerate(lines):
            tw = d.textlength(ln, font=f)
            d.text((q[0] - tw / 2, q[1] - 6 + (k - (len(lines) - 1) / 2) * (size + 2)), ln, fill=c, font=f)

    def seat_rows(ox, rows, blocks, depth=0.45):
        for z in rows:
            for x0, x1, n in blocks:
                w = (x1 - x0) / n
                for k in range(n):
                    xa = x0 + k * w
                    box(ox, [xa + 0.03, z, xa + w - 0.03, z + depth], outline=(120, 40, 40))

    for ox, level in ((M, "ground"), (2 * M + pw + 20, "upper")):
        d.text((ox, M + 14), "GROUND FLOOR AND STAGE" if level == "ground" else "BALCONY AND BOX LEVEL (the boxes' sightlines)",
               fill=ink, font=font(15, True))
        # the building's outline: the cross
        for r in ([0, 0, W, Z_HALL0], [HX_E, Z_HALL0, HX_W, Z_PROSC], [0, Z_PROSC, W, D]):
            box(ox, r, fill=(252, 248, 238))
        for r in ([0, Z_HALL0, HX_E, Z_PROSC], [HX_W, Z_HALL0, W, Z_PROSC]):
            box(ox, r, fill=(228, 232, 214))
        if level == "ground":
            st = sp["seats"]
            seat_rows(ox, [st["first_row_z"] + k * st["row_pitch"] for k in range(st["rows"])], st["blocks"])
            sg = sp["stage"]
            box(ox, sg["pit"]["rect"], outline=ink, fill=(232, 222, 200))
            box(ox, sg["rect"], fill=wood, outline=ink)
            box(ox, sg["apron"]["rect"], fill=wood, outline=ink)
            box(ox, sg["scene_dock"]["rect"], fill=(214, 192, 152))
            box(ox, sg["trap"], outline=red, width=2)
            for stp in sg["apron"]["steps"]:
                hx, hz = stp["head"]
                box(ox, [hx, hz - stp["risers"] * stp["going"], hx + stp["width"], hz], outline=ink, fill=(236, 228, 210))
            tr = sg["footlights"]["trough"]
            for j in range(sg["footlights"]["count"]):
                dot(P(ox, tr[0] + (j + 0.5) * (tr[2] - tr[0]) / sg["footlights"]["count"], Z_APRON + 0.15), 2, (230, 150, 30))
            for s_ in sp["stairs"]:
                if s_["id"].startswith("lobby"):
                    hx, hz = s_["head"]
                    z0 = hz - (s_["risers"] - 1) * s_["going"]
                    box(ox, [hx, z0, hx + s_["width"], hz], outline=ink, fill=(236, 228, 210))
                    for k in range(1, s_["risers"] - 1):
                        z = z0 + k * s_["going"]
                        d.line([P(ox, hx, z), P(ox, hx + s_["width"], z)], fill=ink)
            for gx in sp["girders"]["x"]:
                z = IN_E
                while z < Z_PROSC:
                    d.line([P(ox, gx, z), P(ox, gx, min(z + 0.3, Z_PROSC))], fill=grey, width=1)
                    z += 0.6
            for b in sp["boxes"]["list"]:
                box(ox, b["rect"], outline=(200, 60, 60), width=1)
            label(P(ox, HIN_E + 0.8, 20.3), "box\nover", 9, (200, 60, 60))
            label(P(ox, HIN_W - 0.8, 20.3), "box\nover", 9, (200, 60, 60))
            label(P(ox, CX, 20.0), "FORESTAGE", 11)
            label(P(ox, CX, (Z_HALL0 + BAL_FRONT) / 2), "STANDING ROOM (under the balcony)", 11, grey)
            label(P(ox, HX_E / 2, (Z_HALL0 + Z_PROSC) / 2), "EAST\nCOURT", 11, (90, 110, 70))
            label(P(ox, (HX_W + W) / 2, (Z_HALL0 + Z_PROSC) / 2), "WEST\nCOURT", 11, (90, 110, 70))
        else:
            b = sp["balcony"]
            for t in b["tiers"]:
                shade = 236 - int((FOYER - t["y"]) / 0.6 * 30)
                box(ox, t["rect"], fill=(shade, shade - 18, shade - 32), outline=(170, 150, 130))
                if t["seats"]:
                    x0, z0, x1, z1 = t["rect"]
                    mid = (x0 + x1) / 2
                    seat_rows(ox, [z0 + 0.25], [[mid - t["seats"] / 2 * SEAT, mid + t["seats"] / 2 * SEAT, t["seats"]]], 0.4)
            d.line([P(ox, x, z) for x, z in b["rail"]], fill=gold, width=5)
            for bx in sp["boxes"]["list"]:
                box(ox, bx["passage"]["rect"], fill=(236, 214, 200))
                box(ox, bx["rect"], fill=(200, 60, 60), outline=ink)
                xf = bx["rect"][2] if bx["front"]["side"] == "+x" else bx["rect"][0]
                d.line([P(ox, xf, Z_APRON), P(ox, xf, Z_PROSC)], fill=gold, width=4)
            for hole in sp["ceilings"]["holes"]:
                box(ox, hole, outline=ink, fill=(236, 228, 210))
            label(P(ox, CX, (Z_STAGE0 + Z_DRESS) / 2), "OPEN OVER THE STAGE\n(the fly gallery on the west wall)", 11, grey)
            label(P(ox, CX, 16.2), "OPEN TO THE HALL\n(the chandelier)", 11, grey)
            label(P(ox, (HIN_E + PASS_E) / 2, 15.0), "P\nA\nS\nS\nA\nG\nE", 9)
            label(P(ox, (HIN_W + PASS_W_) / 2, 15.0), "P\nA\nS\nS\nA\nG\nE", 9)
            # sightlines to the east box's door (red: blocked by the box's back wall, green: sees it)
            sl = sp["boxes"]["sightlines"]
            dr, gs = sl["door"], sl["guest"]
            for row in sl["rows"]:
                e = row["eye"]
                c = green if row["door"] else red
                d.line([P(ox, e[0], e[1]), P(ox, dr[0], dr[1])], fill=c, width=1)
                dot(P(ox, e[0], e[1]), 3, c)
            dot(P(ox, dr[0], dr[1]), 5, ink)
            dot(P(ox, gs[0], gs[1]), 5, gold)
            q = P(ox, dr[0], dr[1])
            d.text((q[0] + 6, q[1] + 4), "door", fill=ink, font=font(10, True))
            q = P(ox, gs[0], gs[1])
            d.text((q[0] + 6, q[1] - 12), "guest", fill=(130, 100, 20), font=font(10, True))
        for c in sp["balcony"]["columns"]["at"]:
            dot(P(ox, c[0], c[1]), 4, (40, 40, 50))
        for r in sp["rooms"]:
            on_ground = r["level"] in GROUND
            if (level == "ground") != on_ground or r["level"] == "attic":
                continue
            if r["id"] in ("balcony", "hall", "pit", "apron", "court_e", "court_w") or r["id"].startswith(("passage", "box")):
                continue
            x0, z0, x1, z1 = r["rect"]
            name = r["id"].replace("_", " ").upper()
            label(P(ox, (x0 + x1) / 2, (z0 + z1) / 2), name if x1 - x0 > 3 else name.replace(" ", "\n"), 11 if x1 - x0 > 3 else 9)
        for w in sp["walls"]:
            wl = w.get("level", "ground")
            if w.get("partition") and ((level == "ground") != (wl in GROUND)):
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
                lv = op.get("level", wl if (w.get("partition") and not w.get("stone")) else "ground")
                if (level == "ground") != (lv in GROUND) or lv == "attic":
                    continue
                a, hw = float(op["at"]), float(op["width"]) / 2
                col = blue if op["type"] == "window" else red if op["type"] == "door" else (246, 241, 230)
                if op.get("bar"):
                    col = (240, 140, 0)
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
        label(P(ox, CX, -0.9), "MAIN STREET (south)", 13)

    # ---- the sections
    sx = 3 * M + 2 * pw + 40

    def Q(oy, u, y, u0=0.0):
        return (sx + (u - u0) * S, oy + (HS - y) * S)

    def rect(oy, u0, y0, u1, y1, **kw):
        a, b = Q(oy, u0, y0), Q(oy, u1, y1)
        d.rectangle([min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1])], **kw)

    def man(oy, u, y, c=ink, h=1.75):
        hd = Q(oy, u, y + h - 0.12)
        d.ellipse([hd[0] - 3, hd[1] - 3, hd[0] + 3, hd[1] + 3], outline=c, width=2)
        d.line([Q(oy, u, y + h - 0.25), Q(oy, u, y + 0.85)], fill=c, width=2)
        d.line([Q(oy, u, y + 0.85), Q(oy, u - 0.2, y)], fill=c, width=2)
        d.line([Q(oy, u, y + 0.85), Q(oy, u + 0.2, y)], fill=c, width=2)

    # A-A: across the hall at the boxes' middle, looking north at the proscenium (x mirrored like the plans)
    oy = M + 40
    d.text((sx, oy - 26), "SECTION A-A: ACROSS THE HALL THROUGH THE BOXES, LOOKING AT THE STAGE", fill=ink, font=font(15, True))

    def U(x):
        return W - x
    rect(oy, U(W), 0, U(0), HS, fill=(252, 248, 238))
    rect(oy, U(W), STAGE_TOP, U(0), 0, outline=grey)                                    # the stage house behind
    rect(oy, U(HIN_W), FLOOR, U(HIN_E), 0, fill=(200, 190, 170))
    pa = r3(22 * FT) / 2
    rect(oy, U(HIN_W), STAGE, U(HIN_E), FLOOR, fill=wood, outline=ink)                  # the forestage
    rect(oy, U(CX + pa), STAGE + r3(18 * FT), U(CX - pa), STAGE, outline=gold, width=3)  # the proscenium opening
    label(Q(oy, U(CX), STAGE + 3.0), "PROSCENIUM 22 x 18 ft\n(the stage beyond)", 11, (130, 100, 20))
    for hx, hin in ((HX_E, HIN_E), (HX_W, HIN_W)):
        rect(oy, U(hx), -1.2, U(hin), HALL_TOP, fill=brick_c)
    rect(oy, U(HIN_W), CEILING, U(HIN_E), CEILING - 0.05, fill=ink)
    # the hall's truss over (outline)
    d.line([Q(oy, U(HIN_E), PLATE), Q(oy, U(CX), PLATE + 1.5), Q(oy, U(HIN_W), PLATE)], fill=grey, width=2)
    d.line([Q(oy, U(HIN_E), PLATE), Q(oy, U(HIN_W), PLATE)], fill=grey, width=2)
    for b in sp["boxes"]["list"]:
        x0, _, x1, _ = b["rect"]
        rect(oy, U(x1), BOX_Y, U(x0), BOX_Y - 0.3, fill=(120, 80, 50))
        xf = x1 if b["front"]["side"] == "+x" else x0
        rect(oy, U(xf) - 0.05, BOX_Y + 0.75, U(xf) + 0.05, BOX_Y, fill=gold)
        d.line([Q(oy, U(xf), BOX_Y + 2.6), Q(oy, U(xf), BOX_Y + 0.9)], fill=(170, 30, 30), width=3)   # the drape
        rect(oy, U(x1), BOX_Y + 2.6, U(x0), BOX_Y + 2.55, fill=ink)
        rect(oy, U(xf) - 0.04, BOX_Y - 0.3, U(xf) + 0.04, FLOOR, fill=(40, 40, 50))     # the corner column (behind)
    gx = sp["boxes"]["sightlines"]["guest"][0]
    man(oy, U(gx), BOX_Y, (130, 100, 20), 1.25)
    man(oy, U(BOX_DOOR), BOX_Y, red)
    d.line([Q(oy, U(HIN_E + BOX_W + 0.3), BOX_Y), Q(oy, U(HIN_E + BOX_W + 0.3), STAGE)], fill=red, width=2)
    d.polygon([Q(oy, U(HIN_E + BOX_W + 0.3) - 0.15, STAGE + 0.3), Q(oy, U(HIN_E + BOX_W + 0.3) + 0.15, STAGE + 0.3),
               Q(oy, U(HIN_E + BOX_W + 0.3), STAGE)], fill=red)
    q = Q(oy, U(HIN_E + BOX_W + 0.45), (BOX_Y + STAGE) / 2)
    d.text((q[0] + 4, q[1] - 14), "3.5 m drop\nto the forestage", fill=red, font=font(11, True))
    for e in sp["boxes"]["sightlines"]["rows"]:
        if e["who"].startswith(("parquet, front row, west", "balcony, front row, middle", "an actor on the forestage")):
            ex, _, ey = e["eye"]
            c = green if e["guest"] else red
            d.line([Q(oy, U(ex), ey), Q(oy, U(gx), BOX_Y + 1.1)], fill=c, width=1)
            dot(Q(oy, U(ex), ey), 3, c)
    label(Q(oy, U(CX), 0.2), "HALL FLOOR", 10)
    label(Q(oy, U(HX_E / 2), 6.0), "EAST\nCOURT", 11, (90, 110, 70))
    label(Q(oy, U((HX_W + W) / 2), 6.0), "WEST\nCOURT", 11, (90, 110, 70))
    q = Q(oy, U(HIN_E), BOX_Y + 3.0)
    d.text((q[0] - 110, q[1] - 10), "EAST BOX", fill=ink, font=font(11, True))

    # B-B: along the east box's line (x = the box's door), looking east, the lobby on the left, the yard on the right
    oy2 = oy + int(HS * S) + 60
    d.text((sx, oy2 - 26), "SECTION B-B: ALONG THE EAST BOX'S PASSAGE, LOOKING EAST: THE WAY IN AND THE GETAWAY",
           fill=ink, font=font(15, True))
    rect(oy2, 0, 0, D, HS, fill=(252, 248, 238))
    rect(oy2, 0, CORNICE, Z_HALL0, 0, outline=grey)
    rect(oy2, Z_PROSC, STAGE_TOP, D, 0, outline=grey)
    for z0, z1, top in ((0, T_OUT, CORNICE), (Z_LOBBY, Z_HALL0, r3(FRONT_ROOF + 0.6)), (Z_PROSC, Z_STAGE0, STAGE_TOP),
                        (Z_DRESS, Z_DRESS0, STAGE_TOP), (Z_BACK, D, DRESS_TOP)):
        rect(oy2, z0, -1.2, z1, top, fill=brick_c)
    for y in (FOYER, ATTIC, FRONT_ROOF):
        rect(oy2, T_OUT, y, Z_LOBBY, y - 0.25, fill=(120, 80, 50))
    rect(oy2, T_OUT, FLOOR, Z_LOBBY, 0, fill=(200, 190, 170))
    rect(oy2, Z_HALL0, FLOOR, Z_APRON, 0, fill=(200, 190, 170))
    rect(oy2, Z_APRON, STAGE, Z_PROSC, FLOOR, fill=wood, outline=ink)                   # the forestage under the box
    rect(oy2, Z_STAGE0, STAGE, Z_DRESS, FLOOR, fill=wood, outline=ink)
    rect(oy2, Z_DRESS0, STAGE, Z_BACK, FLOOR, fill=wood, outline=ink)
    rect(oy2, Z_DRESS0, DRESS_UP, Z_BACK, DRESS_UP - 0.25, fill=(120, 80, 50))
    rect(oy2, Z_HALL0, FOYER, PASS_Z[0], FOYER - 0.3, fill=(120, 80, 50))                # the back aisle
    rect(oy2, PASS_Z[0], BOX_Y, Z_PROSC, BOX_Y - 0.25, fill=(120, 80, 50))              # the passage and the box
    rect(oy2, PASS_Z[0], BOX_Y + 2.35, Z_APRON, BOX_Y + 2.3, fill=ink)                  # the passage's ceiling
    rect(oy2, PASS_Z[0] - 0.05, BOX_Y + 2.3, PASS_Z[0] + 0.05, BOX_Y + 2.03, fill=ink)
    rect(oy2, PASS_Z[0] - 0.05, BOX_Y + 2.03, PASS_Z[0] + 0.05, BOX_Y, fill=(240, 140, 0))   # the barred door
    rect(oy2, Z_APRON - 0.05, BOX_Y + 2.6, Z_APRON + 0.05, BOX_Y + 2.0, fill=ink)
    rect(oy2, Z_APRON - 0.05, BOX_Y + 2.0, Z_APRON + 0.05, BOX_Y, fill=red)             # the box door
    rect(oy2, Z_PROSC, STAGE + 2.13, Z_STAGE0, STAGE, fill=red)                          # the wings' door under the box
    rect(oy2, Z_BACK, STAGE + 2.29, D, STAGE, fill=red)                                  # the stage door
    rect(oy2, T_OUT + 0.0, CEILING, Z_PROSC, CEILING - 0.05, outline=None)
    rect(oy2, Z_HALL0, CEILING, Z_PROSC, CEILING - 0.05, fill=ink)
    for k in range(3):
        rect(oy2, D + 0.3 * k, STAGE - FLOOR - 0.35 * k + 0.0, D + 0.3 * (k + 1), 0, fill=(200, 190, 170))
    # the stair up from the lobby to its landing
    d.line([Q(oy2, ST_FOOT, FLOOR), Q(oy2, ST_TOP, FOYER)], fill=ink, width=3)
    route = [(ST_FOOT - 0.5, FLOOR + 0.9), (ST_TOP, FOYER + 0.9), (PASS_Z[0] - 0.4, FOYER + 0.9), (PASS_Z[0] + 0.4, BOX_Y + 0.9),
             (Z_APRON + 0.6, BOX_Y + 0.9), (Z_APRON + 1.2, BOX_Y + 0.9), (Z_APRON + 1.4, STAGE + 0.9),
             (Z_STAGE0 + 0.6, STAGE + 0.9), (Z_BACK - 0.6, STAGE + 0.9), (D + 1.0, FLOOR)]
    d.line([Q(oy2, u, y) for u, y in route], fill=(200, 40, 140), width=3)
    man(oy2, Z_APRON + 1.0, BOX_Y, (130, 100, 20), 1.25)
    for z, txt, y in ((1.3, "LOBBY\n(the stair)", FLOOR + 2.5), ((Z_HALL0 + PASS_Z[0]) / 2, "back\naisle", FOYER + 2.6),
                      ((PASS_Z[0] + Z_APRON) / 2, "THE PASSAGE (0.9 m wide,\nshut off from the house)", BOX_Y + 1.75),
                      ((Z_APRON + Z_PROSC) / 2, "BOX", BOX_Y + 2.0), ((Z_APRON + Z_PROSC) / 2, "forestage", STAGE + 0.5),
                      ((Z_HALL0 + Z_APRON) / 2, "the side aisle under the passage", FLOOR + 1.6),
                      ((Z_STAGE0 + Z_DRESS) / 2, "STAGE (the east wing, the scene dock)", STAGE + 2.4),
                      ((Z_DRESS0 + Z_BACK) / 2, "dressing\nrooms", STAGE + 2.4), (D + 1.2, "yard", -0.6)):
        label(Q(oy2, z, y), txt, 10)
    q = Q(oy2, PASS_Z[0], BOX_Y - 0.6)
    d.text((q[0] - 30, q[1]), "barred door", fill=(200, 100, 0), font=font(10, True))
    q = Q(oy2, Z_APRON, BOX_Y - 0.6)
    d.text((q[0] - 20, q[1]), "box door", fill=red, font=font(10, True))
    q = Q(oy2, D - 0.2, STAGE + 2.6)
    d.text((q[0] - 40, q[1]), "stage door", fill=red, font=font(10, True))
    d.text((sx, oy2 + int((HS + 1.5) * S)), "magenta: the shooter's way, up the lobby stair, along the back aisle, through the "
           "barred door, along the passage,\ninto the box behind the guest; over the rail 3.5 m to the forestage, the door "
           "under the box into the wings,\nacross the stage, by the corridor out the stage door to the yard.", fill=ink, font=font(12))

    sl = sp["boxes"]["sightlines"]
    seen = ", ".join(r["who"] for r in sl["rows"] if r["door"])
    d.text((M, im.height - 96), "brick red: walls   blue: windows   red: doors   orange: the passages' barred doors   gold: "
           "the balcony's and boxes' rails   dots: cast-iron columns, footlights   dashed: girders\n"
           "sightlines to the east box's door (balcony plan): green sees it, red doesn't. The door is %.1f m behind the "
           "guest's chair, %d degrees off where he looks.\nWho sees the door: %s. Nobody in the parquet or the balcony "
           "does.   (north up, east on the right)" % (sl["door_to_guest"], sl["door_behind_guest_deg"], seen),
           fill=ink, font=font(13))
    x0, y0 = M + pw - 20 * FT * S, im.height - 30
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
        if a.startswith("--members="):
            import importlib.util
            spec_ = importlib.util.spec_from_file_location("old_opera", a.split("=", 1)[1])
            mod = importlib.util.module_from_spec(spec_)
            spec_.loader.exec_module(mod)
            print("\n".join(member_report(mod.spec())))
        if a == "--sizing":
            print("| Member | Size, span, load | Stress | Deflection (live) | |\n| --- | --- | --- | --- | --- |")
            for row in sizing():
                print("| " + " | ".join(row) + " |")
