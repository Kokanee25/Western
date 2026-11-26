#!/usr/bin/env python3
"""The Railroad Saloon's spec (#1285, the building lab's step 2): writes config/buildings/railroad_saloon.json.

Re-run it whenever a number moves (never edit the JSON by hand):

    python3 experiments/building_lab/railroad_saloon/make_spec.py          # writes the spec, prints the collapse's numbers

The Silver Spike (Sean's name, 2026-11-26): the cheapest drinking house in Salt Creek, on Back Street by the tracks,
two storeys, the bar below and a bare dance floor upstairs whose girder the Baron's men saw (Payday Night). Sean's
picks of 2026-11-26 (this session's chat): raw board-and-batten with the gable to the street; a short built bar with
barrels on racks behind it; one outside stair up the west side; the piano carried up and the band upstairs;
24 x 30 ft on the 12 x 9 m lot.

Coordinates as FORMAT.md: a north-side lot facing south (facing 180), so x runs WEST from the building's EAST front
corner, z runs back (north) from the front wall's face, y up from the pad (the front's ground). Feet to metres here;
sizes rough-sawn full (a 2x10 is 2 by 10 in), as a cheap Colorado builder's lumber of 1881 was.
"""
import json
import os

FT = 0.3048
IN = 0.0254
ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
OUT = os.path.join(ROOT, "config", "buildings", "railroad_saloon.json")


def r(v):
	return round(v, 3)


# ---------------------------------------------------------------- the box
W = 24 * FT            # 7.315, across the front (x)
D = 30 * FT            # 9.144, front to back (z)
WALL = 0.1             # the studs' depth inside the outer face (2x4 full)
GX = r(W / 2)          # the girder's line, down the middle front to back
POSTS_Z = [r(10 * FT), r(20 * FT)]   # the girder's two posts: three bays of 10 ft
BAY = (POSTS_Z[0], POSTS_Z[1])       # the middle bay: over the bar, the one sawn

# ---------------------------------------------------------------- the levels (local y, the pad at 0)
G_TOP = 0.375          # piers flush with the pad, a 6x6 sill, 2x8 ground joists, 1 in boards: one plank step up
CLEAR = 7.5 * FT       # under the girder (2.29 m): a tall man's hat clears it
GIRDER = (6 * IN, 12 * IN)           # 6x12: the book's limit for a dancing crowd, a cheap man's choice (below)
JOIST = (2 * IN, 10 * IN)            # 2x10 at 16 in over 11 ft 8 in (the doctor's rule: men standing need 2x10 over 13 ft)
BOARD = 1 * IN
GIRDER_BOT = r(G_TOP + CLEAR)
GIRDER_TOP = r(GIRDER_BOT + GIRDER[1])
U_TOP = r(GIRDER_TOP + JOIST[1] + BOARD)
KNEE = 4 * FT          # the upstairs walls to the plate: benches under them, the room open to the roof
PLATE = r(U_TOP + KNEE)
PITCH = 10 / 12        # a steep roof (snow), 39.8 degrees
RIDGE = r(PLATE + (W / 2) * PITCH)

# ---------------------------------------------------------------- the outside stair (west wall, +x)
RISERS = 17
RISE = U_TOP / RISERS
GOING = 10 * IN
STAIR_W = 3.5 * FT     # 1.07
LAND = (r(D + 0.05), r(D + 1.15))      # the landing behind the back wall, from the stair's head to the gable's door
LAND_X0 = 4.95                          # its east end, past the door (its post clear of the back door's steps)
HEAD_Z = LAND[0]
FOOT_Z = r(HEAD_Z - (RISERS - 1) * GOING)
SX0, SX1 = r(W), r(W + STAIR_W)
BACK_DOOR_X = 5.7                       # the back door and the upstairs door over it, off the girder's wall post (3.66)

# ---------------------------------------------------------------- the collapse's numbers (USDA Wood Handbook)
# Ponderosa pine (western yellow pine, the Colorado mills' wood), Wood Handbook (FPL-GTR-282, 2021) Table 5-3a, clear,
# 12 % moisture: MOR 65 MPa (9,400 psi), MOE 8.9 GPa; green MOR 35 MPa (5,100 psi). A year-old rough timber with knots
# (strength ratio about 0.5, Handbook ch. 7) breaks at about 4,500 psi in bending; the period books allowed about
# 1,000 psi working stress for pine (Kidder 1895; Hatfield 1880), a factor of 4-5.
RUPTURE_PSI = 4500.0
WORKING_PSI = 1000.0
LB_PER_KG = 2.2046
FT2_PER_M2 = 10.764


def psf(kg_per_m2):
	return kg_per_m2 * LB_PER_KG / FT2_PER_M2


def collapse_numbers():
	"""The girder's middle bay: its moment under each night and its strength whole and sawn (lb-in)."""
	span_ft = (BAY[1] - BAY[0]) / FT                  # 10 ft
	trib_ft = W / 2 / FT                               # 12 ft of floor each side's half-spans
	b_in, d_in = GIRDER[0] / IN, GIRDER[1] / IN
	inside = (W - 2 * WALL) * (D - 2 * WALL)          # 63.6 m2
	dead = 3.0 + 2.5 + 0.5                             # psf: 2x10 at 16 in (~3), 1 in boards (~2.5), benches and lamps
	men = 75.0                                         # kg a man in boots, a woman a little less: the crowd's mean
	# A normal night: 15 upstairs, a reel set of eight dancing, the rest on the benches.
	normal = psf(15 * men / inside) * 1.5              # stamping ~1.5x a man's weight (dynamic, a jig on a springy floor)
	# Payday packed: 40 upstairs (four in the band and the piano at the back wall), 28 dancing in the middle 36 m2.
	packed_mid = psf(28 * men / 36.0) * 1.8            # a stamping reel in step: 1.8x (crowds in step reach 2x)
	piano_lb = 300 * LB_PER_KG                          # an upright with its iron frame, ~300 kg, at the back wall (bay 3)

	def moment(live):                                  # simply supported over the bay (the girder is jointed over its posts)
		w = (dead + live) * trib_ft                    # lb/ft along the girder
		return w * span_ft ** 2 / 8 * 12               # lb-in

	def strength(depth_in, stress):
		return stress * b_in * depth_in ** 2 / 6

	whole = strength(d_in, RUPTURE_PSI)
	design = 70.0                                      # psf, a dance floor (Hatfield's hall; saloon B's check)
	left_in = 3.0                                      # the sawn girder: cut 9 of its 12 in from below, 3 in left
	sawn = strength(left_in, RUPTURE_PSI)
	return {
		"span_ft": span_ft, "trib_ft": trib_ft, "dead_psf": dead,
		"normal_live_psf": normal, "packed_live_psf": packed_mid, "design_live_psf": design,
		"m_quiet": moment(0.0), "m_normal": moment(normal), "m_packed": moment(packed_mid), "m_design": moment(design),
		"working_stress_at_design_psi": moment(design) / (b_in * d_in ** 2 / 6),
		"whole": whole, "sawn_left_in": left_in, "sawn": sawn, "piano_lb": piano_lb,
	}


N = collapse_numbers()

# ---------------------------------------------------------------- the spec
spec = {
	"_doc": ("The Railroad Saloon, THE SILVER SPIKE (#1285; Sean 2026-11-26 on #1097: Payday Night's floor falls here, the "
		"dance floor upstairs over the bar; his picks in the session's chat the same day). Written by "
		"experiments/building_lab/railroad_saloon/make_spec.py: re-run it, never edit this by hand. Step 2 only: not built "
		"yet (the build is the next issue); fields marked NEW are what the builder may need adding."),
	"format": 1,
	"id": "railroad_saloon",
	"identity": {
		"owner": "a railroad contractor's ex-foreman who put it up in a fortnight in 1881 for the track gangs and never painted it",
		"trade": "a cheap saloon: rotgut from the barrel, keg beer, a stove; a bare dance floor upstairs on paydays",
		"means": "the cheapest drinking house in town: raw board-and-batten, a crude sign, one outside stair, nothing planed",
		"age_and_repair": "1 year: soot from the engines on the back, the floor's sawdust never swept out, a cracked window stuffed with a sack",
		"clues": ["Lowry Bros. XXX tapped on the rack behind the bar (#1222)", "spittoons nobody aims for",
			"the dance floor's boards worn pale in a ring where the reels go round", "a track gang's tally chalked on the back door",
			"a shovel and a lantern by the back door for the men from the pens"],
		"built": 1881, "now": 1882,
	},
	"lot": {
		"_doc": ("valley.json town.extras 'second_saloon' (centre [-42, -62], 12 x 9 m: x -48..-36, z -66.5..-57.5), between Back "
			"Street (z -54.25..-48.15) and the tracks, by the stock pens and the team track. The building on the lot's west "
			"half, its back wall on the lot's back line; 30 ft runs 0.14 m past the lot's front edge into the 3.25 m verge "
			"before Back Street (no walk on Back Street). Its east front corner is the origin. The outside stair stands on the "
			"lot's west edge (x -47.92); the 3.5 m yard east holds the empty kegs, the privy and the way round to the pens."),
		"valley_lot": "second_saloon",
		"walk": False,
		"side": "north",
		"at": [r(-36.0 - 3.5 - 0.0), 2.17, r(-66.5 + D)],
		"facing": 180,
		"pad": {"_doc": ("Probed (Python ValleyPlan terrain, this session): the ground rises 0.66 m front to back (world 2.18 at "
			"the front wall, 2.84 at the back) and falls 0.06 m west to east. The pad dug level at the front's ground (2.17) "
			"over the building, the stair and the yard, and 1.5 m on behind the back wall (off the lot, toward the tracks) so the "
			"back door opens onto the pad two steps down, the 0.7 m cut bank behind it. The build adds the lot's spec and pad "
			"to valley.json and re-bakes."),
			"y": 2.17, "rise_front_to_back": 0.66, "behind": 1.5},
		"width": r(W), "depth": r(D),
		"yard": [-3.5, 0.0, 0.0, r(D)],
		"footprint_with_stair": [-3.5, 0.0, SX1, LAND[1]],
	},
	"levels": {
		"_doc": (f"Low and cheap: the floor one plank step over the pad; 7 ft 6 in clear under the girder (8 ft 6 in to the "
			f"joists), the dance floor at {U_TOP}; 4 ft walls upstairs to the plate (benches under them) and a 10/12 roof open "
			f"to its rafters, the ridge at {RIDGE}."),
		"ground": {"top": G_TOP},
		"upper": {"top": U_TOP},
		"plate": PLATE,
		"false_front": 0.0,
		"roof_pitch": 39.81,
		"roof_from": -0.3,
		"roof_to": r(D + 0.3),
	},
	"frame": {
		"_doc": ("A balloon frame, cheap (Bell 1858; Woodward 1865): rough-sawn full sizes, studs sill to plate, the dance floor's "
			"joists on a 1x6 ribbon let into the side walls' studs and on the one girder down the middle, on two posts. Sized "
			"by the USDA Wood Handbook for ponderosa pine (below and README.md)."),
		"stacked": True,
		"foundation": {"_doc": "dry rubble piers and a stone sill course just to the pad: a cheap man's footing", "wood": "stone", "thick": 0.4, "bottom": -0.3, "top": 0.0, "piece": 1.5},
		"sill": {"section": [0.15, 0.15], "wood": "framing"},
		"pier": {"size": 0.4, "wood": "stone"},
		"girder": {"section": [0.15, 0.2], "wood": "framing", "pier_every": 1.83},
		"joist": {"_doc": "the bar room's floor: 2x8 at 24 in between the ground girders (10 ft or less)", "section": [0.05, 0.2], "spacing": 0.61, "wood": "framing"},
		"dance_joist": {"_doc": (f"2x10 at 16 in over 11 ft 8 in, side wall to girder: {round(N['working_stress_at_design_psi'])} psi in the girder "
			"at Hatfield's 70 lb/ft2 dance load; the joists ~660 psi under the 1,000 psi the books allowed. Cut 12 mm short "
			"(end_gap) so a fallen bay doesn't jam."), "section": [r(JOIST[0]), r(JOIST[1])], "spacing": 0.406, "wood": "framing"},
		"floor_board": {"_doc": "wide 8 in boards, 1 in, square-edged (no tongue: the dust sifts through)", "width": 0.2, "thick": r(BOARD), "wood": "floor"},
		"stud": {"section": [0.05, 0.1], "spacing": 0.406, "wood": "framing",
			"tall": {"_doc": "the side walls' studs 2x6: they take the roof's thrust over the 4 ft knee walls above the ribbon", "section": [0.05, 0.15], "walls": ["yard", "stair"]}},
		"plate": {"height": 0.1},
		"ribbon": {"section": [0.025, 0.15]},
		"header": {"height": 0.15},
		"post": {"_doc": "6x6 rough posts on stone footings under the girder", "section": [0.15, 0.15], "wood": "framing", "look": "wood:int_timber", "chamfer": 0.012},
		"beam": {"_doc": "THE GIRDER: one 6x12, jointed over its posts (three pieces)", "section": [r(GIRDER[0]), r(GIRDER[1])], "wood": "framing", "look": "wood:int_timber", "chamfer": 0.012},
		"bracket": {"reach": 0.3, "thick": 0.08},
		"wall_post": {"section": [0.15, 0.1]},
		"rafters": {"_doc": ("2x6 at 24 in, 10/12, on the plates against a 1x8 ridge; a 2x6 collar on EVERY pair 8 ft over the dance "
			"floor (raised ties: the lamps hang from them); 1x8 roof boards, tar paper and battens; 12 in eaves."),
			"rafter": [0.05, 0.15], "spacing": 0.61, "ridge": [0.025, 0.19], "collar": [0.05, 0.15], "collar_every": 1,
			"collar_down": r((RIDGE - (U_TOP + 8 * FT)) / (RIDGE - PLATE)), "eave": 0.3},
		"truss": {"_doc": "unused (rafters above); kept for the builder's eave and board helpers, as the doctor's", "tie": [0.05, 0.15], "principal": [0.0, 0.0], "queen": [0.0, 0.0], "purlin": [0.0, 0.0], "rafter": [0.05, 0.15], "rafter_spacing": 0.61, "at": [0.0, r(D)], "purlins": []},
	},
	"girders": {"_doc": "under the bar room's floor, on stone piers, under the girder's posts", "z": [POSTS_Z[0], POSTS_Z[1]]},
	"posts": {
		"_doc": "the girder's two 6x6 posts at 10 and 20 ft, each on a pier; its ends on wall posts in the front and back walls' studs",
		"free": [[GX, POSTS_Z[0]], [GX, POSTS_Z[1]]],
		"wall": [[GX, 0.05], [GX, r(D - 0.05)]],
	},
	"beams": [{
		"_doc": ("THE GIRDER THE BARON'S MEN SAW (#772): one line down the middle, jointed over its posts: beam/spine/0 (front "
			"bay), /1 (the middle bay, OVER THE BAR), /2 (back bay, under the piano). No brackets: they would catch the halves."),
		"id": "spine", "brackets": False, "from": [GX, 0.1], "to": [GX, r(D - 0.1)],
	}],
	"sabotage": {
		"_doc": (f"Payday Night: the middle bay's piece, cut at its middle. The story's cut is 9 of the 12 in sawn from below that "
			f"morning (the pale kerf a lamp finds from the bar, S23), leaving 3 in: it holds the quiet afternoon at "
			f"{N['sawn'] / N['m_quiet']:.1f}x and an ordinary night at {N['sawn'] / N['m_normal']:.1f}x, and breaks at "
			f"{N['m_packed'] / N['sawn']:.1f}x when the payday reel stamps over it. In the game the event cuts it through "
			"(cut_member, a kerf) at its time; the bench measures the fall. Down come both sides' joists over the 10 ft bay, "
			"hinging on the side walls' ribbons: the east half onto the bar, the west half onto the tables."),
		"girder": "beam/spine/1", "cut": [-0.15, 0.15], "from_below": 0.229, "onto": "bar",
	},
	"floors": [
		{"id": "ground", "level": "ground", "rect": [0.1, 0.1, r(W - 0.1), r(D - 0.1)], "joists": "z", "look": "wood:int_floor"},
	] + [
		{"_doc": ("THE DANCE FLOOR, the whole upstairs open to the roof, laid as three floors a bay each (RECIPE 'a balcony "
			"to be blown down': boards cut at the bay lines, or the fallen bay hangs on its neighbours' boards): 2x10s across "
			"the building broken over the girder, cut 12 mm short. The middle one, over the bar, is the one that falls."),
			"id": id_, "level": "upper", "joist": "dance_joist", "end_gap": 0.012,
			"rect": [0.1, z0, r(W - 0.1), z1], "joists": "x", "breaks": [GX], "look": "wood:int_floor"}
		for id_, z0, z1 in (("dance", 0.1, POSTS_Z[0]), ("dance_mid", POSTS_Z[0], POSTS_Z[1]), ("dance_back", POSTS_Z[1], r(D - 0.1)))
	],
	"walls": [],
	"stairs": [{
		"_doc": (f"THE ONLY WAY UP: the outside stair up the west wall past the back corner to a landing behind the back wall "
			f"and the upstairs door in the back gable. {RISERS} risers of {RISE / IN:.1f} in, 10 in treads, 3 ft 6 in wide, open on its outer side "
			"with a pole rail; three lines of posts under it. On Payday Night the two men go up it with a saw in the "
			"morning; Joe watches from it; the crowd jams it when the floor goes."),
		"id": "outside", "head": [SX0, HEAD_Z], "dir": "+z", "width": r(STAIR_W), "from": 0.0, "to": "upper",
		"risers": RISERS, "going": r(GOING), "rail": "+x", "wood": "weathered_pine",
		"posts": [[r(SX1 - 0.05), r(FOOT_Z + 1.4)], [r(SX0 + 0.12), r(FOOT_Z + 1.4)], [r(SX1 - 0.05), r(FOOT_Z + 2.8)], [r(SX0 + 0.12), r(FOOT_Z + 2.8)]],
	}, {
		"_doc": "the back door's two steps down to the pad behind (the cut's bank 1.5 m back), under the landing", "id": "back", "head": [r(BACK_DOOR_X - 0.5), r(D)], "dir": "-z",
		"width": 1.0, "rail": "none", "from": 0.0, "to": "ground", "risers": 2, "going": 0.28, "wood": "weathered_pine",
	}, {
		"_doc": "the front door's plank steps to the pad", "id": "front", "head": [4.15, 0.0], "dir": "+z", "width": 1.4, "rail": "none",
		"from": 0.0, "to": "ground", "risers": 2, "going": 0.28, "wood": "weathered_pine",
	}],
	"balconies": [{
		"_doc": ("the outside stair's landing behind the back wall: from the stair's head (west, past the wall's end) to the "
			"door in the back gable; it roofs the back door under it. Three beams across it on posts, its joists along the wall over them (a stair's stringers on a beam, never a joist)."),
		"id": "landing", "wood": "weathered_pine", "post": [0.15, 0.15], "beam": [0.15, 0.25],
		"posts": [[LAND_X0, r(LAND[0] + 0.08)], [LAND_X0, r(LAND[1] - 0.08)], [6.65, r(LAND[0] + 0.08)], [6.65, r(LAND[1] - 0.08)],
			[r(SX1 - 0.08), r(LAND[0] + 0.08)], [r(SX1 - 0.08), r(LAND[1] - 0.08)]],
		"beams": [[[x, r(LAND[0] + 0.08)], [x, r(LAND[1] - 0.08)]] for x in (LAND_X0, 6.65, r(SX1 - 0.08))],
		"ledgers": [],
		"decks": [{"rect": [LAND_X0, r(LAND[0] + 0.02), SX1, r(LAND[1] - 0.06)], "joists": "x"}],
		"rails": [[[LAND_X0, r(LAND[1] - 0.04)], [r(SX1 - 0.04), r(LAND[1] - 0.04)]], [[r(SX1 - 0.04), LAND[0]], [r(SX1 - 0.04), r(LAND[1] - 0.04)]],
			[[r(LAND_X0 + 0.04), LAND[0]], [r(LAND_X0 + 0.04), r(LAND[1] - 0.04)]]],
	}],
	"front": {
		"_doc": "a gable front, no false front: the crude sign board nailed across the gable between the door's head and the upper windows",
		"sign_text": "THE SILVER SPIKE",
		"gable_sign": {"y": [2.55, 3.0], "width": 4.3},
	},
	"rooms": [
		{"id": "bar_room", "level": "ground", "rect": [0.1, 0.1, r(W - 0.1), r(D - 0.1)],
			"use": "the short bar down the east wall under the middle bay, barrels on racks behind it, the stove forward of the girder's front post, tables and benches west, spittoons, sawdust"},
		{"id": "dance_floor", "level": "upper", "rect": [0.1, 0.1, r(W - 0.1), r(D - 0.1)],
			"use": "benches round the walls, the piano and the band at the back wall, the door from the outside stair in the back gable, the reels in the middle"},
	],
	"fixtures": [
		{"_doc": "THE BAR: one 3 m built section (10 ft) down the east wall, exactly under the sawn bay (z 3.05-6.10); the customers west of it. UNDER THE CUT.",
			"kit": "bar", "at": [2.0, r(sum(BAY) / 2)], "facing": 90},
		{"_doc": "barrels on racks behind the bar against the east wall: Lowry Bros. XXX, Brandauer's, South Platte (#1222's rotgut)",
			"kit": "keg_rack", "at": [0.45, r(sum(BAY) / 2)], "facing": 90},
	],
	"furniture": [
		{"_doc": "two rough tables west of the girder, under the falling west half", "kit": "table", "at": [5.3, 3.7], "chairs": 2},
		{"kit": "table", "at": [5.3, 5.8], "chairs": 2},
		{"_doc": "the front table by the window, clear of the fall", "kit": "table", "at": [5.4, 1.4], "chairs": 2},
	],
	"lamps": {
		"_doc": ("#824's rules: smoky coal-oil lamps, few. Below: a reflector lamp on the yard wall by the bar's front end and one on "
			"the stair wall by the tables. Upstairs: two hung from the collars over the girder's posts (the dressing's `plan` "
			"batch, as saloon B's S1 hangs its lamps from joists) and one on the back wall by the piano."),
		"kit": [
			{"room": "bar_room", "kit": "reflector_lamp", "wall": "yard", "level": "ground", "at": 2.2, "height": 1.7, "lit": [17, 4], "shadows": True, "energy": 1.2, "reach": 6.0},
			{"room": "bar_room", "kit": "reflector_lamp", "wall": "stair", "level": "ground", "at": 5.0, "height": 1.7, "lit": [17, 4], "shadows": True, "energy": 1.2, "reach": 6.0},
			{"room": "dance_floor", "kit": "reflector_lamp", "wall": "back", "level": "upper", "at": 4.2, "height": 1.0, "lit": [19, 3], "shadows": True, "energy": 1.0, "reach": 6.0},
		],
	},
	"dust": {"_doc": "dust sifts through the square-edged boards onto the bar; a fall under anyone moving upstairs (FloorDust); on Payday's last seconds, into the drinks", "floor": "dance_mid", "rest": 0.25, "motes": 50},
	"materials": {
		"_doc": "Step 4's: all raw. Outside the library's rough_pine_batten (approved R1 family), weathered; inside the same, unplaned; the floors FL1 worn hard. Never 'trial': true.",
		"wear": {"use": 1.0, "dings": 0.0, "_why": "a year of track gangs' boots, sawdust and spit; dents off until the judges like them (#901)"},
		"floor": "wood:int_floor", "wall_boards": "rough", "timber": "wood:int_timber", "roof": "weathered_pine", "rough": "framing", "deck": "weathered_pine",
		"finishes": {"exterior": {"use": {"entry": "rough_pine_batten", "age": "old", "role": "wall"}},
			"floor": {"use": {"entry": "floor_fir_worn", "age": "old", "role": "floor"}}},
	},
	"sources": [
		"USDA Forest Products Laboratory, Wood Handbook (FPL-GTR-282, 2021), ch. 5 Table 5-3a (ponderosa pine MOR, MOE), ch. 7 (strength ratios of knotty timber)",
		"Hatfield, The American House Carpenter (1880): 70 lb/ft2 for a dance floor; Kidder, Building Construction and Superintendence (1895): ~1,000 psi working stress for pine",
		"Bell, Carpentry Made Easy (1858); Woodward's National Architect (1869): balloon framing",
		"experiments/building_lab/railroad_saloon/sheet/ (the target sheet, the look only)",
	],
}

# ---------------------------------------------------------------- the walls
def wall(id_, line, out, top, openings, doc):
	return {"_doc": doc, "id": id_, "line": line, "out": out, "top": top,
		"outside": {"siding": "vertical", "wood": "rough_pine_batten", "battens": True},
		"inside": [{"level": "ground", "from": 0.1, "to": r((W if out in ("-z", "+z") else D) - 0.1), "finish": "rough", "to_y": r(GIRDER_TOP - 0.15)},
			{"level": "upper", "from": 0.1, "to": r((W if out in ("-z", "+z") else D) - 0.1), "finish": "rough"}],
		"openings": openings}


win = lambda level, at, w=0.76, h=1.07, sill=0.9, lights=4: {"type": "window", "level": level, "at": r(at), "width": w, "height": h, "sill": sill, "lights": lights}
spec["walls"] = [
	wall("front", [[0, 0], [r(W), 0]], "-z", "gable", [
		win("ground", 1.83), {"type": "door", "level": "ground", "at": 4.85, "width": 1.07, "height": 2.13, "leaf": "inward", "_doc": "the wide plank door, off the girder's wall post (x 3.66)"},
		win("ground", 6.5), win("upper", 1.83, 0.6, 0.76, 0.6, 2), win("upper", 6.5, 0.6, 0.76, 0.6, 2)],
		"To Back Street: the gable, the plank door west of the girder's line, a small window each side, two small windows over them upstairs; the sign board across the gable."),
	wall("back", [[0, r(D)], [r(W), r(D)]], "+z", "gable", [
		{"type": "door", "level": "ground", "at": BACK_DOOR_X, "width": 0.91, "height": 2.03, "leaf": "inward", "_doc": "to the pens and the tracks, under the landing"},
		{"type": "door", "level": "upper", "at": BACK_DOOR_X, "width": 0.81, "height": 1.98, "leaf": "inward", "_doc": "the upstairs door off the landing: the only way in and out, THE JAM when the floor goes"},
		win("upper", 2.0, 0.6, 0.6, 1.4, 2)],
		"To the tracks and the pens: the back door and the upstairs door over it (west of the girder's wall post), the landing outside between them; a small window high over the piano."),
	wall("yard", [[0, 0], [0, r(D)]], "-x", "plate", [
		win("ground", 1.2), win("ground", 7.9), win("upper", 1.2, 0.6, 0.6, 0.25, 2), win("upper", 7.9, 0.6, 0.6, 0.25, 2)],
		"The east side, to the yard: windows front and back of the bar (the racks stand between them), the same over them upstairs."),
	wall("stair", [[r(W), 0], [r(W), r(D)]], "+x", "plate", [
		win("ground", 1.5), win("ground", 3.2), win("upper", 1.5, 0.6, 0.6, 0.25, 2)],
		"The west side, the outside stair's: two windows before the stair's foot, one small one under the eaves upstairs (the 4 ft knee wall)."),
]

# ---------------------------------------------------------------- the dressing the plan needs (the prop lab's to place)
# Dressing heights are over the ground floor's top (saloon B's), not the pad: the upstairs things at UP_REL.
UP_REL = r(U_TOP - G_TOP)
# A hanging lamp's `at` is its foot, its hook 1.01 over it (saloon_b_dress.py LAMP_FOOT), 1 cm under the collar it
# hangs from (the collars' undersides 8 ft over the dance floor; on the rafters' own spacing, the ones over the bay lines).
LAMP_Y = r(U_TOP + 8 * FT - G_TOP - 1.01)
spec["dressing"] = {"_doc": "The plan's (README.md 'The crowd'): the prop lab places the rest by its recipe.", "batches": {"plan": [
	{"id": "piano", "kit": "upright_piano", "at": [2.2, UP_REL, r(D - 0.45)], "facing": 180, "use": "carried up the outside stair that afternoon (S24): its back to the back wall, in the back bay (not the sawn one)"},
	{"id": "piano_stool", "kit": "piano_stool", "at": [2.2, UP_REL, r(D - 1.1)], "facing": 0},
	{"id": "hanging_lamp_0", "kit": "hanging_lamp", "at": [GX, r(U_TOP + 8 * FT), 2.685], "facing": 0, "light": 0.33, "shadows": False, "energy": 1.0, "use": "hung from the collar nearest the girder's front post"},
	{"id": "hanging_lamp_1", "kit": "hanging_lamp", "at": [GX, r(U_TOP + 8 * FT), 6.345], "facing": 0, "light": 0.33, "shadows": False, "energy": 1.0, "use": "hung from the collar nearest the girder's back post"},
	{"id": "stove", "kit": "box_stove", "at": [5.2, 0.0, 1.9], "facing": 0, "use": "forward of the fall, its pipe up through the dance floor's front bay and the roof"},
	{"id": "bench_e", "kit": "wall_bench", "at": [0.35, UP_REL, 1.9], "facing": 90, "repeat": {"count": 3, "step": [0, 2.4]}},
	{"id": "bench_w", "kit": "wall_bench", "at": [r(W - 0.35), UP_REL, 2.2], "facing": 270, "repeat": {"count": 2, "step": [0, 2.4]}},
	{"id": "bench_f", "kit": "wall_bench", "at": [3.66, UP_REL, 0.35], "facing": 0},
	{"id": "spittoon_bar", "kit": "spittoon", "at": [2.6, 0.0, 3.4], "facing": 0},
	{"id": "spittoon_bar2", "kit": "spittoon", "at": [2.6, 0.0, 5.8], "facing": 0},
]}}

# ---------------------------------------------------------------- use points (the crowd's places, README.md "The crowd")
up = []
for i, z in enumerate([3.4, 4.1, 4.8, 5.5]):
	up.append({"id": f"bar_{i}", "use": "drink", "who": "drinker", "at": [2.75, G_TOP, z], "facing": 270, "_doc": "at the bar: UNDER THE CUT"})
up.append({"id": "barman", "use": "serve", "who": "barman", "at": [1.2, G_TOP, 4.6], "facing": 90, "_doc": "behind the bar: UNDER THE CUT"})
for i, (x, z, f) in enumerate([(1.0, 7.4, 270), (4.4, 8.3, 180), (2.5, 1.2, 0)]):
	up.append({"id": f"edge_{i}", "use": "stand", "who": "drinker", "at": [x, G_TOP, z], "facing": f, "_doc": "standing drinkers outside the bay"})
for i, (x, z) in enumerate([(3.4, 8.45), (4.25, 8.45), (3.4, 7.6), (4.25, 7.6)]):
	up.append({"id": f"band_{i}", "use": "play", "who": "band", "at": [x, U_TOP, z], "facing": 180, "_doc": "the band beside the piano at the back wall, in the back bay, clear of the door (the pianist on the piano's stool)"})
for i, (x, z) in enumerate([(1.5, 3.3), (2.7, 3.3), (4.6, 3.3), (5.8, 3.3), (1.5, 4.6), (2.7, 4.6), (4.6, 4.6), (5.8, 4.6), (1.5, 5.8), (2.7, 5.8), (4.6, 5.8), (5.8, 5.8)]):
	up.append({"id": f"reel_{i}", "use": "dance", "who": "dancer", "at": [x, U_TOP, z], "facing": 0, "_doc": "the middle set: OVER THE CUT"})
spec["use_points"] = up


def main():
	with open(OUT, "w") as f:
		json.dump(spec, f, indent=1)
		f.write("\n")
	n = N
	print(f"wrote {os.path.relpath(OUT, ROOT)}")
	print(f"levels: ground {G_TOP}, girder {GIRDER_BOT}-{GIRDER_TOP}, upper {U_TOP}, plate {PLATE}, ridge {RIDGE}")
	print(f"stair: {RISERS} risers of {RISE:.3f} m, foot z {FOOT_Z}, head z {HEAD_Z}, landing {LAND}")
	print(f"girder middle bay {n['span_ft']:.0f} ft, tributary {n['trib_ft']:.0f} ft, dead {n['dead_psf']:.0f} psf")
	print(f"live: normal night {n['normal_live_psf']:.1f} psf, payday packed reel {n['packed_live_psf']:.1f} psf, design {n['design_live_psf']:.0f} psf")
	print(f"moments (lb-in): quiet {n['m_quiet']:.0f}, normal {n['m_normal']:.0f}, packed {n['m_packed']:.0f}, design {n['m_design']:.0f}")
	print(f"girder stress at the design load {n['working_stress_at_design_psi']:.0f} psi (allowed ~1,000)")
	print(f"strength whole {n['whole']:.0f} ({n['whole'] / n['m_packed']:.1f}x packed); sawn to {n['sawn_left_in']:.0f} in {n['sawn']:.0f}: "
		f"{n['sawn'] / n['m_quiet']:.2f}x quiet, {n['sawn'] / n['m_normal']:.2f}x normal, {n['sawn'] / n['m_packed']:.2f}x packed")


if __name__ == "__main__":
	main()
