# Planting dynamite where you aim (#506)

For the farmhouse hostage breach (Sean, 2026-10-31). The code: `DynamiteViewmodel` (planting:
`plant_spot`, `plant`, `claims_use`), `DynamiteStick.stick_to`/`planted` (its hiss is `Events.noise` `fuse`),
`PlayerShove` (leaves E alone while the stick claims it), `OutlawBrain._on_heard` (`fuse`:
`FUSE_FEAR`, turns his head). Dials in `BlastTuning` ("The stick"): `plant_reach` 2.2 m from the
eye, `plant_time` 0.6 s, `plant_fuse_seconds` 5, `fuse_heard` 9 m (halved through a wall). The
blast itself is untouched (#494 as merged; Sean kept #484's option 1).

How it plays (Sean, 2026-10-31: "it goes wherever you aim ... if you fuck up the placement that's
the player's fault"; "posts or beams or really any structure piece"): stick in hand (3), aim at any
piece of a building within reach (a board, a stud, a post, a beam, a floor, a shelf) or the ground,
and hold E: the stick is fixed right where you aim, flat to it, along the piece's length where that
lies across the face (`DynamiteStick.stick_to`: frozen there until that piece breaks, is cut or goes,
or a ball hits the stick). Let go and the fuse is lit (5 s); let go early, nothing is set. Aimed at a
man, or at nothing in reach, E is the shove and kick as before. Thrown sticks are as they were.

## Files

- `check.gd` / `check_runner.gd`: the #484 test with a planted stick (the player's own code, E
  pressed and let go; `--aim=foot|chest`): 8 spots 0.5 m apart along the store's side wall, the hole's clear height
  (0.4 x 0.5 m box from floor height, 0.1 m steps), the blast frame and Prof's top five (F3's
  numbers). `-- --side=inside|outside [--spots=N] [--first=M] [--out=FILE]`.
- `bridge.gd`: `plant_where` (where E would set it now, or why not).
- `results/2026-10-31/`: `inside_foot.json`, `outside_foot.json`, `inside_chest.json`,
  `outside_chest.json`, `summary.txt`, the film
  (`plant_film.mp4`, the town's store, 11:00; sheet `plant_film_sheet.jpg`: set, lit, run, blast).

## Results (2026-10-31, this workspace's 2.1 GHz core, no native plugin)

The store's side wall, 8 spots 0.5 m apart, the player 0.9 m off aiming at its foot (~0.1 m up) or
chest high. Inside, the first two spots' aim meets the store's shelves, so the stick goes on a shelf.
Clear height of a 0.4 x 0.5 m box from floor height (`summary.txt`, `*_foot.json`, `*_chest.json`):

| Aim | Walk-through (≥ 1.7 m) | Stoop (≥ 1.3 m) | Crawl (≥ 0.6 m) |
|---|---|---|---|
| Inside, the foot | 4 of 8 | 6 of 8 | 8 of 8 |
| Outside, the foot (on the boards 0.18 m up) | 2 of 8 | 2 of 8 | 8 of 8 (0.9–1.1 m) |
| Inside, chest high | 6 of 8 | 6 of 8 | 6 of 8 (two leave the low boards: a window) |
| Outside, chest high (0.9 m over the floor) | **8 of 8** | 8 of 8 | 8 of 8 |

- Every stick breaks studs (2–6) as well as 15–40 boards (the check's `broken` rows).
- **The blast frame** (headless, wall clock of the frame it went off in): 18–76 ms, median ~27
  (~12–50 ms at Sean's by the 0.65 clock scale). Top systems in it: `ballistics` 2–13 ms
  (splinters), `settle_analyse` 1–27, `batches` 1–7.
- The film (`plant_film.mp4`) is the first version (set at the wall's foot), before "where you aim".
- Men hear it: an outlaw 3 m from a lit planted stick gets `a fuse hissing` in his fear and looks
  that way; 30 m off he doesn't (`tests/test_outlaw_tactics.gd`). Getting clear of it isn't built.

Sean, in the session (#511): fine with the hole one stick makes; no change to the blast.
