# Sound: current state

Sound work runs as the gameplay lane's sound sessions (`src/audio/`, `experiments/sound_lab/`, brief
`docs/briefs/sound-lab.md`). Sean judges sound by ear. Replace your lines here at the end of a session; no
history. Keep under ~10 KB. History to 2026-11-11: `docs/status/current-state-2026-11-11.md` (search "sound").

## What's in the game
- `GameAudio` places every sound (delay by distance, air, rooms, walls, slaps; `config/sound.tres`);
  black-powder gunshots; dynamite (Sean's recordings, #605; the crack held 0.3 s; volleys for bundles).
- Train: 18 of 20 sounds real recordings (`assets/audio/train/`, `CREDITS.md`), brakes synthesised.

## Open
- **The fiddler in the game (#799)**: our own bowed-string model (B, Sean's pick on #790); Soldier's Joy as
  note data; then the piano player with it (one music system, week 3; the first saloon entry, #810).
- **Voiced lines (#807)**: one script a mission as data (`docs/scripts/`, README there) and one artifact page
  each, the listening board (`docs/scripts/board.html`, Sean's notes and picks in its database). The sheriff
  on the road's script is written (66 lines, 5 speakers; page https://claude.ai/artifact/FyzbCopumhRVDAeH7hN1vX),
  No Law (32 lines, https://claude.ai/artifact/65eAXArWQm5XD5FCEXpYuY) and No Justice (47 lines,
  https://claude.ai/artifact/3ojdVLjNoGLCt5qkADSEiW) the same way. All three wait on Sean's Script OK (#835).
  Next: casting (#836, the sheriff's first), then 3-4 takes a line, then into the game.
- Waiting on Sean's ears: #601 (train), #264 (snap or whirr).

## Traps
- Pre-1929 music only; recordings CC0/CC BY, credited. Wikimedia refuses downloads here: Sean uploads them.
- The balcony's boards don't stop GameAudio's wall ray.
- One lavapipe game at a time.
- Built lines (`config/moments/`) are copied into a script as they are; changing one is gameplay's. The board
  reads `script.json` published beside it: republish the JSON with the page (`files`), never paste it in.
