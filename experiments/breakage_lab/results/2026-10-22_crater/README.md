# The crater (2026-10-22)

Step 3 of `docs/briefs/dig-ground.md`, measured against main (the street's ground made of slabs and
tiles, #235, still flat). One game at a time, each scenario run twice, `bold_cowboy_s0`.

## The change

- **`Blast.crater`**: a charge whose ray down (0.05 m above it to 0.4 m below) meets the ground,
  not a board, takes a bowl `crater_k` x cbrt(kg) across (0.8: Kinney and Graham's regression, as
  Ambrosini et al. 2002 checked it; quoted, the papers not read) and `crater_depth_ratio` (0.27) of
  that deep, less the higher it went off (none from `crater_height` x cbrt(kg), 0.3: 18 cm for a
  stick). Of the earth taken, `crater_packed` (30%) is packed down; the rest is laid as a lip
  (a ring from the crater's edge, highest at 1.25 r, out to 2 r) and thrown as 16 clods (`Clod`)
  that lie down as loose earth where they come to rest on the dirt.
- The lab scans the ground at 2.5 cm (`scan_step`), counts clods as their own kind, measures the
  crater from the charge, and its below-ground flag is below the ground there (a crater's floor is
  below y 0).

## Before and after

| | main | the crater |
| --- | --- | --- |
| `ground_dynamite_0m`: depth, radius (from the charge), lip | none | 0.113 m, 0.20 m, 0.027 m at 0.27 m |
| `ground_dynamite_1m` | none | 0.115 m, 0.19 m, 0.026 m at 0.27 m |
| The fit for a stick lying 2 cm up | – | 0.47 m across at contact (r 0.235), 0.127 deep; 2 cm up, 0.42 m and 0.113 |
| Clods (0.14 kg each) | – | 16; 14 and 16 lay down as earth within 8 s; the farthest 9.7 m and 6.6 m (gravel hits some) |
| Same seed, same result | 2 of 2 | 2 of 2 (the clods too) |
| Pieces | 224, 232 | 249, 249 (16 clods, a chip, the same glass) |
| Flags | the 0 m run's glass shard 8 cm under the ground | the same shard (already on main) |
| Event frame (ms, this workspace) | 212, 207 | 294, 255 |

The event frame, timed by section in one more run each: `detonate` on main 65 ms gathering and
breaking, 147 ms effects; with the crater 52 + **25 (the crater and the gravel)** + 126. The sections
swing ±20 ms run to run; the crater's own cost is about 24 ms here (take ~15, put ~8, clods ~1;
~16 ms at Sean's), nearly all the tile meshes built in GDScript (step 5: native).

## Sheets

- `sheets/ground_dynamite_0m_look.jpg`: `run.py --look=0,0.12,0.5,2,8`, a row each, main above, the
  crater below.
- `sheets/crater_8s_main_vs_crater.jpg`: the 8 s frame cropped, main left (the scorch on flat
  ground), the crater right (the bowl in the scorch, its lit far wall and the lip's loose earth).

What it shows: a small scoop reads at a few metres, about what one stick should make; it's drawn
in the ground's own material (art's pass: the fresh earth, the lip and the clods, the brief's "What
art needs"). The scorch still lies over it.
