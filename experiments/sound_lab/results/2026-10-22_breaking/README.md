# Change 4: breaking placed, and a voice limit (2026-10-22)

Against the baseline's item 9 (`../../baseline/baseline.md`). "Before" is change 3 (dynamite placed,
breaking not: `build/sound_lab/d_after`, `v_before`); "after" `build/sound_lab/v_after`.

## What changed

- **Breaking placed** (`GameAudio.play`): a member's `timber_crack` and rubble's `timber_crash`
  (`Structure._play`), a pane's `glass` (`StructureMember`), a lamp's `glass` (`OilLamp`). Like the
  rest: late by distance, the air, the Room bus inside, muffled through walls.
- **A voice limit** (`GameAudio._room_for`): at most `max_voices` (32) placed sounds at once,
  playing or on their way, and at most `breaking_limit` (4) of one breaking sound. When full, the
  quietest at the ears gives way to a louder newcomer, or the newcomer isn't played if it's the
  quietest. Dials in `config/sound.tres` ("How many at once").

## Measured

| | before | after |
|---|---|---|
| Voices at once: the store's front down (3 sticks) / one stick in the saloon | 135 / 50 | 32 / 22 |
| The saloon's stick from the street at 30 / 100 m (LUFS) | −9.4 / −16.2 (its breaking at once, unmuffled) | −21.5 / −32.8 |
| Its decay to −20 dB at 30 / 100 m | 0.23 / 0.30 s | 1.71 / 1.94 s (the roll, through the walls) |
| The gang's fight: voices at most / mean | 9 / 1.9 | 9 / 1.9 (it never reaches the limit) |

Cost: 32 voices is ~1.3 ms of mixing a frame on this workspace's 2.1 GHz core (the lab's cost run:
~0.04 ms a voice), ~0.85 ms at Sean's, for the moment a building comes down; before it was 135.

Left unplaced (not this lab's files): the prop lab's `GlassProp` (bottles; it shatters at once at any
distance, and one in the saloon breaks when the lab clears the town), the fire's crackle and the
steam (next: fire by size).

## Clips (`clips/`: before, a second's gap, after)

`dynamite_in_5`, `dynamite_in_30` (from the street), `wall_down`.
