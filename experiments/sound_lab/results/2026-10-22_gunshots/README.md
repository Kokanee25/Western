# Change 1: gunshots with weight, placed (2026-10-22)

The first change against the baseline (`../../baseline/baseline.md`, items 1–4): the gunshot remade
for black powder and every gunshot heard from where it happened. Before and after are from **one
build**: `run.py --old-sound` puts the gunshots back as they were (`GameAudio.enabled()`). The
street's guns now aim 3 m ahead into the dirt (they aimed 15 m ahead, at 6°, and their balls and
pellets ricocheted, which was measuring the ricochet, not the gun); the saloon's are as before.
Runs `build/sound_lab/g_before`, `g_after`; tables `table_before.md`, `table_after.md`.

## What changed

- **The sound** (`SynthSounds`, 44.1 kHz): the **report** (the cap's click, the blast's shock as a
  Friedlander pulse, the gas's rush, the deep push of slow-burning powder; no echo baked in) and
  the **roll** (a low boom that swells and dies slowly, and the hills sending it back four times,
  duller and smeared each time). The coach gun has its own (`report_big`, `rolling_big`: a longer,
  deeper push), not the revolver's pitched down.
- **Placed** (`GameAudio`, `src/audio/game_audio.gd`; dials `config/sound.tres`):
  - late by the distance over 343 m/s;
  - the air's loss of highs (a high shelf whose corner falls with distance);
  - the report full within 3 m, then −6 dB a doubling; the roll far quieter close and falling
    slowly, so a far shot is mostly its roll;
  - **inside** (a roof overhead and a wall every way) on the `Room` bus, a timber room's reverb;
  - **a wall between** the ears and the shot (people looked past): `Muffled` (low-pass 700 Hz,
    −6 dB), or `RoomMuffled` for a shot in a room heard from outside;
  - **outdoors, the slap**: up to two image sources off the nearest fronts (a wall is where two of
    three rays a metre apart in height agree, so not a post or the back of a room through a door),
    −8 dB.
- The player's revolver and coach gun and the gang's revolvers all use it.

## Measured (revolver; LUFS is the loudest 400 ms)

| | before | after |
|---|---|---|
| Street, yours / 2 m / 7 m / 20 m / 80 m | −18.6 / −18.6 / −18.6 / −22.7 / −35.5 | −18.0 / −17.7 / −24.1 / −29.4 / −35.6 |
| Heard after the shot at 7 / 20 / 80 m (s; sound takes 0.02 / 0.06 / 0.23) | 0.02 / 0.02 / 0.02 | 0.05 / 0.09 / 0.27 |
| Centroid at 2 m / 80 m (Hz) | 318 / 195 | 504 / 379 (the near report has its top back; far, mostly the roll) |
| Saloon at 2 m against the street at 2 m: decay to −20 dB, tail (150 ms–1 s) | 0.27 / 0.27 s, −7.9 / −7.9 dB (the same) | 0.40 / 0.21 s, −7.2 / −12.8 dB |
| At 7 m: the street / the saloon's open door / its wall | −18.6 / −18.6 / −18.6 | −24.1 / −23.5 / −32.3 (centroid 466 / 684 / 252 Hz) |
| Saloon to the street 20 m / 80 m | −22.7 / −35.4 | −37.4 / −42.5 (through its front) |

- **Closeness:** a shot 7 m off is now 6.4 dB under one 2 m off (before: the same), and 20 m 11.7 dB.
  Yours and 2 m away are still the same loudness: both at the cap, and at the limiter. The far end is
  as loud as before but dull and late.
- **Falloff** −3.4 dB a doubling in the street overall (from −3.2): the roll holds the far end up;
  the report alone falls 6.
- The shotgun's street numbers carry its own report and roll only now (no ricochets); in the saloon
  its charge still breaks floorboards, whose `timber_crack` isn't placed yet (so the 80 m "onset"
  is the crack, 0.08 s).
- **Cost:** a shot is up to 4 voices (report, roll, two slaps) and 26 ray casts when it goes off
  (inside: 5; walls: 1; slaps: 3 heights × 8 ways); nothing per frame after.

## Clips (`clips/`, each the before, a second's gap, the after)

`revolver_street_2`, `_7`, `_20`, `_80`; `revolver_saloon_2`, `_door7`, `_wall7`, `_80`;
`shotgun_street_2`, `shotgun_saloon_2`. The views are `build/sound_lab/g_after/<scenario>/view.png`.

## For Sean's ears

1. Does the near report sound like black powder: a heavy, dull boom with weight, not a modern crack?
2. Is the step from 2 m to 7 m to 20 m right, and is a shot at 80 m (late, dull, mostly the roll)
   too quiet or about right?
3. The saloon: enough room ring? Through its wall, muffled enough?
4. The roll and its echo off the hills: too much, too little?
