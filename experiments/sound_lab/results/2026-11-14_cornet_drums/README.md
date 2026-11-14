# The travelling band's cornet and drums, made ourselves (#822), 2026-11-14

Yankee Doodle as an 1880s band quickstep (`../../fiddle/march.py`, `yankee_doodle.json`), played by
our own cornet (`cornet.py`, a lip-reed and bore model) and drums (`drums.py`, modal calfskin bass and
side drums with gut snares), and the same parts by VSCO 2 CE's real trumpet, bass drum and snare
(`band_samples.py`, CC0). How each is made and how to run it all again: `../../fiddle/README.md`,
"The travelling band's cornet and drums". No paid calls; nothing in the game changed.

**For Sean:** the listening page https://claude.ai/artifact/GXddFYCNLBv4SHnvi6h4hb (private), or
`listen/1.mp3` to `listen/7.mp3`. Clips 1-2 are the cornet pair, 3-4 the drums pair, each one ours and
one real, in a random order (`key/KEY.md`, the seed in it). Each clip is at one fixed gain to
-22 LUFS (`bench_clip.py`). Clips 5-7 aren't blind: the march with our cornet and drums, with the
real recordings, and Payday Night with the game's band parts (`assets/audio/band/payday_night/`)
and our cornet and drums joining in (`travelling_band.py`).

## No cornet record yet

#822 asks for a pre-1925 cornet record to measure against. archive.org, loc.gov (the National
Jukebox) and UCSB's discography were all outside this session's network (refused by the proxy), so
none was fetched. A good one: Herbert L. Clarke's cornet solos for Victor (1908-1918; US recordings
published before 1923 are public domain since 2022 under the Music Modernization Act). The listening
issue asks Sean to allow a host or upload one. Until then the yardstick is VSCO's trumpet, a
trumpet (brighter than a cornet) played by a modern player.

## What was measured (`measures.md`, `spectrum.png`)

- **Brightness rising with loudness:** our held notes go from about the trumpet's soft centroid
  (1100-1350 Hz) to about its loud one (1700-2400 Hz) from soft to loud. Up high (D5) ours is much
  brighter than the trumpet's.
- **The march's notes:** 110 of 110 speak on their own partial; pitch median +7 cents (5-95% -3 to
  +36), onsets ~50 ms (the trumpet's 25-50).
- **The drums:** the side drum within a few dB of VSCO's snare in each band and its decay (-40 dB at
  ~220 ms to its ~290); the bass drum's (1,1) at 73 Hz to VSCO's 83, its low end stronger.

## Faults known before Sean's listen (each tried twice; reported, not chased further)

- The cornet flares bright at each note's start and settles darker: the steady tone sits just
  under the wave-steepening's threshold, so the attack's extra pressure tips it into a near-shock.
- A tongued note runs up to ~35 cents sharp for its first ~100 ms (the start transient, eased by the
  lips starting slack).
- A note grows from rest over ~150 ms in the plain model; the tongue's puff (a burst of flow at the
  resonance) is a modelling shortcut for the release's pulse down the bore.
- The low C (1+3 valves) sounds grainy; 81-83 hold only up to a middling loudness.
