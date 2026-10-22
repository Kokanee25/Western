# Brief: the Unreal test scene (Sean, 2026-10-20; side experiment, not on the roadmap)

The full brief, with its build-pipeline diagram, is a doc:
https://claude.ai/artifact/V51Ky9cZTHX3DWx3L2g7P8 . This is its summary, so a session can start
from the repo.

**Question:** does Unreal Engine 5.8 bring Main Street closer to its painted target than Godot,
and can Claude keep building in it the way it builds Salt Creek? Two yeses mean a move is worth
weighing; anything less and Salt Creek stays in Godot (it is ~31,000 lines of GDScript, a Rust
plugin and custom shaders, so a move is a rewrite).

- **Scene:** the demo's five-building block from `config/town.json` (livery, saloon, jail, store,
  telegraph), from the judge's street shot (`shot_match_street`), at 17:00, 18:36 and 21:00. No
  people, guns, fire or destruction.
- **Where:** Unreal on Sean's Shadow PC (RTX 2000 Ada, 16 GB VRAM, DirectX 12 Ultimate: passes
  Lumen and MegaLights; 16 GB RAM is half Epic's recommendation; driver from 2024, update it). A
  new private repo `saltcreek-unreal-test`; Salt Creek cloned beside it read-only. `.uasset` and
  `.umap` gitignored and rebuilt by script; no Git LFS.
- **How:** `export_street.gd` (cloud, Godot headless) writes the block as glTF plus a JSON of each
  surface's texture and texels per metre; `build_street.py` (UnrealEditor-Cmd, Python) imports,
  makes materials, places by `town.json`, sets sun, sky, fog and lanterns from one clock;
  `capture.py` shoots the same camera. Textures nearest-filtered at Godot's density. Godot's
  per-texel light doesn't carry over; its cost is part of the result.
- **Lighting:** Sky Atmosphere and Volumetric Cloud, a clock-driven sun, Virtual Shadow Maps,
  Lumen, height fog with volumetric fog, lanterns under MegaLights, fixed exposure per hour.
- **Assets:** only Salt Creek's own; no Fab, Megascans or starter content. $0 paid generation.
- **Scorecard (all must pass):** `judge.py` closer at golden hour; a blind A/B critic picks Unreal
  at 2 of 3 hours; Sean picks Unreal clearly; rebuildable from a fresh clone by one script; Claude
  can check its own captures; 60 fps at 1280×720 with every lantern lit on the Shadow PC.
- **Time box:** three sessions. Unreal's MCP plugin may help look around but the build can't
  depend on it.
- **Context (2026-10-20):** UE 5.8 ships an experimental MCP plugin; UE6 (early access targeted
  end of 2027) is built around AI via MCP. Godot stays easier for Claude today because everything
  is text.
