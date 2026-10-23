# Change 5: fire by size, and footsteps on boards and dirt (2026-10-22)

Against the baseline's items 8 and "fire is one 3-second loop" (`../../baseline/baseline.md`). Before
and after from one build (`run.py --old-sound`); runs `build/sound_lab/f_before`, `f_after`.

## What changed

- **Fire** (`FireSystem`'s lights): a crackle that doesn't repeat (`fire_crackle`: eight seconds of
  sap pops and snaps of every size over the burning's hiss; was a 3 s loop of 70 identical-length
  clicks), no two fires in step (each its own pitch and place in the loop), and **a roar** under a
  big fire (`fire_roar`: the low surging rush of a building alight), past three members burning and
  louder the more. Both placed like the rest (the Room bus inside, muffled through walls, the air),
  kept up to date as the fire or the ears move (`GameAudio.replace_loop`).
- **Footsteps** (`Player._footsteps`, every 0.75 m as before): on any timber underfoot (a boardwalk,
  a floor, a kit prop) a heel's knock and the plank's hollow ring; on the street's dirt a soft
  crunch and a dull thud; four of each so a walk doesn't tick; quieter crouched, louder running.
  Only the player's own for now (the gang's and the town's steps are the perception lab's sounds to
  hear; whether you hear them is a next step here).

## Measured

| | before | after |
|---|---|---|
| The store alight, from 5 m: loudest 400 ms / centroid | −17.5 LUFS / 1,012 Hz | −14.6 / 558 Hz (the roar) |
| From across the street (15 m) | −24.3 / 488 Hz | −18.8 / 446 Hz |
| Walking on the boardwalk / the dirt / running on it | silent | −34.8 / −36.4 / −29.7 LUFS (boards 265 Hz, dirt 1,082 Hz) |

## Clips (`clips/`: before, a second's gap, after)

`fire` (5 m, then across the street), `steps` (the boardwalk, the dirt, running).

## For Sean's ears

Does the fire sound big enough when the store's going up? Do the boards sound like boards?
