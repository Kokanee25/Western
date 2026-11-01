# Library clips

Generic movement for every man, played by `LibraryMotion` (`src/bodies/library_motion.gd`) when
`Settings.library_motion` is on (off in the game until Sean passes them; `-- --library-motion=on`,
the bridge's `library on`).

Since #539 these are **real people from the CMU motion-capture database** (B. Hahne's BVH
conversion; credited in `CREDITS.md`). The first set, from Quaternius' and KayKit's free CC0 packs
(#529), was cartoon motion on our men (Sean: "brutal", the strafe "highland dancing") and is gone.
Made by `tools/blender/library_motion.py takes|promote` from `tools/blender/library_picks.json`
(every candidate take, the pick and why); the takes are fetched by `tools/blender/fetch_library.sh`.
Each gait is one loop cut from a long take's steady middle (`find_cycle`), turned to face ahead,
made seamless, in place, its stride fitted to keep the foot carrying him still. `manifest.json`
lists each clip: its take, licence, length, loop, speed and stride.

How well the feet stay put in the game (`tools/library_lineup.gd --measure`: the carrying foot's
skate, m/s; the game's own gait in brackets): walk 0.12 (1.04), backwards 0.50 (1.16), sidestep
0.42-0.44 (1.12), crouch walk 0.51 (0.41), run 1.15 (2.24: a CMU runner's planting foot drifts on
our legs; foot IK would fix it).

Not here yet: the one-handed aim, the reload, hits (Uthana, #539 step 3, with Sean's OK on the cost).
