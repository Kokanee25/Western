# The prop lab's bench

The prop lab (Sean, 2026-10-21; `docs/briefs/prop-lab.md`) makes each prop end to end and promotes
it into the **prop kit** (`assets/props/kit/<id>.json`, built by `KitProp`/`PropKit` in
`src/props/`; `docs/PARTS.md` "Props"). This bench measures a kit prop against the breakage lab's
set and the prop's own cases, the way the breakage lab measures the street: one fresh headless game
per scenario, on a 4 x 4 m floor of boards on joists (a room's), every physics tick measured.

```sh
python3 experiments/prop_lab/run.py --out=build/prop_lab/base            # every scenario, 4 at a time (~10 min)
python3 experiments/prop_lab/run.py --out=DIR --scenario=seated_kick_front_leg,table_burn
python3 experiments/prop_lab/run.py --out=DIR --render --jobs=3 --scenario=...   # frames (xvfb + lavapipe)
python3 experiments/prop_lab/run.py --sheet=DIR --only=seated_kick_front_leg     # frames -> DIR/<name>_sheet.jpg
python3 experiments/prop_lab/run.py --table=DIR                                  # DIR/table.md from the summaries
godot --headless --fixed-fps 60 -s res://experiments/prop_lab/bench.gd -- --scenario=list
xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://experiments/prop_lab/bench.gd -- --look --out=DIR
godot --headless --fixed-fps 60 -s res://experiments/prop_lab/bench.gd -- --perf=kit|lib --out=DIR [--render]
```

- **Scenarios** (`scenarios.json`; edit it to add one): the breakage lab's set (`revolver` and
  `shotgun` from 5 m with the production loads through `Ballistics`; dynamite 1, 3 and 6 m off
  through `Blast.detonate` with a stick's charge; a limp man on his back dropped from 1 m over it),
  `kick` (`KitProp.take_blow`: a leg of ~8 kg at 6 m/s, 48 N·s), `burn` (members lit, FireSystem
  running, 10 minutes), and for chairs `seated`: a Studio man (`bold_cowboy_s0`) posed sitting, his
  weight on the seat (`KitProp.sit`), before the shot or kick. `"prop": ""` is the floor alone, the
  frame-time baseline for the blasts. Every run is seeded: run it twice into two folders and compare
  the summaries' fingerprints.
- **Each summary** (`DIR/<scenario>/summary.json`): what snapped, whether it went over (loose) and
  when, pieces and how far, the hits, what caught and burnt away (and when), the man (down, when,
  on the floor), the lamp (on the table: smashed, spills), physics faults (sunk, below ground,
  flung over 20 m/s, a man's part over 12 m/s), frame times (the event's frames, the settle's, the
  first second's added mean; this workspace's 2.1 GHz core: x0.65 for Sean's), a fingerprint.
- **Full barrels and loose props:** a full barrel's summary has `contents` (left, run out, on the bus,
  leaks and slots, released, litres in the first second); a loose prop put on with `glass` (the
  spittoon, the cups) reports holes, dents, spilt, upright and how far it went; `kick_glass` kicks
  one (`take_blow`).
- **`--look`**: the kit's chair and card table (right) beside PropModels' (left), a Studio man
  between, lamplight and daylight, wide and close: the sheet the kit's look is judged on.
  `--props=barrel,crate,bar_stool` puts those in a row each side instead (wall props hung on a
  boarded wall behind).
- **`--perf`**: the saloon's set (two tables, four chairs at each, as `SaloonBuilding` places
  them) untouched, as kit props or as PropLibrary's props through `StaticBatch`; `--set=stores`
  the town's barrels, crates and bar stools instead (14, 12 with 4 stacked, 7).

## Results

- `results/2026-10-21_baseline/`: the chair and the card table, every scenario (`table.md`), the
  budget (`perf_*.json`). Same seed, same result: 22 of 22.
- `results/2026-10-22_stores/`: the barrel, the crate and the bar stool: 19 scenarios (`table.md`),
  the look sheets (`look_*.png`), the budget for the town's set (`perf_*_stores.json`: +0.05 ms
  physics and +127 draws at Sean's for all 45).
- `results/2026-10-23_contents/`: full barrels (`whiskey_*`, `water_*`, `oil_burn`) and the loose
  props (`spittoon_*`, `cup_*`, `cups_*`): `table.md`, the summaries, the budget (`perf_*.json`:
  the saloon's set with its 2 spittoons and 5 cups +0.018 ms physics at Sean's and 30 fewer draws
  than the drawn props; the town's stores with 8 full barrels +0.054 ms and +127 draws, as when
  they were empty), the look sheet's blind critic (`critic.md`).
- `results/2026-11-01_deer_fidelity/`: the deer head's fidelity (issue #524; the lab in
  `deer_fidelity/`): which step loses Rodin's deer between its render and the saloon's wall (the
  grid shader's min-square coarsening, then no mipmaps; not the triangles or the paint's size),
  the stand and in-game sheets, costs, the kit checks.
