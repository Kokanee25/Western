# Brief: mopping (Sean, 2026-10-22)

Gameplay lane, with the prop lab's leave for the mop and its bucket (`src/props/`, `assets/props/`:
each commit that touches them says so). Branch `claude/gameplay-mopping`, on top of the barkeep's
rag (`claude/gameplay-barkeep-rag`, PR #260: the chores, `reach_to`, the cloth's soft body).

## Goal

The saloon's floor gets dirty and the barkeep mops it: blood, spilled drinks, and the mud and dust
boots bring in from the street. When it's quiet he fetches his mop and bucket, wets the mop, mops
the dirty stretch in side-to-side strokes, rinses and presses it out in the bucket as it fills with
dirt, and puts them back. A dirty mop spreads dirt; a dirty bucket he empties outside and fills
again at the trough.

## Sean's calls (2026-10-22)

- **Who mops:** the barkeep (his chores; no new man).
- **Spilled drinks:** wet patches now, built so the water lab's spills (roadmap: a grid of puddles
  that run across and between the boards) can drive them later.
- **The floor in general:** mud and dust tracked in on boots.
- **The mop head:** a soft body, as the rag.

## What it's made of

- **`FloorMarks`** (`src/world/floor_marks.gd`): what's on the boards, one shared part. A sparse
  grid of 12.5 cm cells over every floor something lands on (found by a ray onto a floor member),
  each with **dirt** (g/m²), **liquid** (ml, by kind: water, whiskey, beer, lamp oil) and **stain**
  (soaked in, by kind). The grid *is* the water lab's substrate: its spills will move liquid from
  cell to cell; today liquid only stays where it fell, soaks into bare boards and dries.
  - **Tracked dirt:** every walker's boots pick up dirt on the street (`boot_pickup`) and leave it
    step by step on boards (`boot_shed`), so it builds at the door and along the bar.
  - **Wet patches:** `Events.liquid_spilled` (a broken bottle, a knocked cup) puts its litres down as
    a thin film round where it landed; it dries (`evaporate`, by kind) and part soaks in as a stain
    (whiskey and beer leave one, water doesn't).
  - **Blood** stays Blood's own painted marks (splats, pools, prints); cleaning reaches them too
    (`Blood.take`: a mark gives up its ml and shrinks; dried brown it comes up slower).
  - Drawn as one decal a 4 m chunk of floor, its texture a texel a cell (dust, wet and dark, stain),
    redrawn only when it changes; a decal draws on the world's layer only, not on people.
  - `clean(at, radius, ...)` takes what's under a mop; `mess(near, radius)` says how much there is.
- **The mop** (`MopProp`, `src/props/mop_prop.gd`, kit kind `mop`): a 1.3 m ash handle and a cotton
  head as one Jolt soft body of strands (the rag's parts: pinned tops moved by the prop), holding
  water and what it's picked up; it drips when it's too wet, leaves a wet film and spreads its own
  dirt when it's dirty. Held in two hands; free it falls as a rigid handle.
- **The bucket** (`MopBucket`): the bucket line's wooden bucket (its model shared, not a second one),
  with water and the dirt rinsed into it (its water darkens).
- **The chore** (`MopFloor`, `src/people/mop_floor.gd`, dials `config/mop.tres`): a second chore in
  the barkeep's mind (`CivilianBrain.chores`; one at a time). It wants to when the floor near his
  post holds enough mess (fresh blood first) and nobody's near; trouble stops it (mop and bucket
  set down where he is); he finishes and puts them back.
- **Arms by dials:** both hands on the handle by `reach_to`, the head's path a sweep of dials
  (stroke width, rate, lane spacing), his trunk turning into each stroke.

## References

- Bare softwood boards take up spilt liquid; evaporation off an indoor floor film ~0.1–0.3 mm an
  hour for water (still air, ~20 °C), faster for a 40% spirit at first.
- Mud tracked in: most of a boot's dirt is shed in its first few steps indoors (entrance-matting
  studies: ~80% in the first 3–5 m); a dry street gives dust, a wet one mud.
- A cotton mop head holds ~3 times its dry weight of water; pressed, it keeps about one.
- The rag's lab (`experiments/barkeep_rag/`) for the soft body, the chores, the cost and the film.

## What done looks like

1. **The lab** (`experiments/mopping/`): the barkeep, the bar, a floor of boards, his mop and
   bucket, scenarios (the floor muddied by walkers then mopped; a bottle smashed and mopped; blood
   after a fight mopped; interrupted; the bucket emptied and refilled), a film, the cost.
2. **The saloon:** his mop and bucket in the corner behind the bar; the gang's boots muddy the
   floor; he mops when it's quiet.
3. **Tests** for the floor (dirt tracked, a spill's patch, drying, stains, cleaning, blood taken up)
   and the chore and props.
4. **The cost** within People and Physics, the floor's drawing within render.
5. **Promoted:** `docs/PARTS.md`, `docs/LAYOUT.md`.

## How it's judged

Sean watches the film: does the floor read as a saloon floor getting dirty and clean, does the mop
read as a wet mop, does he mop like a man who's done it a thousand times? Numbers: what's left
after a go, the cost, the faults (points through the floor, flung, lost).
