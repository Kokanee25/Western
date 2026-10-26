# The saloon cinematic (brief)

Sean, 2026-10-26: a trailer that looks professional, made from our own characters but **animated
and rendered like a film, not in the game** (no physics, no game engine). A pre-rendered cinematic.

## Decisions (Sean, 2026-10-26)

- About 60 s, one scene: the saloon at night, seen from the player's seat at the card table.
- No caption at the start. Ends on **SALT CREEK** in big bold old-west letters.
- The chair kick is part of the cheater's shooting. The cheater dies on the floor.
- The stranger at the table says **"Welcome to Salt Creek."** after the shooting: an AI voice.
- The morning sheriff scene is cut.
- Cast: the stranger at the table (`bold_cowboy_s3_talking`, the painting's man), the cheater
  (`young_drifter_s3_talking`), Hothead Lyle the shooter (`hothead_lyle_s2_talking`), the player
  (`sean_s3_talking`, seen from behind), the barkeep, the rancher and the miner as the room.
- Music and sound effects generated (fal: ElevenLabs sound effects, TTS; a music model), the
  same `FAL_KEY` the characters' paint uses. Cents a call; the cost is given before each batch.
- Rendered on GitHub Actions (Cycles, CPU), the frames split across parallel jobs.

## The shots

1. Black. Cards shuffling, a piano down the room, chatter.
2. Over the player's shoulder (hat and shoulder soft): the stranger across the table, silent.
3. The room: slow push-ins on faces in lamplight; the barkeep at the bar behind.
4. The cheat: the ace sliding from the cheater's sleeve; his smirk.
5. Lyle notices; his eyes lift. Everything drops out but a clock.
6. The kick: Lyle kicks the chair out; the cheater goes down; cards and coins rain.
7. The draw: the gun clears leather, low angle.
8. The cheater on the floor, terrified, one hand up.
9. The shot: the flash lights the room one frame. The player's view: smoke, the body, coins rolling.
10. The stranger hasn't moved. He picks up his whiskey: "Welcome to Salt Creek."
11. Black, then SALT CREEK, dust settling.

## How

- `tools/cinematic/saloon.py` (bpy 5.0.1): the room from the game's interior woods
  (`assets/textures/woods/int_*`, 384 texels a metre, filtered closest: the game's squares), kit
  props from `assets/props/kit/*.json` (members as boxes, lathes turned, the round top whole), the
  Studio men with their painted textures and their 20 face shapes (smirk, scowl, brows, jaw),
  posed by aiming bones. Lamps, sconces, a moon through the doors, lamp haze. 2.39:1.
- `.github/workflows/cinematic.yml`: stills on every push to `claude/cinematic-*`.

## Steps (each its own session)

1. **Look test** (this one): set, cast, light; four stills (2, 4, 5 and the room). Sean judges.
2. Animation: every shot blocked and keyed (the Uthana kick and draw clips where they fit), a
   low-quality full-length preview with temporary sound.
3. Sound: the voice line, the effects and the score generated; mixed to the cut.
4. Final: frames rendered in parallel, the title card, grade and grain, the MP4.

## How it's judged

Sean watches it. Before him: the stills against `docs/concept/saloon-night.png` (the warm lamp
pools, the moon in the door, faces readable in lamplight), and no men through chairs or tables.
