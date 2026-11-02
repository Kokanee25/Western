# Train step 3: the models (#542), 2026-11-02

## What's made

- **The engine and tender** (`blender/engine.py` -> `assets/train/`): a 2-8-0 after the D&RG
  class 70 of 1880-82 (3 ft gauge, 37 in drivers, 15 x 20 in cylinders: a 10 in crank, a diamond
  stack, a box headlight, a wooden pilot and cab, Stephenson gear inside the frames, so only the
  rods show). 12,770 triangles; the tender 1,164.
- **The rods by distance** (`EngineModel.roll`): drivers s / r; the side rods ride the pins (the
  right leading the left by a quarter); the main rods run from the third pair's pins to the
  crossheads on their slides. Held by `tests/test_train_models.gd`: the rod ends stay within 2 mm
  of the pins and crossheads over a turn, the crosshead travels the stroke (0.508 m), four beats a
  wheel turn.
- **Puffs and smoke:** a puff up the stack each beat (sized by the steam), the cylinder cocks
  blowing white at a start (below 2.5 m/s), the stack's own thin smoke always; the headlight lit
  at night.
- **The five cars of boards** (`TrainModels`): the ore cars (plank sides on stakes, a low heap of
  grey-brown ore: the mine's kind is still Sean's, #552), the boxcar (red sheathing, sliding
  doors, ladders up each end, the roof walk, the brake wheel), the express car (green sheathing,
  barred windows; inside the strongbox, a mail case and parcels), the coach (varnished oak,
  thirteen windows a side, a clerestory, platforms with railings; inside benches both sides of the
  aisle, a stove, three lamps). Arch-bar trucks, their wheels turning with distance.
- **Ladders** (`Ladder`, a new part, `src/structures/ladder.gd`; the player's `_ladder_step`): the
  boxcar is shut and gone over by its end ladders and roof walk (step 2's steps up its ends are
  gone). Walk into a ladder to climb, out over its top to go down; it carries you with the car.
- **Passengers** (`train_passengers N`): the Studio's men seated in the coach, window seats first.

## The proofs

- **The sheet** (`sheet_golden_hour.jpg`, `sheet_night.jpg`, the views in `sheet/`): the train
  standing at the depot at 17:36 and 22:30; the coach inside lit by its lamps at night.
- **The rods at a start** (`films/rods_start.mp4`, 24 s): the engine standing, the regulator
  opened, the drivers and rods turning, the cocks blowing at each beat; then riding beside them.
- **Walking the whole train back to front at speed** (`films/walk_train_back_to_front.mp4`,
  23 s): at 22 km/h, from the coach's back platform up the aisle past fourteen seated passengers,
  through the express car, up the boxcar's ladder, along its roof walk and down, along the ore
  cars, over the tender's coal into the cab. `train_cross`: cars 6, 5, 4, 3, 2, 1, 0 in order,
  the cab reached in 18 s.
- **The frame cost** (`cost.json`; the whole train in view at 25 km/h, fourteen passengers in
  both, lavapipe): draw calls 646 with the models vs 430 with step 2's boxes (+216, ~0.2 ms of
  render CPU at Sean's by the calm street's rate); the train's tick 0.90 vs 1.06 ms (the same
  within noise: the passengers' bodies are most of it); the drawing (placing, rods, wheels)
  0.40 vs 0.18 ms. The frame under lavapipe is the people and the renderer's, the same either way
  (2.17 vs 2.16 s).

## The critic (blind, `critic/verdict.md`): all six FAIL. Its top three

1. The surfaces aren't painted like the authority: square blotches on the boiler and drivers
   that don't follow their forms; the coach inside glossy, photographic grain, the seats plastic;
   the ore cars' planks clean.
2. The light fails at both ends: the cars' shade sides and the coach at night black; the
   lamp-lit coach one glaring orange (since dimmed: 3.5 not 6, the re-render in `sheet/`); no
   cool fill.
3. The ground's coarse squares beside the fine sky; far off the engine a dark smudge; the
   passengers in the windows faceless.

These are the look (Sean's call, step 3's "the engine's colours and how clean it is") and art's
(the painted pass): the models take the game's woods and metals as they are.

## Not done, known

- The cars' woods take the world-space grime and bleach (texel_grid's), which slide over a moving
  car's boards (art: a per-material switch).
- The coach's lamps have no shadows (a moving car's would redraw every frame): their light reaches
  the ground through the walls a little.
- Men can't climb ladders yet (step 7, fighting along the train).
- The wheels still aren't solid (step 5).
- The passengers sit by pose alone (no `Seating` chair: the benches aren't kit props); sitting at
  speed they hold still with the car.
- Under lavapipe the street's perf tests are over their budgets here on main too (18.0 / 19.5 ms
  against 16; with this branch 18.3 / 18.5): this machine, not the train.
