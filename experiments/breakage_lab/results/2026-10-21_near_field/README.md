# Blast's near field queried on its own (2026-10-21)

The breakage lab's first fix (`baseline/baseline.md`, "The first fix"), step 1 of
`docs/briefs/blast-surfaces.md`. Measured against the baseline (main at #164), one game at a time,
every dynamite scenario run twice, `bold_cowboy_s0` (the bodies make no difference to breakage).

## The change

`Blast.detonate` took what it acts on from one sphere query out to its reach (14.6 m for a stick),
capped at 1024 colliders, which came back in the physics engine's order. On Main Street there are
1,600–2,500 colliders in that sphere, and from the store's front it left out every member within a
metre of the stick. Now `Blast.gather`:

- every member and loose body where timber can break (`BlastTuning.break_reach_per_cbrt_kg`, 6 m
  per cube root of kg: 3.5 m for a stick), by a query of its own that's asked again with more room if
  it ever comes back full. Blast's rule breaks nothing past 2.0 m from a stick anywhere on Main Street
  (150 random spots, every member within 5 m): 3.5 m leaves a margin;
- out to the full reach: debris, ragdoll parts and sticks (their own query), every pane of glass
  (each building keeps its panes: `Structure.panes()`), and the loose rubble and fallen fittings
  (their groups).

Nothing else in Blast changed: the same rules for timber, glass, fire, people and loose things.
`tests/test_dynamite.gd` gains a crowded street (five buildings, 1,457 things in reach): the board
beside the charge, everything within a metre of it and every pane in reach are looked at, and the
board goes.

## Before and after

`left_out_within_1_2_break_m` is 0, 0, 0 from every charge now (it was up to 45 within 1 m).

Frames: detonation + next (settle) frame, ms, this workspace's core (×0.65 for Sean's).

| scenario | target before → after | found | members broken (glass) | pieces | opened ≤1 m (all) m² | detonate + next frame ms | +1st s |
|---|---|---|---|---|---|---|---|
| boardwalk_dynamite_0m | holds → broken | no → yes | 6 (6) → 46 (20) | 103 → 359 | 0.0 (0.0) → 3.17 (8.09) | 355+50 → 490+53 | 0.80 → 1.22 s |
| boardwalk_dynamite_1m | holed → broken | no → yes | 4 (4) → 38 (14) | 70 → 287 | 0.0 (0.0) → 3.17 (6.9) | 364+41 → 378+58 | 0.62 → 0.97 s |
| bottle_dynamite_1m | holds → holds | yes → yes | 42 (6) → 47 (9) | 150 → 225 |  | 382+431 → 358+436 | 1.66 → 1.75 s |
| bottle_dynamite_3m | holds → holds | yes → yes | 45 (7) → 51 (10) | 171 → 247 |  | 411+184 → 297+315 | 1.35 → 1.34 s |
| bottle_dynamite_6m | holds → holds | yes → no | 54 (6) → 61 (12) | 171 → 304 |  | 510+348 → 491+412 | 1.77 → 2.11 s |
| chair_dynamite_1m | holds → holds | yes → yes | 36 (5) → 45 (11) | 110 → 247 |  | 511+245 → 317+293 | 1.56 → 1.48 s |
| chair_dynamite_3m | holds → holds | yes → yes | 35 (6) → 41 (10) | 136 → 235 |  | 1267+980 → 291+252 | 5.60 → 1.29 s |
| chair_dynamite_6m | holds → holds | yes → no | 67 (5) → 70 (8) | 175 → 253 |  | 427+228 → 401+275 | 1.61 → 1.85 s |
| door_dynamite_0m | holds → broken | no → yes | 4 (4) → 54 (19) | 86 → 361 |  | 433+33 → 417+45 | 0.90 → 1.60 s |
| door_dynamite_1m | holed → broken | no → yes | 3 (3) → 54 (19) | 61 → 358 |  | 348+36 → 376+61 | 0.79 → 1.43 s |
| door_dynamite_3m | holed → holds | no → yes | 6 (6) → 45 (20) | 120 → 357 |  | 295+31 → 382+42 | 0.85 → 0.98 s |
| door_dynamite_6m | holds → holed | no → no | 6 (6) → 26 (12) | 102 → 264 |  | 387+31 → 376+65 | 0.77 → 0.81 s |
| floor_dynamite_0m | broken → broken | yes → yes | 49 (7) → 54 (11) | 179 → 260 | 3.17 (21.96) → 3.17 (21.35) | 523+443 → 433+362 | 2.12 → 1.97 s |
| floor_dynamite_1m | broken → broken | yes → yes | 36 (7) → 39 (10) | 161 → 232 | 3.17 (20.13) → 3.17 (20.13) | 436+107 → 345+111 | 1.39 → 1.36 s |
| ground_dynamite_0m | no crater → no crater | no → yes | 4 (4) → 10 (10) | 86 → 224 |  | 326+7 → 337+9 | 0.96 → 0.78 s |
| ground_dynamite_1m | no crater → no crater | no → yes | 5 (5) → 11 (11) | 94 → 232 |  | 366+4 → 300+5 | 0.98 → 0.69 s |
| lamp_dynamite_1m | holds → holds | yes → yes | 41 (6) → 46 (11) | 144 → 249 |  | 554+300 → 339+351 | 1.75 → 1.63 s |
| lamp_dynamite_3m | holds → holds | yes → yes | 40 (6) → 40 (10) | 144 → 233 |  | 367+294 → 380+311 | 1.62 → 2.06 s |
| lamp_dynamite_6m | holds → holds | yes → no | 37 (5) → 44 (9) | 118 → 220 |  | 448+96 → 391+233 | 1.29 → 1.63 s |
| roof_dynamite_0m | holds → broken | no → yes | 7 (5) → 59 (20) | 103 → 382 | 0.0 (1.44) → 2.81 (18.96) | 321+39 → 619+190 | 0.55 → 1.52 s |
| table_dynamite_1m | holds → holds | yes → yes | 47 (5) → 41 (11) | 125 → 240 |  | 449+226 → 421+166 | 1.61 → 1.47 s |
| table_dynamite_3m | holds → holds | yes → yes | 33 (5) → 43 (10) | 107 → 240 |  | 502+183 → 318+311 | 1.41 → 1.33 s |
| table_dynamite_6m | holds → holds | yes → no | 37 (5) → 44 (9) | 118 → 221 |  | 544+198 → 508+131 | 1.66 → 1.78 s |
| wall_dynamite_0m | holds → broken | no → yes | 4 (4) → 58 (19) | 80 → 364 | 0.0 (0.0) → 3.07 (6.84) | 338+48 → 436+32 | 0.94 → 1.17 s |
| wall_dynamite_1m | holed → broken | no → yes | 4 (4) → 47 (18) | 80 → 331 | 0.0 (0.01) → 2.07 (5.52) | 277+34 → 311+30 | 0.86 → 0.84 s |
| wall_dynamite_3m | holds → holds | no → yes | 6 (6) → 21 (20) | 131 → 328 | 0.0 (0.0) → 0.0 (0.0) | 361+26 → 385+24 | 1.00 → 1.07 s |
| wall_dynamite_6m | holds → holds | yes → no | 6 (6) → 11 (11) | 120 → 232 | 0.0 (0.0) → 0.0 (0.0) | 338+5 → 371+7 | 1.01 → 0.72 s |
| window_dynamite_1m | holds → shattered | no → yes | 7 (6) → 54 (20) | 136 → 383 |  | 408+35 → 461+47 | 1.04 → 1.45 s |
| window_dynamite_3m | shattered → shattered | yes → yes | 6 (6) → 21 (20) | 113 → 328 |  | 341+49 → 273+39 | 0.99 → 0.73 s |
| window_dynamite_6m | shattered → shattered | yes → yes | 6 (6) → 17 (17) | 120 → 316 |  | 426+12 → 307+15 | 1.03 → 0.77 s |

"Found" no at 6 m is by design now: the target is past where timber can break (the wall at 6 m is
0.05 of Blast's rule; the props are static and Blast doesn't act on them). The baseline's
`chair_dynamite_3m` frames (1267+980) are its slow outlier (`baseline/baseline.md`).

- **The street now breaks where the stick is.** The wall, the door, the window, the roof and the
  boardwalk all go at 0 and 1 m (they held before): 2–3 m² opened within a metre of the stick.
- **A stick by the store can now set it alight**: the fireball reaches boards it finds now (1–7
  catch at the door, the wall, the roof, the window, 0–3 m off; none before). Dynamite "can start
  fires in dry wood" (DESIGN.md §8); the saloon's numbers are unchanged.
- **More windows break: 10–20 panes a blast in the street, 8–12 in the saloon** (4–7 before). That's
  Blast's glass rule (a pane breaks at 3.5 kPa reflected) acting on every pane in reach; before, the
  capped query only happened to find a few. Whether panes 10–14 m off should go is a question for the
  glass rule (the baseline's "Windows far off shatter"), not this fix.
- **Whole members still go**, as the baseline said they would once found: the wall loses 5.5–7 m² of
  lap boards, the roof 19 m² of boards. That's step 2 (boards cut over the stretch the blast
  overcomes).
- **The frame isn't cheaper.** Gathering and working through the members is now ~40 ms of a ~545 ms
  detonation at the store (it was a 1024-collider pass); the rest is the breaking, the settle and the
  panes shattering, and more breaks now. Street blasts cost about the same or up to ~0.7 s more in
  their first second (the door at 0 m: 0.90 → 1.60 s), the saloon's about the same. Where the rest of
  the detonation frame goes is the next thing to measure.
- **Same seed, same result**: 24 of 30; every one that differs is a saloon blast, as in the baseline.
  Every street blast repeats exactly.

## Sheets

`sheets/street.jpg`: the store's front, window, door, roof and boardwalk, the dirt and the saloon
floor, the baseline's frames beside the fix's. The bystander's look differs between them because
main changed the Studio men's models in between (#162, #168); the breakage doesn't depend on him.
