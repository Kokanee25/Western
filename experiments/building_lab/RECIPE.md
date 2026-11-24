# The building recipe (the building lab's step 6)

How a building goes from Sean's word to standing on its valley lot, and what went wrong on the way,
so the next goes faster. Written after the doctor's office (#765, the first of three practice
buildings before the saloon; its record is `doctor/README.md`). Each building's PR adds to it.

## The loop, in order (show Sean each step before the next)

| Step | What | Tools | The doctor's took |
| --- | --- | --- | --- |
| 1 | The target sheet: ten views painted one at a time, the front and the plan given to the rest | `tools/buildings/target_sheet.py`, `.github/workflows/building_sheet.yml` (fires on a pushed `experiments/building_lab/<b>/sheet/request.json` on `claude/art-building-*`) | $1.41, one run, ~10 min |
| 2 | The spec on its lot: rooms, every opening, the frame from period books; each conflict to Sean | `<b>/<b>.json` (`FORMAT.md`), `tools/buildings/plan_sheet.py` (the plan drawn from the spec) | a session's afternoon |
| 3 | The build, the checks, the X-ray sheet | `spec_building.gd`, `checks.gd` (`built_right`), `tests/test_building_<b>.gd`, `tools/buildings/xray.py` | most of the work: the builder grew |
| 4 | The look: finishes from the material library by name (passing swatches only) | `spec_building.gd` `finish()`, `_library_finishes()` | the batching of library boards |
| 5 | The judge: renders from the sheet's views in the valley, beside the sheet; the cheap judge | `<b>/render_valley.gd` (~10 min a view under lavapipe), `tools/critic.py cheap` | ~80 min of renders |
| 6 | This file | | |

Then: the building on its lot (`config/valley.json`: the lot's `spec`, its `pad`, its walk's
`span`/`door_x`; re-bake `python3 tools/valley/valley_plan.py --bake`, 35 s, byte-for-byte
reproducible), the missions that use it, the full suite, the PR.

## Before step 1 (do these first next time)

- **Ask the form questions before writing the prompts:** false front or gable front, paint or
  raw, which way the best light comes from. The doctor's prompts were rewritten after Sean's
  answers (a gable front, not the false front assumed).
- **Probe the ground under the lot** before anything is sized (a few lines: `ValleyTerrain.main()
  .height(x, z)` over the lot from a test or `-s` script). The doctor's rises 0.5 m front to back:
  found at step 2, it needed a pad in the bake.
- **Read the lot's neighbours and its walk** (`valley.json` town.north/south): the walk runs the
  whole lot unless its `span` says otherwise; a side yard behind a walk can't take a wagon.
- **The references:** this session's network refuses loc.gov, archive.org, gutenberg.org,
  hathitrust.org and wellcomecollection.org. Search finds them; nothing can be opened. Ask Sean to
  allow those hosts before the research, or name the few that matter for him to check.

## Step 1: the sheet

- One picture a view (Nano Banana Pro, ~$0.14 at 2K) beats one sheet image: the later views are
  given the front and the plan and mostly agree. The cutaway and the interiors were the best.
- **The model can't spell on glass** ("DRUS"): don't repaint for it, the game's lettering is ours.
- **Say the plan's shape in words:** "a plain rectangle in plan, no wing or ell". The rear view
  invented an L-shaped wing the plan and cutaway don't have.
- **The plan's scale bar is decoration** (it read 30 x 46 ft for a 26 x 48 ft ask) and its room
  order may differ from the words: settle both in the spec, never measure the pictures.
- Say what the yard holds in every outside view's words (the buggy shed went missing in two).

## Step 2: the spec

- **On a north-side lot the building faces south (facing 180): its x runs from its EAST corner.**
  Name the side walls by what they face (`yard`, `lane`), not by the format's compass.
- `lot.at` is the world point of the building's origin (its east front corner here); its y the
  walk's street-edge ground; the valley sets the floor at the walk's top at run time.
- **Doors off a narrow hall open into the rooms**, never across a 4 ft hall.
- **A chimney stands clear of every partition and its junctions** (in the room's corner beside
  the wall), its hole snapped to the joist lines (the builder does that now).
- **A loft that men stand in needs 2x10s over 13 ft spans** (2x8 was at its limit with a crowd).
- **A room with no wall under the joists' break needs a summer beam** (the doctor's front office).
- A loft door needs its head under the rafters: put it off the middle of a gable, check the height.

## Step 3: the build and its checks

The builder (`spec_building.gd`) now has, for the next building to use (all gated on the spec's
own keys; the saloon and farmhouse build exactly as before):
girders front to back (`girders.x`); a floor's own joists (`floors[].joist`); the common-rafter
roof tied by the loft's joists (`frame.rafters`, `frame.ceiling_joist`); summer beams; ceilings;
brick chimneys with their floor and roof holes; narrow clapboard to a gable's rake
(`outside.exposure`) and corner boards; let-in corner braces; a sign on a gable
(`front.gable_sign`); a door's transom (`transom`); the back porch and its shed roof
(`back_porch`); stoops (`stairs[].stoop`); a yard's picket fence, wagon gate and side fence
(`lot.yard_front`); ladders (`ladders`, the game's `Ladder`); kings stopping under and over
stacked openings.

What the checks caught (each a fault a framer would see; each fixed):
- **King studs ran through stacked openings** (the door's up through the loft window over it).
  The saloon's still do, through its upstairs windows: `Checks.built_right` will fail it in its turn.
- **Joists broken over nothing** (the front office: no wall under the hall's line).
- **The support model joins members by their bounding boxes:** a tilted rafter's box takes in the
  whole loft, so it "rested" on fifty things and failed at its joint. In a rafter roof a tilted
  member now touches only what its oriented box truly meets, and pairs meet at the ridge.
- **Members stack by band and kind tier:** a deck's joists can't rest on its ledger in the same
  band, a header can't rest on a cripple (an opening over another is carried a band up).
- **Boards cantilevered at a hole** cut between joists (holes now snap to the joist lines).
- The summer beams' posts read redundant: their beams' ends butt the walls, which the rules count
  as bearing (as the saloon's cellar posts). A framer puts the posts there anyway.

Traps met: a `-s` script can't build a structure (no autoloads): build through a test
(`tests/test_building_<b>.gd` writes `build/<b>_members.json` for the X-ray); GDScript's packed
arrays are values (an append to one fetched from an Array changes a copy); `Structure` already
has a static `_batch_frame`; backticks in a `git commit -m` run as commands (write the message to
a file); the X-ray's and plan's images go in a `.gdignore`d folder (Godot imports any image).

## Step 4: the look

- **The material library has no paint yet** (2026-11-10: R1 new and a few years, C1 old, F2 all
  ages passed the materials judge; #721). The doctor is unpainted on those, each surface naming
  its finish (`materials.finishes`: a `want`, the paint, used the moment the library has it passed
  at that age; else its `use`). Paint him by adding the entries, not by touching the spec.
- **Library boards batch only with boards facing the same way** (the library's shader reads each
  board's axes from the node it's drawn by): `Structure`'s batching does that now (meta
  `board_frame`). The doctor is 109 draws.
- Not in the library: stone, brick, glass, and the sign's lettering (the factory's `lettering`, a
  paid paint job). Members made after the build (a cut's ends) are drawn in their own wood.

## Step 5: the judge

- **Place the interior cameras in each room's far corner, clear of every door's leaf.** Round 1 put
  three behind open leaves: the blind critic could only say DIFFERENT (3 CLOSE -> 5 CLOSE in round 2).
- **Render interiors by day until the lamps are in** (an evening room without a lamp is black).
- **What the judges see before paint and props:** the cheap judge calls every view cheap indie for
  the empty rooms, the grey-box neighbours, windows onto a grey void and dark unlit rooms; judge the
  building by the blind critic's form grades, and the look again once paint, lamps and props are in.
- **Name only woods the game draws:** a wood it doesn't know (the chimneys' "brick") is drawn as
  timber.
- Bare dark walnut everywhere inside reads near black: a building's inside finishes want a pale wall
  as soon as the library has one.

## Floors and furniture (#825, Sean's picks 2 and 5 on #821)

- **The floor's wood by the building's class:** rough, wide pine boards; common (and the doctor), the
  library's worn fir and pine floor (`floor_fir_worn`, oiled, a family `floor` entry); fine, a narrow
  oak or maple floor when the library has one. Never a wall's or the furniture's entry.
- **Feet wear the floor where the building's ways go:** a floor entry with `traffic` takes the
  building's traffic map (`SpecBuilding.traffic_ways`: in each ground-floor room, door to door and
  each use point to its nearest door and nearest outside door; `MaterialLibrary.traffic_image`):
  paler, matte paths, dark by the walls. A building gets it from its `rooms`, its walls' doors and
  its `use_points`: name them and the floor follows.
- **Furniture is never the floor's wood:** the prop lab dresses the rooms in the library's furniture
  entries (`docs/briefs/prop-factory.md`, point 1); `tests/test_material_library.gd` fails the doctor
  if a kit in his rooms is drawn in his floor's entry.
- **A building's props are placed by the game's build from the start; a lab only reads that
  placement** (#844, Sean 2026-11-12: the doctor's D1 and D2 were only in the lab's renders, his rooms
  empty in play). They go in the spec's `dressing` (`{"batches": {"D1": [...]}}`, entries as
  `PropDressing` documents: `at`, `facing`, `on`, `fit`, `cloth_over`, `light`, `row`), placed by
  `SpecBuilding._dressing` wherever the building stands (the valley, the lab, the tests); a lab that
  judges them (`experiments/prop_lab/doctor/dress.gd`) reads `building.dressed`, never a placement of
  its own. The jail (#811) and the store take theirs this way from their first prop.

## Wear by use (#901, Sean 2026-11-13: "wear and dents to the wood ... basically everywhere")

- **Every building is worn by its own use, from its data, never painted per room.** The spec's
  `materials.wear` says how hard the place is used and knocked about: `use` (a saloon 1.0, the jail
  0.65, the doctor's careful office 0.45) and `dings` (dents, gouges, crushed arrises: 0.9, 0.75,
  0.4); without it a middling 0.5 each (`SpecBuilding.WEAR_DEFAULT`). Its library wood draws them
  (`scan_wood.gdshader`'s use pass, `src/render/wood_use.gdshaderinc`), every mark from the board's
  own seed, growing with the finish's age.
- **The members say how they're used** (meta `use_role`, set where the member is made): a door's leaf
  (3; its latch edge, away from the hinge, turned to the board's +Y: grease at the push, boots at its
  foot), a stair's tread (4: dished in the middle, its nosing rounder), a walk's middle boards (5: the
  deck's middle 40 % across, worn along), a door's jamb (9: polished and grimy at the hand's height).
  The floor's feet are the traffic map's (above). A new kind of member that's used gets a role, not a
  painted patch.
- **The props are worn by their kit looks** (`lib:<entry>/<age>/<role>`, `docs/briefs/prop-factory.md`
  point 1): the bar's top `bar` (its front rubbed and dark, burns along the edge, rings, initials),
  its plinth and low rail `kick` (boots' scuffs).

## Light (#824, Sean's pick 1 on #821: rooms get real light)

The doctor's office is the test room; the jail, the store and saloon B follow it.

- **A spec names its lamps, one a room people use** (`lamps.kit`, FORMAT.md): kit lamps hung on a
  wall's boards (the `reflector_lamp`: it falls and smashes when its boards go), each with its hours
  (`lit` [from, until]), energy and reach. Only the lamps in the rooms a player stands in cast
  shadows (`shadows: true`; the doctor's surgery and desk lamps), the rest don't: render CPU.
  `tests/test_building_<b>.gd` fails a room without one (the doctor's test).
- **A spec has `light`** (`fill`, `window_day`). With it, the building's indoor fill reaches its
  outer walls' inside boards (the base probe stopped at the studs' inner face and faded over 0.3 m:
  the outer walls took the sky's cool fill beside the partitions' amber, the doctor's orange /
  blue-grey corner; proved by the test render in `doctor/results/2026-11-12_light/`), its colour is
  the spec's (near neutral, not a tint), and RoomLight lets the sky (or the moon) in at every outer
  door and window (`light_openings`), `window_day` times its usual day light.
- **By day the windows light the rooms, not a fill** (#829). The fill by day is low (`light.day_fill`,
  0.1 for the doctor; DayCycle's 0.45 else, one even level everywhere, so the far wall was as bright
  as the one by the window: the judge's "flat light"). The light comes in at the windows instead
  (RoomLight's daylight rooms, `RoomLightTuning` "Daylight"): each window's sky spot sits partway up
  the window and aims at the floor 0.6 of the way across the room (a high window steeper; the floor
  found through a counter under it), reaching about twice the far wall's distance (the engine's
  range window has a light at a fifth by 0.87 of its reach) and falling off with distance
  (`window_day` 7: the window side bright, the far side dim, the window's own wall dark round it).
  **By day the windows cast shadows** (doors don't): what made the judge pass the desk (round 1
  without them failed: "no shadows, nothing shows where the light comes from"); the desk throws its
  shadow up the wall, the chair on the floor, and a partition stops a window's light, so each
  window lights its own room and not the next one evenly. Not by night: the moon through a window
  is too faint to show one, and each shadowed light costs render CPU. Their colour is near white
  (`day_window_colour`), not the sky's pale blue (round 1's "blue-grey wash").
  And the sun through a window lights the room round its patch: rays through the window toward the
  sun (a porch roof shades them) and on in find where it lands; a soft spot off that patch, facing
  back into the room, carries the sun's energy x the window's area as the sun sees it x the patch's
  lightness (x2.5, art's), half the floor's hue (the warm wall beside the window view's patch).
  Recast as the sun moves (every 0.5 degrees).
- **Inside paint wears from the room's floor**, not the street's ground (`INSIDE_FINISHES`: inside,
  ceiling, floor): the hand band and the scuffs over the skirting land where hands and boots are.
- **Judge the rooms lit:** the four views of `doctor/light_views.gd` (desk corner, dispensary,
  window from inside, the surgery at night with its lamp), before and after, by the cheap judge.
  `--cpu` measures each view's render CPU; the interior's must stay under 4 ms at Sean's (with the
  windows' shadows the doctor's day views are 1.6-2.8 ms, #829). `--variants=` tries dials in one
  load (`day_fill`, `window_day`, `room.<RoomLightTuning dial>`).
- **What a room by day still lacks** (#829's judge): the dispensary under its one high window, out
  of the sun, still reads flat (judged before #826's sash and glass, when the window was a blank
  card; with them the light holds, not yet re-judged: next, a brighter, tighter sky spot there).
- **Not done here:** contact shadows under furniture (#711's; SSAO is all there is, and the lamps
  that cast shadows), lamps lit by people (a man carrying or lighting one: the lamps keep the clock).

## Walls and windows (#826, Sean's picks 3 and 4 on #821)

- **A finish is drawn at the board width it was judged at.** A spec says `inside_finish.boards:
  "judged"`; the builder cuts members three of the paint's boards wide (27 cm for
  `painted_pale_tg`'s 9 cm) and draws each as that many beaded boards (`strips_mesh`: one mesh, so
  it batches as one board). The test fails a board more than a fifth off its entry's `board_w`.
- **Every boarded room has a skirting** (`inside_finish.skirting`, 0.2 m), stopped at the door
  casings; **casings, skirting and sashes take the trim's finish** (surfaces `/casing`, `/skirt`,
  `/window_` before `/in_ground/`), never the wall's (they vanished in it).
- **Windows are sashes:** give every outer window its `lights` (two-over-two is the 1880s' town
  sash; one-over-one for a small loft or high window). `Checks.built_right` fails a window whose
  panes aren't its lights or whose reveal isn't lined. Barred windows (`bars: true`) keep their
  sashes inside the bars.
- **The sash stands by its joints in the support graph:** linings in framing's tier (as the
  nailers), rails through between the linings, stiles and bar pieces standing on them, a pane on
  the rail or bar under it (glass on trim, `_link`'s one exception). Trim beside trim carries
  nothing: a piece that only touches its neighbours at the side falls at load.
- **A pane is a draw of its own** (glass isn't batched): the doctor went from 14 panes to 52,
  158 draws to 195 in the lab's count. A building with many small lights (six-over-six) wants
  them counted against the render budget before it's specced.

## A stone building's look (#811, the jail)

- **Sashes in stone:** a barred window takes `lights` as any other (SashWindow inside the bars, at the
  stone's face), its reveal lined through the wall's whole thickness (`stone.gd` passes `outer` 0 and
  `inner` the wall's inside face from its `profile`): the boxed reveal its inside shutters fold into,
  so you never look into rubble. Two-over-two (4) for the town's 1880s sash, not six-over-six (12 a
  window, a draw a pane). A slit (`glass: false`) stays open and barred.
- **Lamps on stone:** `lamps.kit` hangs on a stone wall's face at the lamp's height (`_kit_lamps` reads
  its `profile`; a stone partition's `+` side is its line, `-` its thickness in). Cages and cells are
  lit by the corridor's lamp through their straps (its shadows the straps on the floor: the cheap
  judge's best view of the jail); the test asks a lamp of every room but those and the roof.
- **Name every floor:** a floor's surfaces pattern names each floor's id (`floor/ground/` and
  `floor/ground_back/`): one not named falls to `framing` and its boards take the batten. The test
  checks every board of the floor takes the floor's finish. A flat roof's joists and boards are the
  rooms' ceiling: name them (`floor/roof_`, `floor/ell_roof`).
- **Cameras for the judge:** take the sheet's own direction for each interior (the critic marks a
  view looking the other way DIFFERENT, "mirrored"); stand clear of a lined reveal (0.56 m deep, at
  arm's length it fills the frame); the roof from its back over the deck to the parapet, not at it;
  hide the valley's place labels (Label3D) in renders.
- **Until the library has plaster and rubble,** a stone building's walls are the game's `stone`
  inside and out: both judges name its blotched blocks first (the critic leaves it out by brief).
  The spec already names them (`materials.stone` `want` `rubble_stone`, `inside_finish.regions`):
  `_stone_finish` draws them by StoneFinish the moment the library passes an age (#860).
- **Procedural rubble by a height field doesn't pass** (#860, two rounds, `docs/screenshots/judge/
  2026-11-13_stone_r*`): stones drawn as a height field and lit by the screen-space bump
  (`real_bump`) get a dark line on their low edges and a pale one on their high (the judge's "navy and
  cream outlines", "cartoon at 5 m"), steep or soft; plaster as noise reads as a flat card. Don't tune
  it a third time: Sean's pick (#857 follow-up) is the method.
- **A parapet that steps** (#857 2a): a wall's `parapet_steps` [[s0, s1, top]] raise it over a run
  (the door's centre, the corner piers); every row from the base coping up is cut at the steps' edges,
  the base coping under a step an ordinary piece. **Dressed stones proud** (`stone_wall.dress`): sills
  by `sill.proj`, the coping by `coping.proj` (past a free end too), lintels by `dress.lintel`; the
  coping's stones `coping_len` long, `coping_jitter` off level.
- **Merging the building's branch:** `git checkout --ours FILE` on a conflict keeps all of one side's
  file, not only the conflicted hunk (the jail's stone checks went); resolve with `git merge-file` or
  by hand.
- **A lot's walk or spec in valley.json re-hashes the bake:** re-bake (`tools/valley/valley_plan.py
  --bake`; if the ground didn't change, only `valley_json_sha256` moves).

## A two-storey building under trusses (saloon B, #848 step 1)

What the corner saloon's frame taught (its record: `saloon_b/README.md`):

- **Write the spec with a script while its numbers move** (feet to metres, every wall's openings
  from the same constants), then keep only the JSON. B's girder lines, well and partitions moved
  three times before the checks passed.
- **Lay the upper floor out from its bearing lines first:** the two girders, the bearing
  partitions under them, a beam on posts wherever a floor's edge has nothing under it (the well's
  gallery, the stair's well, the stair's head: the stringers land on a beam, never on a joist).
  A floor that would need tail joists is split into floors instead (the band ladder can't hang a
  tail from a header and carry boards on it).
- **Keep openings off the lines where a girder or beam meets a wall** (its wall post stands in the
  studs there), and stack upper openings over lower ones centred and no wider, or a clear 0.3 m
  apart; set `frame.stacked`.
- **A bearing partition that runs with the joists stands on a girder** (`girders.under`), not on a
  floor board between two joists (the crowd's check failed one board in twenty).
- **Run the game's own settle on the built building** (`b.settle()` returns nothing on a sound
  frame), not only `Checks.stands`: it found the balcony's joists hanging by one end after a change
  the stand check had been run before.
- **Load it as its use loads it:** B's dance floor is checked at 70 lb/ft2 (Hatfield's hall), not
  the 40 of a dwelling: the balloon studs went to 4x4 and the joists to 12 in for it.
- **A collapse on purpose needs room to fall.** Cut, the girder's pieces and joists stood jammed:
  rigid pieces as long as their bays wedge end to end, wall boards drawn over the joists' ends
  hold them, and a post's brackets catch a girder's halves. So: the floor's `end_gap` (12 mm),
  the ground floor's wall boards stopped under the ribbon (`to_y`), no brackets under the girder
  that's cut, and the cut made with `cut_member` (a kerf), not `break_member` (two halves in place).
- **Measure a collapse by where the pieces are**, not by which members broke: broken members stay
  where they were; the fallen pieces are the `rubble` group's bodies.
- **The X-ray sheet reads a two-storey frame** as it is (`tools/buildings/xray.py`), its titles
  still the doctor's (the section's, the side walls' names).

## A big room's look (saloon B, #867 step 2)

- **Light scales with the room.** The doctor's `day_fill` 0.1 and `window_day` 7 leave a room 16 m
  deep near black past its middle; saloon B takes 0.32 and 14. Judge an interior by the light the
  sheet painted it in: a bar room by lamplight (19.0), not at 15.5 with its lamps out.
- **Name every surface** (`materials.surfaces`, first match wins): whatever is left falls to
  `framing`. A finish redraws a member as a plain board, so a dressed member (a bracket's cove)
  takes the finish `-` to keep its shape.
- **No dressed timber in the library yet:** oak draws fresh orange, rough pine reads as bark,
  planed pine as driftwood; walnut is the nearest for posts, girders, rails and doors.
- **A wainscot** stops at any opening whose bottom is under its cap, with an apron under a sill.
- **Butt a big roof's boards** (`levels.roof_tight`): from inside, 3 mm gaps are specks of sky.
- **The golden images are the old town's**, so a valley building changes none.
- A render is 10 to 14 minutes a view here: give a background render its whole time
  (`timeout`), and try a change on one or two views before a round.

## A shop's look (the general store, #1035)

- **Scale the light by the room before anything else.** The doctor's `day_fill` 0.1 / `window_day` 7 left the 16.8 x 10.7 m
  shop near black; 0.55 / 26 lit it to the back wall (saloon B's 0.32 / 14 was a hall 22 m deep with a bar lamp). Try two
  variants of the dials in one load (`render_valley.gd --variants=`) before any round: a render is ~15 min.
- **A spec that names library entries needs no paint step**: check each `want` entry's `approved` list passes its age, then render.
- **Cameras:** a side panel taken from a 1.2 m alley is a wall of the neighbour's grey box: pair it with a corner view instead.
- **Before the judges: what they will mark that isn't yours.** Empty rooms (props), the cellar's doors and lantern (#695), grey
  neighbours: tell the critic nothing, but expect 5-6 DIFFERENT and don't spend a second round of renders on them.
- **Measure the valley's render CPU once per building** (`--cpu`): a camera under the dug lot (the cellar) draws everything, 5.4 ms.
- **A shop is lit through its storefront, not by dials** (#1053): sash windows on a 17 m deep room leave the back near black
  however the fill is turned. Give a shop a `recess` entry and `show` windows (`Storefront`), let RoomLight see their full area
  (`opening_max_area` 12), and leave the indoor exposure (RealLook `exposure_indoor` 1.7) to do the rest: back wall 0.110 -> 0.193.
  A pale beaded ceiling (`ceilings`, `around_beams`) bounces it; measure each with grey cards, not by eye.
- **Wide openings need a deeper header** (an opening's `header`): a 5 m recess on the 0.15 m default bent 1.24 in the checks.
- **Cloud Vulkan:** `apt-get update && apt-get install -y mesa-vulkan-drivers libvulkan1` gives lavapipe's ICD; Godot 4.7.2 from
  the release zip, `cargo build --release` in the native plugin, `--import` ~6 min.

## The valley

- A lot's `spec` builds its building in place of its block (`ValleyWorld._make_buildings`); tests
  that counted a block a lot or a walk a whole frontage were told so.
- An alley beside an open yard is no alley: fence the yard (the doctor's side fence).
- **A cellar dug in the valley's first ground chunk (x -30 to 98) fails the card-game tests** (#1220): ValleyGround
  re-cuts a chunk's collision into squares round any dug tile, and the saloon yard's card set stands in that chunk.
  The hotel's and saloon B's cellars wait for it (`cellar._dig`); the undertaker's is in the next chunk.
- **A change to the valley's static bodies can tip the card-game tests** (they share one valley; Jolt's contact
  order moves the chairs' pieces): the jail's shorter walk failed both chair tests in every full CI run. Run
  `--only=card_game` after any valley.json walk or lot change; the jail's walk waits on #834.

## A church (#1142, the building lab's fourth practice building after the saloons: a tower and a steeple)

Record: `church/README.md`. What it taught:

- **A new kind of structure goes in its own file, hooked in at three places** (`church_tower.gd`, called from `SpecBuilding.build`): the
  tower's walls are ordinary spec walls (a numeric `top`, `ribbon: false`), its footing, floor, belfry and spire are the module's.
- **Tilted members rest only where their oriented boxes meet** (12 mm): a hip rafter lifted 5 cm off the ring it should land on had
  no load path, so did a spire's whole skin (90 shingle courses). Centre a hip on its line; sit courses on it, not above it.
- **A 28 ft span is the ceiling joists' job** (3 x 15 in at 16 in; 2x10 failed at 1.11 with a crowd); keep the doctor's rafters (a 2x8 and a 10/12 roof stopped touching the ridge board).
- **A belfry's ring of plates carrying a spire needs posts at the middle of each face** (the commons' feet land mid-span) and a deep section
  (0.15 x 0.25); boards run across joists, never with them (a board along its joist read 1.04 in bending).
- **A hatch goes between two joists**, never cutting one (a cut joist is two cantilevers: "joint" 5.4).
- **A pointed (or any shaped) head is the window's, not a decoration over it** (`SashWindow`'s `rise`): cut the opening to the apex so the
  studs, siding and finish all stop round it, then fill the corners beside the point with short stepped boards (the slanted lining covers the
  steps). A V of trim and glass stuck on the siding over a square sash read as a sticker.
- **A bell is a kit prop on four posts** (`solid` 0.035 for its weight); hung bells aren't supported by the member rules.
- **Use points on a platform fail the "used" check** (it wants the floor's height): put the room's point on the floor by it.
- Blocks the place's old grey box and `bell_tower` blocks in valley.json (they drew a box where the building stands).
- **Tiers decide what rests on what** (#1170, StructureMember.TIERS): a bracket's arm (a `beam`) beside its plate (a `beam`)
  had no load path; an arm of a higher tier (`rafter`) on the plate, a brace a `cripple`, did. A second pitch hung off the first
  by its edge fails "joint": lay a ledger on the plates under the joint (`ChurchTower._flare`'s `ledger_from`).
- **A pointed door is a pointed window's head over leaves** (a door's `pointed`/`rise`): the opening cut to the apex, the leaves
  to the springing under a transom bar, `SashWindow.pointed_head` glazed over them.
- **The valley render now peaks over 14 GB:** a 16 GB box OOM-kills it; a 6 GB swapfile outside the repo lets it finish.

## A log building and its yard (Harlan's homestead, #1126)

- **One session can take a small building through every step** when the sheet runs while the code is
  written: push the sheet's request first (on a `claude/art-building-*` branch: the workflow fires only
  there; merge its results back), then build. Eight views, $1.12.
- **Log walls are a part** (`LogWall`, FORMAT.md "A log building's parts"): give a wall `log: true` and the
  builder lays courses, chinking, notched corners, bucks and a board gable. Keep the courses level all
  round (butt and pass at the corners) so every log rests on what's under it; half-offset courses leave a
  log's end over air in the support graph.
- **A porch deck's posts need room:** `_deck` stands its posts on 0.25 m blocks under a 0.12 m beam, so a
  deck under ~0.5 m makes a negative post (a BoxShape error). Put the deck's ledger on the footing's stones
  (the deck a step under the floor) so it rests along the wall, not on one contact at the sill's middle.
- **A repair job is a real piece, and it is weak:** a sprung board fails a crowd. The test lets a member with
  meta `repair` fail the crowd check, and nothing else.
- **Things off the pad stand on the slope:** a Structure grounds members only at its own y 0; the yard's
  `YardStructure` grounds each on the ground under it (`ground_y`), so a pipe down a hill doesn't fall.
- **A dirt floor** (`levels.ground.dirt`): the checks take the ground as the floor for use points under the
  sills' level.

## A cellar you walk down into (the undertaker's, #1174)

- **The valley's ground is a height field: a cellar needs its ground dug.** `cellar.dig` (CellarDig) sets
  Ground's dug tiles (5 cm points) under the cellar and the bulkhead's areaway to the cellar's floor, the
  cut's edge 10 cm inside the walls' stone so its slope never shows. The lab's ground opens the same pits
  (`lab.gd`). No pad needed: the lot keeps its slope, and `lot.ground.plane` (checked against the bake in
  `tests/test_undertaker_valley.gd`, within 4 cm) stands the yard's things on it.
- **A cellar's rooms are partitions on its flags** (walls of level `cellar`): put the bearing ones under
  the girders (they carry them); a door in one needs 1.98 m under its header, so the cellar's floor goes
  1.6 m under the street edge (2.41 m to the joists). Its openings and lamps count from the flags' top.
- **A post on floor boards gives the boards its load** (StructuralAnalysis shares an upright's load evenly
  among what it touches): a summer beam's post goes down through a slot in the floor onto its girder,
  standing between two joists and 2 cm clear of the boards (CONTACT_EPSILON is 1.2 cm). Put the girders
  on a floor board's middle so the slot cuts one row.
- **Keep a partition off a summer beam's line** (its plate and the beam overlap: the settle drops both).
- **A beam sits on a hatch's edges only if the hatch's sides are on the girders' faces** (boards beside a
  hatch over a strip with no joist bent 2x with a crowd).
- **An outward door in an outer wall has nothing under its leaf** (the floor's inside): open it inward.
- **The walk test** (`Waypoints._foot_height`, `_walkable`, as saloon B's): sample every 0.2 m up a steep
  stair (a 44 degree stair rises 0.27 in 0.3 m, over STEP_UP); the player's own limit is 46 degrees.
- **Valley bodies:** 44,986 of Jolt's 65,536 with the undertaker in (his 4,079): no guard to raise.
- **A building's history in blood** (#1187, `src/art/past_stains.gd`): a `past` event's `blood` is laid once the building
  stands in a world, through the game's own systems (dried Blood splats, FloorMarks stains), so it scrubs off, saves and
  draws as any blood. Place it by the props (`by`, `off`) and the ways people go (the stair, the carrying path), never on a
  prop's top (a ray finds the floor; a kit prop's hit is refused) and beside a heap, not under it. Keep it under two fifths of
  Blood's cap (160 a world); Blood's cull spares it (`past`). A save holds it all (SaveGame clears Blood before loading).
  A `smoky` lamp burns deeper and sooty (soot up the boards over it); `light.cellar_haze` the cellar's close air.

## A big two-storey hotel (#1220, the Salt Creek Hotel's main block)

- **Past 60 ft wide, a flat roof behind the parapet** (`frame.flat_roof`): a queen-post truss won't span 80 ft, and the
  period's blocks were flat behind their fronts. The roof is a floor on the plates, a ribbon on the false front's
  studs and the upper bearing partitions (those full height, the rest 2 cm short); its boards take no crowd.
- **A bearing wall across the joists needs a sole** (a floor's `blocking` {z, sole}): the analysis bends a board under
  studs however well it's carried (blocks under it still failed 2x). Lay the wall's line on one board row over the
  girder, and the sole replaces that row.
- **Keep every joist line 1.2 cm clear of a wall's studs and of every post** (CONTACT_EPSILON): 5 mm from the lane
  wall's studs, a ground joist carried two storeys of wall; a well's post through the floor stood a joist on it. Floors
  stop 0.12 short of a 4x4 wall; posts go where the joists' lines (0.145 + 0.406 k) aren't.
- **A stair's stringer stops clear of the partition at its head** (its boards rest on the stringer), and the leaves of
  doors near a stair's foot open away from it. A back stair is easiest with its head at the outer wall (the stringers
  on its ribbon, the well wall to wall: no tail joists).
- **A balcony to be blown down: a beam a bay ending on the posts, and a deck a bay** (its boards cut at the post lines,
  or the fallen bays hang on their neighbours' boards). The decks end at the posts' centres, the rails' ends over them.
  Measured by physics: blow the post (`break_member`), settle, and count the broken joists bay by bay.
- **A drift (a tunnel) under the valley's height field**: dig its trench and lay a cover of the ground's own material
  over its lagging (CellarDig: the cover's top where the ground was, sampled before the dig; skipped on a re-dig).
  Measure its head room with a man's box, not a ray (rays up from the planks found nothing).

