# Bundles against #492's gate, round 2 (#647, 2026-11-04/05)

Headless, `--fps=60`, `bf_blast in=street sticks=N bundle=4 plunger=1 fuse=1 seconds=8` (and the
trestle lab's `collapse_runs.py --only=bundles_two,bundles_two_under_40`). **This VM is faster than
round 1's:** main's one stick on Main Street is 125 ms on its tick here, 183-186 there, so "at
Sean's" isn't x0.65 of these numbers; by the one stick it's about x1.1 (round 1's x0.65 times
183/109). Main was run on this VM for the before (`m_*`); every run is one game at a time.

## What changed (each measured here)

1. **A blast's breaking is sliced** (`Structure.break_members(..., budget)`, `Blast.BREAK_TICK_MS`
   20, `Structure.BREAK_FRAME_MS` 12 a tick for all buildings together): what breaks is decided on
   the blast's tick as before; it's broken nearest first (the buildings nearest first), and what
   doesn't fit on the tick is broken on the ticks after, then the one settle. A kit prop's push waits
   for it (`Structure.any_breaking`), so what shields it is what's still standing, as before.
   `-- --blast-break=whole` is the before. The bundle's own tick: **196 -> 125 ms**.
2. **Quiet rubble kept awake is held** (`RubbleSleep.QUIET_AWAKE_S`): after a bundle ~2,100 still
   pieces lay awake round a dead man's ragdoll and the bone chips by him (not rubble, so never held)
   for the rest of the run: Jolt sleeps a pile whole, and something in it kept it awake. A piece
   quiet (under 1 cm/s at any point) and still awake 0.5 s past its still spell is held now as a
   restless one is; one knocked loose lets go what's held lying on it (`_lying_on`, a shape query).
   One bundle: **back to the calm street's ~11 ms by 5 s** (main: ~52 ms, 2,240 awake at 8 s).
3. Heavy timber tough (the breakage lab's `2026-11-04_tough_timber/`): fewer heavy members fall.

## The table (`street_table.md`, `trestle_table.md`)

- **The trestle passes:** two bundles of four on the River Kwai bent's inner posts, the plunger,
  as the engine comes on at 40 km/h: the bent comes down under it, 15 of 20 cars in the gorge,
  worst frame 38 ms here, the slow spell 0.04 s. With no train the bent stands (6 members broken).
- **One bundle on Main Street:** its tick 125 ms here (~140 at Sean's), the next 88-100, then
  ~60-80 ms frames for 3 s while ~3,200 pieces fly and land, then the calm street by 5 s. Fails the
  gate's first half (one hitch under 100 at Sean's) by ~40 ms and its second (50 fps in 0.5 s) by
  ~3.5 s.
- **Three bundles on Main Street:** ticks 123-132, 217-221, 154-162; ~7,400 pieces awake and
  ~120-138 ms frames for 5-7 s (main: the same, and still 118 ms with 3,000 awake at 8 s); down to
  73-126 ms at 8 s. **Fails by far.** The cost is Jolt's step with ~7,000 pieces moving (~100 ms of
  it at 2 s); nothing is held while they move.
- One stick: its tick 125 -> 70 ms here; after, the same.

The broken counts: one bundle 1,088-1,099 against whole breaking's 1,104-1,114 on this branch
(main's 1,144: the timber); two whole runs differ by 6-10 members, sliced against whole by 30-45 of
~1,100 (kit props and cut ends that come down after: the blast's own set is the same); under
`--deterministic` (not repeatable on the street, as #560's), sliced 1,063/1,067 vs whole 1,073.

## What's left, and the one lever not taken

Jolt stepping thousands of flying pieces (the 20/8 solver steps the falls need, for all of them).
**Chips not on chips** (`-- --lab-debris-solo`: a cut's hand-span pieces, already on the debris
layer you walk through, no longer land on one another, only on the ground, timber and big pieces):
one bundle 80/68/63 -> 53/41/31 ms in its first three seconds, three bundles 121/133/134 ->
98/90/73 and calm by 6 s. It changes what's seen (a heap of chips lies as a flatter scatter), so
it's Sean's call, not taken.
