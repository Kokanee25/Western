# The farmhouse's slow motion after a ring of sticks (2026-11-02, issue #584)

Branch `claude/gameplay-farmhouse-slowmo-cyqo2p`. This VM: 4 cores at 2.1 GHz, headless, `--fps=60`,
no fire. Sean (2026-11-02, an older build): dynamite thrown all round the farmhouse; a minute after
the last blast the game was still in slow motion.

```sh
printf 'bf_blast in=farm fire=0 fuse=1 gap=3 seconds=60 out=build/farm/a.json\nquit\n' > /tmp/f.txt
python3 tools/bridge.py run /tmp/f.txt --headless --fps=60           # ~6 min
python3 experiments/blast_freeze/seconds.py build/farm/a.json        # a row a second from the last stick
python3 experiments/blast_freeze/seconds.py --brief build/farm/*.json  # a line a run
experiments/blast_freeze/farm_runs.sh DIR PREFIX N 30                # N runs, two games at once (outcomes only)
experiments/blast_freeze/farm_pairs.sh MAIN_DIR N 45 [mission=1]     # main and the branch alternately (frame times)
```

`bf_blast in=farm` lays a stick on the ground 0.6 m out from each wall's breach spot (the farmhouse
lab's `WALLS`, `walls=` picks them; default front, east, back, lean_back, lean_west, west), `gap`
s apart, the player 12 m off the front; `mission=1` starts the mission first (the gang in the house,
the rovers). Twice a second the frame carries a census of the awake bodies (`bodies`: rubble awake,
their speeds, how many on the ground, buried, the six fastest with every contact, RubbleRest's
counts, Ground's lifts and rescues) and every frame how many pieces fell asleep and woke (`slept`,
`woke`). `bf_movers N`: the N awake bodies moving most, with all their contacts.

## Reproduced (main, the house alone)

Six sticks 3 s apart: from the second stick on every frame is ~100 ms here (~65 at Sean's), the
physics' step ~85 of it, with ~900 pieces of rubble awake. Most of them barely move (median speed
under 1 mm/s), and they don't fall asleep. In the first run they all slept at once 44 s after the
last stick; in three of four later runs ~900-1,000 were still awake 30 s on (frames 80-130 ms).
Our scripts' physics ticks (`window`) are ~12 ms of a frame (people ~3, the structures ~2), the
rest of the frame ~6; the fire and the settles nothing. So it's the issue's suspect 1, rubble
that won't sleep, but not for the slope: three things keep the piles awake.

**1. RubbleRest woke every pile it lay in each time it fell asleep.** A piece lying still 1.5 s
joins its cell awake; when the pile at last falls asleep, `_on_sleep` set each piece's shape nodes
aside (held as shape owners). A body's shapes changed wakes it, and the next tick the whole pile
woke with it. One stick on the back wall, the per-frame counts:

| | the pile asleep | woken on the next tick |
|---|---|---|
| main's code (`--rr-shapes-asleep`) | 351 at 5.47 s, 354 at 8.52, 356 at 13.22, 354 at 18.02 | 354, 354, 356, 354 |
| the branch | 376 at 11.65 s | none |

A pile of ~900 was woken this way for most of a minute. The #459 session had seen that doing it to
awake piles kept them awake (and stopped); done as a pile slept, it still woke it. Now only a
frozen piece's shapes go aside; a sleeping one keeps its shape nodes (its mesh still joins the
cell: that's the drawing). One stick on the back wall: all asleep 7.5 s after it and staying so;
with RubbleRest off entirely, the same.

**2. Pieces trapped under the dug ground.** A stick on the ground digs a crater: those tiles are a
height field (no thickness) over solid columns topped 1 cm under the lowest point of the surface
over them. The census found pieces touching the height field *from below* (its contact pushing
them down) and a column from above, spinning at 2-47 rad/s, now and then thrown out at up to
186 m/s (pieces 1.9 km up). A crater's lip or a clod's earth laid where a piece lay came up through
it; a pile's weight pressed others through. Up to 134 awake pieces had their middle under the
surface.

**3. (Not fixed.) Pieces on a sloping crater wall touching the field and a column top both.** The
physics lets a resting body sink 2 cm into what it lies on (its slop); the column tops are 1 cm
under the field's lowest point, so a piece lying near it on a slope can touch the flat column top
too, and some of these spin. Tried:
- rescuing pieces that touch a column: it lifted legitimately resting pieces again and again
  (1,600-2,300 lifts a run, neither of two runs settled): taken back;
- the columns 3 cm under (past the slop): 5 of 6 runs settled against 4 of 6, within six runs'
  noise, and a box lying across a dug tile's edge then sank the full 2 cm
  (`test_things_rest_on_a_tile_as_on_the_flat_ground`; at 6 cm fast chips fell on through the
  columns' seams): taken back.

Capping the rescues (a piece lifted into its pile and pressed under again was lifted ~5 times a
second on the lean-to's crater in one run) made it worse, so every rescue stays.

## The changes

- `RubbleRest._shapes_aside`: only a frozen piece (`-- --rr-shapes-asleep`: the before).
- `Ground._lift_out` from `_wake`: after an edit, a loose body the earth came up through is set
  back on top (by its deepest corner; people's parts left to their joints).
- `Ground.rescue`, from `Structure._physics_step` every `RESCUE_TICKS` (15) per awake piece: one
  touching a dug tile's field from below, or with its middle under the surface, is lifted out.
- `-- --no-ground-lift`: no lift or rescue (the lab's before).

## The numbers

Six sticks round the house, the house alone, 30 s after the last stick; two games at a time (so
the frame times here are inflated; outcomes only). "Settled": fewer than 50 pieces awake from then
to the end of the run.

| | settled within 30 s | when (s after the last stick) | broken |
|---|---|---|---|
| main | 1 of 4 | +6.1 | 582-663 |
| RubbleRest + the lift at edits | 2 of 4 | +0.9, +6.8 | 582-651 |
| + rescue (middle under the surface) | 2 of 6 | +1.6, +4.6 | 576-639 |
| **+ rescue (field from below): the branch** | **4 of 6** | +4.0, +6.3, +8.5, +27.5 | 576-639 |
| (+ columns 3 cm under: not kept) | 5 of 6 | +3.3, +7.5, +15.0, +17.4, +24.5 | 574-649 |
| (+ at most 2 rescues a piece, its middle 1 cm under: not kept) | 1 of 6 | +7.0 | 576-645 |

The branch's runs together (batch d and the two pairs below): **6 of 8 settled within 30 s** of
the last stick; main's (four runs and the two pairs): **1 of 6** (one more at +40 s). Run to run
it's chancy, so these batches of six are rough.

Broken counts: the same spread as main's. Two collapses come up run to run on main and the branch
alike, ~575-590 and ~640-665 members (the loft or not); on main the second never settled in our
runs.

**Frame times**, main and the branch alternately, one game at a time (`farm_pairs.sh`), 45 s after
the last stick; the median frame from 3 s after it to the end (ms here; x0.65 for Sean's):

| | main: settled / median | branch: settled / median |
|---|---|---|
| the house alone, pair 1 | +40.1 s / 101.8 | +29.9 s / 84.6 |
| the house alone, pair 2 | not (838 awake at +45) / 95.7 | **+20.6 s / 13.4** |
| the mission running (`mission=1`) | not (942) / 103.1 | not (934) / 133.6 |

A frame with ~900 pieces awake is ~100 ms here (~65 at Sean's: 15 fps, the slow motion), Jolt's
step ~85-120 of it; settled, ~10 ms here. With the mission running the gang moves about the house
among the rubble (20-odd other bodies awake) and, on main and the branch alike, the pile stayed
awake the whole 45 s.

## Left

- Two runs in six still don't settle within 30 s: clusters on the back and east craters spinning at
  2-8 rad/s, touching each other and the field from above (3. above, and a pile's own jostling).
- Before the last stick (3 s apart) the frames are ~100 ms here with ~900 pieces settling: the
  physics' step of a fresh pile (20 velocity steps, CCD and a contact monitor on every piece). That
  is #585's: rubble's cost while it settles.
- A thrown piece can still come to rest on the hills far off and roll a while (seen: 350 m away).
