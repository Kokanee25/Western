# Saloon B, the corner saloon (#772, #848): step 1, the spec and the frame

Art lane, the building lab. Sean picked concept B (PR #772; his nine answers are in
`docs/briefs/saloon-design.md` "Sean's answers (2026-11-10)"). Two steps: **this one, the spec and
the frame on its corner lot, judged for being built right**; step 2 the finishes, light and judges.

| File | What |
| --- | --- |
| `concept.json`, `sheet/` | the target: B's plans and three views (PR #772) |
| `saloon_b.json` | the spec (format 1, `../FORMAT.md` "Saloon B's parts") |
| `results/xray.jpg` | the frame drawn from the built members (`tools/buildings/xray.py`) |
| `results/plan.png` | the ground plan drawn from the spec (`tools/buildings/plan_sheet.py`; it doesn't draw the cut corner or the arch yet) |
| `results/2026-11-12_frame/` | the lab's renders: the four sides and the well from the gallery |
| `render_frame.gd` | those renders (one lavapipe run, `--game-args=--real`) |

## The building

54 x 72 ft (16.46 x 21.95 m), two storeys, 13 ft floor to floor below and 11 ft above, on the
north-side corner lot: it faces south, so its x runs from its **east** corner (the yard) to the
North-South Street. Walls by what they face: `front`, `side`, `yard`, `back`.

- **Ground:** the bar room 54 x 44 ft, entered at the corner; the bar down the yard wall (three kit
  sections, the back bar four) under the east girder's panel; the card tables under the well by the
  side street's windows (No Law's is `no_law_table`). Behind the bar room's back wall: the stair
  hall with its own door on the side street, the gaming room through a wide arch, the kitchen and
  its lunch hatch, the store room with the trap. The cellar (16 x 46 ft, narrowed from the concept's
  20 so the girder's posts stand on solid ground) under the bar's back half and the store room.
- **Upper:** the dance hall 36 x 44 ft over the bar on open 3x12 joists at 12 in, two lines of 10x12
  girders on 8x8 posts; the owner's office over the corner; the **open well 14 x 22 ft** over the
  card tables, a 36 in rail round it, a 4 ft gallery along the side street's wall; the upper hall
  and four rented rooms behind; a door to the outside stair's landing in the yard.
- **The corner:** cut off 8 ft each way (the walls' `void` openings), the upper floor carried over
  it on a beam each way to one iron column; glazed double doors and a transom in the diagonal wall.
- **The balcony** wraps the corner, 54 ft on Main Street and 44 ft down the side street, 8 ft deep
  on ten 6x6 posts, a beam a bay; under it Main Street's walk and a boardwalk down the side street
  (`lot.side_walk`), past the stair hall's door.
- **The roof:** queen-post trusses across the 54 ft, a low 2/12 behind the street's cornice.

## The girder the Baron's men saw

`sabotage` names it: `beam/east/2`, the east girder's piece between the posts at 22 and 33 ft,
beside the bar. `tests/test_building_saloon_b.gd`:

- **uncut**, with a dancing crowd on the floor (70 lb/ft2, Hatfield), the game's own settle breaks
  nothing;
- **cut** (`SpecBuilding.saw_girder`: a kerf through its middle, `Structure.cut_member`), its two
  halves tip off their posts and its 22 joists hinge down, one bay on the yard wall's ribbon, the
  other on the west girder, with the 72 boards on them and the stretch of the well's rail that
  stood there: a panel 11 ft along the girder and 18 ft each side, over the bar and the men at
  it. Nothing outside the panel gives (the other girder pieces, the trusses, the walls stand).

What made it fall and not hang: see `../RECIPE.md` "A collapse on purpose needs room to fall".
For Payday Night (gameplay's): put the dancers' weight on the dance floor's boards
(`extra_load`), call `saw_girder()` when the floor is to go, and let the structure settle. A girder
only half sawn holds in the game as in the brief (the analysis gives the sound girder 0.15 of its
limit under the crowd): the mission cuts it through at its moment.

## What the checks say (`tests/test_building_saloon_b.gd`, nine tests)

- **Destructible through and through:** 7,560 members (the doctor has 3,400, the old spec saloon
  5,200), nothing drawn or solid that isn't a member, a kit prop or a fitting.
- **It stands:** every member has a load path; under its own weight nothing is over 0.66 of its
  limit (the side balcony's ledger); with a crowd on every floor (40 lb/ft2, 60 on the balcony)
  nothing is over 0.73 (a stud of the store room's bearing wall); the game's own `settle()` breaks
  nothing, with a dancing crowd (70 lb/ft2) on the dance floor either.
- **Built right** (`Checks.built_right`): nothing crosses any of its 43 openings (29 in the outer walls), every
  outer opening framed (kings, header, rough sill) and every window a lined four-light sash.
- **People fit:** 20 doors, 5 stairs (each climbed on its ramp floor to floor), 31 use points, a
  use point in every room; the corner's doorway clear for a man.
- **The well's rail:** a man walking into it is held; a man thrown at it (5.5 m/s) breaks the span
  he hits and falls 13 ft to the bar room (`last_fall`: flat, 7.2 m/s, ribs broken, alive).
- **The corner's column knocked out** (by the rules): the two beams under the corner and the
  balcony's corner beam go over their limit.
- **A lamp in every room** (the cellar has none), RoomLight given all 30 outer openings.
- **What it costs:** 484 draws in the lab's count (231 batches, 189 of its own meshes: the panes
  and the kit; 64 lamp meshes; 27 lights). In the valley, on its lot: **render CPU at Sean's 1.1 ms
  from Main Street and 1.9 ms from the crossroads** (805 and 1,764 draws; `render_frame.gd --cpu`,
  lavapipe x0.65), 1.8 ms over the well from the gallery and 1.9 ms in the bar room (2,186 and 1,817 draws), against the 4 ms budget. **Collision bodies in the valley: 27,651 of
  Jolt's 32,768** (`project.godot` max_bodies): the building's members are a body each, and the
  jail, the store and this building's props will want the guard raised or members put to rest.

Not checked here: the frame's deflection (the format's item 12), fire and blast in this building
(the lab's runner does them for the old saloon; nothing in B's frame is new to them but its size).

## Not in step 1 (for step 2 or its owner)

- **The hip.** The roof is a plain 2/12 on trusses, its gables to the yard and the side street
  behind boards (the bracketed cornice is on both streets since step 2). Sean's to pick.
- **The cellar's bulkhead to the yard** (the concept's 5) and the cellar dug in the valley: the
  valley's ground isn't opened under the building yet (#695), so on its lot the cellar's members
  stand in the ground. In the lab the pit is open and the trap's stair reaches it.
- **No Law's set stays in the yard.** See "No Law" below.
- **The sign's lettering** (THE SALT CREEK): a paid paint job, Sean's to OK. The rest of the
  look is step 2, below.
- **Props**: the bar and back bar are the kit's sections and four card tables with chairs; the
  rest is the prop lab's (`docs/briefs/saloon-design.md` "The props B needs").
- **Working doors**: every leaf stands open (the format's item 13).

## Step 2: the look (#867)

- **Finishes by name** (`materials.finishes`, `surfaces`): dark red board and batten
  (`painted_oxblood_batten` at "few", the age it passed) with buff trim, casings, sashes, skirting
  and the walks' posts and rails; inside, buff painted boards over a dark wainscot with a picture
  rail on the bar room's street walls; the worn fir floor; the posts, girders, open joists, the
  well's rail, the hall stair and the doors in the library's walnut (`oak` and `timber`: the
  library's oak drew a flat fresh orange, its rough pine read as bark, its planed pine as
  driftwood; there is no dressed-timber entry yet). The brackets keep their coves (finish `-`).
- **A bracketed cornice on both streets** (`front.brackets`, its `sides`), and the roof's boards
  butted (`levels.roof_tight`: the 3 mm gaps drew as specks of sky from the dance hall).
- **Light** (`light`): fill 0.62/0.6/0.57, `day_fill` 0.32, `window_day` 14, for a room 54 ft wide
  and 13 ft high (the doctor's 0.1 and 7 left the far half near black: `results/2026-11-13_look/
  light_a_b.jpg`).
- **Dust through the dance floor** (`dust`, `FloorDust` in `src/art/`): a few motes hang under the
  boards, and more fall under anyone moving on the floor above (`stir` for anything else).
- **Judged, two rounds** (`docs/screenshots/judge/2026-11-13_saloon_b_r1`, `_r2`; renders in
  `results/2026-11-13_look/`, `pairs_r2.jpg` beside the sheet). The cheap judge: **the bar room
  good indie** from the corner doors (both rounds) and from behind the bar by lamplight (round 2);
  **the corner cheap indie**, as are the front, the back, the dance hall and the gallery. The
  tells still open, most outside this step:
  - outside: no town, ground or sky around it (grey lots, a posterised dusk sky), the blank sign,
    nothing lit on the walks at night (the building has no porch lamps), one even red with no
    corner boards or belt course, the walks' deck on bare posts with no skirt;
  - inside: nothing dressed and nobody there, all the woodwork one varnished red-brown with bold
    grain and a glossy floor (a dressed-timber and a matt floor entry are the material library's
    next), pale flecks and dark dashes on the buff boards (the paint's wear, drawn large), an open
    door leaf near the dance hall's camera that reads as a black slab, lamp light through the
    balusters' feet and on the ceiling over the bar's lamps.
- **Cost:** render CPU at Sean's (x0.65 of this VM's), budget 4 ms: Main Street 2.1, the corner at
  dusk 2.6, the bar room from the doors 3.0, from behind the bar by lamplight 3.2, the gallery over
  the well by lamplight 3.4 (step 1: 1.1 to 1.9 by day; the dance hall's view not measured). Members 7,763 (step 1: 7,560); the valley's collision bodies 27,908 of
  Jolt's 32,768.
- **Goldens:** none change (the golden views are the old town's, not the valley's).

## The stage, the wing and the dressing room (#902)

Sean, 2026-11-13: put it where it fits best, 16 x 8 ft for now, backstage with a dressing room, a
curtain that opens and a painted backdrop of Salt Creek as the Baron promises it; Payday Night's
band plays there. The spec's `stage` (FORMAT.md "Saloon B's stage"):

- **The stage:** against the dance hall's back partition, x 2.5 to 7.4 by z 10.9 to 13.3, 30 in
  high: 15 legs under three bearers, 2x8 joists at 16 in front to back, the dance floor's boards, a
  boarded skirt on its front and its open (+x) side; three steps down to the dance floor at the open
  side (z 11.25 to 12.25, clear of the public door). Its nearest edge is at z 10.88, 0.8 m past the
  sawn girder's panel (z 6.7 to 10.06), and the cut test holds every stage, step and wing member up
  while the panel falls.
- **The proscenium and curtain:** a walnut post at each front corner (0.45 m deep), a header over
  them 2.2 m up, an iron rod between them 0.34 m back from the stage's front, and on it the red
  `DrawCurtain` (`src/art/`, a part: two halves with a gold fringe, drawn open and shut in ~3 s;
  `SpecBuilding.open_curtain` / `close_curtain`; `to_dict` / `from_dict`). It hangs shut.
- **The backdrop:** a `PaintedDrop` (`src/art/`) 4.6 x 2.3 m (15 x 7.5 ft: the room is 2.59 m from
  the stage to the trusses' ties, so no 9 ft drop) under a batten on the back wall, **plain canvas**
  painted: Salt Creek as the Baron promises it (Sean's yes on #960; `tools/textures/materials.json`
  `drop_baron`, the factory's new `painting` kind, FLUX.2 [max], $0.10 on People run 133).
- **The wing:** the corner x 0.1 to 2.45, z 10.9 to 13.36, boarded off from the dance floor (the
  `wing` partition), three steps up onto the stage's end, a lamp; its door through `dance_back` at
  1.58, straight across the upper hall from room_6's, its leaf hung on the far jamb (`hinge: "end"`)
  so it opens clear of the steps. The door at 3.56 went (it was behind the stage); the public door at
  8.43 stays. The dance hall's back-wall lamp moved off the stage's wall to 9.85.
- **The dressing room:** room_6 (three rooms let now): a dressing table against the yard wall between
  the door and the window, a chair, an oil lamp on the table. **For the prop lab** (made in #903, not
  placed): the dressing mirror over the table, the costume pegs across from it, the travelling trunk
  (one shut here, one open in the wing), the dressing screen across the corner by the door, as
  `experiments/prop_lab/README.md` "Saloon B, the stage and dressing room" says. The five footlights
  are placed (its places, z 11.02), all five lit softly with no shadows (two shadowed lamps had cost ~1,600 draws).
- **For gameplay (Payday Night):** the band's places are use points on the stage, behind the
  curtain's line: `fiddler` (4.3, 12.6), `band_2` (5.5, 12.7), `band_3` (6.5, 12.4), the act out
  front `stage_act` (4.9, 11.7), all at the stage's top (y 5.67); `wing_wait` in the wing; `dressing`
  at the table. The fiddler's old place in the hall's back corner is the wing now.
- **Walked:** `tests/test_building_saloon_b.gd` walks a man from the outside stair's landing into the
  upper hall, into the dressing room, back to the wing's door, through the wing and up its steps,
  across the stage behind the curtain and down its steps to the dance floor (Waypoints' own test, a
  step at a time).
- **Cost:** render CPU at Sean's (lavapipe x0.65, median): the `stage` view shut **3.48 ms** (3,887
  draws), open on the drop **3.71 ms** (4,003), both under 4; main's spec without the stage, same view:
  3.34 (3,583). The `dance` view **5.10 ms** (6,102 draws) against main's 5.19 without the stage: the hall
  view was over 4 on main already (the valley's buildings behind it), the stage adds nothing to it.
  Bodies: **31,688** in the valley (+175 on main's 31,513 with #886; **1,080 left** of Jolt's 32,768); 7,775
  members (+141), 39 lamps (+7: the proscenium has none, five footlights, the wing's and the table's).
- **Judged, one round** (`docs/screenshots/judge/2026-11-14_saloon_b_stage_r1`; renders in
  `results/2026-11-14_stage/`): the cheap judge called the stage shut, the stage open on the drop and the
  dance hall **cheap indie**, all three (open the best, then shut, then the hall). Tells: the hall empty
  (nothing on the floor, nobody there); the five footlights read as tin buckets, two lit throwing hot
  cones up the curtain (the critic: 8 to 12 small lamps in a hooded trough, all lit, one soft wash;
  since judged, all five lit softly with no shadows);
  the proscenium a bare dark box (no swag valance, painted frame, pilasters or lettered apron); the
  curtain's pleats too even and too orange under the footlights, its fringe blocky; the drop lit flat,
  short of the header, more a framed lithograph than a scene drop with wings; the public door's open
  leaf by the dance view's camera a slab of big walnut grain; a light by the side steps' foot with no
  lamp to it (a footlight's chimney seen past the step, most likely; not chased). Shared with the rest
  of the building: the speckled board paint, no haze, blank windows.

## Step 3: the sign and the walks' lamps (#886)

- **THE NEW OCCIDENTAL** (Sean's "pay", #885; his name for it, #886, 2026-11-13: "the new" for an
  old Occidental that burned or fell): the texture factory's `letters_the_new_occidental` (kind
  `lettering`: gold-ochre sign-writer's paint on white, the white keyed out; one call, $0.10, People
  run 132; THE SALT CREEK, run 131, $0.10, replaced). The painter put it on two lines, a small THE NEW
  over a big OCCIDENTAL (asked for one line; kept, it's period and reads). The spec builder lays a
  front's painted letters (`SignArt.letters`) on its own board, cut to them, as the jail's are on its
  boards (`FacadeArt._paint_letters`); the board is a plain trim board in the walnut (`front/sign` ->
  `oak`). `front.sign_from` 7.9 (one line's was 8.45): a 1.6 m board over the upper doors' heads,
  the letters 1.14 m tall and 4.9 m across, held to that by `front.sign_width` (new). Why not the
  factory's `sign` kind: it takes the board's width from the picture, at most 21:9, a 2.3 m board.
- **Lamps on the walks** (Sean's "add lamps", #885): four reflector lamps under the balcony on the
  siding outside (`lamps.kit` `side: "out"`, new), two on Main Street's wall (at 5.4 and 10.6) and two
  on the side street's (6.1 and 12.8), 1.85 m over the walk, lit 17 to 4, energy 1.4, reach 6.5; only
  the one at 10.6 casts shadows.
- **THE NEW OCCIDENTAL judged, one round** (`docs/screenshots/judge/2026-11-14_saloon_b_occidental`;
  renders in `results/2026-11-14_occidental/`, with a new view `street_dusk`: down Main Street from the
  east at 18.0, ~25 m off): the cheap judge has all three cheap indie (the corner at 19.4 now near
  black under main's new sky, #918's crushed night: not this step's). The sign reads "THE NEW /
  OCCIDENTAL" by day on a close look and just reads at dusk down the street (THE NEW blurring); it holds
  the eye weakly, dark gold on a dark board on a dark red wall, and is lost at night. Open: the board's
  contrast or a light on it. Render CPU at Sean's: the front 2.27, the corner 3.69 (2.98 before main's
  sky; inside 4). Valley bodies 31,395 of Jolt's 32,768.
- **Judged, one round** (`docs/screenshots/judge/2026-11-13_saloon_b_sign`; renders in
  `results/2026-11-13_sign/`): the cheap judge has **the corner at dusk good indie** (step 2: cheap
  indie; the sconces, lit windows and pools of light lift it) and the front by day still cheap indie
  (grey neighbours, flat light, the empty street: not this step's). The blind critic: the lamps are
  placed right with visible flames but each throws a tight smear that doesn't reach the walk; the
  sign only just reads by day (grey on grey in the front's shade) and is lost at dusk. Open: the
  lamps' reach and colour, the board's darkness against the letters, the sign's light at night.

## No Law

The issue asked for the yard set swapped into the building where the spec allows, behind a switch
if the mission needs the yard. **It is not swapped, and there is no switch: the mission plays in
the yard as before** (its tests pass with the building beside it). Why: the set is ValleyFolk's own
bar, table and chairs placed on the ground of a lot (`config/valley_folk.json`), the ways in and
the murder's approach paths are tuned to the yard, and No Law step 4 (PR #847) was open on those
files while this was built. Moving it is small for gameplay and wrong to do from here blind:

- the spec has the places: the card table under the well (`furniture` id `no_law_table`, at the
  building's x 13.1, z 7.3: world 10.96, -17.35), its four chairs, the bar down the yard wall and
  the barman's and drinkers' use points;
- what the move needs is in `docs/lanes/gameplay.md` (the set on the saloon lot's floor, not the
  pad's ground; the spec's own table and bar used instead of a second set; ways in by the corner
  door and Main Street's walk).
