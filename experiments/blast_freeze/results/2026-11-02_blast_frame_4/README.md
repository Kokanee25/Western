# The blast's own frame, round 4: the street's later sticks (2026-11-02, issue #538)

Branch `claude/issue-538-part-2-q8wwa6`. This VM: 4 cores at 2.8 GHz, headless, `--fps=60`, no
fire. **It ran main ~1.3x slower than round 3's VM did** (the street's three sticks, worst frame:
main 183-228 here against ~175 there) and swung up to 1.4x within a run (a whole frame slower in
every timer at once), so every number below is main and this branch run alternately on the same
machine (main in a worktree at `origin/main`, the same native build). The JSON runs weren't kept
(~3 MB each); the tables are theirs.

```sh
printf 'bf_blast fire=0 fuse=1 seconds=5 in=street sticks=3 gap=0.4 out=build/bf/st3.json\nquit\n' > /tmp/st3.txt
python3 tools/bridge.py run /tmp/st3.txt --headless --fps=60
```

## Where the street's later sticks went (main, ms here)

The second stick's frame was 260-318 here, `dynamite` 180-229 of it:
- **`Blast.gather` 36-48** (the third stick 40-61). Not the GDScript walk over the rubble (1-2 ms):
  the two sphere queries. Each rubble body cost ~15-18 µs in Jolt's `intersect_shape` (a glass
  shard, a body part, a member ~3 µs; why, not found), and by the third stick 1,300 of them were
  in the 17 m query. Every one of them within reach was walked to by its group anyway.
- **The blast's settle 10-25**: two boardwalks' *first* analyses (57 and 73 members, ~200 µs a
  member here; the slicing's estimate of 15 a millisecond is the saloon's), whole on the frame.
- **The cuts 35-55** (~70 a stick): of a cut's ~0.6 ms, making the two new ends' members
  (`add_member`, 55-140 µs each: a node, a mesh, a shape) the most, then the chunks' dice (~0.15),
  the relink (~0.12). Each end is a size of its own, so `MemberMesh.box` missed its cache every time.
- **The fire's load checks on the third stick's frame, 14-36**: the fire ticks before the stick in
  the tree, so a slice of the second stick's collapse (a building's first analysis begun, 150
  records copied) landed on the third stick's own frame.
- The response 14-24, snaps 8-16, `kit_balance` 7-11. On the frame after: the kit props' push
  20-48, the gravel and splinters' impacts 13-17 (rays ~1 ms), Jolt's step 40-55 with ~700 new
  bodies awake.

## What round 4 changed

- **`Blast.gather` without the rubble in its queries**: the `rubble` and `fallen` bodies are excluded
  from both queries and found by their groups, as before. One whose middle is past the reach is
  still in when a shape of it reaches in (`Blast._shapes_within`: a box exactly), as the query had
  it. The members come back in the same order (Jolt's, the rubble filtered out). New test
  `test_gather_finds_the_rubble_the_queries_found` (rubble in, out, and a chip and a long board
  whose middles are past the reach). The third stick's far query: 17.4 ms with the rubble, 2.1
  without. Sub-timers `gather_query`, `gather_panes`, `gather_loose`.
- **A blast's first analyses sliced** (`Structure.BLAST_FIRST_WHOLE`, 24 members): bigger goes to
  the fire's queue. Not a kit prop's (`blast_first_whole`): its push reads what's left of it the
  tick after (with the rule on them, the saloon's next frame grew, `kit_blast` 40 -> 52-72, and 2-3
  fewer members broke).
- **`FireSystem.sit_out(tick)`**: the load checks skip the tick a stick goes off on. A lit stick asks
  a tick ahead (`DynamiteStick`, fuse under a tick); the blast for its own.
- **`MemberMesh.box` from templates**: a box laid out once a kind (which axis is longest, and which
  of the other two), so a cut's end is 9 µs, not 34; the same arrays, array for array.

## The numbers (ms here, alternating; worst frame of the first 60 after each stick)

| | main | round 4 |
|---|---|---|
| street, three sticks: worst (6 pairs) | 183-228, median 210 | 160-203, median 177 |
| street, three sticks: second stick's frame | 169-228, median 197 | 154-203, median 162 |
| street, three sticks: its `dynamite` | 115-152, median 128 | 98-133, median 104 |
| street, three sticks: third stick's frame | 166-209, median 179 | 134-168, median 149 |
| street, one stick: worst (4 pairs) | 155-264, median 183 | 147-178, median 156 |
| saloon, one stick: blast frame / next (2 pairs) | 99-109 / 110-125 | 91-92 / 112-113 |
| saloon, three sticks: worst (8 pairs, both orders) | 130-251, median 148 | 126-185, median 159 |

The saloon is the same code path as main for its first stick (no structure there meets the new
rule; the stick's tick has no fire work on main either); its spread is the machine (the slow runs
are slower in every timer on the frame, `kit_blast`, `fire`, the analysis set-up, all x1.4).

At Sean's clock: x0.65 of here gives the street's three sticks ~115 (median 177), the gate's ~100
not met. Scaled by this VM's main against round 3's (x0.78), ~90.

Broken at the end, the same as main's: street three sticks 947-952 / main 947-951; saloon three
755-758 / 754-759; saloon one 623-624 / 621-625; street one 343-350 / 348-352.

## Determinism

The lab's `--deterministic` pair for the saloon's three sticks isn't repeatable **on main** on this
machine: of three runs two were the same and one parted 2 ticks after the third stick, with a broken
set (hash 1649360796) that this branch's runs also produce. This branch: 4 outcomes in 5 runs, all
parting at the third stick + 2. Main's street pair parts 3 ticks after the first stick. Round 3's
"600 frames, 0 differing" was one pair. Likely #560's kind (a worker's run that isn't the same
simulation); not this round's doing, not chased.

## Left

- **The street's three sticks, ~115 at Sean's by x0.65.** What's left on the later sticks' frames:
  the cuts (~35-45 here: the new ends' members are the most, a node, mesh and shape each), the
  response (15-24), `gather`'s near query (11-22: Jolt's first query in that area each frame, the
  repeat ~2-11), snaps (~10), `kit_balance` (~7-9). The frame after: the kit props' push (20-40),
  gravel and splinter impacts (13-17: holes carved, every one a `bullet_hit`), Jolt's step (40-55).
- Why a rubble body costs Jolt ~5x a shard in a shape query (contact monitor and CCD are on rubble;
  shapes are boxes): unknown. Rays and `Senses`' lines may pay it too.
- The deterministic pairs above.
