# What a stick does to you (#596 step 2, "On you"), 2026-11-04

One stick on Main Street's dirt (0.2 kg TNT, hits as 0.36 kg with the ground), the player standing
2, 5, 12 and 30 m off, facing it. The lab's `dynamite_you_*` scenarios (24 s after the bang),
measured by `on_you.py` from each run's `voices.csv` (the ears' cutoff, the whine's level, the shake,
the grit, a row a frame) and `heard.wav`. Table: `table.md`; numbers: `on_you.json`.

```sh
python3 experiments/sound_lab/run.py "--scenario=dynamite_you_*" --out=build/sound_lab/on_you --jobs=2
python3 experiments/sound_lab/on_you.py build/sound_lab/on_you
python3 experiments/sound_lab/run.py "--scenario=dynamite_you_*" --out=build/sound_lab/films --jobs=2 --picture   # the films
```

## Before

Everything ran off one number, `ringing` = 0.5 s a kPa at the ear, capped at 40 s:
- the world dulled for as long as the ringing lasted (cutoff by `ringing / 12`): at 2 m, 28 s at
  500 Hz before it began to come back; at 5 m 17 s of ringing;
- the 3.8 kHz whine played through that same low-pass on Master, so while you were dulled it was cut
  ~40 dB: you heard the ringing only as the dulling lifted;
- the "shake" turned your aim: a random walk of up to 3 degrees a tick for 0.75 s (your aim left
  off by several degrees at 2 m);
- a stick across the street flashed you red as a hit did;
- past the blast's reach (17.8 m for a stick) nothing at all.

## After

Each by its own share of the pressure at your ear, on a log scale (`PlayerWounds.blast_share`,
BlastTuning's "On you" group, all PROPOSED). Your ears still hold clear 0.3 s and give over 0.5 s,
so the crack comes through (step 1).

| | 2 m | 5 m | 12 m | 30 m |
|---|---|---|---|---|
| pressure at the ear (reflected kPa) | ~150 | ~34 | ~11 | ~4 |
| eardrums (as before, Physiology.blast_injury) | both burst: 8.3 kHz for good | may burst (35 kPa) | whole | whole |
| world dulled (cutoff < 15 kHz) | 7.6 s, to 313 Hz | 5.3 s, to 1.5 kHz | 2.8 s, to 5.0 kHz | 0.45 s, to 14.5 kHz |
| ringing heard | 22.7 s, top −9 dB | 13.7 s, top −18 dB | 6.9 s, top −29 dB | 0.9 s at −54 dB (not heard) |
| whine band 1–3 s after vs other highs | −27 vs −40 dB | −36 vs −49 dB | −49 vs −49 dB | — |
| view shaken (top, length) | 2.9°, 1.5 s | 1.6°, 1.1 s | 0.7°, 0.8 s | 0.2°, 0.5 s |
| grit on the screen | 4.0 s | 2.3 s (a few specks) | none | none |

Against the brief's eardrum radii (`docs/briefs/blast-surfaces.md`): inside 2.5 m both eardrums go
and the world is dullest; at 5 m (the first eardrum's radius) it's dulled for seconds and rings
for longer; at 12 m (well inside the 17.8 m reach) a short dulling and a faint ring; at 30 m
(past it, now felt out to `felt_reach_x` x reach, ~45 m) a thump of shake and nothing to hear.

- **The whine is heard through the dull world:** it still plays on Master (a stream can't skip
  its bus's effects, and bus 0 can't be renamed), raised by exactly what the ears' low-pass takes
  off at 3.8 kHz (`PlayerWounds.lowpass_db`: the Audio EQ Cookbook's biquad, Godot's filter). In
  the recording the whine's band is 13 dB over the other highs at 2 m (it would be ~44 dB lower
  without it).
- **The shake turns the view, not your aim:** `view_shake` goes on the camera with the gun's kick
  (`WeaponViewmodel._animate_camera`), a kick away from the blast springing back in ~0.1 s and a
  wobble at 11 Hz; the camera is back where it was after (`test_on_you_by_distance`).
- **A stick that missed you** no longer flashes you red; the dust wash and the grit are what you
  see up close.
- **Found:** the player's shielding ray started at the charge on the dirt, and the lip of its own
  crater (dug a moment before people are reached) stopped it from ~15 m out at a low angle: from
  30 m the blast counted as behind a wall. It's asked from 0.3 m over the charge now (the player's
  only; `HumanBody.take_blast` has the same ray and is left for the session that tunes men's ears).

## Cost

`_update_ears` + the shake + the grit's uniforms: 1.8 µs a tick idle, 6.8 µs while a blast is on
you (this VM; ~1.2 / ~4.4 µs at Sean's). The grit is one full-screen rect with a few hashes a
pixel, drawn only for the few seconds there's grit. No new bodies, no particles.
