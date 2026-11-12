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

## The valley

- A lot's `spec` builds its building in place of its block (`ValleyWorld._make_buildings`); tests
  that counted a block a lot or a walk a whole frontage were told so.
- An alley beside an open yard is no alley: fence the yard (the doctor's side fence).
