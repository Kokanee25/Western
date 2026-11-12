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
  each, the listening board (`docs/scripts/board.html`, Sean's notes and picks in its database). Sheriff on the
  road: script OK (Sean, 2026-11-12), **cast fixed** (`cast[].voice.picked`: sheriff c4, doctor b3, widow b1,
  freighter b4, livery b1; voice ids on fal's ElevenLabs account). No Justice: Script OK tapped; No Law: not yet
  (#835). Paid calls: request files in `tools/voices/requests/`, run once on GitHub (`voices.yml`, FAL_KEY);
  ledger `tools/voices/paid.csv`, terms `tools/voices/TERMS.md`. Next: Sean picks a take per wording on the page (212 takes, method A
  fixed by the acting test); two wordings refused by fal's checker; then cut and wire the picks (#807 step 5).
  Branch `claude/voices-sheriff-road-takes`, no PR yet.
- Waiting on Sean's ears: #601 (train), #264 (snap or whirr).

## Traps
- Pre-1929 music only; recordings CC0/CC BY, credited. Wikimedia refuses downloads here: Sean uploads them.
- The balcony's boards don't stop GameAudio's wall ray.
- One lavapipe game at a time.
- Built lines (`config/moments/`) are copied into a script as they are; changing one is gameplay's. The board
  reads `script.json` published beside it: republish the JSON with the page (`files`), never paste it in.
- Voices: say "perfect audio quality, modern studio recording" first and no era words, or ElevenLabs makes an old
  film (round 1). "Understated" makes it flat. Short moment tags (`[exhales]`, `[short pause]`, `[whispers]`)
  over stage notes. fal's checker refuses some violent lines ("Then he shot me", ~half the time; free).
  The page's asset store takes no mp3: audio-only mp4 (AAC). A fal voice id won't work with our own
  ElevenLabs key: remake it from the recorded design inputs and seed (TERMS.md).
