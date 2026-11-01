# The blast-freeze lab

Issue #374 (Sean, 2026-10-24): "in the saloon fight I threw dynamite half way through when there
was some fire already and it just paused for a good 20 seconds." A stall, not a slow frame rate:
one job doing seconds of work on one frame. This lab reproduces it headless and times every frame
through the blast, so the job is named and the fix measured. **It changes nothing about how the
game plays** (the fix is in `src/structures/` and `src/fire/`, measured here).

## The command

```sh
export GODOT=~/godot/godot
printf 'bf_blast at=6.0,0.8,6.0 fire=6 burn=20 fuse=1 seconds=8 out=build/blast_freeze/run.json\nquit\n' > /tmp/bf.txt
python3 tools/bridge.py run /tmp/bf.txt --headless --fps=60        # ~2 min; the answer is the headline
python3 tools/bridge.py run /tmp/bf.txt --headless --fps=60 --game-args=--full-analysis   # every analysis from the top (the before's way)
python3 tools/bridge.py run /tmp/bf.txt --headless --fps=60 --game-args=--deterministic   # count budgets: two runs the same frame for frame
python3 experiments/blast_freeze/summary.py build/blast_freeze/run.json [more.json]          # mean, p95, worst, each timer, before and after the stick
python3 experiments/blast_freeze/summary.py --same A.json B.json                             # the same twice? (the broken set, each frame's counts)
```

`bf_blast [at=X,Y,Z] [fire=N] [burn=S] [fuse=S] [seconds=S] [stall=MS] [player=X,Y,Z] [census=1] [in=street] [sticks=N] [gap=S] [spread=M] [out=FILE.json]`:
`in=street` puts the sticks on Main Street instead (perf_bench `--scene=blast`'s spots: a third of
the way through the first buildings' members); `sticks`/`gap` set off several, `gap` s apart (in the
saloon `spread` m along its front); `census=1` takes the tree census (`stick_added`), off by default
since #538 (a walk of ~26,000 nodes, ~40 ms, landed on the stick's frame). The spec
saloon (the building lab's, out in the desert; built if it isn't), `fire=N` floor and wall boards
nearest `at` (the saloon's own space: x along the front, z back, y up; the hall floor is 0.78) set
alight and left `burn` seconds (6 boards and 20 s give ~170 hot members, 20 burning, as Sean's
"some fire already"), then a stick at `at` with `fuse`, and every frame recorded from a second
before to `seconds` after: wall-clock ms (this workspace's clock; x0.65 for Sean's), each Prof
system, the blast's own timers (`blast_gather`, `blast_response`, `blast_break`, `blast_settle`,
`blast_crater`, `blast_fx`), the settle's (`settle_analyse`, `settle_apply`), the fire's
(`fire_tick`, `fire_loads`, `fire_analyse`, `fire_apply`, `fire_grid`, `fire_fx`), the batches
(`batches`), what broke and what fell. The headline: the worst frame and what was in it, every
frame over the stall line (50 ms here), the sum of each timer. `bf_frames [N]` reads the last
frames back. The file has them all, and `broken_ids` (every broken member of the saloon at the end,
hashed in the setup): two runs of the same scenario on the same build should name the same.
`player=X,Y,Z` (the saloon's space) puts the player there first: where he is decides the fire's
bands (`player=12.0,0.8,2.0` is in the hall, 7 m from the stick; left out, he's where he starts,
99 m off). Each frame also has PhysicsWindow's split (`window` our physics ticks, `step` Jolt's,
`rest`; a frame late), the rubble and how much of it is awake; the run, `stick_added` (what the
stick's frame added to the tree, by class). `bf_analyse` times the spec saloon's load analysis
member by member (µs by kind, the slowest).

The town's people are left as they are (Sean was in a fight): their brains cost what they cost.

## Results (`results/2026-10-25/`)

| | The frame the stick goes off on | What it was | Cuts | Pieces | After, 8 s: mean / worst frame |
|---|---|---|---|---|---|
| Before (main c543efd) | **11,599 ms** | `settle_analyse` 10,195 + `settle_apply` 982 (the settle's 64 rounds, each a fresh analysis of all 5,150 members, to snap one) | 22 | 255 | 37.9 / 365 ms |
| After | **241 ms** | `blast_break` 102 (22 boards cut, ~110 pieces of rubble made), `blast_fx` 21, `blast_response` 21, `blast_gather` 14, the batches 8 | 22 | 255 | 45.5 / 262 ms |

The same 22 boards are cut and the same 255 pieces lie at the end; every run of the fixed build
breaks the same 306 members (`broken_ids_hash` 1650757771 on eight runs through the fix's rounds).
The collapse that was all on one frame now unfolds over the frames after: nothing left to settle
3.6 s after the stick. At Sean's clock the stick's frame is ~160 ms (was ~7.5 s here-scaled; his
20 s was a bigger fire and a fight).

What the fix is (`docs/LAYOUT.md` "src/structures", "src/fire"):
- **An analysis carried over** (`StructuralAnalysis.begin_update`, `Structure.start_analysis`,
  `mark_dirty`): after a change only the members whose loads can have changed are worked out
  again: what the broken member touched and everything that hands its load down through, plus what
  has lost its last support (falling) and what rested on that. A round near a blast is a few
  hundred members, not 5,150. `tests/test_settle_incremental.gd` holds it to the full analysis,
  member by member, and a blast to the same broken set either way.
- **A budget on the frame** (`Structure.settle(budget_ms)`, `FireSystem._check_loads`): a blast's
  settle runs rounds while the frame has budget (6 ms here), then the FireSystem's slices take the
  rest (8 ms a frame, 150 members a slice), and a round drops at most 40 members (whole clumps).
  A big building (>1,500 members) gets its first analysis a slice a frame when built, so the first
  thing to break it finds one to carry over.
- **The batches**: a material's batch rebuilds from its own members (not a scan of all 5,150),
  within 6 ms a frame; the shadow-only merge of every batch (60 ms on the spec saloon, every frame
  something broke) is merged as plain arrays on a worker thread, at most once a second.
- **The blast skips what it can't break**: a bound on the face impulse from the member's nearest
  point before the samples are walked (`Blast._member_response`): 48 -> 20 ms.

**Since (more-cores step 5, `results/2026-10-27_step5/`):** the townsfolk's looks at the fire, the
fire's grid and smoke redraws, the load check's slices and the noises' rays:
in the burning hall before the stick 18.8 → 7.0 ms a frame (worst 90 → 32), after it 32 → 21
(frames over 50 ms 80 → 5 of 420). The stick's own frames are as they were (~500 ms here over
three: ~660 new bodies, ~500 of them glass shards, for the physics engine; step 6's).

What was left on the after-frames before step 5 (noted for the performance session, #373):
- `civilian_brain` 30-90 ms a frame while the saloon burns (184 of 480 frames over 20 ms): the
  townsfolk's fire response.
- The fire's periodic work: the grid rebuilt every 2 s (~40 ms), the neighbour lists refreshed
  together at 30 s (~45 ms), the smoke field's step/upload counted under `fire` (90-130 ms twice).
- The frame after the stick: ~125 ms untimed (the physics engine taking ~110 new bodies and 44
  new members; the batches' upload).
- The stick's frame itself: making ~110 pieces of rubble for 22 cut boards is ~100 ms here.

**The blast's own frame (#538, `results/2026-11-01_blast_frame/`):** one stick in the spec saloon,
no fire: 305 -> ~110 ms here on its frame, the next ~250 -> ~160; Main Street ~480 -> ~165; three
sticks' worst 330 -> 160 (saloon), 550 -> 280 (street). Glass shards and a cut board's pieces are
made 120 a tick (SpawnQueue), the kit props' blast handler and Fittings made cheap, the blast's
inner sum inlined, a small building's first analysis sliced. Left there: the street's frame ~110 at
Sean's, the frame after (the kit props' push), the shadow mesh.

## Files

- `bridge.gd`: the commands (`BridgeLab`; found by the bridge at start). `results/2026-10-25/`:
  the before and after runs' summaries (frames round the blast kept, the rest dropped).
