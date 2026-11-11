# Art lane: current state

Branch `claude/art-…`. Files: see CLAUDE.md "How we work". Replace your lines here at the end of a
session (no history: that goes in `docs/status/` and the PR). Keep this file under ~10 KB.
Full history to 2026-11-11: `docs/status/current-state-2026-11-11.md` "Art".

## Where the look stands
- **Realistic, toward Red Dead** (Sean 2026-11-04; DESIGN.md §4, `docs/briefs/red-dead.md`). The real
  look (`RealLook`) is the default (#641); N turns it off; goldens exist in both looks (`<view>_real`).
  Day exposure blended by the sun (`config/looks/real_light.json`). SDFGI off (#643).
- **Material library** (`config/material_library.json`, `SamplePanel`, `scan_wood.gdshader`; LAYOUT
  "src/render"). Passing woods: R1 (all ages), C1, F2. Approved paints: `painted_white_lap`,
  `painted_green_trim`, `painted_buff_drop`, `painted_pale_tg`, `painted_pale_tg_green` (all ages),
  `painted_oxblood_batten` (few, old). Buildings take finishes by name.
- **Judges decide** (Sean, #721): materials judge (`tools/material_judge.py`,
  `docs/concept/judge/MATERIAL.md`): a swatch passes at "game" or better with no tile tell. Cheap judge
  (`critic.py cheap`, `--refs=<Studio>/references`) for whole views. Judges vary about a grade run to run.

## Open
- **Buildings in mission order** (#765): doctor's office done, in his paints (`experiments/building_lab/doctor/`,
  `RECIPE.md`). **Next: the room fixes (#824-826), then the jail (#811)**, then the general store, then saloon B, the corner saloon (#772,
  `docs/briefs/saloon-design.md` "Sean's answers").
- **The doctor's room review** (#818, `docs/reviews/2026-11-doctor-room.md`): why the office reads cheap (flat
  indoor fill and no lamps, one walnut everywhere, 24 cm boards under a 9 cm paint, slab windows, indoor wear
  under the floor). **Sean said yes to all five picks (#821, DECIDED).** Built once in the doctor's office by #824
  (light and lamps), #825 (pine floor, furniture woods and finish), #826 (sash window part, narrow beaded boards,
  skirting, casings); then the jail (#811, branch `claude/art-building-jail-xrtsvh`) on those parts.
- Paint round 2 (#804: an opaque film inside, failing in strips outside, P3 new): parked until after the slice unless Sean says otherwise.
- Lighting (#711): the sun's saw-tooth shadows, rim light, shadows under feet, the shade fill; F2's varnish waits on it. Week 2.
- Room light (#608): off; waiting on Sean.
- Waiting on Sean: #615 (yardstick), #641 follow-ups.

## Traps
- One lavapipe render at a time (~10 GB each; two OOM). A real-look view ~10 min; a full golden render
  ~2.5 h (batches of 24-25 with `--only=`); a material lab shot ~1 min after ~1.5 min of load.
- Start with `--game-args=--real`: switching the real look on at runtime crashes lavapipe. Needs
  `mesa-vulkan-drivers`, or Vulkan silently falls back to OpenGL.
- Moving the clock re-blends the look (a bridge `set` before `time` is lost); wait ~5 s after a clock jump
  before a screenshot. Try dials with `screenshots.gd --variants=` (one load).
- `pgrep -f`/`pkill -f` match their own command; `pkill -x godot` stops every render.
- A per-board hashed value must be a flat varying (the weave). Check a scan's grain with the test, not by eye.
- A data texture with alpha needs `process/fix_alpha_border=false`. After a local import the Studio men's
  `.import` stubs fill in: keep them out of commits but filled locally, or the men draw white.
- Render only what changed; a review round is ~2.5 h here.
