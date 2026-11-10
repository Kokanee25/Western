# Brief: the material library (#701; art; Sean 2026-11-08)

**Goal.** Approve the world's materials now, on sample panels only, so that every building made
after the greybox (#695, then the saloon, #660) picks from one approved library. Sean: *"We don't
need to rebuild any buildings right now since the map is being made. We need to start approving
materials for when the builds start getting made."* No building is rebuilt here.

**The families (#701's comment, in order):** woods by class and age; paint jobs; no repeats
(part 1); board shape variance (part 5); trim profiles (part 4); masonry faces (#663); roofing.
One or two families a session, then stop for Sean's yes / change per swatch.

**References:** the real look (#631, #641, ×1.05 by day since #710); RDR2's direction
(`docs/briefs/red-dead.md`); the AAA references in the Studio's `references/` (branch
`claude/studio-refs`) for the cheap judge; MetaHuman Sean (Studio #692, build `sean_metahuman_s3`)
for scale and realism once he's on the Studio's main. Until then, the bold cowboy (`bold_cowboy_s0`).

## How it's built (extends the material lab; no new system)

- **Scans:** CC0 from Poly Haven and ambientCG, fetched on GitHub (`tools/textures/scans/`,
  `.github/workflows/scans.yml`: the catalogue's thumbnail sheets, then `picks.json` into
  `assets/textures/scans/<id>/`: albedo 2048, normal 1024, roughness 512, JPEG, imported
  BC-compressed with mipmaps). Credited in `CREDITS.md` "Materials". Only grain scans with no
  seams are used: each board takes its own crop.
- **`config/material_library.json`** (`MaterialLibrary`): one entry per material (id, swatch
  code, class, layout, board sizes, nails, scans, tints, dials, `approved` ages).
- **`SamplePanel`** (`src/art/sample_panel.gd`): a 2 × 2 m wall, a 2 × 1.2 m floor patch and a
  rail on two posts (0.95 m; 1.07 m bar height for fine woods), every piece a board of real size.
  Classes (#695): rough, common, fine, each new / a few years / old (`SamplePanel.CLASSES`: warp,
  gaps, size variance).
- **`scan_wood.gdshader`** (`src/render/`): the scans board by board.
  - **Part 1:** each board's own offset, flip, variant scan and hue / value / roughness shift from
    its seed, plus a large-scale layer in world space (sun-fade, grime from the ground up, water
    streaks).
  - **Age:** blends toward a weathered scan; for varnished woods, ambers the varnish and wears it
    where hands go.
  - **Detail:** nails at the studs (rusting, streaking), and saw arcs on rough-sawn faces.
  - **Part 5:** twist, cup, bow, crook and a lifted corner in the vertex shader from the board's
    seed (CUSTOM0-2: the same meshes can be members later; collision stays the box).
  - `variety` and `warp_gain` switch parts 1 and 5 off for the before / after.
- **`tools/material_lab.gd --panels=FAMILY`**: the panels in a row in the desert, facing
  south-west (lit at noon, raked at golden hour), the man beside the one in view. Lights: noon,
  golden hour, and night inside (a plain room round the panel with the saloon's lamps). Views: 5 m
  and 1 m. `long` (a 12 m wall, part 1 before / after) and `shape` (part 5 true / warped, raking).
- **`tools/material_library_sheet.py`**: a sheet per family, a row per swatch (code e.g. `R1-F`).

## Done looks like

A sheet per family in `docs/screenshots/material_library/<date>/`, the cheap judge's verdict on
each (with its extra question: *does the man look like he belongs in the same game as the wood
beside him?*, and his height against the rail, bar and wall in numbers), and a `waiting on Sean`
issue asking yes / change per swatch. Approved entries get their ages in `approved`; only those
are used by buildings.

## How it's judged

The cheap judge (`tools/critic.py cheap`, rubric `docs/concept/judge/CHEAP.md`, `--refs=` the
Studio's AAA references) on each sheet's renders; part 1's repetition score (the judge's measure,
before and after on the long wall); part 5's cost (the panels' triangles; draw calls the same).
Sean's yes / change decides.

## Not yet (later sessions)

Paint jobs (part 2, with #695's class), trim profiles (part 4), masonry faces (#663), roofing; the
library into the game's members (MemberMesh carrying the seed, the shader under the real look's
`texel_grid` or beside it), once Sean has approved the woods.
