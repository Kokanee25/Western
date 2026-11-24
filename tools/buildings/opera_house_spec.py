#!/usr/bin/env python3
"""Writes config/buildings/opera_house.json (McCready's Opera House, #1143: the building lab's step 2, as a
DESIGN: the lot, the levels, the walls and every opening, the rooms, the stairs, the balcony, the seats and
the new parts the builder needs) and draws its two plans, so a change is one number and a re-run:

    python3 tools/buildings/opera_house_spec.py [--plans=OUT.png]

Sean's answers (2026-11-24, the session on #1143): a new lot at Main Street's east end, north side (the front
faces south, facing 180); red brick with dressed stone quoins, base and window heads; MCCREADY'S OPERA HOUSE
1881 in the cornice; a horseshoe balcony. NOT BUILT: `status` says so; the builder can't lay brick, a curved
balcony, a raised stage or Howe trusses yet (the README's parts list).

Sizes: 60 x 110 ft (18.29 x 33.53 m), a ground-floor hall 54 ft long, ~480 seats (Central City's opera house,
1878, ~550, in a town of a few thousand). Walls from Kidder's rule for public halls (16-17 in brick for walls
30-40 ft high), seats at 32 in rows and 20 in widths (the period's theatre-chair catalogues).
Space: x along the front from its EAST corner (facing 180), z back from the front wall's outer face, y up from
the pad (the walk's street-edge ground). Metres.
"""
import json
import math
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
FT = 0.3048

W, D = round(60 * FT, 3), round(110 * FT, 3)       # 18.288 x 33.528
T_OUT = 0.43                                        # 17 in brick (four bricks), the outer walls
T_IN = 0.33                                         # 13 in brick, the proscenium (fire) wall
T_PART = 0.3                                        # 12 in brick, the lobby and dressing walls
FLOOR = 0.45                                        # the walk's top: three steps
STAGE = round(FLOOR + 3.5 * FT, 3)                  # the stage 3 ft 6 in over the hall
FOYER = round(FLOOR + 5.0, 3)                       # the upper floor (the foyer, the balcony's back)
PLATE = round(FLOOR + 10.0, 3)                      # the hall's wall plate, the trusses' bearing
CORNICE = round(14.0, 3)                            # the front's cornice top over the pad (46 ft)
PEDIMENT = round(15.9, 3)
STAGE_TOP = round(FLOOR + 13.5, 3)                  # the stage house's walls (roll drops, not flown)

# Lines along z (back from the front's outer face).
Z_VEST = 2.6                     # vestibule | lobby (the stair hall)
Z_LOBBY = 7.0                    # the lobby's back wall (brick, 12 in)
Z_HALL0 = round(Z_LOBBY + T_PART, 3)
Z_PIT0 = 19.8                    # the orchestra pit's rail
Z_APRON = 21.64                  # the apron's edge (4 ft out of the proscenium), the footlights
Z_PROSC = 22.86                  # the proscenium wall's hall face
Z_STAGE0 = round(Z_PROSC + T_IN, 3)
Z_DRESS = 29.9                   # the stage's back wall (12 in)
Z_DRESS0 = round(Z_DRESS + T_PART, 3)
IN_E, IN_W = T_OUT, round(W - T_OUT, 3)   # the hall's inside faces (x)
CX = round(W / 2, 3)


def r3(v):
    return round(v, 3)


def window(at, sill, h, w=1.07, level="ground", arch=True, **kw):
    o = {"type": "window", "level": level, "at": r3(at), "width": r3(w), "height": r3(h), "sill": r3(sill),
         "lights": 4}
    if arch:
        o["arch"] = "round"      # NEW: a semicircular head of gauged brick with a stone keystone
    o.update(kw)
    return o


def door(at, w, h, level="ground", **kw):
    o = {"type": "door", "level": level, "at": r3(at), "width": r3(w), "height": r3(h)}
    o.update(kw)
    return o


def walls():
    front_doors = [door(x, 1.68, 3.05, leaves=2, leaf="outward", arch="round", fanlight=0.84, glazed=True,
                        _doc="a pair of panelled and glazed doors 5 ft 6 in by 10 ft, a fanlight in the arch; outward for a crowd leaving (Chicago's code after 1871's fire)")
                   for x in (CX - 3.05, CX, CX + 3.05)]
    front = {
        "_doc": "The front on Main Street (facing south): red brick, stone quoins at both corners, a stone base course "
                "to the walk, stone sills and keystones; three arched doorways in the middle (a pair of cast-iron "
                "columns either side of the middle one), an arched window either side; five tall arched foyer windows "
                "over them, five small arched windows in the attic storey; the galvanized-iron cornice on brackets, "
                "its frieze MCCREADY'S OPERA HOUSE in gilt, the pediment's roundel 1881.",
        "id": "front", "line": [[0, 0], [W, 0]], "out": "-z", "stone": True, "brick": True, "thick": T_OUT,
        "top": CORNICE, "pediment": {"at": CX, "width": 6.1, "top": PEDIMENT, "roundel": "1881"},
        "openings": front_doors + [
            window(2.6, FLOOR + 0.75, 3.2), window(W - 2.6, FLOOR + 0.75, 3.2),
        ] + [window(CX + k * 3.05, FOYER + 0.45, 3.35, w=1.22, level="upper") for k in (-2, -1, 0, 1, 2)]
          + [window(CX + k * 3.05, FOYER + 4.7, 1.3, w=0.91, level="attic") for k in (-2, -1, 0, 1, 2)],
    }
    # The hall's side windows: four a side between the trusses' pilasters, sills over the balcony's side arm.
    bays = [Z_HALL0 + 2.0 + 3.66 * k for k in range(4)]
    def side(id_, x, out, lane_doc):
        return {
            "_doc": lane_doc, "id": id_, "line": [[x, 0], [x, D]], "out": out, "stone": True, "brick": True,
            "thick": T_OUT, "top": STAGE_TOP, "steps_down": [{"from_z": 0, "to_z": Z_PROSC, "top": PLATE + 1.0}],
            "pilasters": {"at_z": [r3(b + 1.83) for b in bays], "proj": 0.11, "width": 0.56},
            "openings": [window(z, FLOOR + 1.6, 4.6, w=1.22, shutters="iron") for z in bays] + [
                door(Z_PIT0 - 1.2, 1.52, 2.44, leaves=2, leaf="outward",
                     _doc="the hall's side exit to the lane, by the boxes"),
                door(Z_HALL0 + 0.9, 1.22, 2.29, leaf="outward",
                     _doc="the hall's back exit, from the cross aisle under the balcony"),
            ],
        }
    east = side("east", 0.0, "-x", "The east side, on the open ground where the East Road leaves town: plainer brick, "
                "pilasters between four tall arched windows (iron fire shutters), the stage house rising at the back.")
    west = side("west", W, "+x", "The west side, on the 8 ft lane to the undertaker's: as the east, its windows the same "
                "(they look at his wall, 3 m off); the lane is the hall's second way out.")
    back = {
        "_doc": "The back, on the yard and Back Street: the stage door up four steps, the scenery door at the stage's "
                "height (a wagon backs up to it: the yard's ground and a wagon bed are near the stage's level), the "
                "dressing rooms' windows on two floors.",
        "id": "back", "line": [[0, D], [W, D]], "out": "+z", "stone": True, "brick": True, "thick": T_OUT,
        "top": STAGE_TOP,
        "openings": [
            door(CX, 1.07, 2.29, _doc="the stage door, to the dressing rooms' corridor"),
            window(2.2, FLOOR + 1.0, 1.83, w=0.91, arch=False), window(W - 2.2, FLOOR + 1.0, 1.83, w=0.91, arch=False),
            window(5.6, FLOOR + 1.0, 1.83, w=0.91, arch=False), window(W - 5.6, FLOOR + 1.0, 1.83, w=0.91, arch=False),
            window(2.2, FOYER + 0.9, 1.83, w=0.91, arch=False, level="upper"),
            window(W - 2.2, FOYER + 0.9, 1.83, w=0.91, arch=False, level="upper"),
            window(5.6, FOYER + 0.9, 1.83, w=0.91, arch=False, level="upper"),
            window(W - 5.6, FOYER + 0.9, 1.83, w=0.91, arch=False, level="upper"),
        ],
    }
    # The scenery door is in the east wall's stage bay (the back is the dressing rooms'): 8 x 12 ft at the stage.
    east["openings"].append(door(Z_STAGE0 + 2.4, 2.44, 3.66, leaves=2, leaf="outward", sill=STAGE - FLOOR,
                                 _doc="the scenery door, at the stage's height: flats and trunks off a wagon's bed"))
    parts = [
        {"_doc": "The vestibule's back: the box office's wall (east) and the cloak room's (west), plaster on brick.",
         "id": "vestibule", "line": [[IN_E, Z_VEST], [IN_W, Z_VEST]], "out": "-z", "partition": True, "level": "ground",
         "stone": True, "brick": True, "thick": 0.23, "top": FOYER - FLOOR,
         "openings": [door(CX - IN_E, 3.05, 2.9, leaves=2, _doc="into the lobby: three pairs under one arch, held open"),
                      ]},
        {"id": "box_office", "line": [[4.6, T_OUT], [4.6, Z_VEST]], "out": "-x", "partition": True, "level": "ground",
         "openings": [window(1.6, 1.0, 0.6, w=0.6, arch=True, grille="brass",
                             _doc="the ticket window, onto the vestibule: a brass grille and a marble shelf")]},
        {"id": "cloak_room", "line": [[W - 4.6, T_OUT], [W - 4.6, Z_VEST]], "out": "+x", "partition": True,
         "level": "ground", "openings": [{"type": "hatch", "at": 1.6, "width": 1.5, "height": 1.0, "sill": 0.95,
                                          "_doc": "the cloak counter"}]},
        {"_doc": "The lobby's back wall (12 in brick, the balcony's back rests on it): the doors into the hall's "
                 "cross aisle under the balcony.",
         "id": "lobby_back", "line": [[IN_E, Z_LOBBY], [IN_W, Z_LOBBY]], "out": "-z", "partition": True,
         "level": "ground", "stone": True, "brick": True, "thick": T_PART, "top": FOYER - FLOOR, "bearing": True,
         "openings": [door(CX - IN_E - 3.0, 1.52, 2.44, leaves=2, leaf="swing"), door(CX - IN_E + 3.0, 1.52, 2.44, leaves=2, leaf="swing")]},
        {"_doc": "The proscenium wall: 13 in brick from the footing to the roof (the stage's fire wall), the arch 28 ft "
                 "wide and 20 ft high over the stage, framed in gilt plaster; doors either side from the boxes' "
                 "passages to the wings.",
         "id": "proscenium", "line": [[IN_E, Z_PROSC], [IN_W, Z_PROSC]], "out": "-z", "partition": True,
         "level": "ground", "stone": True, "brick": True, "thick": T_IN, "top": STAGE_TOP, "bearing": True,
         "openings": [{"type": "void", "at": r3(CX - IN_E), "width": r3(28 * FT), "height": r3(20 * FT), "sill": r3(STAGE - FLOOR),
                       "arch": "segmental", "_doc": "the proscenium opening over the stage's floor"},
                      door(1.3 - IN_E, 0.91, 2.13, sill=r3(STAGE - FLOOR)), door(W - 1.3 - IN_E, 0.91, 2.13, sill=r3(STAGE - FLOOR))]},
        {"id": "dressing_front", "line": [[IN_E, Z_DRESS], [IN_W, Z_DRESS]], "out": "-z", "partition": True,
         "level": "ground", "stone": True, "brick": True, "thick": T_PART, "top": STAGE_TOP, "bearing": True,
         "openings": [door(CX - IN_E, 1.22, 2.29, sill=r3(STAGE - FLOOR), _doc="the stage's back door to the corridor")]},
        {"id": "corridor_e", "line": [[CX - 0.76, Z_DRESS0], [CX - 0.76, D - T_OUT]], "out": "-x", "partition": True,
         "level": "ground", "openings": [door(1.0, 0.76, 2.03), door(2.2, 0.76, 2.03)]},
        {"id": "corridor_w", "line": [[CX + 0.76, Z_DRESS0], [CX + 0.76, D - T_OUT]], "out": "+x", "partition": True,
         "level": "ground", "openings": [door(1.0, 0.76, 2.03), door(2.2, 0.76, 2.03)]},
        {"id": "dressing_split_e", "line": [[IN_E, Z_DRESS0 + 1.45], [CX - 0.76, Z_DRESS0 + 1.45]], "out": "-z",
         "partition": True, "level": "ground", "openings": []},
        {"id": "dressing_split_w", "line": [[CX + 0.76, Z_DRESS0 + 1.45], [IN_W, Z_DRESS0 + 1.45]], "out": "-z",
         "partition": True, "level": "ground", "openings": []},
    ]
    return [front, east, west, back] + parts


def balcony():
    """The horseshoe: a back arm of four stepped rows over the cross aisle and the last rows, two side arms of two
    rows each running to the boxes, joined at the back corners by quarter circles. Carried on cast-iron columns at
    its front edge and bearing in pockets in the brick behind."""
    back_front = r3(Z_HALL0 + 3.4)          # the back arm's front rail
    side_depth = 2.3                        # the side arms (two rows)
    radius = 3.2                            # the corners' curve (on the rail's line)
    side_end = r3(Z_PIT0 - 0.4)             # the side arms stop at the boxes
    cols = []
    # Columns under the rail: along the back arm and down each side, ~3.6 m apart, clear of the aisles' lines.
    for x in (CX - 5.4, CX - 1.8, CX + 1.8, CX + 5.4):
        cols.append([r3(x), back_front])
    for z in (back_front + 3.6, back_front + 7.2, side_end):
        cols.append([r3(IN_E + side_depth), r3(z)])
        cols.append([r3(IN_W - side_depth), r3(z)])
    return {
        "_doc": "NEW (a curved balcony, `Balcony.horseshoe`): the deck's rows stepped up toward the walls (0.3 m a row), "
                "its rail's line a horseshoe; the curve laid as straight segments of 0.6 m (each a joist bay: a ball "
                "or a charge brings down a segment, not the whole sweep). The front a panelled, gilded fascia on the "
                "rail's line; cast-iron columns (6 in, hollow: they shatter, they don't bend) under it.",
        "kind": "horseshoe",
        "back_front_z": back_front, "back_rows": 4, "side_depth": side_depth, "side_rows": 2,
        "corner_radius": radius, "side_end_z": side_end,
        "front_rail_y": r3(FOYER - FLOOR - 1.2 + 0.0), "back_floor_y": r3(FOYER - FLOOR), "row_rise": 0.3,
        "row_going": r3(32 * 1.05 / 12 * FT * 12 / 12),
        "columns": {"kind": "cast_iron", "dia": 0.15, "at": cols},
        "seats": {"back": 96, "sides": 56},
    }


def boxes():
    out = []
    for side, x0, x1 in (("east", IN_E, IN_E + 2.0), ("west", IN_W - 2.0, IN_W)):
        for tier, y in (("lower", r3(STAGE - FLOOR + 0.3)), ("upper", r3(FOYER - FLOOR + 0.3))):
            out.append({"id": "box_%s_%s" % (side, tier), "rect": [r3(x0), r3(Z_PIT0 - 0.4), r3(x1), Z_PROSC],
                        "floor_y": y, "chairs": 4, "front": "curved, velvet rail, gilt; drapes tied back"})
    return out


def seats():
    """The parquet: twelve rows of 26 (6-14-6 in three blocks), 32 in rows, 20 in seats; side aisles under the
    balcony's side arms, two aisles between the blocks; a 4 ft cross aisle at the back under the balcony."""
    rows, pitch, seat = 12, r3(32 * FT / 12 * 12 / 12 * 1.0), r3(20 * FT / 12 * 12 / 12)
    pitch = r3(32 / 12 * FT)
    seat = r3(20 / 12 * FT)
    z0 = r3(Z_HALL0 + 1.22)
    aisle, side_aisle = 1.1, 0.95
    blocks = []
    x = IN_E + side_aisle
    for n in (6, 14, 6):
        blocks.append([r3(x), r3(x + n * seat), n])
        x += n * seat + aisle
    return {"_doc": "Folding theatre chairs on cast-iron standards screwed to the floor in rows (the front four rows on "
                    "runners, cleared for a ball: Sean's dances). The floor is level: a dance floor too.",
            "rows": rows, "row_pitch": pitch, "seat_width": seat, "first_row_z": z0,
            "last_row_z": r3(z0 + (rows - 1) * pitch), "blocks": blocks, "count": rows * 26}


def rooms():
    g = "ground"
    return [
        {"id": "vestibule", "level": g, "rect": [4.6, T_OUT, r3(W - 4.6), Z_VEST],
         "use": "a show night's crowd in out of the street; tickets bought at the window, bills on the walls"},
        {"id": "box_office", "level": g, "rect": [IN_E, T_OUT, 4.6, Z_VEST],
         "use": "the ticket seller behind the grille, the cash box, the seating chart, the night's takings"},
        {"id": "cloak_room", "level": g, "rect": [r3(W - 4.6), T_OUT, IN_W, Z_VEST], "use": "coats, hats and guns checked"},
        {"id": "lobby", "level": g, "rect": [IN_E, Z_VEST, IN_W, Z_LOBBY],
         "use": "the two stairs up to the foyer and balcony, the inner doors to the hall; waiting, smoking, the interval"},
        {"id": "hall", "level": g, "rect": [IN_E, Z_HALL0, IN_W, Z_PIT0],
         "use": "the parquet: ~312 seats; the crowd's place; a ball with the front rows cleared"},
        {"id": "pit", "level": g, "rect": [r3(CX - 5.0), Z_PIT0, r3(CX + 5.0), Z_APRON],
         "use": "the band: a piano, a fiddle, a cornet; a rail before the first row"},
        {"id": "stage", "level": g, "rect": [IN_E, Z_STAGE0, IN_W, Z_DRESS], "floor_y": r3(STAGE - FLOOR),
         "use": "the acts (#1143's later shows); the wings either side of the arch, the pin rail on the west wall, "
                "roll drops and flats; a trap in the middle"},
        {"id": "apron", "level": g, "rect": [r3(CX - 4.27), Z_APRON, r3(CX + 4.27), Z_PROSC], "floor_y": r3(STAGE - FLOOR),
         "use": "the footlights along its edge (kerosene, tin reflectors), the curtain's line behind it"},
        {"id": "dressing_1", "level": g, "rect": [IN_E, Z_DRESS0, r3(CX - 0.76), r3(Z_DRESS0 + 1.45)], "use": "the star's"},
        {"id": "dressing_2", "level": g, "rect": [IN_E, r3(Z_DRESS0 + 1.45), r3(CX - 0.76), r3(D - T_OUT)], "use": "the company's men"},
        {"id": "corridor", "level": g, "rect": [r3(CX - 0.76), Z_DRESS0, r3(CX + 0.76), r3(D - T_OUT)],
         "use": "the stage door to the stage; the stair to the upper dressing rooms"},
        {"id": "dressing_3", "level": g, "rect": [r3(CX + 0.76), Z_DRESS0, IN_W, r3(Z_DRESS0 + 1.45)], "use": "the company's women"},
        {"id": "dressing_4", "level": g, "rect": [r3(CX + 0.76), r3(Z_DRESS0 + 1.45), IN_W, r3(D - T_OUT)], "use": "trunks and costumes"},
        {"id": "foyer", "level": "upper", "rect": [4.6, T_OUT, IN_W, Z_LOBBY],
         "use": "the balcony's foyer: the five tall windows over Main Street, settees, the interval's promenade"},
        {"id": "office", "level": "upper", "rect": [IN_E, T_OUT, 4.6, Z_LOBBY],
         "use": "McCready's office over the box office: the safe, the bookings, the window on the street"},
        {"id": "balcony", "level": "upper", "rect": [IN_E, Z_HALL0, IN_W, Z_PIT0], "use": "the horseshoe: ~152 seats, the cheaper ones at the back"},
        {"id": "dressing_upper", "level": "upper", "rect": [IN_E, Z_DRESS0, IN_W, r3(D - T_OUT)],
         "use": "four more dressing rooms off the corridor's stair, the wardrobe"},
    ]


def stairs():
    """Two dog-leg stairs in the lobby's open well, one against each side wall: the outer flight up toward the
    back to a landing against the lobby's back wall, the inner flight back toward the front to the foyer (whose
    floor stops round the well). 26 risers of 0.192 for the 5 m, 0.25 goings: 13 a flight, 3.0 m runs."""
    n, going, width = 13, 0.25, 1.37
    run = (n - 1) * going
    out = []
    for side, outer, inner in (("east", IN_E, r3(IN_E + width)), ("west", r3(IN_W - width), r3(IN_W - 2 * width))):
        out.append({"id": "lobby_%s_1" % side, "head": [outer, r3(Z_LOBBY - 1.0)], "dir": "-z", "width": width,
                    "risers": n, "going": going, "from": "ground", "to": "landing",
                    "_doc": "the lobby's %s stair, outer flight: up toward the back to the landing (1 m deep, both flights' "
                            "width) against the lobby's back wall; a turned walnut newel, a red runner on brass rods "
                            "(the hotel's stair as a part)" % side})
        out.append({"id": "lobby_%s_2" % side, "head": [inner, r3(Z_LOBBY - 1.0 - run)], "dir": "+z", "width": width,
                    "risers": n, "going": going, "from": "landing", "to": "upper",
                    "_doc": "the inner flight, back toward the front, arriving at the foyer"})
    return out + [{"id": "dressing_stair", "head": [r3(CX - 0.6), r3(D - T_OUT - 0.1)], "dir": "+z", "width": 1.2,
                   "risers": 26, "going": 0.0, "from": "ground", "to": "upper", "_doc": "a steep boxed stair in the corridor (a ladder-stair: its going to the spec at build)"}]


def spec():
    return {
        "_doc": "McCready's Opera House (#1143): the building lab's step 2 as a DESIGN, written by "
                "tools/buildings/opera_house_spec.py (edit it, not this). NOT BUILT: the build waits for after the slice "
                "and Sean's OK on the sheet and plan; the builder's new parts are listed in "
                "experiments/building_lab/opera_house/README.md. Sizes here, the look on the sheet "
                "(experiments/building_lab/opera_house/sheet).",
        "format": 1, "id": "opera_house", "status": "design",
        "identity": {
            "owner": "Ezra McCready, who sold his share in the Argentine lode in 1880 and built the town something to be proud of (and a stage for his wife's sister)",
            "trade": "an opera house: travelling companies, melodrama, a singer with the band, lectures, the magic lantern, the Fourth of July ball, the Miners' Union meetings",
            "means": "the only brick building in Salt Creek but the bank: freighted-in brick, plate glass, iron, 480 opera chairs from Chicago, scenery painted in Denver",
            "age_and_repair": "1 year: the brick new and sharp, the walk already worn at the doors; one window in the lane boarded where a drunk put a bottle through",
            "clues": ["a stack of old show bills behind the box office", "cigar ash ground into the foyer's carpet",
                      "a banjo case and a pair of dancing shoes left in a dressing room", "chalk seat numbers on the backs of the chairs",
                      "a bucket of sand and a bucket of water by every footlight"],
        },
        "lot": {
            "_doc": "PROPOSED new lot (Sean, 2026-11-24): valley.json town.north past the undertaker's (x 106-128): a lane "
                    "x 128.0-130.4 (8 ft, the hall's side exit), the lot x 130.4-149.0, 18.6 m (61 ft) by the town's "
                    "125 ft depth to Back Street. Main Street's and Back Street's x [-125, 130] grow to 150 (the East "
                    "Road still leaves from x 130 to the south-east; at x 149 its north edge is at z ~+2, clear of the walk). "
                    "The ground (probed 2026-11-24, ValleyTerrain.height): -0.44 (west) to -0.58 (east) at the front line, "
                    "+0.18..+0.06 at 20 m back, +0.84..+0.38 at 30 m (Back Street's bank): 0.65-1.0 m of rise to the back "
                    "wall, so a pad dug level at the walk's street edge (saloon B's) with a bank left behind the yard.",
            "valley_lot": "opera_house", "side": "north", "at": [148.84, -0.5, -10.05], "facing": 180,
            "width": W, "depth": D, "yard": [0.0, D, W, r3(38.1 - 0.3)],
            "pad": {"y": -0.5, "x": [130.0, 149.6], "z": [-9.75, -44.6], "blend": 3.0},
            "walk": {"h": FLOOR, "awning": 0, "span": [130.4, 149.0], "door_x": 139.7,
                     "why": "A brick front needs no awning; three wide stone-edged steps at the doors for a crowd and ladies' skirts."},
            "footprint": [[0, 0, W, D]],
        },
        "levels": {
            "_doc": "The hall's floor at the walk's top; the stage 3 ft 6 in over it; the foyer and the balcony's back 5 m "
                    "over it (the lobby's ceiling 15 ft); the hall 32 ft to its plaster ceiling under the trusses' bottom "
                    "chords; the stage house 13.5 m (roll drops: a small town's stage didn't fly its scenery).",
            "floor": FLOOR, "stage": STAGE, "upper": FOYER, "plate": PLATE, "ceiling": r3(FLOOR + 9.75),
            "stage_top": STAGE_TOP, "cornice": CORNICE, "pediment": PEDIMENT, "roof_pitch": "3/12 behind the parapets",
        },
        "frame": {
            "_doc": "NEW: a load-bearing brick building with timber floors and roof. Walls from Kidder's Building "
                    "Construction and Superintendence (public halls: 17 in to 40 ft), lime mortar; the hall's roof on Howe "
                    "trusses (timber chords and diagonals, iron rods for the verticals: Haupt, Hatfield) spanning the "
                    "57 ft between the side walls at 12 ft centres, bearing on brick pilasters; the balcony and upper "
                    "floors on joists in pockets in the brick.",
            "brick_wall": {"_doc": "NEW (`BrickWall`): bricks in courses (8 x 4 x 2.25 in, 3/8 in joints), common bond "
                                   "(a header course every sixth), each member a run of bricks a course high, so a ball "
                                   "chips a face and a charge brings down courses (masonry lab: brick as its kind); "
                                   "dressed stone quoins, base, sills and keystones as the jail's stone pieces",
                           "thick": T_OUT, "brick": [0.203, 0.102, 0.057], "joint": 0.0095, "bond": "common_6",
                           "quoin": [0.46, 0.3], "base": {"height": 0.9, "stone": "buff_sandstone"},
                           "footing_below": 1.2, "footing_spread": 0.2},
            "truss": {"kind": "howe", "span": r3(IN_W - IN_E), "at_z": [r3(Z_HALL0 + 1.83 + 3.66 * k) for k in range(5) if Z_HALL0 + 1.83 + 3.66 * k < Z_PROSC],
                      "depth": 2.0, "chord": [0.2, 0.3], "web": [0.15, 0.2], "rod": 0.032, "panels": 8},
            "joist": {"section": [0.076, 0.305], "spacing": 0.406, "_doc": "3 x 12 at 16 in: the balcony and the foyer at "
                      "100 lb/ft2 (a crowd standing), the dance floor's 70 too"},
            "column": {"kind": "cast_iron", "dia": 0.15, "wall": 0.019},
        },
        "walls": walls(),
        "balcony": balcony(),
        "boxes": boxes(),
        "seats": seats(),
        "stage": {
            "_doc": "NEW (`Stage`): saloon B's stage grown up: a raised floor of members on joists and posts, an apron "
                    "with the footlights' trough, a trap between two joists (the church's hatch rule), the drop curtain "
                    "and three roll drops on battens hung from the gridiron, wings of flats, a pin rail with ropes "
                    "(the Rope part). Lit by the footlights and border lamps (OilLamps).",
            "floor_y": r3(STAGE - FLOOR), "rect": [IN_E, Z_STAGE0, IN_W, Z_DRESS],
            "apron": [r3(CX - 4.27), Z_APRON, r3(CX + 4.27), Z_PROSC],
            "proscenium": {"width": r3(28 * FT), "height": r3(20 * FT)},
            "footlights": {"count": 14, "kind": "kerosene, tin reflectors"},
            "drops": ["drop curtain: a painted lake under mountains in a painted gilt frame", "a parlour", "a forest", "a street"],
            "trap": [r3(CX - 0.6), r3(Z_STAGE0 + 2.4), r3(CX + 0.6), r3(Z_STAGE0 + 3.6)],
        },
        "front": {
            "sign": "MCCREADY'S OPERA HOUSE", "year": "1881",
            "cornice": {"kind": "bracketed", "top": CORNICE, "depth": 1.1, "brackets": 14,
                        "_doc": "NEW (`Cornice`, shared with the hotel): galvanized sheet iron on a timber frame, painted "
                                "stone-colour, its brackets in pairs, a frieze for the gilt name (the game's own lettering)"},
            "lamps": [{"kind": "lamp_standard", "x": r3(CX - 4.5)}, {"kind": "lamp_standard", "x": r3(CX + 4.5)}],
            "posters": [
                "THE MORTGAGE ON HAZEL FARM, or a Daughter's Sacrifice: a melodrama in four acts",
                "The Hartwell Shakespearean Company: HAMLET and RICHARD III, two nights only",
                "Professor Alcott's Magic Lantern: Wonders of the Yellowstone, sixty views",
                "Signor Valetti, Prestidigitator: the Vanishing Lady",
                "Miss Lottie Byrne, the Colorado Nightingale, with the Salt Creek Cornet Band",
            ],
        },
        "rooms": rooms(),
        "stairs": stairs(),
        "materials": {"_doc": "From the material library by name when built; new: brick, sandstone, plaster on lath, "
                              "wallpaper, red plush, gilt, galvanized iron. Floors `floor_fir_worn`; the lobby's woods walnut "
                              "(FN3 is parked: its walnut figure needs the material lab first)."},
        "sources": [
            "F. E. Kidder, Building Construction and Superintendence (1890s eds.): brick wall thicknesses for public halls",
            "Herman Haupt, General Theory of Bridge Construction (1851) and Hatfield, The American House-Carpenter (1880): Howe trusses",
            "Central City Opera House (1878, stone, ~550 seats) and the Tabor Opera House, Leadville (1879, brick, three storeys): size and arrangement",
            "Wright Opera House, Ouray (1888): a cast-iron front on a mining-town opera house (a little late: the columns only)",
            "A. H. Andrews & Co. (Chicago) opera-chair catalogues, 1880s: 20 in seats on cast-iron standards, 30-32 in rows",
        ],
    }


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
    ink, red, blue, brick, gold = (25, 20, 15), (190, 40, 30), (40, 80, 170), (150, 62, 45), (176, 140, 40)
    d.text((M, 12), "McCready's Opera House (#1143): the plans from the spec (config/buildings/opera_house.json)",
           fill=ink, font=font(20, True))

    def P(ox, x, z):
        return (ox + (W - x) * S, M + 40 + (D - z) * S)

    def box(ox, r, **kw):
        a, b = P(ox, r[0], r[1]), P(ox, r[2], r[3])
        d.rectangle([min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1])], **kw)

    for k, (ox, level) in enumerate(((M, "ground"), (2 * M + pw + 40, "upper"))):
        d.text((ox, M + 14), "GROUND FLOOR" if level == "ground" else "UPPER: FOYER, BALCONY, BOXES", fill=ink, font=font(16, True))
        box(ox, [0, 0, W, D], fill=(252, 248, 238))
        for r in sp["rooms"]:
            if r["level"] != level:
                continue
            x0, z0, x1, z1 = r["rect"]
            c = P(ox, (x0 + x1) / 2, (z0 + z1) / 2)
            name = r["id"].replace("_", " ").upper()
            f = font(12 if x1 - x0 > 3 else 10, True)
            tw = d.textlength(name, font=f)
            yoff = {"hall": -ph * 0.17, "balcony": -ph * 0.17}.get(r["id"], -8)
            d.text((c[0] - tw / 2, c[1] + yoff), name, fill=ink, font=f)
        if level == "ground":
            st = sp["seats"]
            for row in range(st["rows"]):
                z = st["first_row_z"] + row * st["row_pitch"]
                for x0, x1, n in st["blocks"]:
                    for s in range(n):
                        xa = x0 + s * st["seat_width"]
                        box(ox, [xa + 0.03, z, xa + st["seat_width"] - 0.03, z + 0.45], outline=(120, 40, 40))
            box(ox, sp["rooms"][[r["id"] for r in sp["rooms"]].index("pit")]["rect"], outline=ink, fill=(232, 222, 200))
            sg = sp["stage"]
            box(ox, sg["rect"], fill=(226, 206, 170), outline=ink)
            box(ox, sg["apron"], fill=(226, 206, 170), outline=ink)
            box(ox, sg["trap"], outline=red, width=2)
            c = P(ox, CX, (sg["rect"][1] + sg["rect"][3]) / 2)
            d.text((c[0] - 22, c[1] - 30), "STAGE", fill=ink, font=font(14, True))
            for j in range(sg["footlights"]["count"]):
                x = sg["apron"][0] + (j + 0.5) * (sg["apron"][2] - sg["apron"][0]) / sg["footlights"]["count"]
                c = P(ox, x, Z_APRON + 0.1)
                d.ellipse([c[0] - 2, c[1] - 2, c[0] + 2, c[1] + 2], fill=(230, 150, 30))
            for s in sp["stairs"]:
                if s["id"].startswith("lobby"):
                    hx, hz = s["head"]
                    run = (s["risers"] - 1) * s["going"]
                    z0, z1 = (hz - run, hz) if s["dir"] == "-z" else (hz, hz + run)
                    box(ox, [hx, z0, hx + s["width"], z1], outline=ink, fill=(236, 228, 210))
                    for k in range(1, s["risers"] - 1):
                        a, b = P(ox, hx, z0 + k * s["going"]), P(ox, hx + s["width"], z0 + k * s["going"])
                        d.line([a, b], fill=ink)
                    if s["dir"] == "-z":
                        lx = hx if s["id"].startswith("lobby_east") else hx - s["width"]
                        box(ox, [lx, hz, lx + 2 * s["width"], hz + 1.0], outline=ink, fill=(236, 228, 210))
        else:
            b = sp["balcony"]
            bf, sd, r_ = b["back_front_z"], b["side_depth"], b["corner_radius"]
            # The deck: the back arm and the two side arms, the corners' curve on the rail.
            box(ox, [IN_E, Z_HALL0, IN_W, bf], fill=(230, 214, 200))
            box(ox, [IN_E, bf, IN_E + sd, b["side_end_z"]], fill=(230, 214, 200))
            box(ox, [IN_W - sd, bf, IN_W, b["side_end_z"]], fill=(230, 214, 200))
            pts = []
            pts += [P(ox, IN_E + sd, b["side_end_z"]), P(ox, IN_E + sd, bf + r_)]
            for a in range(0, 91, 10):
                t = math.radians(a)
                pts.append(P(ox, IN_E + sd + r_ - r_ * math.cos(t), bf + r_ - r_ * math.sin(t)))
            for a in range(90, -1, -10):
                t = math.radians(a)
                pts.append(P(ox, IN_W - sd - r_ + r_ * math.cos(t), bf + r_ - r_ * math.sin(t)))
            pts += [P(ox, IN_W - sd, b["side_end_z"])]
            d.line(pts, fill=gold, width=5)
            for c in b["columns"]["at"]:
                q = P(ox, c[0], c[1])
                d.ellipse([q[0] - 5, q[1] - 5, q[0] + 5, q[1] + 5], fill=(40, 40, 50))
            for bx in sp["boxes"]:
                if bx["id"].endswith("upper"):
                    box(ox, bx["rect"], fill=(200, 60, 60), outline=ink)
            box(ox, [IN_E, Z_STAGE0, IN_W, Z_DRESS], outline=(150, 140, 125))
            c = P(ox, CX, (Z_STAGE0 + Z_DRESS) / 2)
            d.text((c[0] - 60, c[1] - 8), "OPEN OVER THE STAGE", fill=(120, 110, 95), font=font(12, True))
            c = P(ox, CX, Z_HALL0 + 8.0)
            d.text((c[0] - 70, c[1]), "OPEN TO THE HALL\n(the chandelier)", fill=(120, 110, 95), font=font(12, True))
        for w in sp["walls"]:
            if w.get("level", "ground") != "ground" and w.get("partition"):
                continue
            if level == "upper" and w["id"] in ("vestibule", "box_office", "cloak_room"):
                continue
            (ax, az), (bx_, bz) = w["line"]
            t = float(w.get("thick", 0.12))
            o = w["out"]
            if w.get("partition"):
                r = [ax, az, bx_, bz] if not w.get("stone") else [ax, az, bx_, bz + t]
                if not w.get("stone"):
                    r = [ax - 0.06, az - 0.06, bx_ + 0.06, bz + 0.06]
            elif o == "-z":
                r = [ax, az, bx_, az + t]
            elif o == "+z":
                r = [ax, az - t, bx_, bz]
            elif o == "-x":
                r = [ax, az, ax + t, bz]
            else:
                r = [ax - t, az, ax, bz]
            box(ox, r, fill=brick if w.get("brick") else ink)
            for op in w.get("openings", []):
                lv = op.get("level", "ground")
                if (level == "ground") != (lv == "ground"):
                    continue
                if lv == "attic":
                    continue
                a, hw = float(op["at"]), float(op["width"]) / 2
                col = blue if op["type"] == "window" else red if op["type"] == "door" else (246, 241, 230)
                if w["line"][0][1] == w["line"][1][1]:   # along x
                    a += ax
                    zz = az if o in ("-z",) or w.get("partition") else az - t
                    box(ox, [a - hw, zz, a + hw, zz + t], fill=col)
                else:
                    a += az
                    xx = ax if o == "-x" else ax - t
                    box(ox, [xx, a - hw, xx + t, a + hw], fill=col)
        c = P(ox, CX, -0.6)
        d.text((c[0] - 60, c[1] + 4), "MAIN STREET (south)", fill=ink, font=font(13, True))
    d.text((M, im.height - 60), "brick red: walls   blue: windows   red: doors   gold: the horseshoe's rail   dots: cast-iron "
           "columns, footlights\nseats: %d parquet + %d balcony + %d in boxes = %d   (north up, east on the right)"
           % (sp["seats"]["count"], sum(sp["balcony"]["seats"].values()), 16,
              sp["seats"]["count"] + sum(sp["balcony"]["seats"].values()) + 16), fill=ink, font=font(14))
    # A scale bar: 20 ft.
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
