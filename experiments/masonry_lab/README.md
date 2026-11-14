# The masonry lab

Stone, brick and adobe that crack, hole and come down: Sean's brief (2026-11-04), the plan in
`docs/briefs/masonry-lab.md`, the engine-neutral rules in `docs/destruction/destruction-spec.md`
and the numbers in `config/destruction/materials.json`. This folder is the bench: an empty slab of
ground out of town (1.5 km west, 200 m up: only sky behind it) with one test piece on it, driven by
the dev bridge.

## Commands (`bridge.gd`)

```sh
python3 tools/bridge.py start --headless --fps=60       # or --size=960x540 to draw it
python3 tools/bridge.py "masonry_lab" "masonry_blast sticks=1 wait=6"
python3 tools/bridge.py "masonry_lab seed=2" "masonry_cam back 6" "screenshot /tmp/b.png"
```

- `masonry_lab [piece=wall_panel] [seed=N]`: the piece built afresh from
  `config/destruction/structures/<piece>.json` (seed N: its walls laid again with that seed, in
  memory; the committed file is seed 1).
- `masonry_blast [x= y= z=] [sticks=N] [wait=S] [out=PATH]`: a charge at x, y, z of the piece's own
  space (x along, y up, z in from the outer face; z < 0 in front), `sticks` of the game's dynamite.
  It reports what the blast freed and cracked, the joints it broke, what fell after (the solver),
  the hole's extent, and every frame's time over `wait` s (`out` writes them). `sticks=0`: none,
  the frames alone (the baseline).
- `masonry_cam front|back|side|close|high [D]`, `masonry`.

`film.sh` records the breach (front and back, three seeds) through Movie Maker.

## Step 2 (#667): one rubble-stone wall panel, blown at its base

The parts (promoted to `src/structures/`, `docs/PARTS.md` "Masonry"):

- `MasonryMaterials`: reads `materials.json`; `is_masonry(wood)` is the game's one "is it stone?"
  test (ballistics' surface and ricochet, the voxels' carving and chips, the fire's fireproof,
  BlastCloud's dust, a member's weight).
- `MasonryExpander` (`tools/masonry_expand.gd`): a file's walls laid as coursed rubble, seeded;
  its rules in `config/destruction/structures/FORMAT.md` "The expander". The panel: 294 elements
  (279 stones, 9 through-stones, 6 footing stones), 1,087 joints, 13 courses, two leaves.
- `MasonryWall`: the expanded file as arrays; the joints' state (bonded or broken).
- `MasonryStructure` (a `Structure`): each element a member (`wood` its material, drawn in the
  game's stone, chamfered so the mortar reads as grooves), its supports from `rests_on` (no n²
  `infer_supports`), what falls with what by the mortar still bonding them.
- `MasonryBlast`: the spec's section 5 (the push, joints first, units crack only far harder, what's
  freed flies), with friction on the beds holding a stone in (S4's friction x N).
- `MasonryStructure.take_blast`/`_fling`: the far leaf thrown first, each stone along the face's
  normal at `blast_throw_factor` x its impulse / its mass, passing through the standing stones
  near it till it's clear, and the settle (what else falls) `free_before_settle_s` later.
- `StructuralAnalysis._masonry`: S1 bearing and S2 bond for masonry members (never the timber
  checks); the arch rule (S3) is step 3's.

### Results (2026-11-04, headless on this VM, one stick of 0.2 kg at x 2, 12 cm up, 12 cm out)

| Seed | Freed | Cracked | Fell after | Hole (x, y m) | Standing |
| --- | --- | --- | --- | --- | --- |
| 1 | 20 | 0 | 22 (to course 9) | 1.35-2.82, 0-2.13 | 252 of 294 |
| 2 | 15 | 2 | 37 (to course 9) | 1.25-3.02, 0-1.99 | 260 |
| 3 | 14 | 0 | 57 (to course 12) | 1.15-2.88, 0-2.62 | 243 |
| 1, three sticks | 30 | 2 | 106 (to the top) | 0.59-3.59, 0-3.0 | 158 |

Every breach goes through both leaves, the wall's ends stand, and the stones are blown out whole
(0-2 of 14-20 cracked). Without the arch rule what's over the hole falls as a slot until a course
holds by its bearing and bond (2.0-2.6 m up with one stick; three sticks take it to the top):
step 3's arch is what should leave a rounded hole with stone arching over it.

**`blast_dynamic_factor` 0.01** (was 1.0, the spec's first guess): the reflected peak right by a
stick is ~100 MPa for a millisecond or so; taken as a static push it frees stones 3 m away. At
0.01 one stick blows a ~1.5 m hole through the 0.55 m wall, matching Sean's call for timber
(#484: one stick usually opens a way through). Real breaching practice (the US Army's breaching
formula, FM 5-250, P = R³KC) puts a breach of 0.55 m of masonry at several sticks: how many sticks
a jail wall takes is Sean's call (step 3's issue).

**Getting the stones out of the wall** (three dials and a rule, each found by a film that showed
the wall still standing): Kinney-Graham's impulse is a far-field fit and threw the nearest stone at
~1 m/s (`blast_throw_factor` 4: the detonation products' momentum by a contact charge); thrown along
the line from the charge they went up inside the wall (now along the face's normal); packed face to
face a box sliding out snags on every edge it passes (a thrown stone passes through the standing
stones within a wall's thickness of it till it's clear); and the settle on the blast's own tick
dropped the stones over the hole onto the ones on their way out (`free_before_settle_s` 0.1).
Then what fell over the hole: dropped as mortared clumps (16 stones one rigid body) it sat back
in the hole, so rubble falls one stone at a time (`big_hit.falls_as` `units`, as the data said),
and a loose stone's box is the stone without its share of the mortar (`joint_thickness`): face to
face it had snagged on its neighbours. Stones over the hole now sag, tip and wedge as they drop
(some hang tilted: the start of the arching step 3 makes a rule). `tests/test_masonry.gd` checks
that the freed stones leave the wall's footprint and that rays pass through the hole.
Film and stills: `results/2026-11-04_step2/` (`breach.mp4`, `stills.jpg`).

Frame times (headless, `--fps=60`, 6 s; this VM's 2.1 GHz core, x0.65 for Sean's): the town alone
runs worst 43 ms, p95 25 here. One stick at the panel: worst 58-98, p95 26-28; the blast's frame
~59 ms (the call 27-43 ms), the next ~49 (the thrown stones and the cloud entering), the settle's
~35; three sticks: worst 122, the call 71 ms. At Sean's that's about two frames under 45 fps per
stick: the benchmark's first row fails as it stands; Sean's F3 on Shadow is still to come
(`docs/destruction/benchmarks.md`).

## Traps

- A `-s` script can't build a structure (autoloads): probe through a test (`tests/test_masonry.gd`)
  or the bridge. Never two games at once here.
- Under lavapipe a drawn run is slow (the town's load is minutes); `masonry_cam` before the first
  screenshot.
- The panel's file is generated: edit its `walls`/`seed` and run `tools/masonry_expand.gd`, never
  its `elements` by hand (the test holds it to the expander).
