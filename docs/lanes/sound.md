# Sound: current state

Sound work runs as the gameplay lane's sound sessions (`src/audio/`, `experiments/sound_lab/`, brief
`docs/briefs/sound-lab.md`). Sean judges sound by ear. Replace your lines here at the end of a session; no
history. Keep under ~10 KB. History to 2026-11-11: `docs/status/current-state-2026-11-11.md` (search "sound").

## What's in the game
- `GameAudio` places every sound (delay by distance, air, rooms, walls, slaps; `config/sound.tres`);
  black-powder gunshots; dynamite (Sean's recordings, #605; the crack held 0.3 s; volleys for bundles).
- Train: 18 of 20 sounds real recordings (`assets/audio/train/`, `CREDITS.md`), brakes synthesised.

## Open
- **The band in the game (#799, merged 2026-11-14)**: `Band` (src/audio/band.gd, config/band.json) plays Payday
  Night's six parts (fiddle B, banjo, piano, harmonica, bones, tambourine) from one note data, rendered ahead by
  `tools/band/render_band.py` into `assets/audio/band/payday_night/` (3 MB of Ogg) and placed through GameAudio.
  The fiddler and pianist (stand-in factory bodies) play in person at No Law's yard set (saloon B's dance hall,
  #884, wasn't on main); the other four are placed sound only. Open: the band's place in saloon B's dance hall
  when it's built; more tunes (render each: ~3 min); a fist fight played through faster (a second tempo's
  render); the bowed sound and hands judged by Sean (the dry mix in
  `experiments/sound_lab/results/2026-11-14_band/`); the dropped fiddle as the kit prop.
- **The band's instruments, our own models (#790's follow-ons, `experiments/sound_lab/fiddle/` README)**:
  the banjo (gut on calfskin, clawhammer, take 3 Sean's "way better", measured against Macon 1924; steel and a
  modern open-back with three-finger rolls on the Banjo Bench, waiting on Sean's round-1 answers), bones,
  tambourine, harmonica (against Jenkins 1924), the saloon piano (take 2, against Morton 1924 and Confrey
  1921; "a bit digital" after take 1), `band.py` (any tune, any players), ten fiddle tunes (two drunk), and
  Payday Night, an original reel the band plays (`tunes/payday_night.abc`). One page an instrument and one for
  the band (links in `experiments/sound_lab/results/2026-11-10_fiddle/README.md`).
- **The travelling band's cornet and drums (#822 done; Sean's listen #942)**: `cornet.py` (lip-reed, calibrated
  per note in `cornet_tuning.json`: delete it and run `calibrate()` after changing the model), `drums.py` (modal
  calfskin bass and side drum, gut snares), `march.py` (Yankee Doodle), `band_samples.py` (VSCO's trumpet and
  drums: the blind pairs' "real"), `travelling_band.py` (with the game's Payday Night parts). Page
  https://claude.ai/artifact/GXddFYCNLBv4SHnvi6h4hb. Known: the cornet's attack flares bright then settles
  darker, short notes start up to ~35 cents sharp, high notes brighter than a trumpet's. No cornet record yet
  (#942 asks for a host or an upload).
- **Voiced lines (#807)**: one script a mission as data (`docs/scripts/`, README there) and one artifact page
  each, the listening board (`docs/scripts/board.html`, Sean's notes and picks in its database). The sheriff
  on the road's script is written (66 lines, 5 speakers; page https://claude.ai/artifact/FyzbCopumhRVDAeH7hN1vX),
  No Law (32 lines, https://claude.ai/artifact/65eAXArWQm5XD5FCEXpYuY) and No Justice (47 lines,
  https://claude.ai/artifact/3ojdVLjNoGLCt5qkADSEiW) the same way. All three wait on Sean's Script OK (#835).
  Next: casting (#836, the sheriff's first), then 3-4 takes a line, then into the game.
- Waiting on Sean's ears: #601 (train), #264 (snap or whirr).

## Traps
- Pre-1929 music only; recordings CC0/CC BY, credited. Wikimedia refuses downloads here: Sean uploads them.
  On 2026-11-14 archive.org, loc.gov and PyPI were refused too (no numba: the cornet and drums run without it).
- The balcony's boards don't stop GameAudio's wall ray.
- One lavapipe game at a time. The bridge's game renders a few frames a second under lavapipe: the band's
  clock follows the parts (real time), so a tune "ends" in fewer game seconds there.
- Built lines (`config/moments/`) are copied into a script as they are; changing one is gameplay's. The board
  reads `script.json` published beside it: republish the JSON with the page (`files`), never paste it in.
