# The kick and shove lab (issue #479)

Sean, 2026-10-28: "a kick and a shove for the player, so he can put bad men over and through
furniture, over rails and down stairs". By the systems, nothing canned: the player's side is
`PlayerShove` (`src/player/player_shove.gd`, numbers in `config/shove.tres`: `ShoveTuning`, with
its sources), the man's side `HumanBody.take_push`.

## How it works

- **The key:** E (the right stick's click). Tapped, a two-handed shove at arm's length (0.75 m
  from your middle); held past 0.22 s and let go, a front kick (1.0 m), slower, and you're off
  balance half a second after it. With the revolver or dynamite in hand the shove is your left
  hand alone (0.6 of two); with the shotgun or a bucket you shove with it held across you.
- **The force:** an inelastic knock between the share of you behind it and him:
  p = m M / (m + M) v. A shove is 0.3 of your 80 kg at 3 m/s: **55 N·s, 0.69 m/s on an 80 kg
  man**. A kick is 0.35 of you at 7 m/s: **145 N·s, 1.8 m/s**, and 130 J into his belly (the
  energy it gives him). Running at him adds your speed to the hands' or the boot's. Nothing is
  scaled for the look of it.
- **His side (`take_push`):** past what he can catch with a step (the blast's knockdown speed,
  0.8 m/s; down to 0.24 on a torn leg, less in shock) he goes over where he stands, turning about
  his feet, braces, and gets up once still. Under it he staggers back, braking as he steps (1 m/s²:
  a shove is ~0.25 m), and on the way:
  - something low behind him (a chair's seat at his knees, a stool, a step up behind his heels),
    or a drop (the top of a stair, a porch edge) takes him over;
  - a light kit prop (under 3 times his weight: a chair, a card table) goes over with him;
  - something fixed at his hips or above (a rail, the bar, a wall, a heavy prop) stops him on his
    feet.
- **Your side:** a torn thigh kicks at its strength or not at all; on a stair a kick costs you your
  footing 35% of the time; a kick at a wall or a post that holds stops your boot dead and your foot
  takes its own energy (about 29 J: it hurts, nothing breaks); a kick at a rail or board breaks it if
  it's more than its `BodyImpacts.capacity`. Kit props take it by `KitProp.take_blow`, bottles and
  lamps break past their `breaks_at`, a spittoon by `LooseProp.take_blow`.
- **The deed:** `shove`, `kick`, and `kick_down` for a man on the floor (Relations: a kick is 1.5
  to him, 0.8 to his friends; kicking a man who's down is a fight with him and his friends). A
  civilian who sees a kick within 15 m is frightened by it.

## Running it

```sh
python3 experiments/kick_shove/run.py --out=build/kick_shove/base      # group O, 20 seeds (~1.5 h, 3 jobs)
python3 experiments/kick_shove/tally.py build/kick_shove/base           # the table below
python3 experiments/physics_lab/run.py --render --scenario=O_gallery_rail_kick --jitter=1 --out=...  # footage
xvfb-run -a godot --path . --rendering-driver vulkan --resolution 960x540 --fixed-fps 60 \
    -s res://experiments/kick_shove/fp_view.gd -- --out=DIR --move=kick|shove [--gun] [--at=0.75]   # first person
```

The cases are the ragdoll lab's group O (`experiments/physics_lab/scenarios.json`, cause `push`):
each pushed back (his +z) as a man facing you is, on the lab's fixtures. Each seed (`--jitter`)
moves where he stands (2 cm, 3°) and the push (10% of its momentum, 4 cm up or down, 6° either way).

## Results (2026-10-28, `results/2026-10-28/tally.md`, 20 seeds a case)

"down" is runs in which he went off his feet; "back" is where his middle ended along the push
(m, from where he stood); "drop" how far it fell; "broke" runs with any member broken.

| case | shove | kick |
|---|---|---|
| open floor | 0 of 20 down; 0.25 m back (0.20 to 0.29), on his feet | 20 of 20 down; 0.88 m back, up again in all |
| wounded (torn right thigh: he catches 0.41 m/s, not 0.8) | 20 of 20 down, 0.95 m back | 20 of 20 down |
| saloon gallery rail behind him (0.45 m) | 0 of 20: stopped on his feet against it | 20 of 20 down, 18 over and off the gallery (2.6 m), the rail broken in all 20 (5 members) |
| a breakable 1 m rail over a 2.47 m drop (the lab's) | 0 of 20: stopped against it | 20 of 20 through it and off the deck (2.8 m) |
| the hitching rail (0.8 m behind, its top at 1.14) | 0 of 20: doesn't reach it | 20 of 20 down against it (0.94 m), it holds |
| the saloon stair's head, his back to the flight | 0 of 20 (0.25 m: short of the first step) | 20 of 20 down the stair (1.9 m), a rail member broken in 11 |
| the stair's sixth tread, facing up | 17 of 20 down the stair (1.4 m) | 20 of 20 down the stair |
| the oak stair's head | 9 of 20 down it (the edge is nearer) | 20 of 20 down it (1.7 m) |
| a porch edge 0.15 m behind his heels | 19 of 20 off it (0.7 m down) | 20 of 20 off it |
| a chair behind him | 20 of 20 down over it (17 up again; it broke in 5) | 20 of 20, the chair smashed in all 20 (13 members) |
| a card table behind him | 20 of 20 down into it | 20 of 20, over it in most (1.25 m), broke in 7 |
| the bar behind him | 0 of 20: stopped on his feet against it | 20 of 20 down against it |

So the shove moves a man and takes him over anything low or light at his back, or off an edge.
The kick puts him down anywhere, and through a rail or off a gallery when one's behind him. The
lab's flags (`launch`, `jitter_after_settle`) in these runs are the get-up: the ragdoll lab reads
the rig's parts as he rises and takes that for flying parts (50 to 86 m/s, 2 to 3.5 s after he
went down, as he rises). In the 1.5 s after he goes down his fastest part is a hand at 4 to 10 m/s
(9 m/s falling 2.6 m off the gallery), and his head is at 3 m/s as a kick turns him over.

### The frame cost of a kick that breaks a rail

The kick itself costs nothing to speak of (a cast and a push: the open floor's worst frame in the
3 s after it, 5.3 to 5.8 ms here, all the ragdoll). Breaking the saloon gallery's rail costs one
long frame, the first member's: `settle_analyse` ~95 ms (+ `analysis_full_begin` ~5 ms) here,
about 60 ms at Sean's (x 0.65), with a FireSystem in the world or not, before and after more-cores
step 8 (main 520abe1). The members after the first are brought up to date in 2 to 3 ms. It is the
saloon's first analysis, done whole on the frame something first breaks in it: a ball through a
baluster pays it the same. (`lab.gd --light` and the Prof timers, 2026-10-28; the frame's whole
time was 110 to 150 ms while a playtest ran alongside.) The fix is the structures': each
building's analysis taken before anything breaks (at load, a slice a frame, or on the worker), so
the first break is an update.
