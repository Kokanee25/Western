# Sound: current state

Sound work runs as the gameplay lane's sound sessions (`src/audio/`, `experiments/sound_lab/`, brief
`docs/briefs/sound-lab.md`). Sean judges sound by ear. Replace your lines here at the end of a session; no
history. Keep under ~10 KB. History to 2026-11-11: `docs/status/current-state-2026-11-11.md` (search "sound").

## What's in the game
- `GameAudio` places every sound (delay by distance, air, rooms, walls, slaps; `config/sound.tres`);
  black-powder gunshots; dynamite (Sean's recordings, #605; the crack held 0.3 s; volleys for bundles).
- Train: 18 of 20 sounds real recordings (`assets/audio/train/`, `CREDITS.md`), brakes synthesised.

## Open
- **The band in the game (#799, #938)**: `Band` (src/audio/band.gd, config/band.json) plays two tunes (Payday
  Night, Turkey in the Straw), six parts each, rendered ahead by `tools/band/render_band.py` into
  `assets/audio/band/<tune>/`, each with a hurried render (`--faster=1.15`, `<tune>_fast/`) it goes over to at a
  phrase's top while a fist fight's near (shove, kick; `punch` listed for when it exists), back 20 s after the last
  blow; a gun drawn near stops them. **Payday Night** all six on saloon B's stage (#902's use points, the curtain
  drawn open), the fiddler and pianist walking up the outside stair and through the wing, the stage's own upright
  (folk's `set.stage_piano`); **other nights** the fiddle and piano only, still in No Law's yard set. Open: the
  bar room's piano corner for ordinary nights and the first night's trio (Sean on #938) once #984 places that
  piano; the fiddler only "sometimes" on ordinary nights; the banjo, harmonica, bones and tambourine are sound only
  (no bodies); the bowed sound and hands judged by Sean (the dry mix in `experiments/sound_lab/results/2026-11-14_band/`).
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
- The balcony's boards don't stop GameAudio's wall ray (the dance hall's floor does: the stage heard RoomMuffled
  from the bar room under it, #938).
- No numba here (PyPI refused): render with `PYTHONPATH=tools/band/nonumba` (plain Python, the piano in numpy;
  the fiddle ~4 s an audio second, the banjo ~9). Render a tune's parts in one run (`--only=a,b,...`): parts from
  separate runs are padded only to the length known then.
- One lavapipe game at a time. The bridge's game renders a few frames a second under lavapipe: the band's
  clock follows the parts (real time), so a tune "ends" in fewer game seconds there.
- Built lines (`config/moments/`) are copied into a script as they are; changing one is gameplay's. The board
  reads `script.json` published beside it: republish the JSON with the page (`files`), never paste it in.
