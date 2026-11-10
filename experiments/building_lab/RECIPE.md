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

(Filled in when the doctor's round is judged: see `doctor/README.md`.)

## The valley

- A lot's `spec` builds its building in place of its block (`ValleyWorld._make_buildings`); tests
  that counted a block a lot or a walk a whole frontage were told so.
- An alley beside an open yard is no alley: fence the yard (the doctor's side fence).
