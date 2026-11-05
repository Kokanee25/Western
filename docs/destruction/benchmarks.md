# Masonry destruction: benchmarks

Each test scene, what happens in it, its pass target, and every result over time. Every finished
step adds its rows (the portability rule, `destruction-spec.md` section 1, rule 4). When a new PC
arrives, run the same scenes on it and log both side by side: this table is what the same scenes
in Unreal are compared against later.

## The machines

| Name | What | Notes |
| --- | --- | --- |
| **Shadow** | Sean's Shadow PC: RTX 2000 Ada 16 GB, 8 vCores, 16 GB RAM, Windows | close to a modest player's machine; the targets below are measured here |
| **Workspace** | the cloud session's VM: one 2.1 GHz core in use, lavapipe (software Vulkan) | headless and CPU numbers only; scaled by 0.65 to Sean's core (CLAUDE.md "Frame budget"); never a frame-rate pass |

Salt Creek's own frame budget applies as well: the structures system's share is 1.0 ms of the
14 ms frame at Sean's (`config/frame_budget.tres`; `tools/perf_bench.gd` prints it).

## The scenes and their targets (Sean approved, #666, 2026-11-04)

| Scene | What happens | Pass target |
| --- | --- | --- |
| Wall panel breach | one dynamite charge at the base of a 4 x 3 m rubble-stone wall (test piece 1) | never below 45 fps during the blast; back to normal within 3 s |
| Wall stress | 50 rifle hits, then 3 charges in a row | no crash; debris count stays under the cap set in step 6 |
| Jail breach | breach one jail wall; its roof section sags and drops | never below 40 fps; the rest of the jail stands |
| Persistence | three breaches, then a full in-game day passes | rubble still there; frame rate as before the breaches |
| Street test | the jail breach on Main Street with the townsfolk and the clutter loaded | never below 30 fps |

## Results

No results yet: step 1 wrote the spec and the data. The first row comes with step 2 (the wall
panel breach).

| Date | Step | Build | Scene | Machine | Result | Pass? | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
