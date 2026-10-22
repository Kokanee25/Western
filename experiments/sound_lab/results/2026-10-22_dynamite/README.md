# Change 3: dynamite near and far, and what it throws coming down (2026-10-22)

Against the baseline's item 10 (`../../baseline/baseline.md`). Before and after from one build
(`run.py --old-sound`); runs `build/sound_lab/d_before`, `d_after`; tables `table_before.md`,
`table_after.md`.

## What changed

- **The blast** (`SynthSounds` `blast`, 44.1 kHz): a shock several times a gunshot's (a Friedlander
  pulse, 4 ms positive phase), a thump held above the speakers' 45 Hz floor, the tearing of what it
  throws, a heavy low roar over a second and more. No echo baked in.
- **The roll** (`blast_roll`): thunder off the hills, five times back, each duller and smeared,
  six seconds long. Close, it's under the blast; far, it's most of what you hear.
- **Debris** (`GameAudio.blast`): ten clods and splinters (one stick's worth; more by the cube root
  of the charge) landing 1.5–9 m round it, 0.5–2.8 s after, each placed and late by its own distance.
- Placed like the guns: late by distance, the air, the Room bus inside, walls, the slap off the
  fronts. Dials in `config/sound.tres` ("Dynamite"). The ringing ears after a blast near you were
  already there (`PlayerWounds`) and still are.

## Measured (one stick, loudest 400 ms)

| | before | after |
|---|---|---|
| In the street at 5 / 30 / 100 m (LUFS) | −13.4 / −18.0 / −29.1 | −13.2 / −19.4 / −33.8 |
| Heard after it goes off at 30 / 100 m | 0.01 / 0.01 s | 0.10 / 0.31 s |
| Decay to −20 dB at 5 / 30 / 100 m | 0.86 / 0.65 / 0.65 s | 1.39 / 1.62 / 1.70 s (the roll) |
| Centroid at 5 / 100 m | 625 / 225 Hz | 495 / 177 Hz |
| Falloff a doubling | −3.5 dB | −4.7 dB |
| Inside the saloon (5 m in; 30 and 100 m out in the street) | −6.9 / −9.3 / −15.9 | −7.4 / −9.4 / −16.2 |

Inside, little changes: what you hear is the saloon breaking (its timber's crack and crash, every
pane's glass, its fire), which isn't placed yet, so even at 100 m it comes at once. That, and the
voices at once (135 when the store's front comes down, with the debris), is the next change:
breaking placed, and a voice limit.

## Clips (`clips/`: before, a second's gap, after)

`dynamite_out_5`, `dynamite_out_30`, `dynamite_out_100`, `dynamite_in_5`.

## For Sean's ears

Does it thump close and roll far? Is the debris coming down after it right, too much, too little?
