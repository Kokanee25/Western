# Train sound 2: the sounds from real recordings (#586, plan #542), 2026-11-03

Step 4's sounds were all synthesised (Sean: "sounds very computerized and not real"). Now 18 of
the 20 are cut from real steam locomotive recordings on Wikimedia Commons. The timing system is
step 4's, unchanged (`TrainSound`: one-shots timed from the sim to the sub-tick, late by distance,
Doppler; loops held by the frame). Only the sounds and their dials changed.

## The recordings

Four sources, all licences that allow it in a public repo (credited in `CREDITS.md`):

| Source | Licence | Cut into |
|---|---|---|
| South Australian Railways Garratt 406 starts off (SCHolar44) | CC0 | every exhaust beat (long, mid, quick), rolling, standing (simmer) |
| Train sounds from Iowa (Glaneur de sons) | CC BY 3.0 | the three-chime whistle (355/452/560 Hz), the bell, rail joints, couplers |
| Steam locomotive S06-018, steam release (Work With Sounds) | CC BY 4.0 | the cylinder cocks (bursts and hiss), the safety valve |

**Still synthesised:** the brakes' squeal and grind (no recording had them).

Wikimedia refused every download from this workspace (429 "too many requests" on the shared
address, ~45 min of polite retries); Sean downloaded the six files on his PC and uploaded them to
the session. Two weren't used: the S06-018 "starting" (a standing machine's hum, no beats) and the
German single-tone whistle (the Iowa chime is the American sound). The only American chime whistle
besides Iowa's, UP 844's, is CC BY-SA and wasn't needed.

## How they're cut (`experiments/train_lab/recordings.py`, `recordings.json`)

`fetch` (when the network allows), `cut` (every sound from its manifest line: source, start,
length), `onsets`, `credits`. Each sound is mono 16-bit at 44.1 kHz in `assets/audio/train/`,
imported uncompressed (`compress/mode=0`, written with it; Godot's default is QOA):

- **one-shots** (beats, clacks, couplers, the bell, the cocks' bursts) cut at an onset found from
  the envelope, faded out over their tail, then led by `TrainSynth.LEAD` (50 ms) of silence;
- **loops** (rolling, simmer, cocks, safety valve, whistle) have their tail crossfaded (equal
  power) with what came just before their start, then filtered round the circle: no step at the seam;
- a zero-phase high-pass (60 Hz, more where the train's rumble has to go: the bell at 800 Hz,
  the cocks at 900), the clacks low-passed at 2.5 kHz to leave out the bell ringing over them;
- each set to the loudness of the synthesised sound it replaces (`tools/train_synth_dump.gd`
  writes those), so the dials keep their meaning.

`SynthSounds` gives a `train_*` id its recording when the file is there (`TrainSynth.recording`),
else the synthesis; `-- --train-synth` plays step 4's sounds.

## The dials (`config/train_sound.tres`)

The first film with the recordings at step 4's dials came out quieter: the start's beats 7-10 dB
under step 4's (second by second), the bell alone 4-10 dB under, the passes ~2 dB. Set for the
recordings: `chuff_db` 2 -> 9 (`chuff_max_db` 6 -> 12; `mid_db` 3 -> 1, `short_db` 6 -> 1: mid
beats +5, short +2), `cocks_db` -1 -> 3, `cocks_loop_db` -9 -> -5, `bell_db` -1 -> 5, `clack_db`
-2 -> 0 (`clack_max_db` 4 -> 6), `rumble_db` -5 -> -3, `simmer_db` -14 -> -12, `valve_db` 2 -> 4.
The script's defaults stay step 4's.

## The film (`films/train_sound2.mp4`, 1 min 54 s; `train_sound2.mp3` its soundtrack)

`films/sound.txt`, as step 4's: the start close by (bell, two long blasts, the cocks, the slack
running out), passes at 10 m, 40 m (blowing for a crossing) and 150 m, the stop (brakes, the slack
bunching), standing (the safety valve). Heard on the Master bus throughout (nothing walled).

Levels (`levels.json`, dBFS, mono; `spectrogram.png`) against step 4's:

| Section | RMS step 4 -> now | Peak | Loudest second |
|---|---|---|---|
| A start, close by | -14.9 -> -16.5 | -1.6 -> -1.4 | -11.4 -> -12.4 |
| Passing at 10 m | -24.5 -> -24.2 | -2.7 -> -5.4 | -17.4 -> -17.0 |
| Passing at 40 m (whistle) | -22.8 -> -23.7 | -5.0 -> -5.3 | -16.2 -> -16.4 |
| Passing at 150 m | -41.5 -> -42.1 | -22.0 -> -26.6 | -39.7 -> -40.3 |
| A stop, close by | -30.3 -> -30.2 | -11.4 -> -11.3 | -23.7 -> -23.8 |
| Standing, the valve | -25.4 -> -25.5 | -11.4 -> -11.3 | -24.1 -> -24.6 |

The 150 m pass's loudest second is 23 dB under the 10 m pass's (step 4: 22); not changed here,
it's Sean's call (#581's B).

## Tests

`tests/test_train_sound.gd` holds the recordings to the synthesis's rules (loops seamless, one-shots
led by silence, nothing clipped, under 3% of the energy below 40 Hz): 9 of 9. The whole suite:
909 passed, 0 failed.

## Sean's ears (#601) and the fixes

Sean: "way better". Two fixes from his listening, each with a short film:

- **The bell ended abruptly before the next ring** (`films/bell_start.mp4`). The cut stopped at
  0.72 s (the Iowa recording's next strike came 0.73 s later) and faded fast. Now the strike at
  58.7 s, with 1.19 s clear after it: 1.15 s, ringing down to the recording's own floor (its
  partials fall 15-30 dB a second), so each strike rings on under the next. `bell_db` 5 -> 2 (the
  cut sets 2.5 dB louder, the strikes overlap). Sean: "sounds great".
- **A computerised "doo doo doo" through the 10 m pass** (`films/pass10.mp4`). The quick beats
  (from the P-8) were 64-72% a low resonant bark at 140-190 Hz, two clips alternating at the beat
  rate. Now from the Garratt getting going (48.2 and 50.0 s, clear of a tone that sweeps through
  its recording from 27 to 45 s), its steady roar taken out under them (`recordings.py`'s
  `denoise`: spectral subtraction of the stretch's median, after Boll 1979, a floor of a tenth);
  `mid_0` from 22.375 s. The pass: 140-190 Hz 66% -> 7% of its energy, the exhaust's bark
  (300 Hz-3 kHz) 10% -> 51%, the level the same. Sean: "sounds great". The P-8 is no longer used.
