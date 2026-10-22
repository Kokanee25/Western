# The sound lab

Sean, 2026-10-21; brief `docs/briefs/sound-lab.md`, `docs/briefs/labs.md` "Sound lab". It measures
how the game sounds **to the player**: every sound, how it's placed (distance, delay, indoors and
out, walls), how loud and long each is, how many play at once and what they cost. The perception
lab (the gunfight lab) owns what the *men* hear. **The bench changes nothing in the game.** Changes
come one at a time, each measured against `baseline/`.

Outputs go under `build/sound_lab/` (git-ignored); the baseline's table, findings and a few clips
are in `baseline/`.

## Commands

```sh
# every scenario (45 games, 4 at a time: ~20 min on this workspace's 4 threads), then the table
python3 experiments/sound_lab/run.py --out=build/sound_lab/base
python3 experiments/sound_lab/run.py --scenario=list
python3 experiments/sound_lab/run.py "--scenario=revolver_*,dynamite_out_30" --out=...
python3 experiments/sound_lab/run.py --table=ROOT          # measure again, no Godot
python3 experiments/sound_lab/measure.py ROOT --compare=BASE   # the table with each change against BASE
python3 experiments/sound_lab/run.py --clips=ROOT          # ROOT/clips/<scenario>.mp3
# one scenario in a game you drive (under Movie Maker so the mix runs on game time)
python3 tools/bridge.py start --movie=build/sound_lab/m.avi
python3 tools/bridge.py "sound revolver_street_20 out=build/sound_lab/one" "quit"
python3 tools/bridge.py "sound_inventory"                  # every player, bus and effect now
python3 tools/bridge.py "sound_find stone -2.5 0.6 -28.5"  # members of a wood or kind near a point
```

`run.py` takes `--seed=N` (default scenarios.json's), `--jobs=N` (3), `--picture` (draw every frame
and keep the movie: slow under lavapipe). Needs xvfb, lavapipe (`mesa-vulkan-drivers`), ffmpeg, numpy
and scipy.

## How a run goes

1. A fresh game (`main.tscn`) under xvfb and Movie Maker (`--write-movie`, `--fixed-fps 60`), started
   with `--sound-lab-dark` (nothing drawn: the mix doesn't need it) and a bridge script:
   `sound SCENARIO seed=.. out=..`, then `quit`. Movie Maker mixes the audio once a frame on game
   time, so a slow frame doesn't skew it and two runs of one seed give the same WAV.
2. The town quietened (TownLife, the spawner and everyone in it gone but in `fight`), the clock
   stopped at 15:00, Ballistics' ricochet draws seeded.
3. The ears placed: the player himself, or for the guns an `AudioListener3D` of the lab's at the
   listener's spot (the gun aims down the current camera, so his camera stays current). One frame
   is drawn from there (`view.png`).
4. An `AudioEffectCapture` goes on the end of the Master bus (after the ear filter, the high-pass
   and the limiter): what comes out of the speakers. Half a second of quiet, then the event made
   through the game's own code:
   - **gun**: the player fires (`shoot 1`: cock, fire) at the dirt or the saloon's floor;
   - **pass**: a revolver ball (`config/revolver.tres`) flown by Ballistics from 30 m to pass his head
     at 0.3/1/2 m, nobody's; `report` adds a gunshot placed as an outlaw's (`outlaw_brain.gd`: unit 25,
     max_db 6); `tumbling` makes it a ricochet's;
   - **impact**: a ball (no report) into a board, a pane, the dirt, a townsman's chest, 5 m from him;
   - **ricochet**: a ball grazing the street (5°), the well's stones (8°), the windpump's iron (10°);
   - **dynamite**: sticks lit with half a second of fuse, 5/30/100 m off, outside and in the saloon;
     `wall_down` is three against the store's front;
   - **fire**: the store set alight, 45 s to grow, then heard from 5 m and across the street;
   - **steps**: walking on the boardwalk, on the dirt, running on the dirt;
   - **fight**: the gang brought and set on him, 30 s, he shoots back every 4 s;
   - **cost**: 0/8/32/64 looping 3D sounds round him, the frame's time with each (under Movie
     Maker the mix runs inside the frame).
5. Out (`ROOT/<scenario>/`): `heard.wav` (stereo, 48 kHz), `summary.json` (the setup, the marks,
   every sound that began: what, who played it, where, how far from the ears, its bus, unit_size,
   max_db, filter, and the level Godot's inverse-distance model gives it; every bullet hit),
   `voices.csv` (a row a frame: voices playing, frame ms), `view.png`, `godot.log`.

## Measures (`measure.py`)

Round each event's mark: sample peak (dBFS), loudness (ITU-R BS.1770, K-weighted: the loudest
400 ms `lufs_max`, and over the window), onset after the mark (the arrival delay), length (until 40 dB
under its peak), `decay20` (peak to −20 dB), C50 (the first 50 ms against the rest: high is dry,
low is a tail), the spectral centroid and band shares of its first half second, left/right
balance. A fire or steps: loudness and centroid over the stretch. Derived: falloff in dB a doubling
of distance, the arrival delay against distance / 343 m/s, inside against outside at 2 m, the
street against the saloon's open door and its wall at 7 m, voices at once in the fight, cost a
voice.

## Files

- `bridge.gd`: the lab's bridge commands (`sound`, `sound_list`, `sound_find`, `sound_inventory`).
- `runner.gd`: one scenario, recorded and written out. `scenarios.json`: the scenarios (guns are made
  from its `guns` block: `WEAPON_PLACE_LISTENER`).
- `run.py`: the runs, the table, the clips. `measure.py`: the measures.
- `baseline/`: `baseline.md` (inventory, table, the ten worst), `measures.json`, `clips/` (a few mp3s).
