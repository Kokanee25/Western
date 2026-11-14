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
  Second take (Sean: "much more keyboard than the fiddle"): two polarisations a string (`POLS`: the
  vertical one into the head, loud and quick; the horizontal quiet, ringing on, 1.3 cents apart), the
  head's thump under each strike (`POP`), strings a few cents off and wandering, strikes and brushes
  varied. Single strikes: early decay / late decay 1.3 -> 3.5 (one slope to two stages), the ring's
  waver 0.16 -> 0.62 dB; the tune's strikes 1.2 -> 1.8 dB apart. The banjo alone sits at -20 LUFS
  (strikes are peaky; not limited).
  Third take (Sean: "still kinda digital"), measured against a real one: Uncle Dave Macon's "Papa's
  Billie Goat" (1924, fetch.sh). His strikes are broadband ticks whose highs die in tens of ms; ours
  kept every partial ringing as long as the note. Now `loop_filter` sets each string's loss from two
  decay times (the note `t60`, partials near 2 kHz `T60_HIGH` 0.25 s), the output is the wave arriving
  at the bridge (not the strike itself: its spike over the note 10 -> 0 dB), the head's thump softer,
  and the nail landing no longer mutes the old note dead. Single strikes: early / late decay 4.7 (take
  1: 1.3); every struck note within 30 cents. Spectrogram beside his:
  `../results/2026-11-10_fiddle/banjo/spectrogram_macon_vs_take3.png`.
  Strings (Sean, 2026-11-12): `--strings=gut` (the default, the period's: take 3 unchanged, byte for
  byte) or `steel` (`STRINGS`: from the 1890s on, Macon's: the highs ring 0.7 s, the note longer, a
  harder nail, the head tighter; centroid 1.7 kHz to gut's 1.1, above 4 kHz 8 dB more); duet.py and
  band.py take it too. In the band the bones clack on the banjo's own beats and the tambourine is
  two thirds of everything above 5 kHz: the banjo's strike reads differently there.
  **The banjo bench** (Sean, 2026-11-12: "an artifact that's just the banjo until it's perfect ...
  more like The Dead South", whose banjoist plays open-backs, clawhammer and three-finger):
  `--strings=modern` (steel on a tight synthetic head, `HEAD_Q`), `--style=rolls` (`arrange_rolls`:
  three-finger with metal picks, the tune on the 3-3-2 accents, the fingers cycling between with the
  thumb on the drone, the third string either finger's), `bench_clip.py` (one fixed gain to -22 LUFS,
  no leveller). Rounds in `../results/2026-11-10_fiddle/banjo_bench/`.
- `duet.py`: fiddle and banjo together from one tune's note data, the banjo 2.5 dB under.

## The bones and tambourine (the minstrel band)

- `rhythm.py`: the beat grid the rhythm players play to (banjo.arrange's: four running notes a
  beat, bars from the tune's bar 1, the fiddler's swing).
- `bones.py`: two rib-bone slats as free bars (modes 1 : 2.756 : 5.404 : 8.933 over ~650 Hz, Q
  ~20-35), each clack a ~0.3 ms contact into both, half of them flammed; the reel rhythm (beat,
  half beat, a triplet roll into the next beat, a longer roll every four bars).
- `tambourine.py`: a damped calfskin head (Bessel modes over ~190 Hz) and six jingle pairs, each
  with its own energy spent in random collisions (Cook's PhISEM idea), each collision ringing a thin
  disc's modes over 3-4 kHz. A hit's jingle: -20 dB in ~145 ms, -40 in ~320. Hits on the beat, taps
  on the half beat, a shake before each bar, a thumb roll every four bars.
- `band.py`: fiddle, banjo, bones and tambourine from one tune (`--with=` who plays); levels in
  `LEVELS` (banjo -2.5, bones -9, tambourine -11 dB against the fiddle). Each tune's rhythm players
  seeded by its name. Alone the bones and tambourine sit at -23 to -26 LUFS (short strikes in
  silence, not limited); the band at -19 to -20.

## The harmonica

- `harmonica.py`: a ten-hole diatonic in Richter tuning (Hohner's, from 1857), its key from the tune's
  last note (Red River Valley a G harp, Oh! Susanna a D). A free reed chops the breath: the flow is the
  slot's opening (only the clearance while the reed is in it, a gap growing as it swings out, its tapered
  tip uncovering it gradually) times the breath's speed, and we hear the flow's rate of change; the reed
  grows from rest, faster when the breath already flows; the blow chord tuned just. The part: melody
  single-note (tongue blocked), slaps now and then, a soft chord and the hand tremolo on long notes,
  slides over the holes between on one breath, bends for missing low notes.
  Measured against Jenkins and Jenkins' "Mouth Organ Blues" (1924, fetch.sh): the dip at a change of
  note (his -1.7 dB; ours was -9 to -11, a hole as one reed stopped and the next started from rest; now
  -1.8 to -2.5) and the way a note comes in (his ~3 cents flat; ours was 15 sharp from the reed's second
  mode; now -1 to -4). Left: held notes waver 4-7 cents to his 1.6 (`../results/2026-11-10_fiddle/harmonica/`).

## The saloon piano

- `piano.py`: an old upright: one wound string a note in the bass, two in the tenor, three from the
  middle up; each partial a stiff string's (f_n = n f0 sqrt(1 + B n^2), B an upright's), dying in two
  stages (Weinreich's), damped at the key's release (none in the top octave and a half), through a
  soundboard and case (`board_ir`: modes over a set curve) with each key's knock. Out of tune (each key
  ~6 cents, its strings ~7 apart: the honky-tonk), hard felt. The hammer's push (`hammer_force`): its
  length the measured one (Askenfelt & Jansson: ~4 ms low bass to ~0.7 near the top), shorter for a
  harder blow, peaked, with the near end's returning jolts on it; its shape fitted so middle C's
  partials match Fletcher's measured tone at soft, ordinary and hard touches. (A simulated hammer on a
  pass-through string held middle C on ~4 ms whatever the felt: left for a string modelled under the
  hammer.) Voiced: each key measured through the board and set even (`piano_voicing.json`, four
  strikes a key; delete it after changing the model), then left ~1.5 dB uneven per key.
  The part (`arrange`): oom-pah (bass root then fifth on the beat, an octave under on the bar, a close
  chord off the beat), the tune in the right hand a hair ahead, a third/sixth or octave under the
  strong notes. Checks: single notes within ~14 cents (the tuning built in; median +4, the strings'
  stiffness); above 4 kHz -25 dB of the whole; the tune 2.6-4.9 dB over the left hand.
  Take 2 (Sean: "a bit digital"), against Morton's "35th Street Blues" (1924) and Confrey's "Kitten on
  the Keys" (1921) (fetch.sh): the strikes' first 12 ms were already as noise-like as Confrey's (1.5-1.8x
  the note after, his 1.5); the gaps between strikes measure the music more than the piano. What changed,
  by how pianos and pianists work rather than by a measurement: the pedal each bar (each beat in a slow
  tune; `pedal` in the part, dampers off while it's down), the unstruck strings answering
  (`sympathetic`: every string's partials as a response the bridge drives, all of them while the
  pedal's down, the undamped top always; ~18 dB under the whole), felt dampers (slower, a faint thud),
  each string of a note its own stiffness (+-6%: each overtone beats its own way), the off-beat
  chord's voicing turned and sometimes rolled, the left hand drifting ~10 ms, phrases swelling +-10%.

## The travelling band's cornet and drums (#822)

- `march.py` -> `yankee_doodle.json`: the march, Yankee Doodle as a quickstep (traditional), verse and
  chorus twice in F, 2/4 at a quarter = 116, with its beats (two a bar) and a two-bar drum roll-off first.
- `cornet.py`: a B-flat cornet, **our own lip-reed model**. The lips an outward-striking valve (one mass
  on a spring, tuned by the player near the note), the flow through them by Bernoulli; the bore its
  input impedance as resonances (the partials on each valve combination; 1+3 and 1+2+3 sharp as on a
  real horn; peaks highest near the cup's ~850 Hz, gone above the bell's ~1.3 kHz cutoff); the
  pressure and flow solved together each sample in closed form. The bell's high-pass, and the forte
  "blare" as the bore's wave steepening (each period's time warped by its pressure). A tongued note
  starts with the tongue's puff (a burst of flow at the resonance: without it a note grows from rest
  over ~150 ms) and the lips a little slack; slurs keep the breath. **`cornet_tuning.json`** (from
  `calibrate()`; delete it after changing the model): each note's lip tuning and how far its
  resonance sits under it (the lips sound above the bore's resonance, so a real horn's resonances sit
  a little under its notes); the player lips half the soft/loud pitch drift away. `cornet_check.py`:
  each note of a render's pitch, onset and brightness. Runs without numba (~1 s an audio second).
- `drums.py`: **our own modal drums**, calfskin and rope-tensioned: a 28-inch bass drum (lambswool
  beater) and a 16-inch side drum (hickory sticks). Membrane modes at Bessel zeros, the air's pull on
  the low ones, each mode by the stroke's place and the contact's spectrum, a hard stroke's pitch
  glide; the gut snares slap the snare head whenever its swing outruns them (noise bursts by the
  excess), so the rattle thickens in a roll and fades with the head. The part: Bruce & Emmett's
  rudiments (flams, five- and seven-stroke rolls, the roll-off), the bass drum on every beat.
- `band_samples.py`: A, the same parts from VSCO 2 CE's real trumpet, bass drum and snare (CC0;
  `fetch.sh`). The listening set's real instruments.
- `travelling_band.py`: our cornet and drums added to the game's band parts
  (`assets/audio/band/payday_night/`).
- Results: `../results/2026-11-14_cornet_drums/` (the clips, the key, `measures.md`, `spectrum.png`).
  No pre-1925 cornet record yet: archive.org and loc.gov were outside the network (#822's listening
  issue asks).

## Commands

```sh
experiments/sound_lab/fiddle/fetch.sh                       # needs dn801308.us.archive.org allowed
python3 experiments/sound_lab/fiddle/tune.py                # the note data (already in the repo)
python3 experiments/sound_lab/fiddle/banjo.py turkey_in_the_straw.json [--part=OUT.json]   # the banjo alone
python3 experiments/sound_lab/fiddle/duet.py turkey_in_the_straw.json   # fiddle and banjo
python3 experiments/sound_lab/fiddle/band.py turkey_in_the_straw.json   # with bones and tambourine too
python3 experiments/sound_lab/fiddle/harmonica.py red_river_valley.json  # the harmonica
python3 experiments/sound_lab/fiddle/piano.py oh_susanna.json           # the saloon piano
python3 experiments/sound_lab/fiddle/abc_tune.py ryansMammoth/ArkansasTravellerReel.abc arkansas_traveller.json  # any ABC tune
python3 experiments/sound_lab/fiddle/render.py [--dry|--game]   # ~1 min dry, ~80 min the 8 game runs (one at a time)
python3 experiments/sound_lab/fiddle/compare.py             # measures.md/.json, spectrum.png
python3 experiments/sound_lab/fiddle/blind.py               # listen/1-8.mp3, key/KEY.md (a new shuffle)
python3 experiments/sound_lab/fiddle/check.py build/sound_lab/fiddle/dry/A.wav
python3 experiments/sound_lab/fiddle/march.py                # yankee_doodle.json (in the repo)
python3 experiments/sound_lab/fiddle/cornet.py yankee_doodle.json [--note=70 --vel=0.5]   # ~40 s
python3 experiments/sound_lab/fiddle/cornet_check.py yankee_doodle.json
python3 experiments/sound_lab/fiddle/drums.py yankee_doodle.json [--only=snare] [--hit=snare]
python3 experiments/sound_lab/fiddle/band_samples.py yankee_doodle.json   # A: VSCO's (fetch.sh first)
python3 experiments/sound_lab/fiddle/travelling_band.py payday_night       # with the game's band
python3 -c "import cornet; cornet.calibrate()"               # (in fiddle/) cornet_tuning.json, ~3 min
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
