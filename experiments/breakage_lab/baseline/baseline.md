# The breakage lab's baseline (2026-10-21)

Today's game, measured, nothing changed. Source: `claude/gameplay-breakage-lab-ksr17d` on main at
#159 (the Studio's three men). Headless, this workspace's 4-thread Xeon (2.1 GHz); 102 games, each
run twice (`run.py --repeat=2`), 204 of 204 finished. Sheets from a rendered run (lavapipe).
Frame times from a serial run (one game at a time, `bold_cowboy_s0`, each twice: 72 games).

- `table.md`: every scenario and body, one line each. `baseline.json`: every summary (slimmed).
- `sheets/<target>.jpg`: before, just after and at the end, a row a weapon; `sheets/man_on_table.jpg`
  a row a body.

## The baseline table, by target

The three Studio men and the outlaw give the same breakage to the member (below, "The new men"),
so this is the `bold_cowboy_s0` set; the full table, every body, is `table.md`. "Blast" is
Blast's own rule worked for the target (over 1 breaks it); "found" is whether Blast's query found
the target at all.

| Target | Revolver 5 m | Shotgun 5 m | Dynamite 1 m | Dynamite 3 m | Dynamite 6 m |
|---|---|---|---|---|---|
| Chair (saloon prop) | holds: the ball stops in its box | holds | holds; floor gone 0.6 m off (28 boards, 3 joists) | holds | holds |
| Card table (prop) | holds | holds | holds; 26 boards, 3 joists | holds | holds |
| Bottle on the bar (prop) | holds: stops the ball | holds: stops 9 pellets | holds; 5 fittings fall | holds | holds |
| Lit lamp on the table (prop) | **holds, not smashed**: the ball stops in the prop's box, never reaches the lamp | holds, not smashed | holds, not smashed (another lamp falls and spills) | holds | holds |
| Store door (open leaf) | holed (a 6 cm chip) | holed (9 chips) | holed; blast 0.95, **not found** | holds; 0.09, not found | holds; 0.02, not found |
| Store window (left pane) | shattered (26 shards) | shattered | **holds; blast 190x the glass limit, not found** | shattered (16x) | shattered (5.6x) |
| Store front wall (lap board) | holed | holed (7 chips) | **holed only; blast 1.5x, not found** | holds; 0.2 | holds; 0.05 |

| Dynamite, all targets and bodies | 1 m | 3 m | 6 m |
|---|---|---|---|
| Members broken, saloon (chair, table, bottle, lamp) | 36–53 | 33–48 | 37–67 |
| Members broken, store (door, window, wall) | 3–7, glass (one trim) | 6, glass | 6, glass |
| Pieces, saloon (largest) | 110–165 (a joist, 132 kg, 7.9 m) | 107–176 (the same) | 118–175 (144 kg, 6.6 m) |
| Pieces, store (largest) | 61–136, glass shards (two 11 kg trims) | 113–131 | 102–120 |
| In the blast's reach / found | 1,744–2,510 / 1,024 | 1,770–2,461 / 1,024 | 1,607–2,340 / 1,024 |
| Caught fire, saloon | 2–7 members; a lamp spill in 7 of 16 | 1–4 members | 2–23 members; a lamp spill in 8 of 16 |
| Caught fire, store | none | none | none |
| Bystander | saloon, 2.4 m: thrown down; 2.8 m: nothing | saloon, 0.9 m: down, both eardrums, bruised; 2.3 m: down | saloon, 2.2 m: down; 4.4–4.6 m: nothing |

In the street the bystander stood 3.1–6.8 m off and took nothing at all (under 35 kPa: no
knockdown, no eardrum).

Man on the table: he lands and stays on it, every body (pelvis 0.21–0.26 m over the top), at rest in
2.8 s (4.2 s the bold cowboy), the fastest part 6.0 m/s (a foot), nothing sunk past Jolt's slop
over 3 checks (deepest 4.6 cm for a check), no flags. The table doesn't move or break (a static box).

Same seed, same result: **89 of 102** identical in the parallel run (what broke, pieces, where
every piece ended to the millimetre, the men), **31 of 36** in the serial one. Every one that differs
is a blast on the saloon floor (13 and 5; not the same ones each time): 1–9 members and 2–11 pieces
differ between two runs, a piece ends up to 11.6 m from where it did, a man's pelvis 5–39 cm. Every
gun scenario, every street blast and the man on the table matched every time. One game at a time
didn't cure it, so it isn't cores being shared; the saloon's blasts are the ones that carve, settle
and burn the most (the voxel meshing runs on worker threads, and FireSystem settles a building a
slice a frame), but which of them it is isn't traced.

## What doesn't break that should

1. **A stick by the store front breaks nothing near it.** `Blast.detonate` gathers what's in reach
   with one sphere query capped at 1024 colliders (`intersect_shape(q, 1024)`), in the physics
   engine's order, not by distance. A stick's reach is 14.6 m; on Main Street that's 1,700–2,500
   colliders. From 1 m off the store's front the query found **none of the 14 members within 1 m
   and 2 of the 69 within 2 m**; the lap board Blast's own rule breaks (1.5x) is never looked at.
   The window 1 m off takes 190x the pressure that breaks glass and stays whole; the panes that do
   shatter are 4.8–12 m away (the store's other front window, the saloon's, the store's back
   window). The door: left out at 1, 3 and 6 m. In the saloon the near members happened to come back
   (0 of the ~35 within 2 m left out), but up to 109 of the ~320 within 5 m were.
2. **Props never break or move.** The chair, the card table, the bottle and the lamp are one
   static box each (`PropLibrary`): a .45 ball (612 J) or a shotgun charge stops dead in the box, and
   Blast pushes only rigid bodies. A stick 1 m off leaves them standing on a floor broken 0.6 m away
   (they're fittings, and fall only when every board they touch has gone).
3. **Shooting a lit lamp doesn't smash it.** The lamp's own hitbox (`OilLamp`, 14 x 38 cm) is inside
   the prop's box, so the ball never reaches it: no glass, no oil, no fire. Blast doesn't smash lamps
   either; a lamp breaks only by falling (Fittings) or a ball that finds its hitbox.
4. **Bottles don't shatter**, by design today (props, not members): a ball or nine pellets stop in
   the bottle on the bar.
5. Holes in a door or a front board never break them: they carry no load (utilisation 0 before and
   after), and the frame breaks members only by load.

## What breaks that shouldn't (or not like that)

1. **A stick on the saloon floor drops a quarter of the floor in whole lengths.** Every saloon blast
   breaks 24–30 floor boards and 2–3 joists. A floor board is one member the room's width (9.8 m)
   and a joist runs front to back (7.9 m), so the pieces are lumps: of the 853 pieces of rubble in the
   saloon blasts, the median is **4.7 m long and 81% are over 3 m**; the largest are whole joists of
   130–144 kg. A chair should come apart into pieces; a floor hit by 0.2 kg should hole, not lose
   four metres of boards.
2. **Broken boards leave at the throw cap.** 101 pieces of 0.9–17.6 kg leave at 20–25.6 m/s
   (`BlastTuning.max_throw` 25), most inside the building, jamming into what still stands: 44 pieces
   sunk 3–5 cm into members (flagged), and `flung` is the commonest flag (404 over all bodies).
3. **Windows far off shatter while the near one doesn't** (above, 1).
4. **Side windows shatter into slabs.** `StructureMember.shatter` takes the pane's `size.z` as its
   thickness; a side or back wall's pane is a box with its thin side along x, so each shard is as
   deep as the pane is wide (1.0–1.45 m). 504 of 1,770 shards are such slabs; 477 of them wedge in
   the wall's frame and hang there asleep, 1.2–2.8 m up (`pieces.csv`), and some lie 6 cm into the
   ground (the `below_ground` flags).
5. **The fire draws the whole board.** A board the fireball catches (2–7 in each saloon blast) is
   drawn burning along its full 9.8 m at once (`sheets/lamp.jpg`, "just after").

## The new men

The Studio's `bold_cowboy_s0`, `old_rancher_s1` and `young_drifter_s1` load (`has_model`, 63,701,
71,587 and 70,369 triangles; the outlaw 20,420), stand, go down and come to rest like the outlaw, with
no errors logged. **Physically they're the outlaw**: the ragdoll is the same 17 capsules for every
man (built from `Anatomy`, not the model), so old rancher, young drifter and outlaw give the same
numbers to the centimetre in every scenario (down in the same 6 of 21 blasts, the same harm: thrown off his
feet, and at 0.9 m bruised and both eardrums burst). The bold cowboy alone differs a little (at rest on the table
in 4.2 s against 2.8; pelvis 5 cm higher; the saloon blasts' differences are within their run-to-run spread, below). He's
the only one without a hat (the rancher's and the drifter's come off in a blast as a loose piece,
the `other` in the table; the outlaw's is part of his head) and the only Stage 0 fit; the cause
isn't traced. Whether they **look** right going down is in `sheets/man_on_table.jpg`: all four
land across the table the same way, and in every one the lamp's chimney and the cups show through
his chest and arm (static boxes that don't move; his capsules are thinner than he's drawn), the lit
lamp under him throwing his shadow across the wall. Nothing on the sheet is wrong for the Studio
men that isn't also wrong for the outlaw.

## Frame time per blast

Serial run, headless, this workspace's 2.1 GHz core (×0.65 for Sean's), the lab's own measuring
and FireSystem's periodic grid rebuilds taken out. "Event" is the frame it happens on; "+1st s" is
what the first second costs over the street's own frames (~1.0–1.5 ms each here).

| | Event frame | of which `dynamite` (Blast.detonate) | +1st s in all | Frames in the 1st s (mean / worst) | 1–3 s (mean) |
|---|---|---|---|---|---|
| Revolver 5 m, saloon | 1.6–2.5 ms | – | 0–13 ms | 1.1–1.2 / 2.4 | 1.0–1.1 |
| Shotgun 5 m, saloon | 2.4–19 ms | – | 4–33 ms | 0.9–1.3 / 3.5 | 1.0–1.2 |
| Revolver / shotgun 5 m, store | 12–37 ms (ballistics ~13: the carving) | – | 24–107 ms | 1.1–2.2 / 17 | 0.9–1.5 |
| **Dynamite, store front** | **235–441 ms** | 287–342 ms | 0.48–0.77 s | 5–7 / 61 | 1.7–2.2 |
| **Dynamite, saloon floor** | **369–520 ms** | 394–430 ms | 1.25–1.85 s | 15–24 / 441 | 2.8–10 |
| Man on the table | 3.6 ms | – | 18 ms | 1.4 / 2.5 | 1.5 |

- **A stick is a quarter- to a third-of-a-second hitch on Sean's machine** (0.15–0.34 s at ×0.65),
  nearly all of it inside `Blast.detonate` (Prof's `dynamite`): ~1,024 colliders each worked
  through `face_impulse` (17 samples × 3 across, each a Kinney-Graham impulse and pressure), then
  the breaks and one settle per building. In the saloon the next second costs another 1–1.5 s in
  all, with frames up to 0.44 s (the floor coming down: settles, rubble landing, fire catching); by
  1–3 s it's 3–10 ms a frame here (2–6.5 at Sean's), the fire's share growing.
- Against the 14 ms frame: at Sean's the blast frame alone is 11–24 frames' worth; the saloon's
  1–3 s fits the whole budget there, but its fire share (~3.5 ms here, ~2.3 there) is over "fire and
  effects" (2.0 ms).
- **Render CPU**: not measured headless (lavapipe draws only in the rendered run). Draw calls from
  the rendered run, same camera, a shot before and after: in the street +250–550 for a blast
  (1,100–1,275 → 1,360–1,650) and +20–40 for a shot; in the saloon a blast ends at ~23,000–24,900
  against ~12,200–13,200 after a shot. The saloon's "before" (~2,650) isn't comparable: the lab stops
  drawing between its shots, and the 14 lamps' shadows are redrawn when it starts again with
  anything moved, so read the saloon as **a blast doubles the draws a shot leaves** (rubble moving
  inside the lamps' shadow cubes). The wall scene's render CPU is already over budget (CLAUDE.md).
- The street's own frame here was 1.0–1.5 ms between events, with **FireSystem's grid rebuild every
  2 s: 5–32 ms (median 16) whether or not anything burns** (272 of them across the serial run).

## The first fix I'd make (not made)

**Blast's query: the near field first.** Query the sphere where timber can break (for a stick,
~3 m: the board 1.3 m off is 1.5x, one at 3 m is 0.2x) on its own, with no cap that can drop it,
and keep the 14.6 m sphere only for glass, people and loose things. That alone puts the store
front, its door and its window back in play, stops the far windows breaking instead of the near
one, and shrinks the work the blast frame does on members it can't break. Measured against this
baseline by `wall_dynamite_1m`, `window_dynamite_1m` and `door_dynamite_1m` (target found and
broken; `left_out_within_1_2_5m` 0, 0, 0) and the blast frame. Then, in 3.3's order: props as
members (Prompts 03/06: a chair and table that break by how they're built, the lamp's hitbox as its
box), the floor's boards and joists in shorter lengths, and `shatter` turned to the pane's own thin
side.

## Also seen

- **FireSystem rebuilds its grid every 2 s whether anything burns or not: 5–32 ms on this core,
  median 16** (3–21 at Sean's), the street's biggest spike when nothing's happening. The lab takes these frames
  out of the event's numbers (`fire_grid_ms`).
- The store's door stands open (swung in), so a shot from the street square to the front meets its
  edge; the lab's line is 45° from the front-right.
- The store's window has facade bars in front of its middle (`facade/window0/bar_h0`, `bar_h1`); the
  lab aims between them.
