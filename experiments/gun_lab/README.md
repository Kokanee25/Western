# The gun lab

`docs/briefs/labs.md` "Gun lab" (Sean, 2026-10-21), roadmap 3.2 beside it: everything about a gun
except where its ball goes. How the revolver and the coach gun look in the player's hands and in a
man's, and every movement of handling them: draw, cock, aim, fire, reload, holster, drop. It takes
in the "weapon handling and feel" measures, on `tests/test_gun_feel.gd` and
`config/feel_ranges.json`.

**The bench changes nothing in the game.** Each fix after the baseline is one change, measured
against it (`run.py --compare=BASE,NEW`), with its sheets beside the baseline's.

Real guns, made-up names (Sean, 2026-10-21): the shapes and mechanics are the 1870s guns' (a Colt
Single Action Army, a side-by-side hammer coach gun), but nothing the player sees carries a real
maker's name, logo or stamping. Sounds belong to the sound lab: this lab leaves them alone and
lists what it needs from it (below).

Everything is in this folder. Outputs go under `build/gun_lab/` (git-ignored). The baseline's
table, findings and sheets are in `baseline/`.

## Commands

```sh
# everything: handling numbers (headless), both guns in first person and the four Studio men
# (drawn, xvfb + lavapipe: ~25 min with 2 at a time on this workspace's 4 threads)
python3 experiments/gun_lab/run.py --out=build/gun_lab/base
python3 experiments/gun_lab/run.py --job=handling --out=build/gun_lab/h    # numbers only, ~7 min
python3 experiments/gun_lab/run.py --job=fp --out=...                       # first person only
python3 experiments/gun_lab/run.py --job=men --bodies=sean_s2 --out=...     # one man
python3 experiments/gun_lab/run.py --sheets=ROOT          # the sheets and table again, no Godot
python3 experiments/gun_lab/run.py --compare=BASE,NEW     # every handling number that moved
# one job in a game you're driving
python3 tools/bridge.py start --size=960x540 --fps=60
python3 tools/bridge.py "gun_fp revolver out=build/gun_lab/x" "gun_men bold_cowboy_s0 out=build/gun_lab/x"
python3 tools/bridge.py "gun_grip old_rancher_s1"          # the grip's and holster's gaps, no frames
python3 tools/bridge.py "gun_handling out=build/gun_lab/x"
python3 tools/bridge.py "gun_framing shotgun"              # each hand's share on screen, its parts' pixels
# quick views for working on a pose or a hand: the player alone on a plain floor, seconds a frame
# (not the baseline's frames); detail_* look at the gun from its left, right, below and print
# where the grip and every finger bone sit in the gun's space (cm) to the log
xvfb-run -a -s "-screen 0 960x540x24" godot --path . --rendering-driver vulkan --resolution 960x540 \
    -s res://experiments/gun_lab/views.gd -- --out=build/gun_lab/v --gun=revolver [--only=rest,detail_right]
```

`--hour=H` (default 16, the sun behind you), `--jobs=N` (2), `--skip-done`. Rendering needs xvfb and
lavapipe (`apt-get install mesa-vulkan-drivers xvfb`) and the native plugin built
(`cargo build --release` in `addons/saltcreek_native`, copy the `.so` to its `bin/`).

## Files

- `bridge.gd`: the lab's bridge commands (`BridgeLab`): `gun_fp`, `gun_men`, `gun_grip`,
  `gun_handling`. Nothing in `src/debug/dev_bridge.gd` changed.
- `bench.gd`: the jobs. Each clears the town first (TownLife and the outlaw spawner stopped,
  everyone freed, the clock set and stopped) and stands the player, or a man of the lab's own, in
  the middle of Main Street at (-6, 0, -8.4).
- `views.gd` (a launcher) and `views_impl.gd`: the quick views.
- `run.py`: the runs (a fresh game a job, through `--bridge-script`), the sheets, the table, the
  comparison.
- `baseline/`: `baseline.md` (the table and the list of what's wrong), `handling.json`,
  `men_*.json` (every gap), `fp_*.json`, `manifest.json`, `sheets/`.

## What's measured

**First person** (`fp_<gun>.json`, `sheets/fp_<gun>.jpg` and `_close.jpg`): a frame at rest, aiming
(a second settled), walking, running, a tenth of a second into cocking, cocked, every step of the
reload a moment into it (all six chambers spent: the revolver's gate, each case ejected, each round
loaded, each turn, the gate closed; the coach gun broken open, each shell pulled, each loaded,
closed), the aimed shot at the top of its kick, and put away looking down at the hip; with each
frame, `framing`: the share of each hand's parts on screen (a gun with no hand in view floats).

**A man's gun** (`men_<body>.json`, `sheets/men_<body>.jpg`): each Studio man (`bold_cowboy_s0`,
`old_rancher_s1`, `young_drifter_s1`, `sean_s2`) holstered, 0.15 s into the draw, aiming at a man
6 m off, a frame after a shot (the smoke and flash `OutlawBrain._fire_at` makes), reloading (as the
brain does it: crouched, a 12 s timer) and dropped (`drop_gun`, 2 s later); each from his front
right at 1, 5 and 10 m (1 m on the gun). With every state, the **gap**: his skinned hand's points
(posed by his skeleton) against the gun's grip, or holstered his hip and thigh against the gun's
frame: `nearest_mm` (0 = touching or inside), `inside_share` (his hand's points inside the gun:
the gun cutting through his hand), how far the two middles are apart, and `floating` when the
nearest point is over 15 mm off. Dropped: how far its lowest point sits above the ground, and
whether it's come to rest.

**Handling** (`handling.json`), the player's guns driven frame by frame as fast as the controls
take (each press the first frame it can), on game time:

| Number | How |
| --- | --- |
| Draw to first shot | from the holster key to the ball leaving: draw, cock, fire |
| Cocking | from the cock key to cocked and the hand free |
| Fastest shot to shot | cock and fire the moment each takes, five shots (two for the coach gun) |
| Reload one / a full load | a key press the moment the hand's free, from one spent / all spent, to the gate (action) closed |
| Sight recovery | an aimed shot held still: the barrel's line against where you aimed (sway and kick, as `_shot_line`): its worst, when it's settled (stays within 0.25° of where it ends), what's left (the climb you pull down) |
| Accuracy | 16 shots each where the ball crosses the plane 10 m out against your line of sight: R50 and R90 (cm), the share inside a 45x75 cm torso; steady (2 s on the sights), rushed (0.25 s after raising them, cocked already), from the hip, walking from the hip |
| Wounded | the same aimed, after a revolver ball through the left upper arm (3 s after, adrenaline masking it, and 45 s after), then one through the gun forearm too |
| The outlaw | `OutlawBrain`'s own figures beside them: his draw, reload timer, rounds a load, calm spread, time between shots |

## For the sound lab

Sounds the gun lab's moves will need (the lab doesn't make them): the hammer to half-cock (a
softer click than full cock), the gate opening and closing, the ejector rod's punch and a case
falling on boards and on dirt, a round pressed in, the cylinder's ratchet clicks (one per
chamber), the coach gun's top lever and the barrels dropping, shells pulled and dropped, the gun
coming out of a holster (leather) and going back, a gun dropped on boards and on dirt, a gun shot
out of a hand (the ball on steel). Today `SynthSounds` has `cock`, `dry_fire`, `ratchet`, `gate`,
`insert`, `eject`, `break_open`, `close` for the player's guns; a man's gun has only its shot.
