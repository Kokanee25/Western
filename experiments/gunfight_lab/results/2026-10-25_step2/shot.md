# Sean's per-shot hitch (#385): one ball into the spec saloon's wall

Sean's F3 on build 2466 (#385): while shooting in the spec saloon the worst physics step was 190-250 ms. The blast-freeze lab's `bf_shot` (`experiments/blast_freeze/bridge.gd`): the spec saloon built, a revolver ball from the hall's middle (6, 1.5, 6) each way along the saloon's axes, a second apart, every frame recorded (wall clock, Prof). Not `deterministic` (the game's own budgets). This core; x0.65 for Sean's.

```sh
printf 'bf_shot out=build/shot/run.json\nquit\n' > /tmp/shot.txt
python3 tools/bridge.py run /tmp/shot.txt --headless --fps=60
```

| Ball | before: the shot's worst frame | `batches` | `fire_loads` | after: worst frame | `batches` | `fire_loads` |
|---|---|---|---|---|---|---|
| x | 57.6 | 22.9 | 20.9 | 36.7 | 3.0 | 20.3 |
| -x | 18.9 | 0.6 | 1.8 | 16.2 | 0.8 | 2.0 |
| z | 41.6 | 14.9 | 20.3 | 26.9 | 1.3 | 14.4 |
| -z | 48.2 | 16.7 | 19.0 | 25.9 | 1.4 | 14.7 |

(The shot's own frames: the six ticks from the trigger; `before.json`, `after.json` have every frame.)

**The batch rebuild was the biggest single piece:** the ball's member leaves its batch and `_build_batch` rebuilt that material's mesh for the whole saloon (its largest materials [429, 438, 456, 461, 683] members). Cut into pieces of at most 64 near members (`Structure.BATCH_PIECE`), a hit rebuilds one piece: **62 batches -> 115** for the saloon (pieces' largest [63, 63, 63, 63, 64]), the town's 92 structures 733 -> 736 (`bf_batches`; their materials are mostly one piece already).

**What's left of a shot, for the steps after:**
- `fire_loads` 12-19 ms (8-12 at Sean's): the holed member's load check (`FireSystem._check_loads`, its analysis `fire_analyse`) on the shot's frame. It's the shot's biggest share now. Step 5's (the structures' analysis), or step 8's, off the main thread.
- `civilian_brain`, about 100 ms on one frame, 47 ticks after a shot (the townsfolk reacting; `q_cover` 85 on that frame): the burst #373 saw in the fire scene, here from a shot. Step 5's (c) names `civilian_brain`; step 3's sight service takes the cover rays.
- In a fight, several shots a second and the men's own bursts stack on these; Sean's 190-250 ms was on build 2466, before #375's incremental settle and #382.
