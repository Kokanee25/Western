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
- **Voiced lines (#807)**: script, then 4-5 ElevenLabs takes per line, Sean picks on a listening board;
  first the sheriff on the road. Needs the story bible's voices (#809) for later lines.
- Waiting on Sean's ears: #601 (train), #264 (snap or whirr).

## Traps
- Pre-1929 music only; recordings CC0/CC BY, credited. Wikimedia refuses downloads here: Sean uploads them.
- The balcony's boards don't stop GameAudio's wall ray.
- One lavapipe game at a time.
