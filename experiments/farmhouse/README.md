# The farmhouse (issue #520: the hostage rescue)

Gameplay. The farmhouse out east of town on its knoll in the hills (`src/missions/farmhouse.gd`,
spec `experiments/building_lab/farmhouse.json`), and the mission held in it.

| File | What |
| --- | --- |
| `probe.gd` | the house built on its own: time, members, whether it stands, fits people, is destructible |
| `bridge.gd` | bridge commands: `farm_wall WALL`, `farm_hole WALL`, `farm_view NAME` |
| `breach.py` | the breach check: one stick planted chest high from outside on each wall by the player's own planting, in the game; the hole's clear height and a picture |
| `sheet.py` | the contact sheet (from the road, closer, round it, each room, the breaches) and F3's numbers on a walk round it and through it |
| `farm_bot.gd` | the scripted player: in by the front door, a breach (the kitchen's back wall) or the back door; the gunfight lab's eyes and hand (player_bot.gd), the guard first when he has his gun on the rancher; cuts him loose and takes him out |
| `run.py` | the scripted runs: one headless game a run (`farm_run WAY seed=N`), `results/<round>/runs/*.json`, `summary.md` |
| `PLAYTEST.md` | the blind playtest's brief for the mission |

```sh
godot --headless -s res://experiments/farmhouse/probe.gd
python3 experiments/farmhouse/breach.py --out=experiments/farmhouse/results/DATE_breach
python3 experiments/farmhouse/sheet.py --out=experiments/farmhouse/results/DATE_sheet --breach=experiments/farmhouse/results/DATE_breach
python3 experiments/farmhouse/run.py --ways=front,breach,back --seeds=1-4 --jobs=3 --out=experiments/farmhouse/results/DATE_rN
python3 tools/bridge.py "farm_start" "farm_state"      # in a running game (bridge): the mission, its state
```

## The mission and the squad (steps 2-5, 2026-11-01)

How it plays (`src/missions/`, LAYOUT.md "src/missions"):
- **Before the alarm** five men at their posts (the guard by the rancher, two at the front windows,
  the Kid on the porch watching the road, Hollis in the kitchen on the back door), bored: a word
  now and then, a look round; a sound outside sends the nearest to the window on that side.
- **The alarm** (seen; a shot, glass, timber, a fuse; a ball into one; a blast) and they fight as a
  squad (HouseDefence, the spec's `tactics`): the windows on your side, a man on the door you'd
  come in by, Hollis up to the loft window if you're out front; round the house they follow you
  window to window; in the house, the men in your room fight you there and the rest hold the
  doorways into it from the next room; a breach gets a man with a line on the hole; three out, the
  rest fall back to the bedroom with the guard. They call where you are.
- **The guard** keeps to the bedroom, puts his gun on the rancher when it goes badly (two down)
  and kills him (head, two balls) once you're in the house and it's 20 s since the alarm, or he's
  the last: a 5 s threat first. Never shoots through him at you.
- **The rancher**, cut loose (E held 1.6 s), follows you crouched, behind you from the nearest of
  them, and tells you where the others are.

Measured (scripted runs, 4 seeds a way; each round's `summary.md`):

| Round | What changed | front won | breach won | back won | rancher alive |
| --- | --- | --- | --- | --- | --- |
| r3 | before the squad (the bot's routes in sight of the porch) | 0/4 | 0/4 | 0/4 | 8/12 |
| r5 | the squad; the bot's routes fixed | 2/4 | 1/4 | 2/4 | 12/12 (the guard's shots at his chest didn't kill) |
| r6 | the last stand, the guard shoots to kill, the quiet way round the north | 2/4 | 2/4 | 0/4 | 10/12 |
| r7 | the rancher's safe 40 m off; the same seeds as r6 run for run (front, back): deterministic | 2/4 | 4/4 | 0/4 | 10/12 |
| **r8** | **final**: the scripted player switches to the stick once (drawn, its switch never finished) | **2/4** | **2/4** | **0/4** | **10/12** |

In r8's two breach timeouts every one of the five had given up; the scripted player stuck on its
way to the rancher through the wreck (its straight line, not the mission). The breach runs shift
with the stick's timing (r7 to r8, one tick's difference at the plant); front and back match r6-r8
run for run.

Through the back the scripted player clears the house fast (Hollis, Lyle, Dutch, the Kid) and the
guard, the last man, kills the rancher 5 s after his threat, before it's through the bedroom door
(`threat_seconds`, `shoot_after_alarm`: Sean's dials). The scripted player's seed changes little
(its aim): with the world deterministic the runs of a way mostly come out alike. A person plays
better and worse than it: the films and the playtest are the judge of how it plays.

The alarm comes at 17 s through the front (the Kid sees you on the lane), at 64-68 s the quiet
ways (a fuse's hiss, or Hollis seeing you at the back door). Frames (headless here, the fight):
mean 8-12 ms, p95 14-22, worst 110-270 (the blast's frame ~200).

## Step 1: the house (2026-11-01)

- **Built** from its spec in ~0.2 s: 1,342 members, 17 kit props (204 members), 2 OilLamps; a
  9 x 5.2 m house (the front room with the stove and the table, the bedroom, the loft over both up
  a box stair) and a 5.6 x 2.4 m lean-to kitchen on its back; a porch across the front. Six ways
  to be seen or shot from: the front door, two front windows, a window each side, the kitchen's
  back window (and the back door, the loft's gable window).
- **It stands** under its own weight and with a crowd on the floor and the loft (worst: the loft's
  joists 0.80 of their limit). **People fit** its 4 doors, 2 stairs and 14 places. **Destructible**:
  nothing but members, kit props and fittings.
- **The breach** (`results/2026-11-01_breach/`): one stick planted chest high from outside opens a
  walk-through hole (1.9 m clear) in **7 of 7** walls.
- **The sheet and F3** (`results/2026-11-01_sheet/`): `sheet.jpg`, `frames.json`.
