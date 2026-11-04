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

Step 1 wrote the spec and the data; step 2 (#667) the first row. The headless rows count the CPU
only (no drawing), on a VM whose town alone already runs over 22 ms some frames: they say what the
masonry adds, never whether 45 fps holds. That's Shadow's row (Sean's F3, to come).

| Date | Step | Build | Scene | Machine | Result | Pass? | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-11-04 | 2 | PR (step 2) | Wall panel breach, one stick at the foot, seeds 1-3 | Workspace, headless, 60 fps | the blast's frame ~59 ms (its call 27-43), the next ~49, the settle's ~35; worst over 6 s 58-98 against the town alone's 43, p95 26-28 against 25 (x0.65 at Sean's: ~38, ~32, ~23); the hole 1.5-1.8 m wide, 2.0-2.6 m high, through both leaves | likely fails at Sean's: ~2 frames under 45 fps | three sticks: worst 122 ms, the call 71; what costs: the blast's own work, the thrown stones entering the physics, the settle |
| | 2 | | Wall panel breach | Shadow | Sean's F3 (to come) | to come | target: never below 45 fps, normal within 3 s |

