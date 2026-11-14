# The dynamite's recorded sets, blind (#596 step 1)

Three sets of layers (crack, boom, sub, roll) cut from the eight Freesound CC0 recordings Sean
downloaded (#599; `../../blast_recordings.json`, `assets/audio/blast/`), each played through the
game itself (`blast_clips.py`: GameAudio's placement, the lab's Movie Maker mix), one stick each.

`1_all.mp3`, `2_all.mp3`, `3_all.mp3`: the same stick heard from **5 m, 30 m and 150 m** in the street,
then **5 m inside the saloon**, a second of quiet between. Labels are shuffled (`key.json`: label ->
set; Sean picks by ear first).

| label | where | peak dBFS | LUFS max | onset s | length s | decay20 s | tail dB | centroid Hz |
|---|---|---|---|---|---|---|---|---|
| 1 | 5 m | -4.9 | -13.2 | -0.01 | 5.51 | 1.42 | -0.6 | 156 |
| 1 | 30 m | -6.5 | -17.1 | 0.15 | 2.96 | 1.46 | -1.5 | 231 |
| 1 | 150 m | -17.0 | -28.8 | 0.5 | 3.44 | 1.22 | -2.1 | 155 |
| 1 | saloon 5 m | -1.5 | -9.3 | -0.01 | 5.51 | 1.39 | -1.9 | 141 |
| 2 | 5 m | -1.5 | -10.7 | -0.01 | 5.51 | 0.91 | -1.0 | 144 |
| 2 | 30 m | -1.5 | -13.0 | 0.15 | 4.47 | 0.44 | -3.2 | 169 |
| 2 | 150 m | -12.7 | -24.3 | 0.51 | 5.98 | 0.19 | -3.1 | 177 |
| 2 | saloon 5 m | -1.5 | -8.8 | -0.01 | 5.51 | 1.24 | -1.6 | 142 |
| 3 | 5 m | -3.4 | -13.6 | -0.01 | 5.51 | 1.49 | -0.8 | 178 |
| 3 | 30 m | -7.0 | -17.7 | 0.15 | 2.99 | 1.47 | -1.6 | 334 |
| 3 | 150 m | -17.5 | -28.8 | 0.5 | 3.45 | 0.19 | -2.1 | 164 |
| 3 | saloon 5 m | -1.5 | -9.2 | -0.01 | 5.51 | 1.4 | -2.1 | 148 |

The synthesised blast for comparison (same scenarios, `--blast-set=0`): 30 m LUFS max −19.3, 150 m
−28.5. Inside the saloon every set reaches the Master bus's limiter (−1.5 dBFS), and label 2 does at 5 and 30 m outside too. Cost on the frame: four placed
sounds a stick (the synth: two), the files loaded on a worker at the start (`BlastSounds.warm`).
