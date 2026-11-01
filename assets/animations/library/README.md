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

**Variety** (#539): each man has his own walk, one of five CMU walkers' (08_01, 16_15, 07_01,
38_01, 39_01: 0.12-0.18 m/s of skate) and his own run (09_01, 02_03), picked by his seed, or a
style named for him in `config/walks.json`'s `library` (Lyle walks drunk, 91_09; Brody and the
sheriff confident, 82_09); his stride within ±6% and his arm swing within ±20% of the clip's.

**The gun moves** (Uthana, generated for this project in the Studio's `motions/gun_moves/`, $7.50
with Sean's OK): with his gun out he walks with it low in his right hand (`walk_gun`, 0.10 m/s)
and runs with it raised (`run_gun`, 0.73: better than either CMU run). The aim stance's takes all
came out two-handed, so `pistol_aim` gives only his legs' stance (the gun arm stays the procedural
aim). `reload` and `stagger` are here but no state plays them yet (the stagger: Sean's call,
bullet hits carry no wince).
