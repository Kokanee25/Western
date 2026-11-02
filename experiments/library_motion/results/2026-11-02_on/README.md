# Library clips on in the game (Sean, 2026-11-02: "turn em on")

The same 80 fights each way (`experiments/gunfight_lab/run.py --scenarios=spec_hall,spec_stair
--styles=cover --variant=D --seeds=1-10`, golden and night, revolver and shotgun), clips on (the
default on this branch) and off (`--game-args=--library-motion=off`):

| | on | off |
|---|---|---|
| all, length median | 32.8 s | 26.1 s |
| hall, length median | 43.7 s | 31.0 s |
| hall, the scripted player down | 50% | 32% |
| hall, the gang surrenders | 5% | 40% |
| stair | about the same | |
| his hits on the gang (all) | 2.2 | 2.6 |

The gang is harder to hit with the clips on, so they're hurt less and give up far less. Waiting
on Sean before it merges.
