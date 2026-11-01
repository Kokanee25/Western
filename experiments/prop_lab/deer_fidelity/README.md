# The deer head's fidelity lab (issue #524)

Rodin's deer (Sean's six pictures, 2026-10-24) looks much better as Rodin's render than on the
saloon's wall. This lab finds **which step loses it**, one step at a time from the game's deer
to Rodin's master, without changing the game: the live deer, `deer_head.json`, `model_paint()`
and every default are untouched; the versions are made in `build/` and drawn by the lab.

The master is the Character Studio's `paid/526815a52c02...` (Kokanee25/saltcreek-characters, ledger
row `prop:deer_head`, request `requests/2026-10-24_deer_head_rodin.yaml`, $1.60; sha256 in the
results' `variants.json`). It is only read, never changed. Spend for this lab: $0.

```sh
# 1. The versions from the master (Blender's bpy; ~2 min): build/deer_fidelity/variants/
~/.venvs/studio/bin/python experiments/prop_lab/deer_fidelity/make_variants.py \
    ../saltcreek-characters/paid/526815a52c02259a02f3bb0664b7f31c2bb7d3f454b617b09952c9d98868ce29
touch build/deer_fidelity/.gdignore    # loaded from disk at run time, never imported
# 2. The stand: each version alone, same cameras and lights (A, C), and its cost (~2.5 min)
xvfb-run -a godot --path . --rendering-driver vulkan -s res://experiments/prop_lab/deer_fidelity/stand.gd -- --out=build/deer_fidelity/stand
python3 experiments/prop_lab/deer_fidelity/sheet.py build/deer_fidelity/stand OUT.jpg [--only=C0,C1f,A] [--cols=studio_close,...]
# 3. The game itself (B, D): each version wired into the kit's deer_head on the saloon's back wall,
#    noon and night, the player's eye (~9 min)
python3 tools/bridge.py start --size=1280x720
python3 experiments/prop_lab/deer_fidelity/game_shots.py build/deer_fidelity/game --versions=game,C1,C1f,C2,C4,C7,A
python3 tools/bridge.py stop
python3 experiments/prop_lab/deer_fidelity/sheet.py --game build/deer_fidelity/game OUT.jpg
# 4. D behaves: the game's deer tests and the lab's (hang, fall and split, shots, fire), headless
godot --headless --fixed-fps 60 -s res://experiments/prop_lab/deer_fidelity/d_checks.gd -- --versions=game,C1f,C4 --out=DIR
```

- `make_variants.py`: the master placed in the kit's space (as `deer_head_rodin.py` places it) and
  cut to 15k and 6k; Rodin's colour, normal and roughness maps at 4k, 2k, 1k; normals baked from
  the master onto the cut meshes (Cycles); roughness by surface (fur, antler, glass eye, wet nose,
  varnished plaque) from each texel's place on the model and its colour.
- `deer_variants.gd`: the versions (`VARIANTS`, the ladder) and how each is drawn: `grid` is the
  game's texel grid shader as `PropModels.model_paint` sets it; `pbr` is Godot's standard lighting
  on the maps, written as a shader (`pbr_shader()`) because the kit's `model:` look takes only a
  ShaderMaterial. `use_in_kit(id)` lays a version's parts and material into PropKit's and
  PropModels' caches so `PropKit.make(&"deer_head")` builds the game's own prop drawn by it (D).
- `stand.gd`: a boarded wall, the deer at the saloon's height (2.7 m); views front, threeq,
  profile (2 m off, a 30 degree lens), close (a couple of steps off, the player's eye and 75 degree
  lens), across (9 m); lights studio (neutral), day, lamp (the prop lab's look rigs). Costs:
  triangles, texture bytes, the deer-only frame under lavapipe (CPU raster: a proxy only), draws.
- The prop lab bridge's `deer_variant ID|game|none` swaps the town's hung heads.
- `d_checks.gd` (`d_checks_body.gd`): the version in the kit, then the game's four deer tests and
  the lab's own: drawn (triangles, batches, a headless frame), shot (a .45 ball at head, neck and
  plaque), falls (its nails' boards broken), burns (the neck lit, four minutes).

Results: `../results/2026-11-01_deer_fidelity/` (its README).
