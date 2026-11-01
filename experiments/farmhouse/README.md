# The farmhouse (issue #520: the hostage rescue)

Gameplay. The farmhouse out east of town on its knoll in the hills (`src/missions/farmhouse.gd`,
spec `experiments/building_lab/farmhouse.json`), and the mission held in it.

| File | What |
| --- | --- |
| `probe.gd` | the house built on its own: time, members, whether it stands, fits people, is destructible |
| `bridge.gd` | bridge commands: `farm_wall WALL`, `farm_hole WALL`, `farm_view NAME`; `farm_hide` (where a crouched man is out of sight of every opening and clear of a stick on a wall: a map of the yard), `farm_blast WALL` (one stick on a wall before any alarm: the rancher, the men, what broke) |
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

## The surprise assault (issue #537, 2026-11-01)

Sean: the dynamite way is a surprise assault. You set the stick on a back wall without them
knowing, get to a hiding spot, and the wall going up is the first they know of you.

- **The hiss** is heard only within 3 m (`BlastTuning.fuse_heard`, was 9) and only on the stick's
  side of its wall (`Senses.THROUGH_WALLS`: a fuse none; the stick makes its noise 0.3 m off the
  face it's on, so even a thin wall stands between). Hollis, 1.5 m from it through the kitchen's
  wall, no longer hears it ("What's that hissing?") and looks out of the back window.
- **The hiding spot** (`results/2026-11-01_surprise/hide.md`, `farm_hide`): round the lean-to's
  west corner (x -0.5 to -1.5, z 5-7.5), 4.6 m from the stick's spot between the kitchen's window and
  door, 3.3 s at a crouch (its 5 s fuse), out of sight of every window and door, the lean-to between
  you and the stick (3.4-3.8 m, shielded). Crouched steps carry 2 m (1 through a wall): unheard. The
  outhouse hides you and is clear, but at 10.3 m it's 7.4 s at a crouch; running there is heard
  through the wall. No prop needed.
- **The blast** before any alarm is the alarm (`FarmhouseMission._surprised`; the guard's clock
  starts there) but they're caught cold: each dazed `caught_cold` s (`config/farmhouse.tres`, 4 s,
  0.8-1.2 of it; `OutlawBrain.caught_cold`: in the fight at once, before his fright is weighed),
  knowing only where the blast was, and nobody calls where you are (`HouseDefence.quiet`) till one
  of them sees you or you fire (`found` in the record). What the blast itself does (a man hit,
  timber or glass heard) no longer raises the alarm ahead of it: those wait a tick
  (`_alarm_soon`), and the blast's announced last (Blast.detonate).
- The scripted player: wide round to the house's west side, crouched along the kitchen's back
  wall under its window, the stick between window and door, crouched back round the corner
  (2.7 s), in through the hole at a run once it's gone (ducking under the fallen plate).

Measured (`results/2026-11-01_surprise/r4`, 8 seeds, the scripted player as it is now; `r2` the
same before its fix for a board across the hole; main as it is today the same 8):

| | alarm | lost (blast to found) | at the bedroom | rancher cut loose | won | rancher lives | the guard fired on him |
| --- | --- | --- | --- | --- | --- | --- | --- |
| r13 (Sean's build) | 65.6 s, Hollis at the window, 3.6 s before the blast | 0 | 8-11 s after the blast | 10-14 s after | 3/4 | 4/4 | 0 |
| main today, 8 seeds | the same | 0 | | | 4/8 | 8/8 | 0 |
| the surprise, r2 | at the blast, 8/8 | 10.5 s (7.5-11.7) | 12.8-15.9 s after | 14.9-19.1 s after | 5/8 | 8/8 | 0 |
| **the surprise, r4** | **at the blast, 8/8** | **14.1 s (6.4-15.3)** | 11.9-16.2 s after | 14.5-18.3 s after | **4/8** | **8/8** | 1 (he lived) |

Every loss is a timeout after he's cut loose (alive): the scripted player trading shots on the way
out, or dragging him out cold through the bedroom door, as main's losses are. The film's runs (30
fps under the Movie Maker, the afternoon light) lose all five seeds tried that way, so the film
stops 10 s after he's cut loose. The front way is round 13's (3/4); the back way's 0/4 is main's
today too (it was 2/4 at r13: something merged since changed it; the freed rancher can end up
stood on the kitchen's barrel).

**Which back wall** (`results/2026-11-01_surprise/walls.md`, one stick each, before any alarm):
the kitchen's back wall between its window and door (x 2.5-3.3) leaves the rancher awake (3 of 3;
the scripted runs' stick: 8 of 8, a few blows from what settles); the lean-to's west end leaves him
unhurt (2 of 3) but has no corner to hide behind (5 m out in the open yard); west of the kitchen
window, the lean-to's east end and the bedroom's own back wall each knock him out cold or break a
bone (and the bedroom's takes the guard). Best: the kitchen's back wall between window and door.

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
| r8 | the scripted player switches to the stick once (drawn, its switch never finished) | 2/4 | 2/4 | 0/4 | 10/12 |
| r10 | the playtest's fixes: warned off before shot, a look out of the window at a sound, the drag | 1/4 | 0/4 | 1/4 | 12/12 |
| r11 | the guard's last word counts from you in the house; men with hands up step out of your road | 2/4 | 0/4 | 0/4 | 11/12 |
| r12 | a guard who gives up lets go of the rancher | 3/4 | 0/4 | 1/4 | 12/12 |
| **r13** | **final**: E reaches him by any of him; the scripted player drags him out cold | **3/4** | **3/4** | **2/4** | **12/12** |

What the late rounds found (each a fault a player would meet too):
- r10: every breach timed out with all five given up. Dutch gave up standing in the kitchen
  door and nobody could get by him; the walk from the kitchen's middle caught the door's jamb.
- r11: Brody, giving up, kept his gun "on" the rancher, so the scripted player kept aiming at a
  man with his hands up. And the guard's 5 s ran from his first drawing on the rancher (at the
  blast), so he shot the moment you came in; now they run from you being in the house.
- r12: the blast at the kitchen brings the loft down in the bedroom and knocks the rancher out
  cold most times. E only reached his chest, and the scripted player left him lying.

In r13 the breach's one loss is a timeout with the rancher cut loose and out cold, dragged as far
as the front room. Front and back losses are the scripted player shot down. A person plays
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
