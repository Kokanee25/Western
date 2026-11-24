# The Salt Creek Hotel (#1146)

10 Hotel, Main Street's north side (`config/valley.json` town.north `hotel`). The design is
`docs/briefs/hotel.md` (drawings in `docs/briefs/hotel/`); Sean's calls are on #1215.

## Step 1: the target sheet (Sean OK, 2026-11-23, in session: the cost, ~$1.70)

`sheet/request.json`: twelve views, cap $2.50, painted by `building_sheet.yml` on `claude/art-building-hotel`.
Painted with the brief's recommendations for the calls still open (painted clapboard, two storeys) and the
cellar's secret B (the drift to the saloon's cellar). The spec settles every size; the pictures are the look only.

**Painted 2026-11-23 for $1.68** (twelve views, `sheet/sheet.jpg`; run 13 of `building_sheet.yml`). Where the
pictures differ from the words (the spec settles each, never the pictures):
- **The gallery has a roof in the front and dusk views** (posts running up past the deck to a roof):
  Sean chose an **open deck** with no roof; build the open deck (`docs/briefs/hotel/balcony.png`).
- The plan moves rooms (the sample room and desk east, the bar at the back west, the suite in the back row):
  `docs/briefs/hotel/ground.png` and `upper.png` hold.
- The lobby's stair rises along the east wall, not the back wall; either works, the spec decides.
- The cellar draws the drift as a timbered passage running back and the bricked arch as a separate alcove:
  the drift leaves the beer cellar's west wall (`cellar.png`).
- Good as targets: the blue-grey front with red frieze and green shutters, the lobby's red runner and red-and-
  gold paper, the parlour's red velvet and drapes, the bar's walnut and green paper, the dining room, the
  kitchen's range, the suite's walnut bed and French doors to the balcony, the cellar's stone and kegs.

**Sean OK'd the sheet 2026-11-24** (in session, "Looks great"): the look to match; steps 2-6 next.

## Step 2: the spec on its lot (#1220)

`make_spec.py` writes `config/buildings/hotel.json` (RECIPE: a script while the numbers move). The lot: valley.json
town.north `hotel` (x 42.0-67.2), the west wall 3 cm inside the lot's line on the saloon lane (world x 42.03), the east
corner (the origin: a north-side lot's x runs from its EAST corner) at 66.414, 0.79 m short of the east lane. The bake
rises 0.5-0.6 m to the back wall, so the lot is dug level at the street edge's height (-0.08) under the building
(valley.json's `pad`). The floor is the walk's top (0.75); 13 ft 6 in floor to floor, 11 ft 6 in above; a flat roof at
8.70 behind the parapet's cornice and name board (9.9, 32 1/2 ft over the street).

**Settled here (each a choice the brief left open, or a change from its drawings; Sean may overrule any):**
1. **The main block only.** The two-storey kitchen wing (42 x 24 ft behind the west half) is the next step: the builder
   makes one rectangle, and a wing wants its own walls, floors and roof (the jail's cell wing is stone). The back
   wall's door at the back stair hall is where the wing's back hall will meet it.
2. **A flat tin roof behind the parapet** (not a low gable on trusses): an 80 ft span is past a queen-post truss, and the
   period's commercial blocks were flat behind their fronts. NEW in the builder (`frame.flat_roof`).
3. **The grand stair is one straight flight of 22 risers** (7 3/8 in on 10 in treads) up the lobby's back wall, rising
   east, not the brief's 13 + 9 with a landing: the builder's stairs are straight runs. Its well's posts stand in the
   lobby (8x8, as saloon B's) over piers in the stores.
4. **The upper hall is at 20-28 ft**, not 28-34: the front rooms 20 ft deep (no closets), the hall 8 ft wide over the
   grand stair's well, the back rooms 22 ft. The 28 ft wall carries both floors' joists and the roof's.
5. **The cellar's stair is the bar's trap** (the brief's "a trap to the beer cellar behind the bar"); the brief's cellar
   stair from the kitchen's back hall comes with the wing. The back stair goes ground to upper only.
6. **The beer cellar runs back to 36 ft** (the drawing's 30), so the drift's line (27-33 ft back) meets saloon B's cellar
   (from 26 ft back) inside both.
7. **The drift is 4 ft 7 in clear** (the brief's 4 ft): the player crouches to 1.3 m. Its floor rises 0.23 m to saloon B's
   (the two cellars' floors).
8. **The office is in the lobby's front-west corner** behind the desk, the sample room the full depth of the back-west.
10. **The bar has no street door** (the brief's "the bar's own street door at the west"): townsmen walking the walk
   west from the main doors were pushed in at it and stuck in the bar (`test_valley_folk`). It's a window; the bar is
   entered from the lobby. Its own door could come on the lane side with steps.
9. **The ground floor's windows are tall one-over-one sashes** (plate glass in two lights), not round-arched (the builder
   frames square heads).

## Step 3: the build and its checks

`tests/test_building_hotel.gd` (all pass): 12.5k members; stands (dead, a crowd on every floor and 60 lb/ft2 on the
gallery, the game's settle drops nothing); built right; people fit every door, stair and use point; the gallery's middle
post blown (`break_member`) drops exactly bays 3 and 4, the others standing; a man walks down the trap's stair into the
beer cellar and the whole drift crouched (a standing man doesn't fit); a man climbs the grand stair to the upper hall.
**Not on its valley lot yet** (Sean, 2026-11-24): placed, its 12.5k members (each a Jolt body) made every valley test's
physics frame heavier (a ten-minute street test 2 -> 20 min; CI shards past 75 min even at 8 shards), which players would
feel too. It goes onto its lot when #1227 merges a standing building's members into fewer bodies. What placing it needs is
worked out and was tested: valley.json's lot `spec`, a `pad` (y -0.08, x 41.8-66.7, z -9.75 to -26.0, blend 2.5: the bake
rises 0.5-0.6 m to the back wall), `walk.awning` 0 and `door_x` 53.0, the `cellar` entry, a re-bake of the heights and the
ground map, Jolt's `max_bodies` (the save test's second valley passed 65,536), and tests/test_valley_markers.gd's sample
block (it used the hotel's). The test of it on its lot is in PR #1224's history (tests/test_hotel_valley.gd).

**The valley doesn't dig the cellar or the drift yet** (`hotel.json` `cellar._dig`). ValleyGround collides the valley in
128 m chunks; a dug tile anywhere in one re-cuts the whole chunk's collision into squares, and the first chunk (x -30 to
98) holds the saloon yard's card set: the hotel's dig, the drift's, and saloon B's alone each failed the card-game tests
(every chair test; main and the hotel undug pass all eight). CellarDig is ready for both (the lane-side bulkhead, the
drift's trench with its fall, the cover flush with the lane at the ground's old height): set `cellar.dig` and saloon B's
once the set is inside saloon B, or ValleyGround's re-cut leaves the squares without a tile as they were.

What the checks found (each fixed; RECIPE "A big two-storey hotel"): a joist 5 mm from a wall's studs carries the
wall; a bearing wall's studs on boards bend them however they're carried (a sole); a post through the floor stands a
joist on it (posts off the joists' lines); a stair's stringer into a partition takes its boards; a door's leaf into a
stair's foot; a deck that spans past its beam's end; a stacked pair of doors' leaves with the same id.

Not done (the next steps): the kitchen wing; plaster on lath that breaks as plaster (a slice issue); wallpaper and
carpet (the library); turned posts and balusters on the gallery (square, chamfered); the three paints judged (P7-P9:
`painted_bluegrey_lap`, `painted_cream_trim`, `painted_red_trim`, in the library unjudged, so the hotel draws the passed
white, buff and ox-blood till they pass); props (the prop lab's batches).

## Step 5, begun: the first render (2026-11-24)

`render_valley.gd` (the undertaker's, with the sheet's views): `results/2026-11-24_r1/front.jpg`, the front at 15:30 in
the valley. It stands: two storeys, the open gallery on its nine posts, the bracketed cornice. Against the sheet: the walls
white (P7 blue-grey not judged yet), the name board's letters not legible at this distance, the walk under the gallery
dark. Each view is ~25 min under lavapipe here (the gallery view ran out of its 50 min box with the front); the judge's
round (the sheet's views beside the game's, the cheap judge) is the next step's.


## The grand stair: Sean wants it grand (2026-11-24)

The built stair is a placeholder: one plain straight flight up the lobby's back wall, its well's posts and beam
standing in the room (the brief's two flights round OakStair's newel came out as one; see "Settled here" 3). Sean
(in session, with a picture of a lobby's dark oak stair, red runner and statue newel): "more central ... wider at the
base ... we're going for opulence". `docs/briefs/hotel/stair_options.png` (by `draw_stairs.py`) draws three ways on
the lobby's plan: 1 imperial (a 6 ft flight up the axis splitting in two to a gallery round a double-height void),
2 central with a return (recommended: 5 ft up the axis from curtail steps to a landing, a 4 ft return to the upper
hall), 3 along the back wall, dressed. All: OakStair's dark oak, the red runner on brass rods, turned balusters, a
statue newel lamp, curtail steps, no posts in the room. Sean's pick goes into #1226.
