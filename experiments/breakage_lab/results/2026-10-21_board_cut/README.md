# Boards cut, not broken whole (2026-10-21)

Step 2 of `docs/briefs/blast-surfaces.md`, measured against step 1 (`../2026-10-21_near_field/`),
one game at a time, every dynamite scenario run twice, `bold_cowboy_s0`.

## The change

- **`Blast.torn_stretch`**: for a board, floor board or roof board the blast breaks (`CUT_KINDS`), the
  stretch it overcomes: Blast's own local test (the kick over a hand-span, `local_span` 0.3 m, against
  what that span soaks up bending: fb² / 2E × volume × `absorb_factor`, the USDA strengths in
  `config/timber.tres`) worked about each point along the board, from the point nearest the charge
  out to where it no longer holds (each end found by halving to 5 cm). A board broken by the
  whole-length test alone loses one span about the nearest point. `face_impulse` takes a window
  about any point along the member for it.
- **`Structure.cut_member`**: that stretch flies as ~0.3 m pieces of rubble (small debris under
  0.6 m, as chips are); what's left either side stays in the frame as members `<id>/a`, `<id>/b`
  resting on what held that part (the old member's neighbours relinked by `infer_supports`' rules,
  for those pieces alone); an end under 15 cm goes with the stretch. Saved as the cut
  (`to_dict().cuts`). `Events.member_cut` lets Fittings keep what stood on a piece left.
- Framing (studs, joists, rafters) still snaps where it's hit; doors still go whole.
- **A building that only lost glass isn't settled again** (`break_members`): a pane carries nothing,
  and the saloon's whole-building analysis was ~0.1 s for one window across the street. A stick by
  the store: detonation ~490–715 ms → ~300 ms (one blast timed by hand: 44 ms gathering and the
  rule, the rest breaking and settling the buildings it broke, ~100 ms the first explosion's effects).

## Before and after (step 1 → step 2)

Frames: detonation + next frame, ms, this workspace's core (×0.65 for Sean's).

| scenario | target before → after | found | members broken (glass) | pieces | opened ≤1 m (all) m² | detonate + next frame ms | +1st s |
|---|---|---|---|---|---|---|---|
| boardwalk_dynamite_0m | broken → cut (0.7 m torn out) | yes → yes | 46 (20) → 45 (20) | 359 → 476 | 3.17 (8.09) → 2.71 (5.43) | 490+53 → 338+61 | 1.56 → 0.94 s |
| boardwalk_dynamite_1m | broken → cut (1.2 m torn out) | yes → yes | 38 (14) → 35 (14) | 287 → 318 | 3.17 (6.9) → 1.6 (3.06) | 378+58 → 406+41 | 0.97 → 0.98 s |
| bottle_dynamite_1m | holds → holds | yes → yes | 47 (9) → 42 (9) | 225 → 321 |  | 358+436 → 327+357 | 1.75 → 1.76 s |
| bottle_dynamite_3m | holds → holds | yes → yes | 51 (10) → 39 (10) | 247 → 338 |  | 297+315 → 323+261 | 1.34 → 1.60 s |
| bottle_dynamite_6m | holds → holds | no → no | 61 (12) → 56 (12) | 304 → 451 |  | 491+412 → 689+318 | 2.11 → 2.10 s |
| chair_dynamite_1m | holds → holds | yes → yes | 45 (11) → 38 (11) | 247 → 344 |  | 317+293 → 301+37 | 1.47 → 1.37 s |
| chair_dynamite_3m | holds → holds | yes → yes | 41 (10) → 47 (10) | 235 → 348 |  | 291+252 → 502+199 | 1.29 → 1.95 s |
| chair_dynamite_6m | holds → holds | no → no | 70 (8) → 63 (8) | 253 → 430 |  | 401+275 → 532+137 | 1.85 → 1.78 s |
| door_dynamite_0m | broken → broken | yes → yes | 54 (19) → 50 (19) | 361 → 450 |  | 417+45 → 581+63 | 1.60 → 1.82 s |
| door_dynamite_1m | broken → holed | yes → yes | 54 (19) → 52 (19) | 358 → 435 |  | 376+61 → 336+65 | 1.43 → 1.61 s |
| door_dynamite_3m | holds → holds | yes → yes | 45 (20) → 44 (20) | 357 → 455 |  | 382+42 → 421+50 | 0.98 → 1.42 s |
| door_dynamite_6m | holed → holds | no → no | 26 (12) → 21 (12) | 264 → 277 |  | 376+65 → 231+39 | 1.00 → 0.60 s |
| floor_dynamite_0m | broken → cut (0.9 m torn out) | yes → yes | 54 (11) → 49 (11) | 260 → 357 | 3.17 (21.35) → 2.85 (6.86) | 433+362 → 331+277 | 1.97 → 1.58 s |
| floor_dynamite_1m | broken → cut (0.9 m torn out) | yes → yes | 39 (10) → 37 (10) | 232 → 337 | 3.17 (20.13) → 1.58 (6.41) | 345+111 → 673+113 | 1.36 → 2.04 s |
| ground_dynamite_0m | no crater → no crater | yes → yes | 10 (10) → 10 (10) | 224 → 224 |  | 337+9 → 236+9 | 1.08 → 0.63 s |
| ground_dynamite_1m | no crater → no crater | yes → yes | 11 (11) → 11 (11) | 232 → 232 |  | 300+5 → 157+5 | 1.00 → 0.58 s |
| lamp_dynamite_1m | holds → holds | yes → yes | 46 (11) → 42 (11) | 249 → 354 |  | 339+351 → 353+244 | 1.63 → 2.21 s |
| lamp_dynamite_3m | holds → holds | yes → yes | 40 (10) → 36 (10) | 233 → 332 |  | 380+311 → 455+265 | 2.06 → 1.69 s |
| lamp_dynamite_6m | holds → holds | no → no | 44 (9) → 36 (9) | 220 → 315 |  | 391+233 → 333+193 | 1.63 → 1.47 s |
| roof_dynamite_0m | broken → cut (1.3 m torn out) | yes → yes | 59 (20) → 56 (20) | 382 → 500 | 2.81 (18.96) → 2.76 (9.34) | 619+190 → 541+80 | 1.52 → 1.39 s |
| table_dynamite_1m | holds → holds | yes → yes | 41 (11) → 38 (11) | 240 → 346 |  | 421+166 → 489+146 | 1.47 → 1.58 s |
| table_dynamite_3m | holds → holds | yes → yes | 43 (10) → 37 (10) | 240 → 340 |  | 318+311 → 361+153 | 1.33 → 1.65 s |
| table_dynamite_6m | holds → holds | no → no | 44 (9) → 40 (9) | 221 → 319 |  | 508+131 → 393+215 | 1.78 → 1.52 s |
| wall_dynamite_0m | broken → cut (2.2 m torn out) | yes → yes | 58 (19) → 56 (19) | 364 → 493 | 3.07 (6.84) → 3.03 (4.12) | 436+32 → 300+35 | 1.17 → 1.51 s |
| wall_dynamite_1m | broken → cut (1.5 m torn out) | yes → yes | 47 (18) → 46 (18) | 331 → 453 | 2.07 (5.52) → 1.77 (3.16) | 311+30 → 308+42 | 1.14 → 1.20 s |
| wall_dynamite_3m | holds → holds | yes → yes | 21 (20) → 21 (20) | 328 → 336 | 0.0 (0.0) → 0.0 (0.0) | 385+24 → 239+32 | 1.07 → 1.28 s |
| wall_dynamite_6m | holds → holds | no → no | 11 (11) → 11 (11) | 232 → 232 | 0.0 (0.0) → 0.0 (0.0) | 371+7 → 159+5 | 0.98 → 0.50 s |
| window_dynamite_1m | shattered → shattered | yes → yes | 54 (20) → 54 (20) | 383 → 485 |  | 461+47 → 478+48 | 1.45 → 1.52 s |
| window_dynamite_3m | shattered → shattered | yes → yes | 21 (20) → 21 (20) | 328 → 334 |  | 273+39 → 227+53 | 0.98 → 0.78 s |
| window_dynamite_6m | shattered → shattered | yes → yes | 17 (17) → 17 (17) | 316 → 316 |  | 307+15 → 200+16 | 1.17 → 0.65 s |

- **Holes, not missing boards.** The saloon floor under a stick opens 6.9 m² in all (was 21, out past
  the scan), 2.9 m² of it within a metre; the store's front 4.1 (was 6.8); its roof 9.3 (was 19);
  the boardwalk 5.4 (was 8.1). The target board itself loses 0.7–2.2 m of its length.
- **How big a hole one stick makes is Blast's rule as it stands**: about 2 m stretches across ~20
  floor boards under a stick (a hole ~3 by 2 m), 1–2 m of the lap boards at the store's front. One
  stick inside against the side wall opens a hole to crawl through (0.7–1.4 m tall over the floor);
  three in a bundle, a way to walk out (to 1.7 m). The hole's size is Sean's feel call (the brief's
  decision 4); `absorb_factor` and `local_span` are the dials.
- **The board right at the charge opens least** at a wall's foot (a W-shaped hole): `face_impulse`
  counts how square on the shock strikes from the charge's offset past the member's widest side, so
  a neighbouring board's edge reads as a face struck square on. An existing quirk, not changed here.
- **More pieces** (~+100 a blast: the stretches in short lengths), fewer members broken.
- **The frame**: detonation frames at the store and the dirt are faster (glass-only settles skipped);
  the saloon's about the same. The frames after a blast are the ballistics (~70 ms: 200 splinters and
  gravel flown) and the fire system (~215 ms the frame after) at the store.
- **Same seed, same result: 23 of 30.** The saloon blasts as before, and now the roof (a piece ends
  6.6 m apart between runs) and, once, the wall. With voxel carving off (`run.py --novoxels`) the roof
  still differs, so it isn't the carving's worker threads; the cause isn't traced.

## Sheets

`sheets/surfaces.jpg`: the store's front at 0 and 1 m, its roof, the boardwalk and the saloon floor
at 0 and 1 m, step 1's frames beside step 2's.
