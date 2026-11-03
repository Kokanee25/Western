# Character test 1: Human Generator's Godot recipe (2026-11-03): stopped at step 1

Issue #597 (waiting on Sean). $0 spent. Nothing built, exported or rendered.

**The task:** find out whether Human Generator alone can make a cowboy Sean likes, in the game:
its own sliders, skin, hair and clothes; exported by the Process tab's Godot recipe (glTF
Binary); checked by the Human Generator Godot Companion's `check.gd` in CI; renders and in-game
tests. Step 1: confirm the add-on is the early-access build and the Process tab can run the
recipe. If not, stop.

## What was checked

These are the Studio release `humgen-4.0.29`'s assets (Sean's purchase, 2026-11-01). They were
downloaded to the scratch space only and never committed (Human Generator's licence).

| Asset | Size | What it is |
|---|---|---|
| `HumGen3D_v4_0_29.zip` | 5.1 MB | the add-on, `__version__ = (4, 0, 29)` |
| `HG_Export.hgpack.zip` | 72 KB | "Recipes, game skeleton bone names and mesh reduction data of the Process tab": `process/recipes/{godot,unity,unreal,mixamo,generic,blender}.json` (format `"version": 2`), `process/game_rig_presets.json`, `process/lod/` |
| `Base_Humans/Hair/Clothes_V4_1.hgpack.zip` | 0.7 / 0.1 / 1.1 GB | content (not fetched this time) |

The pack's Godot recipe asks for a glb with embedded textures, humanoid bone names, a T-pose
rest, a `Root` bone in metres, 4 bones a vertex, face-rig, expression and corrective keys kept,
and body, face and age keys baked.

## What 4.0.29 does

- Its Process tab exists: `user_interface/process_panel/process_panel.py`. It is disabled only
  on the trial (`col.enabled = not is_trial`, a `Trial_Content.json` pack). Sean's copy is the
  commercial one.
- Its presets list (`backend/properties/process_props.py`, `get_preset_list`) reads only
  `<content>/process_templates/`. No code anywhere in the add-on reads `process/recipes/` or
  `game_rig_presets.json`. The word "recipe" doesn't appear in the add-on.
- The recipe's settings have no code behind them: grepping for `humanoid`, `t_pose`,
  `root_bone`, `game_rig` and `bones_per_vertex` finds nothing.
- Its own export (`human/process/export.py`) offers OBJ, FBX, Alembic, glb and glTF, with its
  own settings and no engine recipes.

**So the export pack belongs to a newer (early-access) add-on than the one on the release, and
the Godot recipe can't run.** The Godot Companion plugin isn't on the release or in either repo.
`humgen3d.com` (the pack's own link, `/docs/process`) and the docs site `publish.obsidian.md` are
refused by the workspace's proxy (403), and a web search didn't find the plugin.

## To go on

Sean's choice in #597:
- **A.** upload the early-access add-on (and the companion plugin) to a Studio release;
- **B.** allow `humgen3d.com`;
- **C.** run the test on 4.0.29's own glb export, with no recipe and our own report in place of
  `check.gd`.

Then: the Studio's `tools/humgen/fetch.sh` (the asset names must match), `hg_env.py` to enable
it in bpy 5.0.1, and the cowboy from its own sliders (#547's round 4 list of presets is a start).
