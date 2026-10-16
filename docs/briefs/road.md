# The road (roadmap 1.4's follow-up; art, 2026-10-15)

## Goal

A believable, beautiful dirt street with deliberate detail, to Sean's target
(`docs/concept/targets/6_road_target.jpg`), not just a rougher dirt texture. Keep what works (the
painted surface, its relief lit by the sun, the 3D stones: `src/art/road_stones.gd`).

## Decided (Sean, 2026-10-15, on a ChatGPT critique of the first painted road)

- Old, half-worn prints placed now in the busy spots (the town's past traffic); fresh prints
  from people walking stay gameplay's (`docs/BACKLOG.md`), pressed in by the same stamp.
- Up to $2 more on image-model paint (about $3.50 in all; ~$1.50 spent by run 73).
- The ground smooth (no squares) across the whole street, boardwalk to boardwalk.
- No buildings, characters or renderer changes in this pass.

## The work

1. **Surface composition.** A street-wide traffic map made by a tool from `config/town.json`
   (doorways, porch steps, hitching rails, crossings between the boardwalks) and the wheel
   lanes, plus slow noise: broad *compacted* ground (smoother, flatter, a little paler, the fine
   detail and relief turned down) and local *disturbed* ground (clods, loose dirt, full relief,
   most of the stones, in irregular clusters). The ground shader and `RoadStones` read the same
   map.
2. **Ruts.** The base earth repainted without ruts (one or two calls); the ruts drawn along the
   whole street in code as wheel pairs at a wagon's gauge (~1.5 m), their depth, width and crumbled
   edges varying along it (fresh with raised lips in places, shallow or worn nearly away in
   others), as a world-space height that shades, casts shadow and darkens where deep.
3. **Prints.** A horseshoe and a boot print as small relief stamps, and a way to press them into the
   road's height at given places; a few old, half-worn ones in front of the rails and at the steps.
4. **Fidelity.** No squares on the street's ground, no procedural speckle; the painting's
   photographic fine detail softened when it is cut (a light painterly smoothing).

Files: `src/world/ground.gdshader`, `src/art/road_stones.gd`, the road's lines in
`src/art/pixel_art.gd`, `tools/textures/` (paint, reduce, the new map and ruts tools),
`tools/textures/materials.json`, and two views in `tools/screenshots.gd` (shared).

## How it's judged

- Two new fixed views, low and down the ruts as the target is: `road_low_golden` and
  `road_low_noon` (neutral daylight).
- Sheets: target | before (build 1208) | after, in both lights, plus `shot_match_street` and
  `street_golden_hour`.
- Geometry and shadows: stones resting on the dirt (none floating or buried), the stones' and
  ruts' shadows right at both hours.
- Performance: `tools/perf_bench.gd` before and after; `test_perf`; all tests.
- The judge and a blind critic; goldens re-approved in the same merge (batches of 24).
- Sean's eye on the sheets before the merge.
