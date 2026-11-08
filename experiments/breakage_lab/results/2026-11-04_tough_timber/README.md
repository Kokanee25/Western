# Heavy timber made tough (#647, Sean's call on #648)

Sean, 2026-11-04: "timber tougher": a bundle of four sticks cuts a 12x12 post and fewer sticks
don't (one bundle takes one post), and the town's wall holes stay as he liked them (one stick a
crawl hole in siding, three a doorway).

## The rule

`Blast.toughness(cross_section, wood)`: what a timber soaks up bending is multiplied by
`(D / heavy_from) ^ heavy_power` past `heavy_from` (BlastTuning; D its least side; 0.038 m and
0.82). Used by `_member_response`, `torn_stretch` and `rail_share` (the bend of a rail; iron is
left as it was). Why: by the blast's energy rule the least charge that cuts a timber in contact
grows about as D (the kick falls as the section's mass, what it soaks up grows with its volume);
FM 5-25 (*Explosives and Demolitions*, 1967; external timber charge, in contact, P = D²/40 lb of
TNT) has it grow as D². The two agree at a 2x4 stud, so studs, boards and siding are as they were.

The least charge in contact that breaks an upright 3 m post (the old rule / the new one; a stick is
0.2 kg; the probe was a scratch test over `runner.gd`'s `blast_demand`, one stick's radius off the
face), and the ratio a bundle set touching gives (over 1 breaks; ground share at 0.6 m):

| Section | Before | After | Bundle of n sticks touching, after |
|---|---|---|---|
| 2x4 stud | 0.010 kg | 0.010 kg | every n |
| 4x4 | 0.029 | 0.042 | every n |
| 6x6 | 0.058 | 0.102 | 1: 3.7 |
| 8x8 | 0.089 | 0.177 | 1: 1.3 |
| 10x10 | 0.120 | 0.262 | 1: 0.59, 2: 0.96, 3: 1.9 |
| 12x12 | 0.160 (under a stick) | 0.385 | 1: 0.28, 2: 0.42, **3: 0.82, 4: 1.22**, 8: 3.7 |

(A bundle's sticks sit in a ring, so its middle is further off the face than a stick's: four
touching is ~0.7 kg's worth for a 12x12, the manual's 1.6 kg being written to make sure of it.)

`tests/test_dynamite_bundles.gd`'s trestle test now holds it on the viaduct's bottom posts: one
stick and three stand, four and eight cut, the post 0.9 m off never. `test_track`: one stick on a
tie still bows or breaks the line; three single sticks spread along it no longer break it (6x8
ties are tough now), a bundle of four does.

## The town (breakage lab, every dynamite scenario, the outlaw; main vs this)

`run.py --scenario=<the 32 dynamite ones> --bodies=outlaw`; `table_main.md`, `table_tough.md`,
`diff.md`. **The walls are the same in every count** (wall_dynamite 0, 1, 3 and 6 m, the floor,
the roof, the ground, the windows). Where a count changed it's one to four heavier members fewer in
a building's collapse (a joist, a sill or post of a kit prop: `lamp_dynamite_6m` the most, 470 ->
451 broken). `test_dynamite`: the siding's hole and the three-stick doorway as before (one stick by
the wall: 15 boards and 2 framing, was 3; inside: 4 studs, a joist fewer).
