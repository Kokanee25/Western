# The fiddler's sound (#790)

Sean, 2026-11-10: "I'm down to pay a fiddler but before we do that - can we experiment making it
ourselves?" The fiddler plays upstairs at the saloon's dances, built the way the piano player is
planned (`docs/briefs/showcase-moments.md`, "The piano player"): music from note data, the sound
placed at the instrument, his hands from the same notes. This folder tries the sound three ways,
free, and judges them blind by Sean's ear against a real old-time fiddle. Nothing in the game
changes; results in `../results/2026-11-10_fiddle/`.

## The pieces

- `tune.py` -> `soldiers_joy.json`: **the note data.** Soldier's Joy's A part twice (O'Neill's 1903
  setting, public domain, from music21's corpus), ~19 s at half note = 108, written out as an
  old-time fiddler plays it: every note's string and finger in first position (G D A E), the bow
  strokes (the Nashville shuffle: two slurred, two separate; each stroke the other way), bow speed
  and pressure, accents off the beat, a little swing, drones (the open string beside the melody's
  when it's in the chord), double stops on the held notes, slides into the long d's and some F#s.
  The same file is what the hands would be driven by.
- `samples.py`: **A, samples.** VSCO 2 CE's solo violin (CC0). The library's sustains are a classical
  player's, with vibrato: each is read by a pointer that follows the sample's own pitch (YIN every
  5 ms), which cancels the vibrato and draws the note's pitch, slides and slurs at once (a slur is
  one stroke: the sample runs on and only its pitch moves). Each new stroke starts with a short
  stroke's bite (`spic`, two takes and two dynamics, by the accent, in turn); round-robins are
  different stretches of the sustain and a few cents' detune; drones and double stops are their
  strings' own voices; the bow's speed shapes the level; strings ring on after the bow leaves them.
- `bowed.py`: **B, our own bowed-string model**, written from the physics (no copied code): four
  waveguide strings at 96 kHz, the bow's stick-slip by a friction curve solved in closed form each
  sample with hysteresis, the finger's and bridge's losses, rosin noise on the bow's grip, a
  synthetic violin body (decaying modes; A0, B1-, B1+ and a bridge hill near 2.5 kHz). Driven by
  the note data's pitches, bow speed, force and position. Check: a held note slips 10% of each
  period at a bow position of 0.10, harmonics fall as 1/n and the 10th is missing, as Helmholtz
  motion does.
- `hybrid.py`: **C, the hybrid.** A's sustains (without their bites) for the body, B for each
  stroke's start (~50 ms), the slurred note changes (~20 ms either side) and the bow's scratch (B
  above 3 kHz, quietly, throughout).
- `render.py`: the three renders and the reference's 20 s (from 1:40), each at -18 LUFS, then each
  played in the game through the sound lab: `music_balcony_close` (the fiddler on the town saloon's
  balcony, you beside him: the Room bus) and `music_balcony_below` (you on the bar room's floor
  under it, its boards and joists between: RoomMuffled). The game has no dance hall yet; the
  balcony gives the same buses a room upstairs would (GameAudio judges a floor as a wall).
- `compare.py`: the measured comparison against the reference (a guide only); `check.py`: a
  render's pitch against its note data; `blind.py`: the numbered clips and the key.
- `fetch.sh`: the reference record (Internet Archive) and the violin samples (VSCO 2 CE at a fixed
  commit) into `build/sound_lab/fiddle/`.

## The banjo (after Sean picked B)

- `banjo.py`: **our own banjo**, the same way as B: an 1870s five-string (gut strings, calfskin head,
  open back) tuned open to the tune's key. `arrange()` writes his part from the fiddle's note data
  (each melody note's `bar` and `unit`, the beat grid): clawhammer's bum-ditty, hammer-ons, pull-offs,
  drop thumb, the tune an octave down when that keeps it low on the neck; `render()` plays it: a
  waveguide loop a string (gut's losses, each string's decay), strikes combed at 0.28 of the string,
  a hard strike a few cents sharp for a moment, through a calfskin head (a membrane's modes over
  ~260 Hz, a 1-3 kHz rise). Checks (single strikes): in tune within a cent, a G3 down 13 dB by 0.3 s
  and 37 by 0.8 s; in Turkey in the Straw every struck note within 30 cents, centroid ~1.6-1.7 kHz.
- `duet.py`: fiddle and banjo together from one tune's note data, the banjo 2.5 dB under.

## Commands

```sh
experiments/sound_lab/fiddle/fetch.sh                       # needs dn801308.us.archive.org allowed
python3 experiments/sound_lab/fiddle/tune.py                # the note data (already in the repo)
python3 experiments/sound_lab/fiddle/banjo.py turkey_in_the_straw.json [--part=OUT.json]   # the banjo alone
python3 experiments/sound_lab/fiddle/duet.py turkey_in_the_straw.json   # fiddle and banjo
python3 experiments/sound_lab/fiddle/abc_tune.py ryansMammoth/ArkansasTravellerReel.abc arkansas_traveller.json  # any ABC tune
python3 experiments/sound_lab/fiddle/render.py [--dry|--game]   # ~1 min dry, ~80 min the 8 game runs (one at a time)
python3 experiments/sound_lab/fiddle/compare.py             # measures.md/.json, spectrum.png
python3 experiments/sound_lab/fiddle/blind.py               # listen/1-8.mp3, key/KEY.md (a new shuffle)
python3 experiments/sound_lab/fiddle/check.py build/sound_lab/fiddle/dry/A.wav
```

Needs numpy, scipy, numba, matplotlib (`pip install numba matplotlib`), ffmpeg; the game runs need
what the sound lab does (xvfb, lavapipe, the native plugin built).

## Traps

- The sound lab's `_floor` looks down from 2.5 m over a point: on the balcony that finds the roof,
  and under it the balcony. Music scenarios look from 0.6 m.
- The spiccato files are named an octave low (`spic_A4` sounds A5).
- With drones sounding, a pitch tracker hears the two strings' common period: check a render's
  pitch on its melody alone (`check.py` on a melody-only render; see its docstring).
- The record's medium (a 1922 horn: 250 Hz-4 kHz, a strong resonance, surface noise) dominates
  its spectrum, and it plays another tune in another key: its spectral shape and "scratch" say
  little about ours; its surface noise fills the dips between notes, so its "pulse" reads low.
