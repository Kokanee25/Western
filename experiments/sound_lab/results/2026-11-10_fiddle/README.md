# The fiddler's sound, made ourselves first (#790), 2026-11-10

Soldier's Joy's A part twice (~19 s, from the note data `../../fiddle/soldiers_joy.json`) made three
ways, A (samples), B (our own bowed-string model) and C (the hybrid), against a real old-time fiddler
from 1922. How each is made, and how to run it all again: `../../fiddle/README.md`. No paid calls;
nothing in the game changed.

**For Sean:** `listen/1.mp3` to `listen/8.mp3` (or the listening page linked in the issue). Clips
1-4 are up close, 5-8 through the floor; each set has the reference and A, B, C once, in its own
random order (drawn from the system's randomness; the seed is in the key). Within a set every clip
is the same length and loudness (up close -16 LUFS, through the floor -24), so only the sound
differs: as the game plays them, the record comes through the floor 5-7 dB louder than ours (it's
all in the floor's low-pass band). The key is `key/KEY.md`: open it after. The dry renders are
beside it.

## The reference

**"Sallie Gooden"**, A. C. "Eck" Robertson, solo fiddle, recorded for Victor in New York on 1 July
1922, issued as Victor 18956 (1923). From the Internet Archive's transfer of the 78
(https://archive.org/details/ACEckRobertsonSallieGoodenVictor18956), FLAC, 3:08; the clip is 1:40 to
2:00, as it is (hiss and all).

Why it's public domain: it's a US sound recording from before 1923. Pre-1972 recordings had no
federal copyright, only state law; the Music Modernization Act (2018, 17 U.S.C. §1401) gave them a
federal term ending on 31 December 2021 for those first published before 1923, so it entered the
public domain on 1 January 2022. Even counted by its 1923 issue, a 1923 recording's term ended on
31 December 2023. The tune is traditional. It's the target to compare against, not something the
game ships.

The reference isn't Soldier's Joy: US recordings are public domain only up to those published in
1925 (as of 2026), and the Internet Archive's earliest Soldier's Joy is John Baltzell's Edison of
1928 (`edison-52370_01_18379`), protected until 2029. Eck's playing is the yardstick for the sound
and the style; the tune differs.

## The three

- **A, samples:** VSCO 2 CE's solo violin (CC0), its vibrato taken out by reading each sustain at
  the speed that cancels its own measured pitch, short-stroke bites on each new stroke, round-robins,
  slurs as one running sample, drones and double stops on their own strings.
- **B, our bowed-string model:** four waveguide strings and a stick-slip bow, from the physics. A
  held note's check: it slips 10% of each period (its bow position, 0.10), harmonics fall as 1/n
  (-6, -10, -12 dB) and the 10th is missing, as a real bowed string's Helmholtz motion does.
- **C, the hybrid:** A's sustains with B's stroke starts, slurred changes and bow scratch.

All four go in at -18 LUFS. In the game (`music_balcony_close`, `music_balcony_below`): the fiddler
on the town saloon's balcony (4.25 m up, the corner over the bar's end; the game has no dance hall
yet). Up close: you on the balcony 1.3 m from him, the Room bus. Through the floor: you on the bar
room's floor under the balcony, 1.9 m, RoomMuffled (GameAudio's wall low-pass and the room).

## Measured against the reference (a guide; Sean's ear decides)

`measures.md` / `measures.json` (by `../../fiddle/compare.py`), `spectrum.png`. The dry clips, as they
are and as the 1922 horn would have heard them (all four band-passed 250 Hz-4 kHz).

**As the 1922 horn heard it (all four band-passed 250 Hz-4 kHz)**

| Measure | Reference (1922) | A samples | B model | C hybrid |
|---|---|---|---|---|
| spectral shape off the reference (dB RMS, 250 Hz-4 kHz) | 0.0 | 9.57 | 8.5 | 10.13 |
| centroid (Hz) | 773 | 1443 | 1453 | 1714 |
| notes/s found | 7.14 | 5.82 | 5.71 | 6.81 |
| attack 10-90% (ms) | 30.0 | 30.0 | 35.0 | 30.0 |
| pulse: drop between notes (dB) | 3.4 | 7.2 | 3.8 | 3.5 |
| vibrato within held notes (cents s.d.) | 10.0 | 3.2 | 0.0 | 3.6 |
| scratch: flatness 2-6 kHz | 0.046 | 0.007 | 0.003 | 0.006 |

**As they are**

| Measure | Reference (1922) | A samples | B model | C hybrid |
|---|---|---|---|---|
| spectral shape off the reference (dB RMS, 250 Hz-4 kHz) | 0.0 | 9.45 | 8.43 | 9.95 |
| centroid (Hz) | 773 | 1554 | 1468 | 1839 |
| notes/s found | 6.82 | 5.71 | 5.61 | 6.71 |
| attack 10-90% (ms) | 30.0 | 30.0 | 40.0 | 30.0 |
| pulse: drop between notes (dB) | 3.5 | 7.3 | 3.2 | 3.4 |
| vibrato within held notes (cents s.d.) | 9.2 | 3.1 | 0.0 | 1.5 |
| scratch: flatness 2-6 kHz | 0.139 | 0.021 | 0.01 | 0.016 |

What it says, and what it can't:
- **Brightness:** all three are about twice as bright as the record (centroid ~1.4-1.7 kHz vs
  0.77), and above 2 kHz they sit 10-20 dB over it (`spectrum.png`). Most of that is the 1922 horn
  (acoustic recording fell away above ~2.5 kHz); the record's one strong band at 630 Hz is its
  tune's notes in its key. The spectral-shape number is mostly medium and tune, not fiddle.
- **Articulation:** B and C move like the record between notes (a 3-4 dB drop); A is choppier
  (7 dB): its notes stop more cleanly than a bowed string's ring. The record's own dip reads low
  (its hiss fills the gaps).
- **Attack:** all within 25-35 ms of 10-90% rise, as the record's 30.
- **Steadiness:** the record wobbles ~10 cents within a held note (Eck's hand, and the 78's speed);
  A ~3, C ~4, B ~0 (the hand's wander in B is slower than a note). Few held notes were found in ours
  (6-8, against 42 in the record): the drones under nearly every note confuse the pitch tracker,
  so take this one lightly. Eck drones less than our arrangement does.
- **Scratch:** the record's surface noise swamps the measure.

## Found on the way

- **The balcony's floorboards aren't solid to rays** (the `furniture_top` kind): the player stands
  on them, but GameAudio's wall test and the lab's floor ray pass through. From below, the music
  is muffled only because the line from the ear crosses a joist; a step to the side, between
  joists, and the game hears it as in the same room. Gameplay's: matters for the dance hall (a
  sound upstairs should be muffled by the floor, not by luck).
- Two games at once under lavapipe run this workspace out of memory: one at a time (~7 min each).

## Next

Sean's ear on the blind set. If one passes, it becomes the fiddler's voice (the note data drives
both his sound and his hands). If none does, a fiddler records the tunes phrase by phrase from our
sheet music; the hands are built from the note data either way.

## Sean's ear (2026-11-11, on his phone, blind)

| Clip | Sean | Was |
|---|---|---|
| 1 | Sounds real | A, samples (up close) |
| 2 | Sounds real | B, the model (up close) |
| 3 | Wrong | the 1922 record (up close) |
| 4 | Sounds real | C, hybrid (up close) |
| 5 | Sounds real | B, the model (through the floor) |
| 6 | Sounds real | A, samples (through the floor) |
| 7 | Wrong | the 1922 record (through the floor) |
| 8 | Close | C, hybrid (through the floor) |

All three of ours passed; A and B in both places. The record marked wrong is most likely its
medium and tune (a 1922 horn disc, Sallie Gooden). No fiddler needed by this test. **Sean picked B,
our own model** (2026-11-11: "we're going with our own model obviously that was unreal"): it becomes
the fiddler's voice, played from the same note data as his hands.

## From outside (B, Sean's pick; 2026-11-11)

`outside/B_porch.mp3` (the porch by the saloon's door, 5.5 m from him) and `outside/B_across.mp3`
(across the street, 17.5 m): the lab's `music_street_porch` / `music_street_across`, the fiddler on
the balcony inside. The game hears both through the walls (RoomMuffled: the room's ring, the wall's
low-pass and drop). As heard, the porch is -47 LUFS and across the street -57, against -19 up close
and -37 through the floor; the two clips are raised together (the porch to -20) to be heard on a
phone, keeping the 10 dB between them. Found: from the porch, GameAudio's one ray is stopped first
by a porch post, not the wall (the same muffle here, but by luck, like the balcony's joists).

## From outside with the room's crowd (B; 2026-11-11)

`outside/B_crowd_porch.mp3`, `outside/B_crowd_across.mp3`: the fiddler on the balcony and the room's
crowd on the bar room floor (7.5, 2.3, 6.5; off the door's line, or GameAudio counts it outdoors),
both heard through the walls (RoomMuffled), from the porch and across the street (`music_crowd_*`,
the music kind's `bed`). The crowd is the cinematic's ElevenLabs take (`sfx_room.mp3`, branch
`claude/cinematic-saloon`, made through fal on 2026-10-26: "Quiet 1880s saloon at night: low
murmur of men..."): busy for ~2 s and then dying away, so `fiddle/crowd_bed.py` levels its first
10 s and builds a steady 23 s bed of overlapping slices in three layers. A stand-in: a quiet
murmur, not a Payday Night dance. As run (bed at -5 dB) it sat 12 dB under the fiddle at the
porch, barely there; the clips raise its part by 6 dB from the same two runs (the mix is linear at
these levels; the scenarios now say +1 dB): 5.7 dB under the fiddle at the porch, 2.9 across the
street. Raised together to -20 LUFS at the porch, as the fiddle-only pair.

## A second tune: Arkansas Traveller (B only; 2026-11-11)

Sean: "make me another song and make the same sound board for the distances, just our fiddle".
`../../fiddle/abc_tune.py` turns any ABC file into note data the same way as Soldier's Joy (string
and finger in first position, the shuffle, swing, drones from each bar's chord, double stops,
slides); `arkansas_traveller.json` is Ryan's Mammoth Collection's (1883) reel, both parts twice, 37 s
at half note = 108. Dry render: 90% of its 212 melody notes within 30 cents (melody alone). The
chords are guessed per bar from its notes (the B part comes out all D), so they only steer the drones.

`arkansas/`: `balcony_close` (-16 LUFS), `balcony_below` (-24), `street_porch` / `street_across` (the
porch at -20, across 9.7 dB under, as the game has them), `crowd_porch` / `crowd_across` (the crowd
bed run at +1 dB in the scenarios; the porch at -20, across 9.2 under). As heard in the game: close
-19.1, through the floor -37.2, porch -46.6, across -56.3. The porch runs take ~17 min under lavapipe
with a 37 s tune: `run.py --timeout=2000`.

## Devil's Dream at the game's distances

`devils_dream/`: the plain take (`dry.mp3`) and the six game runs, cut as Arkansas Traveller's (pairs keep the
game's level). Heard: close -18.6, through the floor -39.5, porch -48.9, across -58.6 LUFS.

## The banjo

`banjo/`: our banjo model (`fiddle/banjo.py`) alone and with the fiddle (`fiddle/duet.py`), Turkey in the
Straw (open G) and Devil's Dream (open A), plain takes at -18 LUFS. The duet's game distances follow.
Take 3 (after "still kinda digital"): measured against Uncle Dave Macon's 1924 "Papa's Billie Goat"
(`spectrogram_macon_vs_take3.png`); the clips in `banjo/` are take 3.

## The minstrel band

`band/`: the bones and the tambourine alone (Turkey in the Straw) and the band (fiddle, banjo, bones,
tambourine) on Turkey in the Straw and Devil's Dream; plain takes. `turkey_in_the_straw/`: the fiddle
alone at the game's distances (heard: close -18.9, floor -37.7, porch -47.1, across -56.9 LUFS).

Steel strings (`banjo/turkey_*_steel.mp3`): the same banjo and part strung with steel, alone, with the
fiddle and in the band (Turkey in the Straw).

Fiddle and banjo (take 3) at the game's distances: `banjo/turkey_duet_game/` (heard: close -19.0, floor
-36.9, porch -46.4, across -56.1 LUFS).
