# Brief: the sound lab (Sean, 2026-10-21)

Roadmap: the sound lab (`docs/ROADMAP.md`, `docs/briefs/labs.md` "Sound lab"), gameplay lane,
branch `claude/gameplay-sound-lab-…`. Bench in `experiments/sound_lab/`.

## Goal

Sound that sells the fights, as the player hears them: gunshots with weight, ricochets and passing
balls that tell you how close it came, dynamite that thumps near and rolls far, impacts by
material, breaking timber and glass, fire by size, steps on boards and dirt, and every one placed
in the world (distance, delay, indoors against out, walls between, the hills' echo). The
perception lab (gunfight lab) owns what the *men* hear; this lab owns how it *sounds to Sean*.

## References (ideas and figures only; nothing copied)

- **Speed of sound** 343 m/s at 20 °C (~331 + 0.6 T). A sound 80 m off arrives 0.23 s late, 100 m 0.29 s.
- **Period loads:** .45 Colt, black powder under a 255 gr ball, quoted at 850–1,050 ft/s (~260–320 m/s; sources disagree, none a period chronograph; the game's
  revolver: 274 m/s): **subsonic, no crack**; a passing ball hums or flutters. Buckshot from a
  black-powder 12 bore ~350–370 m/s (the game's 365 m/s): just supersonic at the muzzle, below
  sound within a few metres to ~20 m as the pellets slow. Rifles of the day (.44-40 ~370–400 m/s,
  .45-70 ~400 m/s) do crack. The crack is a ball's shock (an N-wave), heard only from a ball faster
  than sound.
- **Black powder vs smokeless:** a lower, duller, longer report (slower burn, lower peak pressure
  at the muzzle, a lot of gas and smoke), more "boom" than "crack".
- **Air absorbs highs with distance** (ISO 9613-1: of the order of 0.1 dB/m at 4 kHz, near
  nothing below 500 Hz), so far shots are dull rumbles; **ground and walls** reflect (a street of
  flat fronts gives a slap-back; open hills a late rolling echo).
- **Rooms:** a small wooden room (the saloon, ~10×15×4 m) has a short reverb (RT60 ~0.5–0.8 s)
  and early reflections inside 20 ms; a wall between loses the highs (a timber wall ~25–35 dB,
  most of it above 500 Hz), an open door lets a lot through.
- Game audio practice in general (attenuation curves, voice limits by priority, buses per space,
  occlusion by raycast): Godot's own docs on `AudioStreamPlayer3D`, `Area3D` reverb buses.

## What done looks like

- An inventory of every sound: what plays it, how it's placed, and every event with no sound.
- A bench that records and measures each scenario (`experiments/sound_lab/`), seeded, with a
  baseline of today's game and the ten worst things about it.
- Then, one change at a time, each with before/after clips and numbers against the baseline:
  gunshots (period-true: no crack from a subsonic ball), distance delay and air loss, the echo,
  walls and rooms, ricochets and passes by distance, dynamite near and far with debris after,
  impacts by material, timber and glass breaking, fire by size, steps, a voice limit.
- Promoted into the game's shared audio (`src/audio/`) and `docs/PARTS.md`; inside the frame
  budget (audio is counted in "Everything else"); the game works the same with any change off.

## How it's judged

- **Numbers** catch what's broken: loudness and length per sound, falloff (dB per doubling of
  distance), arrival delay, inside/outside tail length, the loss through a wall, voices at once in
  a full fight, audio's cost a frame. Each change shows its numbers against the baseline.
- **Ears decide.** Sean listens to before/after clips (a `waiting on Sean` issue says exactly
  what to listen for) and then plays. Numbers only say it's placed right; Sean says if it sells.
- Sources: synthesis first; any recorded or generated sound only with a licence allowing
  redistribution from a public repo, credited in `CREDITS.md`; nothing paid without asking.
