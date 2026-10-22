# Ten wounded men, with their brains (list item 18)

The baseline's perf run had bare bodies. The people budget (4 ms) also counts their minds, so
`--perf --brains` gives each of the ten an `OutlawBrain` (with its senses), as the gang has. They
are timed by Prof's `outlaw_brain` and `senses` with the bodies, skeletons and blood. These are two
runs each, on this workspace's core, in ms a frame over the 10 s after the shots; Sean's is ×0.65.
All four fixes up to fix 9 are in.

| men | people, mean (p99) | of which brains + senses | bodies | people at Sean's, mean (p99) |
|---|---|---|---|---|
| 10 studio men | 2.65–2.69 (6.5–6.6) | 0.39–0.40 (1.5) | 1.69–1.72 | **1.7–1.75 (4.3)** |
| 10 outlaws | 2.81–2.92 (5.2–6.6) | 0.41 (1.6–1.7) | 1.82–1.90 | 1.8–1.9 (3.4–4.3) |

- On average, ten wounded men with their minds take under half the people budget.
- **The worst 1% of frames go over it**: 6.5 ms here, ~4.3 at Sean's, against 4. The body's tick
  is most of the spike (its p99 is 3.4–4.2 here), at the moments men go limp or start tending. The
  ragdoll lab measured `go_limp()` building 17 bodies at 4–5 ms a man on its tick.
- Standing and unhurt before the shots: 2.3–2.5 (p99 4.4–5.7).

`python3 experiments/body_lab/run.py --perf --brains --model=mixed --out=...`
