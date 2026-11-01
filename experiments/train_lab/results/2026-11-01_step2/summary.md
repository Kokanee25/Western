# Train lab, step 2 (#551): couplers, riding, stops to a timetable

All dials PROPOSED (`config/train.tres`, `experiments/train_lab/timetable.json`). Numbers from
`run.gd` (headless, deterministic) and the bridge runs; films in `films/`.

## The six cars (#552) against step 1

| | Step 1 (3 boxes, 106 t) | Step 2 (6 cars, 119.5 t, 66 m) |
|---|---|---|
| 0 to 25 km/h, regulator wide open | 22.6 s | **24.7 s** (78 m) |
| Stop from 30 km/h, full brake | 94 m | **99 m** (20 s) |
| Top speed, level / up 2.5 % | 43 / 27 km/h | **43 / 25 km/h** |

## Slack (`slack.png`)

On a start the couplers go taut front to back: 2.20, 2.73, 3.12, 3.48, 3.78, 4.07 s after the regulator
opens; the coach moves 1.9 s after the engine. On a stop (steam off, then full brake) they bunch over
0.75 s, the rear hardest (0.38 m/s: a bang). Every one is an event for step 4's clanks.

## Ten stops on the mark (`ten_stops.md`): worst 0.46 m (the proof: within 1 m)

## The timetable (`delay_distance.png`)

Depot, the mine (180 s dwell), back. Run times measured on the line at 22 km/h plus 20 %.
On time: 4 s early at the mine, 2 s early back. **3 minutes late:** 84 s late at the mine (he runs
32 km/h), stands 60 s not 180, back 2 s early. **The re-laid line** (2.1 km, other bends, 3 %, a water
stop): the same timetable, its times from that line, on every mark, within 3 s.

## Aboard (bridge runs, films 2-4)

- Walking the train coach to cab: ~23 s, all seven cars in order, at a start, at 17 km/h, and
  braking for the mine (film 3). Riding through the bend and jumping off the ore car (film 2).
- Bullets hit the cars (wood; the engine and tender iron, ricochets).
- A crate 4 m ahead at a start: struck, shoved off whole, 2.2 m from the line's middle. At 17 km/h:
  smashed (loose timber breaks up over 2.5 m/s), the boards mostly left between the rails.
- A man on the line at 17 km/h: knocked down and thrown aside. **Not yet:** the wheels aren't
  solid, so a man lying between the rails is passed over, not run over.

## Cost (`cost.json`): ~0.21 ms a frame at Sean's (step 1: 0.09)
