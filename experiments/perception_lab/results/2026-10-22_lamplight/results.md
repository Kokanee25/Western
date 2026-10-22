# Fix 2: a man is seen by the light falling on him (2026-10-22)

Problem 3 of the baseline (`../../baseline/baseline.md`): Senses took its light from
`DayCycle.get_daylight()` alone, so at night only the sky lit anyone, no lamp counted, and a shut
room with its lamps out was as starlit as the street.

## The change

- `SightLight` (`src/people/sight_light.gd`, numbers in `config/sight.tres`, `SightTuning`): the
  light on a man, in lux, taken at his chest. Two parts:
  - **The sky**, where it reaches him. With nothing overhead he gets all of it. Under a roof it
    comes in sideways (a porch's open front, a door), as the share of 8 rays round him, 15° up,
    that get out, and never less than `room_sky` (3 %: a shut room by its windows and cracks, a
    daylight factor of a few percent). The open sky is 0.02 lux at night (starlight and some moon)
    and 10,000 by day, by ratios in between.
  - **Every lit `OilLamp`** (group `oil_lamps`) with a clear line from its flame to him. A lamp
    gives 10 lux at a metre for each unit of its energy (a period kerosene lamp of about ten
    candlepower is energy 1.0–1.4), falling off over its range as Godot draws it (the window
    (1 − (d/r)⁴)² times d^−attenuation). So a wall keeps a room's light in, and a lamp put out,
    lit or smashed counts at once.
- His reach goes with the logarithm of that light (the eye takes light by ratios,
  Weber–Fechner): 14 m at the night sky's 0.02 lux, 60 m at the day's 10,000. Under an open sky
  that is exactly the old `lerp(14, 60, daylight)`, so outdoors by day nothing changes. Darker
  than a night sky it shrinks on: a black room's 0.0006 lux is 1.7 m. Only the lit man's light
  counts, not the watcher's.
- `Senses`: `range_to(who)` (from `SightLight.range_of`) in place of the one range for everyone,
  in `_look` and `_in_view` (who made a sound). `light_on(who)` is the lux. `Senses.light`, set by
  tests, is now the sky's daylight, and lamps still add to it. `SIGHT_DAY`/`SIGHT_NIGHT` are now
  `range_day`/`range_night` in the resource. The gunfight lab's bot uses the open sky's range
  through `SightLight` (`experiments/gunfight_lab/player_bot.gd`, one line).
- Cost: the light on a man is worked out once a Senses tick (7 frames) and shared by everyone
  looking at him. The lines (sky rays, lamp rays) are cast again only once he's moved 0.5 m or 60
  frames have passed. In between, only the lamps' falloff and lit state are worked out again.
  Two savings in `Senses` that change no result: a man plainly behind the watcher (more than 3 m
  off and over 125° from where he looks) isn't looked at; and `_visibility` casts a ray to a point
  on a man only if that point could show him better than one already seen.
- Tests (`test_senses`): at night, 20 m off under a lit lamp you're picked out; with the lamp
  out you're not; lit, but with a wall between the lamp and you, you're not. A shut room at night
  brings his reach under 3 m, where under the open sky it's over 6 m.

## Measured (the whole lab, before and after, the same lab and seed, each run twice: the same)

| group | judged | as expected | missed | false | slow | leaks |
|---|---|---|---|---|---|---|
| sight | 50 | 33 → **36** | 4 → **3** | 5 → **4** | 8 → **7** | – |
| hearing | 41 | 36 → 36 | 4 → 4 | 1 → 1 | 0 | – |
| search | 8 | 6 → 6 | 2 → 2 | 0 | 0 | 5 → 5 |
| news | 12 | 10 → 10 | 2 → 2 | 0 | 0 | 0 |
| leaks | 6 | 3 → 3 | 0 | 3 → 3 | 0 | – |
| **all** | **117** | **88 → 91** | 12 → **11** | 9 → **8** | 8 → **7** | 5 → 5 |

What changed, every case (spotted in seconds; the light on him in lux):

| case | light | before | after | on him |
|---|---|---|---|---|
| under_lamp_20m | night_lit | never (MISSED) | **2.87** (slow) | 13.9 |
| inside_dark_room | night_out | 4.73 (FALSE) | **never** (ok) | 0.0006 |
| inside_dark_room | night_lit | 4.73 (slow) | **0.87** (ok) | 26.4 |
| through_batwings | night_lit | 4.33 (slow) | **0.73** (ok) | 10.6 |
| through_batwings | night_out | 4.33 | never (not judged) | 0.0006 |
| through_doorway | night_lit | never | 1.00 (not judged) | 1.55 |
| side_walker | night_lit | never | 4.33 (not judged) | 13.8 |
| through_doorway | day / golden | 0.60 | 0.73 (both still ok) | 300 / 149 |
| side_walker | golden | 3.53 | 3.67 (slow, as before) | 1,880 |

As expected: the man between the porch lanterns is seen (2.9 s at 19 m, standing still), the
black saloon is black, and the lit saloon and its batwings are near day speed. Every other case
is unchanged, to the hundredth of a second: the open street in every light, the search, hearing,
news and leaks.

Two day-lit results moved, and the light accounts for both. The man inside the store, seen
through its open door, gets the room's 3 % of the day (300 lux) and is noticed 0.13 s later (one
tick), still within the second. The side walker's line runs under the jail's porch roof, so at
golden hour he gets the sky through its open front only, and is noticed one tick later. The street
cases at night didn't get faster. The man 10 m ahead in mid-street is 7.5 m from the porch
lanterns, past their drawn range of 6.5 m, so he's lit by the sky alone, as he looks in the game.

Still open in sight: `through_window` night_lit (MISSED: the glass stops his eye, problem 4);
smoke and dust (4 false, problem 2); 45 m by day (missed, as in the baseline); the slow ones
(walking past to his side, crouched at 15 m by day, the porch man's 2.9 s).

## Frame cost

`tools/perf_bench.gd --scene=calm --no-ablate`, on this workspace's 2.1 GHz core (runs vary by
±0.3 ms in People here; main itself read 3.75 and 4.02). New `--hour=H` starts the street at that
hour.

| | Senses (raw ms a frame) | People (budget line, ms at Sean's) |
|---|---|---|
| before, 12:00 | 0.87 | – |
| before, 23:00 (every lamp lit) | 0.85, 0.92 | 3.75, 4.02 |
| after, 12:00 | 1.00 | 3.74 |
| after, 23:00 | 1.04 | 3.84 |

About +0.1 ms a frame at Sean's (0.15 raw), day or night. What's left is the per-look call (each of
18 watchers asking for each man's range every tick), not the rays (0.05 ms). People stays under its
4 ms in the after runs, but it's near the line either way.

`before_tables.md` / `after_tables.md`: every case. The sight table's "on him, lux" is the light
`SightLight` gives the target; "sky" is the day cycle's daylight, as before.
