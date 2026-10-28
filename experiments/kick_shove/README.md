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
