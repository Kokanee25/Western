# The blast's own frame, round 5: the street's three sticks (2026-11-02, issue #538)

Branch `claude/gameplay-blast-frame-5`. This VM: 4 cores, Intel Xeon at 2.1 GHz, headless,
`--fps=60`, no fire. It runs main **~1.3x faster than round 4's VM did** (the street's three
sticks, worst frame: main median 163 here against 210 there), and it swings up to 3.5x within a
run (one run's third stick had every cut timer at 3.5x). Every number below is main and this
branch run alternately on the same machine (main in a worktree at `origin/main`, the same native
build). The JSON runs weren't kept (~3 MB each); the tables are theirs.

```sh
printf 'bf_blast fire=0 fuse=1 seconds=5 in=street sticks=3 gap=0.4 out=build/bf/st3.json\nquit\n' > /tmp/st3.txt
python3 tools/bridge.py run /tmp/st3.txt --headless --fps=60
```

## Where the street's later sticks went (main, ms here)

A stick's frame is its tick's scripts and then Jolt's step of that tick. PhysicsWindow reports
both a frame late: a stick's own `window` and `step` are in the next frame's row. For the second
stick, the frame was ~150:

- `dynamite` ~90: the cuts ~35 (the ends' members ~9, the pieces' dice and the first ~115 bodies
  made ~8, the relink ~8, wakes and sounds ~4, unbatch ~3, signals ~3), the response ~12, gather
  ~8, snaps ~6-10, and ~20 under no timer.
- **Jolt's step ~36**, with ~700 awake and ~115 new bodies. On the frame after it's ~23.
- The rest ~18: batches, senses, people.

The untimed part, found with temporary timers:
- **People's `take_blast`, 12-45** (on the first two sticks). One man torn open is ~8 ms of building
  his insides' meshes (`_apply_openings`), and ~8 more if he loses a limb.
- **The `exploded` signal, 8-17.** On the first stick, ~14 of it is the street hearing the blast:
  each townsman cries out (`say`), and everyone hears each cry with a ray (`Events.noise`
  `speech` in `Senses`). On later sticks, the glass props shattering (~6).
- **`GlassCuts.spray`, ~8 on the first stick**: 8-22 rays a pane, looking for people.
- `Blast.gather`'s panes: on the first stick ~9 (every pane of every structure walked).

On the frame after: the kit props' push ~22, the gravel and splinters' strikes ~18-80 (the
`bullet_hit` listeners ~6-31, mostly `ImpactEffects.burst` making a material and a mesh a strike;
carving ~6-32; nudging resting rubble ~5-14), the fire's load checks 4-22, and Jolt's step.

## What changed

- **`Blast.gather`'s panes by bounds**: `Structure.bounds()` (every member's box in its own space,
  made at build, kept up to date as a cut's ends are added) and `may_reach`. The pane walk skips a
  structure whose bounds (with 1.5 m to spare) don't come within reach. Same panes, same order.
- **The kit props' push bounded per prop** (`KitProp._blast_push`): the blast at the prop's
  nearest point (`bounds_distance`) on all its faces at once. The blast falls off with distance
  (checked over 0.02-40 m for 0.1-1 kg), so a prop this rejects is one the old member-by-member
  bound rejected too.
- **The fire sits out the tick after a stick as well** (`FireSystem.sit_out`, the blast's own
  tick + 1). Its load-check slices start on the second tick after.
- **A blast's cries come after its sound** (`CivilianBrain`): 0.2 s, plus the sound's travel
  time to him, then his `cower` line. Spread over ~10 ticks, not all on the stick's. His fear and
  his cowering start at once, as before. Gunshots are unchanged.
- **A blast's openings built a few ticks on** (`HumanBody.open_wound(..., soon)`, from
  `take_blast` only): the wound and its record now, the insides' meshes 0.04 s later. A ball's
  opening is built at once, as before (`test_openings`).
- **`GlassCuts.spray` casts no rays with nobody near**: no person's chest (or root) within its
  reach plus 2.5 m. Its rays could only find a person.
- **`ImpactEffects.burst` shares its process material and mesh**, by colour and speed (and colour
  and size). The burst is turned to the normal by its node, not by the material's direction.
- **A gravel's knock on resting rubble too small to show leaves it lying** (`Ballistics`, the
  blast's own `min_throw`: ~0.05 m/s on a beam). Anything awake, or knocked harder, as before.
- A blast's snaps wake their rubble in break_members' one pass, as its cuts already did; rubble
  shares one `PhysicsMaterial`.

## Tried and taken back: the order things break in

`Blast.gather`'s first query (timber where it can break) returns ~500-1,000 members at ~8 µs each,
8-16 ms a stick. A walk of the structures' members found the same members (the same
`n_blast_members` every stick) in ~3.5 ms, **but the street then broke 917-925 members, main
947-952**. The members come back in the physics engine's order, and that order is the order the
structures break in. It decides:
- whose pieces get the tick's SpawnQueue room (120 bodies);
- which building the fire settles first (its queue is pushed at the front).

In main, a snapped saloon stud's piece lies between the second stick and the card table by the
next tick. The kit props' shielding ray counts a loose piece as no cover, but counts the prop's own
members and a nearby chair as cover (0.35). Without the piece there, the card table and chair_4
aren't pushed loose: 33 members fewer.

Other fixed orders, three sticks, one run each: nearest first 919-925, farthest first 927, by id
928, most broken first **1,043**. Main's order is one draw from a wide spread. So Jolt's order is
kept, and every change that stayed is one that doesn't move what breaks. Holding the blast tick's
SpawnQueue room to the next tick moved it the same way (921) and was taken back.

## The numbers (ms here, alternating; worst frame of the first 60 after each stick)

| | main | round 5 |
|---|---|---|
| street, three sticks: worst (4 pairs) | 145-175, median 163 | 140-177, median 147 |
| the same, by sticks: frame / next, medians | 147/137, 152/109, 131/132 | 118/97, 147/97, 126/108 |
| street, three sticks: every run this session (main 16; this round's builds 13, from the bounds on) | median 168 | median 150 |
| street, one stick: worst (3 pairs) | 129-146, median 130 | 101-106, median 102 |
| saloon, one stick: blast frame / next, medians (3 pairs) | 89 / 111 | 77 / 106 |
| saloon, three sticks: worst (3 pairs) | 105-133, median 127 | 92-119, median 109 |

At Sean's clock, by x0.65 of this 2.1 GHz VM: the street's three sticks **~96 by the median**
(main ~106), its worst single run (177) ~115; one stick ~66; the saloon ~71 (three sticks). This
VM runs main 1.3x faster than round 4's: scaled to that VM first, the three sticks would be ~125
at Sean's, main ~137. The gain over main is the same either way: ~10% on the street's three sticks
(the worst frame), ~20% on one stick and on the saloon's three.

Broken at the end, the same as main's: street three sticks 947-953 / main 946-953 (every run
this session: 16 main, 13 of this round's builds); street one 344-349 / 344-349; saloon three
755-758 / 755-758; saloon one 632 / 632.

The lab's `--deterministic` pair, saloon one stick: the same broken set (1772798801), 420 frames,
0 differing. Tests: 892 passed, 0 failed (here, `test_perf` included).

## Left

- The street's later sticks are still ~150 here on their own frame: `dynamite` ~85 (the cuts ~35,
  the response ~12, gather ~9) and Jolt's step on that tick ~36 (~700 bodies awake, ~115 new, CCD
  and a contact monitor on every piece of rubble).
- The broken set hangs on the order structures break in and on what lies in the kit props' rays
  (above). A kit prop's push not shielded by its own members would be a gameplay change, and
  would change the counts.
- Jolt's sphere query still costs ~8 µs a member (`gather_query`).
