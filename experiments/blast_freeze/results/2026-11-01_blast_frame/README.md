# The blast's own frame (2026-11-01, issue #538)

Branch `claude/gameplay-blast-frame`. Before: main at 72a19a2. This VM: 4 cores at 2.1 GHz,
headless, `--fps=60`; Sean's clock is x0.65 of these. No fire (the game since #458). The runs'
frame times and each blast frame's top timers are in `runs.json`.

```sh
printf 'bf_blast at=6.0,0.8,6.0 fire=0 fuse=1 seconds=4 out=build/bf/s.json\nquit\n' > /tmp/s.txt    # the spec saloon
printf 'bf_blast fire=0 fuse=1 seconds=4 in=street out=build/bf/st.json\nquit\n' > /tmp/st.txt       # Main Street
printf 'bf_blast at=6.0,0.8,6.0 fire=0 fuse=1 seconds=5 sticks=3 gap=0.4 out=build/bf/s3.json\nquit\n' > /tmp/s3.txt
python3 tools/bridge.py run /tmp/s.txt --headless --fps=60
```

## What the frame was (main)

One stick in the spec saloon, ~305 ms here, then ~250:
- the stick's tick (`dynamite` ~220): ~500 glass shards made (~100), 31 boards cut and ~150 of
  their pieces made (~70), the response (~25), the gather (~15), the cloud (~15);
- Jolt's step on it with ~800 new bodies (~75);
- the next frame, outside every timer: each of the town's ~110 kit props resuming its blast
  handler on `physics_frame` (~120: a whole-tree `find_children` for Fittings, 27 ms; every
  Fittings item walked with lambdas for each prop going loose; 498 members' faces sampled);
- the lab itself: its tree census (~40 ms on the stick's frame). Main Street: also the store's whole
  first load analysis (~90-120 ms) on the stick's tick.

## What changed

- **SpawnQueue** (`src/structures/spawn_queue.gd`): glass shards and a cut board's flying pieces
  are made 120 bodies a tick, in order, counted (deterministic). What breaks is decided and hidden
  on its tick; a cut's pieces' velocities are drawn then (they fly as before).
- **Kit props**: one `member_broken` listener for all of them; out of reach, done before walking
  members; a bound (`Blast.most_face_impulse`) before the faces; Fittings found by group and keeps
  each member's items. Their push stays on its tick: queued behind the shards, three sticks brought
  the saloon down to ~450 members, not main's ~240.
- **Blast**: `face_impulse`'s inner sum inlined (bit-identical: `test_the_face_sum_is_the_plain_one_to_the_bit`);
  panes skipped by a cheap distance first and kept as members are added; a body it'd move under
  0.15 m/s (`min_throw`) isn't moved or woken; the cuts' wakes one pass; a building's breaking
  noise heard once a tick; the dust cloud's particles a tick after the flash.
- **Settle**: a building with no analysis yet, bigger than the frame's share (~90 members), has its
  first one a slice a frame (was only over 1,500: the store).
- **Lab**: `in=street`, `sticks`/`gap`, `census` off by default; `rest_idle`/`rest_after`
  (PhysicsWindow), `kit_blast`, `shadow_set`, `spawn_queue`, `blast_glass/cut/snap` timers.

Tried and not kept: the shadow mesh made on its worker (the main thread used it before the
rendering server had it: the barrel test caught it); holding all of a blast's bodies to the next
tick (~30 ms off its frame, but `test_settle_incremental`'s pair then broke other ground boards run
to run); CCD off for slow rubble (no change); a settle handing over a begun analysis (it would lose
the changes it had taken).

## The numbers (ms here; x0.65 for Sean's)

| One stick | blast frame | next | mean of frames 2-30 | broken (end) |
|---|---|---|---|---|
| saloon, main | 305 / 453 / 262 | 214 / 249 / 271 | 33 / 41 / 40 | 117-119 |
| saloon, branch | **123 / 103 / 113** | 140 / 185 / 163 | 33 / 38 / 33 | 118-119 |
| street, main | 472 / 502 / 477 | 199 / 177 / 178 | 45 / 49 / 41 | 342-353 |
| street, branch | **183 / 158 / 160** | 112 / 164 / 148 | 35 / 39 / 43 | 346-353 |

| Three sticks, 0.4 s apart | worst frame | broken (end) |
|---|---|---|
| saloon, main | 320 / 340 | 241 / 241 |
| saloon, branch | **156 / 165** | 243 / 243 |
| street, main | 584 / 519 | 949 / 950 |
| street, branch | **278** | 946 |

At Sean's: the saloon's blast frame ~67-80 ms (was ~170-295) and the next ~91-120 (the kit props'
push, 50-74 ms here); the street's ~103-119 (was ~307-326). After it, ~50 fps at Sean's is reached
about 1 s in, as on main: the seconds after are the building coming down (Jolt's step 12-20 ms here
with 400-500 pieces awake, the settle's slices), not the blast.

**The same?** The lab's pair (`--deterministic`, saloon): the same twice, 480 frames, 0 differing.
Against main every frame is the same through the blast's tick (what it breaks); after it, 125 of
126-128 members in common at the end (the pieces fly a tick or few later). Main Street isn't
deterministic on main either (its own pair differs from the first tick after the stick).

## Left (#538 stays open)

- The street's blast frame ~105-120 ms at Sean's: the response (~30-60 here), the glass
  (~15-25: a noise, the spray's rays and a sound a pane), the cuts (~20-50: ends, relinks), the
  people's `take_blast` (~13). Native response/face sums would be the next step.
- The frame after: the kit props' push (50-74 here), kept on its tick (see above).
- Three sticks on the street: the second and third ~180 ms at Sean's (a settle of ~35 on a building
  the first left standing, the gather and response over ~1,000 loose bodies).
- `shadow_set`: the whole-building shadow mesh made on the main thread, ~25-30 ms here once a
  second while a building changes.
