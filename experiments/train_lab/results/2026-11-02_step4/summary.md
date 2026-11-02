# Train step 4: the sound (#571, plan #542), 2026-11-02

## What's made

`TrainSound` (`src/train/train_sound.gd`, a child of `Train`) and its sounds (`src/audio/train_synth.gd`),
dials `config/train_sound.tres` (`TrainSoundTuning`, all proposed).

- **Timed from the sim, not the frame.** After each physics tick it finds what happened in the tick
  and when, to the sub-tick: each exhaust beat (the drivers past a quarter turn, as `EngineModel`
  counts them), each axle over a rail joint (9.14 m rails), each coupler event, each bell strike.
  Each is queued at its moment plus its distance / 343 m/s, pitched by its Doppler shift then, and
  started on the drawn frame that's due, skipped into its 50 ms lead of silence by how late it is.
  So a beat sounds on its own moment at 60 or 30 frames a second (`test_each_sound_on_its_moment_at_any_frame_rate`:
  the same beats, clacks and onsets to 2 ms either way), never doubled or dropped.
- **The exhaust:** a chuff a beat, four a wheel turn: long and heavy below 3 beats a second (a
  start), short above 8 (a blur at speed), louder with the steam; the four beats each their own
  level and pitch (two cylinders, two strokes: it limps a little, as a real engine does); the
  cylinder cocks' burst on each beat at a start and their hiss between.
- **The rail joints:** a clack an axle a joint: the engine's pony and four drivers (heavier, lower),
  two axles a truck under the rest (31 axles), louder with speed.
- **The couplers:** a bang (or a soft bump) each slack-out and bunch, from TrainSim's events.
- **The brakes:** grind at speed, squeal as the shoes grip near a stand.
- **Rolling** by speed; the engine **simmering** standing; the **safety valve** lifting after 30 s
  standing with the regulator shut (8 s); the **bell** (rung: a strike every 0.8 s) and a
  **three-chime whistle** (a minor chord; patterns: `--` off we go, `--o-` a crossing; held in the cab).
- **Placed** by GameAudio's rules (late by distance, the air's highs, walls), with **Doppler** on
  every one-shot at its moment and on the loops each frame.

**Sources:** all synthesised. The recording sites (Wikimedia Commons, Freesound, OpenGameArt,
archive.org) are blocked by this workspace's network policy, so there are no CC0 recordings yet
and nothing new in CREDITS.md. ElevenLabs wasn't used (nothing paid).

**A fix in GameAudio:** its wall test treated the train's own cars (an `AnimatableBody3D` is a
`StaticBody3D`) as a wall, so every train sound was muffled (the first film: the 10 m pass quieter
than the 40 m one). `GameAudio.walled`/`_ray` now take bodies to look past; the train passes its
own solids (`test_not_muffled_by_its_own_cars`).

## The film (`films/train_sound.mp4`, 1 min 54 s, 960x540, with sound)

Made by `films/sound.txt` (`python3 tools/bridge.py run experiments/train_lab/films/sound.txt
--size=960x540 --movie=OUT.avi`), the stop from a second run of its last part (the bridge timed out
on a 22 s wait under lavapipe; the wait is split now). The engine in the film is step 3's, before
the shape pass (#576): the sound doesn't depend on it.

1. **A start, close by the engine** (0:00): standing simmer, the bell, two long blasts, the
   regulator opened: the cocks hissing with each slow heavy beat, the slack running out down the
   train, the beats quickening, the wheels over the joints.
2. **Passing at 10 m** (0:23), working at ~34 km/h.
3. **Passing at 40 m** (0:42), blowing for a crossing (`--o-`): the whistle drops in pitch as it passes.
4. **Passing at 150 m** (1:01).
5. **A stop, close by** (1:21): brakes from 30 km/h, grinding then squealing near the stand, the
   slack bunching; **standing** (1:45), the safety valve lifts.

Levels (`levels.json`, dBFS of the soundtrack, mono; `spectrogram.png` marks the sections):

| Section | RMS | peak | loudest second |
|---|---|---|---|
| A start, close by | -14.9 | -1.6 | -11.4 |
| Passing at 10 m | -24.5 | -2.7 | -17.4 |
| Passing at 40 m (whistle) | -22.8 | -5.0 | -16.2 |
| Passing at 150 m | -41.5 | -22.0 | -39.7 |
| A stop, close by | -30.3 | -11.4 | -23.7 |
| Standing, the valve | -25.4 | -11.4 | -24.1 |

The 150 m pass sits ~22 dB under the 10 m one (Godot's inverse distance: a train 150 m off is
faint). Whether it should carry further (a working engine is heard far off) is a dial:
`chuff_unit`.

## The cost (the 10 m pass at 34 km/h, the film's run, lavapipe, 30 fps)

`train_cost 10`: the sound's tick **0.10 ms a tick** (beats, 31 axles' joints, couplers, the
bell), its frame **0.26 ms a frame** (starting what's due: ~40 one-shots a second at speed, mostly
clacks; ten loops held). At 60 fps that's ~0.3 ms a frame here, ~0.2 ms at Sean's (x0.65): in
"Everything else" (budget 1.0). Not counted: Godot's own per-player work (each playing
AudioStreamPlayer3D's panning) and the mixing (the audio thread). Making the sounds: ~5 s on one
core of a worker the first time a train is heard (`SynthSounds.warm(TrainSynth.WARM)`), what a
standing engine needs first.

Counts over the stop's run: 145 beats, 342 clacks, 13 couplers, 355 one-shots started.

## The dials (proposed: `TrainSoundTuning`)

| Dial | Proposed | What it does |
|---|---|---|
| `chuff_db` / `chuff_unit` | 2 dB / 14 m | the exhaust's level, and how far it carries |
| `long_below` / `short_above` | 3 / 8 beats a s | where the beats go from heavy to quick to a blur |
| `mid_db` / `short_db` | +3 / +6 dB | the quicker beats as strong as a start's |
| `beat_db` | 0, -2.5, -0.8, -3.2 dB | how much the four beats limp |
| `clack_db` / `clack_unit` | -2 dB / 4 m | the rail joints |
| `bang_db` | 3 dB | the couplers' bang |
| `squeal_db` / `squeal_top` | -3 dB / 2.5 m/s | the brakes' squeal, below what speed |
| `rumble_db` | -5 dB | rolling |
| `valve_after` / `valve_blow` | 30 s / 8 s | when the safety valve lifts standing, how long |
| `bell_period` | 0.8 s | the bell's swing |
| `whistle_db` / `whistle_unit` | 4 dB / 40 m | the whistle |
| `cocks_db` | -1 dB | the cocks' burst at a start |

## Not done, known

- No recordings (the network policy); synthesis throughout. If Sean wants recordings, the hosts
  to allow are `commons.wikimedia.org`, `upload.wikimedia.org` (CC0 / public-domain steam
  recordings) or `freesound.org` (CC0 filter; needs an API key).
- The engineer doesn't whistle or ring yet (two longs before a start, the bell through town):
  `TrainEngineer` could call `blow("--")` and `ring(true)`; Sean's call.
- No echo off the hills or fronts for the train (`GameAudio.slaps`); the test line is out on the flat.
- At speed the 16 clack voices run out and the oldest clack is cut short for a new one (`stolen` in `train_sound counts`).
