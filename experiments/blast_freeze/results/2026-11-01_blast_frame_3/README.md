# The blast's own frame, rounds 2 and 3 (2026-11-01, issue #538)

Branch `claude/538-part-2-7zqn44` (round 2 was `claude/gameplay-blast-frame-2`, merged in). This
VM: 4 cores at 2.1 GHz, headless, `--fps=60`, no fire; Sean's clock is ×0.65 of these. Round 2
(the worktree at 4d14d8c) and round 3 were run alternately (`bf_blast` as in
`../2026-11-01_blast_frame/README.md`), the median of 4 runs (2 for three sticks). The JSON runs
weren't kept (≈3 MB each); the table is theirs.

## Where the frame after went (round 2, the saloon, one stick)

The lab's frames now carry `ph`: the stretch between two of its `_process` calls split into late
process, the frame's end (deferred calls, frees), physics, and early process. The next frame
(~140-190 here) is nearly all physics:
- the kit props' push on `physics_frame` (`kit_blast` 40-46): 29 props faced (~11), 27 go loose
  with **488 members** (`_drop` ~25: putting each resting member's mesh and shape back on it,
  then moving them into a body already in the world, ~10; unbatching ~9; `member_broken` ~5);
- 2 runs in 3: a timber landing on a joist breaks it (`_on_rubble_hit` → `break_member`), and its
  settle ran a whole analysis round on the frame (13-21 ms), with the blast's settle still going
  in the fire's queue;
- that tick's scripts (the spawn queue's 93-120 bodies ~17, ballistics, the fire's slices) and
  Jolt's step (~15-27).

## What round 3 changed

- **Straight into the body** (`Structure._drop`): a resting member's nodes are handed over as
  they're kept (`unbatch(m, false, true)`, `StructureMember.take_parts()`), and the body is made
  up whole before it enters the world (`_new_rubble(ids, false)`, `_enter_rubble`; the
  `member_broken`s after it's in). `_drop` 25 → ~16.5 ms for the saloon's 27 props.
- **The queue charged by members**: a kit prop blown loose counts its members against the tick
  (`SpawnQueue.spent`), not its bodies; its 488 members hold the shards back a tick (frame +2
  ~60 → ~40 here).
- **A break during a sliced settle is queued** (`Structure.settle`, `FireSystem.settling`): a
  building the fire's queue is already bringing down takes the new break's round there, a slice a
  frame, not whole on the frame.
- **Sounds to the voice limit**: a building's timber cracks and panes, `breaking_limit` (4) a tick
  each (`Structure.under_this_tick`); the rest were dropped by GameAudio anyway, after being made
  and placed. `cut_wake` (mostly the cracks) 7-8 → 2-3 ms on the street's later sticks.

## The numbers (ms here; ×0.65 for Sean's)

| | round 2 | round 3 | at Sean's (round 3) |
|---|---|---|---|
| saloon, one stick: blast frame | 102 | 104 | 68 |
| saloon, one stick: next frame | 160 | 113 | 73 |
| saloon, one stick: worst of the first 60 | 160 | 131 | 85 |
| street, one stick: blast frame | 133 | 121-126 | 79-82 |
| street, one stick: next frame | 120 | 106-110 | 69-72 |
| street, one stick: worst of the first 60 | 146 | 121-126 | 79-82 |
| saloon, three sticks: worst | 170 | 130 | 85 |
| street, three sticks: worst | 308 | 173-181 | **112-118** |

Broken at the end, the same: saloon 118-120 / 118-122, street 344-347 / 344-350, three sticks
saloon 246-248 / 243, street 945-946 / 947-950.

After a stick, 50 fps at Sean's (a 10-frame window under 30.8 ms here) comes back 0.5-0.7 s in
for the saloon, ~0.9 s for the street: the building coming down (Jolt with 400-1,500 pieces
awake), as on main. Three sticks on the street: after 1.2 s the mean frame is 45-48 ms here
(~30-31 at Sean's, ~32 fps), p95 63-70.

## Left

- **The street's second stick** (~112-118 at Sean's): `dynamite` ~122 here with ~670 pieces about:
  the breaking ~55 (cuts ~28, the blast's settle's first round ~14, snaps ~10), the gather 23-25
  (the sphere queries and the walk over ~670-1,250 loose bodies), the response ~11, `kit_balance`
  ~7. The settle's first round can't be handed over once begun (round 1 tried: it loses the
  changes it took); a cheap estimate of its reach before beginning would let it be queued.
- **The test pair's flake** (`test_settle_incremental::test_the_worker_brings_it_down_the_same_as_the_main_thread`):
  on 2 cores it differs by a member or a frame about 1 run in 6-8, on **main as well** (1 in 8
  here with `taskset -c 0,1`; CI failed it once on this branch's first push). Not this branch's
  doing; the pair's two runs aren't the same simulation (see the PR).
