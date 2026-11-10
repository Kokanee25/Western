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
