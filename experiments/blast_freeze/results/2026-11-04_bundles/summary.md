# Dynamite bundles against #492's gate (#647, 2026-11-04)

Headless, `--fps=60`, this VM (x0.65 for Sean's clock). The gate: one hitch under ~100 ms at
Sean's, back above 50 fps within 0.5 s.

## Main Street (`bf_blast in=street ... bundle=4 plunger=1`; `street_table.md`)

Charges at the street's first buildings (one a building), fired by the plunger a tick apart.

- **One stick** (baseline, main's game): worst 119-121 ms at Sean's, ~360 members broken, settles.
- **Three sticks together:** worst 176, 872 broken, settles.
- **One bundle of four:** worst ~300 at Sean's (`blast_break` 236 ms + `blast_cut` 172 ms here,
  965 members in its reach: a bundle's break reach is 5.6 m, a stick's 3.5), 1,139 broken, settles
  (65 awake at 8 s).
- **Three bundles of four:** worst 280-330 at Sean's, ~2,090 broken, ~7,800 rubble bodies awake
  after the blasts and 2,700-2,900 still awake at 8 s: ~230 ms a frame here (~150 at Sean's) for the
  whole 8 s, Jolt's step ~160 ms of it. **Fails the gate by far.**

Firing them together isn't the cost: each bundle is on its own tick. The cost is (1) a bundle's own
tick (the break and the cuts, unsliced) and (2) the rubble of three buildings blown open at once.

## The trestle (`collapse_runs.py --only=bundles_*`; `trestle_table.md`)

Two bundles of four on the tallest bent's two inner posts (the light charge), on round 1's 66 m viaduct (measured before #646, the River Kwai size, merged; the bent's posts are the same timber):

- no train, the plunger a tick apart: the bent stands empty; worst 72 ms at Sean's, slow 0.33 s:
  **passes**; on one tick: worst 52, 0.27 s: passes.
- as the engine comes on at 40 km/h (one run): the bent comes down under the engine, the train off
  the rails at the gap (0 of 7 cars into the gorge this run); the fall fails (worst 181, slow 4.6 s):
  that's the collapse and the train's hand-off (#638 call 1), not the bundles.

## Next

The bundle's tick sliced (Blast's break and cuts over a few ticks, as the settle was in #374) and the
rubble of a big blast asleep sooner (#585's RubbleSleep, #626): a later session, measured here.
