# Planting dynamite at a wall's foot (#506)

For the farmhouse hostage breach (Sean, 2026-10-31). The code: `DynamiteViewmodel` (planting:
`plant_spot`, `plant`, `claims_use`), `DynamiteStick.planted` (its hiss is `Events.noise` `fuse`),
`PlayerShove` (leaves E alone while the stick claims it), `OutlawBrain._on_heard` (`fuse`:
`FUSE_FEAR`, turns his head). Dials in `BlastTuning` ("The stick"): `plant_reach` 2.2 m from the
eye, `plant_time` 0.6 s, `plant_fuse_seconds` 5, `fuse_heard` 9 m (halved through a wall). The
blast itself is untouched (#494 as merged; Sean kept #484's option 1).

How it plays: stick in hand (3), face a wall within reach, or the floor at its foot, and hold E:
the hand goes down and the stick is set at the wall's base lying along it against the boards. Let
go and the fuse is lit (5 s). Let go before it's down and nothing is set. Away from a wall E is
the shove and kick as before. Thrown sticks are as they were (and still make no hiss noise).

## Files

- `check.gd` / `check_runner.gd`: the #484 test with a planted stick (the player's own code, E
  pressed and let go): 8 spots 0.5 m apart along the store's side wall, the hole's clear height
  (0.4 x 0.5 m box from floor height, 0.1 m steps), the blast frame and Prof's top five (F3's
  numbers). `-- --side=inside|outside [--spots=N] [--first=M] [--out=FILE]`.
- `bridge.gd`: `plant_where` (where E would set it now, or why not).
- `results/2026-10-31/`: `inside.json`, `outside.json`, `summary.txt`, the film
  (`plant_film.mp4`, the town's store, 11:00; sheet `plant_film_sheet.jpg`: set, lit, run, blast).

## Results (2026-10-31, this workspace's 2.1 GHz core, no native plugin)

| Where | Walk-through (≥ 1.7 m) | Stoop (≥ 1.3 m) | The rest |
|---|---|---|---|
| Inside, planted (settles on the sill in the stud bay) | **2 of 8** | 4 of 8 | 1.2 m |
| Inside, held at floor height (#484's spot; a first try that froze it there) | 4 of 8 | 4 of 8 | 1.2 m |
| Outside, planted on the ground against the boards | **1 of 8** | 1 of 8 | 1.0–1.1 m, a stud often left standing |

- Inside, the store's floor stops 10 cm short of the siding between studs (the boards span
  `w - 2 STUD_D`), so a stick set against the boards drops 16 cm into the bay onto the sill. That's
  where a real one would lie, so it's left to settle there (no freezing it in mid-air); the blast
  from there opens less than #484's stick at floor height.
- From outside the stick lies on the ground, 0.38 m under the floor; the measure starts at floor
  height (a man steps over the bedded sill). One spot in 8 opens a doorway; the rest are crawl holes.
- **The blast frame** (headless, wall clock of the frame it went off in): 17–55 ms, median ~23
  (~11–36 ms at Sean's by the 0.65 clock scale). Top systems in it: `ballistics` 3–11 ms
  (splinters), `settle_analyse` 0–20, `batches` 1–4. The film's run (lavapipe/OpenGL, drawn) is in
  the movie, not timed.
- Men hear it: an outlaw 3 m from a lit planted stick gets `a fuse hissing` in his fear and looks
  that way; 30 m off he doesn't (`tests/test_outlaw_tactics.gd`). Getting clear of it isn't built.

Sean's call (the issue): whether one planted stick's crawl/stoop hole is enough for the farmhouse,
or it wants more (a bundle when planting, or the blast tweaked).
