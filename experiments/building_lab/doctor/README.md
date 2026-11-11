# The doctor's office (#765): the first practice building

Art lane, branch `claude/art-building-doctor-8rz70p`. The building lab's six steps
(`docs/briefs/building-pipeline.md`), each shown to Sean before the next.

| File | What |
| --- | --- |
| `sheet/` | step 1, the target sheet: `request.json` (the views' words), `panels/`, `sheet.jpg`, `spent.json` |
| `REFERENCES.md` | the period references (found by search; not opened from the session) |
| `doctor.json` | step 2, the spec (format 1 and what's NEW for a one-storey gable front) |
| `results/plan.png` | the ground plan drawn from the spec (`tools/buildings/plan_sheet.py`) |

## Step 1: the target sheet (approved by Sean, 2026-11-10)

Ten views painted one at a time by Nano Banana Pro on GitHub (`tools/buildings/target_sheet.py`,
`.github/workflows/building_sheet.yml`; later views are given the front and the plan to match):
$1.41 of a $2.50 cap. Sean's calls: a gable front (not a false front), white with green trim, the
surgery lit from the east, approved as is. The sheet's faults are settled in the spec, not repainted:
the window reads "DRUS" (the game's lettering spells DRUGS), the rear view's L-shaped wing (the
building is one rectangle with a back porch), the plan's scale bar (sizes are the spec's).

## Step 2: the spec

28 x 48 ft, one storey, 11 ft ceilings, floor 3 ft up (its walk's top), a 9/12 roof gabled front to
back. Front to back: the front office across the width; a 4 ft hall down the middle to the back door;
the dispensary (west) and the surgery (east); his sitting room and the sick room; his kitchen and
bedroom. Every door off the hall opens into its room. The surgery has the two tall east windows and a
3 ft 6 in side door to the yard with four steps (Cathell's second door). The frame is a balloon frame
(Bell, Woodward): 2x4 studs at 16 in, 2x10 joists on the sills and two girders under the hall's
walls, common rafters on a ridge board tied by the ceiling joists (Hodgson). Use points for every
room but the attic (23).

New to the builder (step 3): the common-rafter roof and ceiling joists in place of trusses; ceilings;
brick chimneys; the sign on a gable; the back porch; narrow 4 in clapboard; the hatch (an opening
with no glass); a floor's own joist size (the attic's).

Sean's calls on step 2 (2026-11-10): 28 x 48 ft; the lot dug level (a pad at the street edge's
height, a bank behind); the walk stops at the building and the side yard opens on Main Street
through a wagon gate (a wagon backs to the surgery's side door); the loft made usable (2x10 joists,
a window over Main Street to shoot from, a loft door in the back gable with a ladder up to it).

## Step 3: the build, the checks, the X-ray sheet

`tests/test_building_doctor.gd` builds it in the lab (3,398 members, 115 draws) and checks it:
destructible through and through; it stands (nothing over 16% of its limit under its own weight,
nothing over with a crowd on both floors); **built right** (`Checks.built_right`, #695: nothing
crosses any of its 28 openings through the whole wall, the 18 in outer walls framed and every
window glazed); doors and use points fit a man; every room has its use points; the porch's posts
carry its roof. `results/xray.jpg` is drawn from the built members (`tools/buildings/xray.py`).

What the checks caught on the way (each fixed in the builder or the spec):
- the door's kings ran up through the loft window over it, the window's down through the door
  (kings now stop under and over stacked openings, the window over the door a band up);
- the loft's joists broke over the hall's line in the front office with no wall under them
  (summer beams on posts there now);
- a tilted rafter's box takes in the whole loft, so it rested on fifty things and failed at its
  "joint" (in a rafter roof a tilted member touches only what it truly meets; pairs meet at the ridge);
- boards cantilevered past their joists at the chimney holes (the holes snap to the joist lines);
- the porch's joists couldn't rest on its ledger (the order members stack in);
- 2x8 loft joists at their limit over 13 ft with a crowd (2x10 now).

## Step 4: the look (unpainted, from the library by name)

Sean, 2026-11-10: B, unpainted for now on swatches the materials judge passed (#721), no unjudged
woods; each surface takes its finish from the library by name (`materials.finishes`: `want` the
paint, `use` until it passes). Outside C1 old, inside F2 a few years, what's rough R1 a few years;
stone, brick, glass and the sign stay the game's. **The paints he needs** (the next material round):
white lead on narrow planed clapboard (`painted_white_lap`), bottle-green trim, corner boards, sash
and doors (`painted_green_trim`), pale painted beaded boards inside, cream and grey-green
(`painted_pale_tg`); and the sign's lettering, PHYSICIAN & SURGEON (the factory's `lettering`, paid).
Library boards are batched by `Structure` by the way they face (Sean's OK to edit it): 109 draws.

## The valley

`config/valley.json`'s doctor lot: `spec` (this file), `pad` (the lot dug level at the walk's street
edge, -0.23, a 3 m bank: re-baked, only those 144 points changed), the walk's `span` (to the building)
and `door_x`. `ValleyWorld` builds him in place of his block; the side yard opens on Main Street by
the wagon gate; a board fence keeps the doctor's alley an alley. The sheriff mission plays through to
him (bridge, 2026-11-10: packed, taken in 484 m, laid at his steps, `sheriff.care` good).

## Step 5: the judge

`render_valley.gd` draws him on his lot in the game's light from the sheet's views;
`tools/buildings/judge_pairs.py` sets each beside its target.
- **Round 1** (`docs/screenshots/judge/2026-11-10_doctor/`): the blind critic 3 CLOSE (front, side
  yard, surgery) / 5 DIFFERENT, three of those my cameras behind door leaves; the rear "a tall
  storey-and-a-half, no ell" (the sheet's rear had an ell the plan didn't: settled as one rectangle).
  The cheap judge (`2026-11-10_doctor_cheap/`, with the Studio's AAA references): all eight cheap
  indie; its reasons: the grey-box neighbours, the empty rooms, light with no fixture.
- **Round 2** (`2026-11-10_doctor_r2/`: the interior cameras in each room's far corner, clear of the
  doors; the sick room by day): the blind critic **5 CLOSE** (front, side yard, surgery, dispensary,
  quarters) / 3 DIFFERENT (the rear: the sheet's ell, and the ladder, loft door and stair that are
  Sean's loft; the front office and sick room: near black). Its top three: the rooms near black and
  red (the bare walnut, no lamps: "a pale stand-in would settle it"); the inside unfinished (posts,
  the summer beam, wide boards whose grain reads as plywood; no casings shown); the rear. The cheap
  judge (`2026-11-10_doctor_r2_cheap/`): all eight cheap indie, best the side in sun and the surgery's
  sun on the floor; its reasons: empty rooms (props later), the grey-box neighbours and the windows'
  grey void, the dark interiors with no lamp. Fixed after it: the chimneys (an unknown "brick" drawn
  as timber: the game's stone now).

## Step 6: the recipe

`../RECIPE.md`.

## The paints (#721's paint round, 2026-11-11)

The library's paints passed the materials judge (`docs/screenshots/judge/2026-11-11_paint_r*`), so the
doctor's `want`s are used on load: `painted_white_lap` (few) outside, `painted_green_trim` (few) on the
corner boards, trim and outside doors, `painted_pale_tg` (few, cream) inside and on the ceilings. Renders in
game light by `render_valley.gd` (front, side yard, front office, surgery) and each beside round 2's
unpainted one: `results/2026-11-11_paint/`. `painted_pale_tg_green` (the surgery's grey-green) is in the
library too, for when the spec gives the surgery its own finish.
