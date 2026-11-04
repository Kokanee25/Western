# Brief: toward Red Dead (the realistic look)

Sean, 2026-11-04: "We can toss the old painting style since that's just not happening anymore. We
need to make better characters, the sets need to look better (I know we can make better wood, we've
already had good results), we need better props, better horses, better everything." And: "I'm not
actually expecting that level, just that direction." The decision is DESIGN.md §4 (2026-11-04);
#615 chose realistic over painterly; this brief is the plan.

## Goal

Every view of the demo's slice (the street block and the saloon) moves toward Red Dead
Redemption 2's look: real materials, light with shape, air, wear, variety, and people and horses
that read as real. **Red Dead is the compass, not the bar.** Done for the slice is the cheap judge
calling its views "AA" against the references; each step on the way should move views up a notch.

## How it's judged

- **The cheap judge** (`tools/critic.py cheap`, `docs/concept/judge/CHEAP.md`, self-test
  `cheap-probes`), always with `--refs=<Studio>/references` (RDR2, KCD2, Hunt 1896: the private
  Studio's official screenshots, #613; Dishonored 2 out since #615). Before and after on the same
  views every step; its verdicts go in the status entry and `history.md`.
- **The views:** `saloon_night`, `saloon_back_wall_night`, `saloon_toward_door_night`,
  `man_saloon_night`, `road_low_noon`, `street_golden_hour`, plus one film strip; more as a step
  needs (a prop close up, a horse).
- **Sean's F3 on the Shadow PC** for the frame cost of anything that draws more: realistic light
  costs GPU, and this workspace only has a software renderer (lavapipe).
- **Goldens** re-approved in the merge that changes the look (CLAUDE.md), as each step makes it the
  game's.
- The painted references (`docs/concept/`), the art judge's painted rubric (`RUBRIC.md`) and
  `judge.py`'s painting scores stop being the yardstick. The blind critic (CLAUDE.md "Art merges")
  runs against the AAA references and the realistic targets instead of the paintings.

## What's retired, what stays

- **Retired:** the per-texel look (`texel_grid` squares, `min_square_px`, `texels_per_meter`
  snapping), the depth mosaic, quantising and posterising (`Settings.mosaic`, `quantise_once`,
  `surface_blocks`, `pixel_shading`), the nearest-neighbour blow-up of a low internal resolution
  (`src/main`'s pixel pipeline), the painted textures and painted men, the painted concept art as
  the target. Code is switched off first, deleted later once nothing needs it.
- **Stays:** everything that makes the game ours: structures and destruction, bodies, fire, blast,
  people's minds, the town and its layout, the Studio, the wear systems (`BuildingAge`, the stain
  sheet, `FloorMarks`, the building spec's `use`/`past`), the light systems (`LightLooks`,
  `RoomLight`), mocap, the judge.

## The steps (one session each unless said; lanes run in parallel)

### Art

- **R0 the realistic renderer** (first; everything after is judged on it). A look, "real", behind
  the look panel (N) and `--look`:
  - native resolution (the SubViewport at the window's size or a scale of it, with
    anti-aliasing: TAA or FSR2 and MSAA where it pays), no nearest blow-up;
  - the texel grid's squares, the mosaic and quantising off; the world's shaders drawing their
    textures smooth with mipmaps;
  - realistic materials where the textures exist: albedo, normal, roughness, AO (start with the
    woods and the ground);
  - SSAO, SSIL, SDFGI outdoors only (the saloon's indoor light is RoomLight's), volumetric fog, a
    filmic tone curve (AgX), exposure;
  - the judge before and after with refs; Sean's F3. Then Sean's word makes it the default.
- **R1 light with shape:** the saloon at night dark between its lamps (light pass round 3's warm
  wash taken back, RoomLight's bounce carrying the pools: #618's third option), haze in the light;
  then the street by day (#608 part 2: shade, haze with distance, contact shadows).
- **R2 sets:** scanned CC0 materials (Poly Haven, ambientCG: planks, weathered paint, rusted metal,
  dirt, rock), fetched on GitHub like the references (this container can't reach them), recorded in
  `CREDITS.md`; the wear systems driving dirt and wear on them; boards that warp, gap and sag (the
  members already exist one by one). The material lab measures them; the material lab's round 1
  Studio repaint (Sean's pick, #391: "good results") is a candidate for the painted fronts.
- **R3 dressing and variety:** no visible copies (the bottles, sconces, pebbles, grass), the saloon
  filled or its size settled (Sean's call), the street's ends closed.

### Prop lab

- **P1 realistic props:** CC0 scanned models where they exist; Rodin for the unique ones (it
  outputs the material maps); variety rules in the kit (a few shapes, scales and tints, gaps).
- **P2 the horse:** the bay's coat realistic (Rodin's maps, dust low on the legs), mane and tail as
  hair cards, then the gait (the walk's passes, #478).

### Characters

- **C1 the light route:** the Studio's men drawn realistically by R0's renderer (their Rodin
  textures as they are, a skin shader that wraps light, hair cards cut smooth as Human Generator
  round 2 did); judged in the saloon and street. Human Generator is parked (five rounds, #547).
- **C2 only if C1 falls short:** MetaHuman on Sean's Shadow PC (#558's route A); its licence allows
  Godot.
- Then real clothes (`proper garments`, the fitted coat #502/#503) and hats.

### Gameplay

- **M1 motion polish:** planted feet (foot IK, the run's drifting foot), idles and weight shifts
  for everyone standing, no popping in at doors (the gang's arrival), people looking at what's
  happening.

## Spending

None expected for R0, R1 or C1. R2's materials are CC0 (free). Rodin props and horse maps: each
step asks Sean with the cost first (the Studio's ledger, under its budget).

## Not now

- Matching Rockstar shot for shot; strand hair; a custom renderer or engine fork.
- New systems: the realism comes from drawing what exists better.
