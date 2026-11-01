# The farmhouse (issue #520: the hostage rescue)

Gameplay. The farmhouse out east of town on its knoll in the hills (`src/missions/farmhouse.gd`,
spec `experiments/building_lab/farmhouse.json`), and the mission held in it.

| File | What |
| --- | --- |
| `probe.gd` | the house built on its own: time, members, whether it stands, fits people, is destructible |
| `bridge.gd` | bridge commands: `farm_wall WALL`, `farm_hole WALL`, `farm_view NAME` |
| `breach.py` | the breach check: one stick planted chest high from outside on each wall by the player's own planting, in the game; the hole's clear height and a picture |
| `sheet.py` | the contact sheet (from the road, closer, round it, each room, the breaches) and F3's numbers on a walk round it and through it |

```sh
godot --headless -s res://experiments/farmhouse/probe.gd
python3 experiments/farmhouse/breach.py --out=experiments/farmhouse/results/DATE_breach
python3 experiments/farmhouse/sheet.py --out=experiments/farmhouse/results/DATE_sheet --breach=experiments/farmhouse/results/DATE_breach
```

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
