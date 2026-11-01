# Library clips

Generic movement for every man (issue #529): CC0 animations from **Quaternius' Universal Animation
Library** (UAL1 Standard) and **KayKit's Character Animations 1.1** (Rig_Medium), retargeted onto
our 17 segments by `tools/blender/library_motion.py` (the picks and every candidate take in
`tools/blender/library_picks.json`; the packs fetched by `tools/blender/fetch_library.sh`).
`manifest.json` lists each clip: its pack, file and animation, licence, length, loop or not, a
gait's speed and stride on our rig, the loop's seam before and after the clean-up.

Played by `LibraryMotion` (`src/bodies/library_motion.gd`) when `Settings.library_motion` is on
(off in the game until Sean passes them; `-- --library-motion=on`, the bridge's `library on`).

| Move | From | Why |
|---|---|---|
| `idle`, `walk`, `crouch_idle`, `crouch_walk`, `hit_front`, `hit_head` | Quaternius | a grown man's proportions: the walk is 0.72 m a step on our rig with the planted foot steady; KayKit's walks are a chibi's short quick steps (0.3-0.4 m) |
| `run`, `walk_back`, `strafe_l`, `strafe_r` | KayKit | Quaternius has no backing or sidestep; KayKit's run keeps the planted foot (its Running_B runs backwards on our rig) |
| `pistol_aim`, `pistol_shoot`, `reload` | KayKit (1H) | every Quaternius pistol clip holds the gun in both hands (10 cm apart): a modern grip |
| `long_aim`, `long_shoot`, `long_reload` | KayKit (2H) | the only long-gun set |
| `look_around` | KayKit Idle_B | Quaternius' nearest is a talking idle |

Not in either pack: a turn in place, a walking sidestep (the strafes are runs), hits from behind or
the side, a stagger.
