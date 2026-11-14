# The library clips lab (issues #529, #539)

Generic movement for every man from two CC0 libraries, Quaternius' Universal Animation Library
(UAL1 Standard) and KayKit's Character Animations 1.1, retargeted onto our 17 segments and played
by `LibraryMotion` (`src/bodies/library_motion.gd`) behind `Settings.library_motion` (off in the
game). The clips: `assets/animations/library/` (README, `manifest.json`); LAYOUT.md "src/bodies",
"Library clips".

```sh
tools/blender/fetch_library.sh                                       # the packs into build/library_src/
~/.venvs/studio/bin/python tools/blender/library_motion.py takes     # every candidate -> build/library/takes/, takes.json
~/.venvs/studio/bin/python tools/blender/library_motion.py promote   # the picks -> assets/animations/library/
xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 30 -s res://tools/library_lineup.gd -- \
    --out=build/lib_takes --sheet --takes --moves=walk,run         # every take on three men, to choose
experiments/library_motion/film.sh build/library_films [street|saloon|lineup|all]   # the films
godot --headless --fixed-fps 60 -s res://tools/perf_bench.gd -- --scene=calm --no-ablate --folk=2 --library-motion=on
```

## Results, 2026-11-01

`results/2026-11-01/`: the lineup film (every clip on the bold cowboy, the rancher and the
drifter), the street (four men walking), the saloon (spec_hall, the camera on Brody), the
farmhouse (#520's scripted run by the back door, from his eyes; the fight from 1:00), the deformation sheet (each clip's frame with its legs and arms bent furthest, front and
side), the takes sheet (every candidate), the old-vs-new films.

- **The picks** (judged on the men, `library_picks.json`): Quaternius for the idle, walk, jog,
  crouch and the two hits; KayKit's legs alone for backing, sidestepping and the aiming stance.
  On our men every KayKit clip holds the arms out from the body and tips the head back (animated
  for a chibi's big torso and head); its legs are fine. Every Quaternius pistol clip holds the gun
  in both hands (10 cm apart): not 1882.
- **Strides on our rig** (the planted foot's speed under him, worked through our own legs): the
  walk 1.08 m/s, 1.44 m a loop; the jog 4.9 m/s; the crouch walk 0.66 m/s. The game drives each
  gait's phase by the ground he covers, scaled to his legs, so the planted foot stays put at any
  speed.
- **Loops made seamless**: the jog's seam 12.8 -> 0.06 deg (summed over the joints), the rest
  under 0.8.
- **Not in either pack**: a turn in place, a look-around, a walking sidestep (the strafes are
  runs: slow, they play slow), hits from behind or the side, a stagger.
- **Falls**: shot dead running, he lands where he did without the clips (0.15 m); standing, he
  folds where he stands either way, but which way follows the idle's weight (off: back on his
  heels; on: the idle had him on his left leg, so to his left).
- **Cost** (`perf_bench --scene=calm --folk=2`, at Sean's): people 5.41 -> 6.39 ms with the clips
  on (the street with twice its folk; already over its 4.0 budget off). Joint writes 81 -> 436 a
  frame: a clip moves every joint every tick where a man standing on the pose moves almost none.
- **Fights go another way with them on** (the poses change what each man sees and is seen by,
  and how he's hit): the saloon, seed 3, the player down at 27 s both ways, but two of the gang
  surrendered with the clips (none without); the farmhouse, back door seed 2, won without, the
  hostage dead with. One run each: not measured, but the gunfight and farmhouse labs should be
  run with `--library-motion=on` before they go on in the game.

## Results, 2026-11-01 (#539): CMU and Uthana

Sean on the first set (#536): "brutal", the strafe and run "highland dancing", the pistol clips
didn't show. Part of that was the lineup tool's: it moved the men twice the speed the clip was
told (the loop wakes every physics tick, it moved them a frame's worth): fixed, and it now measures
the carrying foot's skate (`--measure`; the game's own gait with `--off`). Then:

- **CMU motion capture** for the basics (`library_picks.json`, `find_cycle` cuts one loop from a
  long take's steady middle and one that travels; the speed fitted to keep the carrying foot
  still; the neck and head left to the pose: CMU's two neck bones kinked ours, the chin poked out).
  Skate (m/s, the game's gait in brackets): walk 0.12 (1.04), backwards 0.50 (1.16), sidesteps
  0.36 (1.12), crouch walk 0.53 (0.41), run 1.10 (2.24; the planting foot drifts on our legs: foot
  IK would fix it).
- **Variety**: five walkers (0.12-0.18) and two runners a man picks from by his seed, named styles
  in `config/walks.json` (Lyle drunk, Brody and the sheriff confident), stride ±6%, arm swing ±20%.
- **Uthana** ($7.50, the Studio's `motions/gun_moves`): the gun walk 0.10, the gun run 0.73; the
  aim takes all two-handed (legs only); reload and stagger in the library, not played.
- Sean: "good enough as a placeholder". Still off in the game.
