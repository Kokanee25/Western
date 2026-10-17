# Credits

Everything used under a licence (code, models, sounds, fonts, data) is credited here. Each session
adds its own lines.

## People (the characters session)

- **MakeHuman** base mesh and targets, v1.2.0 (makehumancommunity/makehuman): CC0. Fetched by
  `tools/blender/fetch_makehuman.py` into `build/`; the men in `assets/people/` are made from them.
  Also its face pose units, default skeleton and weights (`poseunits/`, `rigs/`; CC0, fetched by
  `tools/faces/mh_units.py --fetch`): the talking men's mouths, lids and expressions.
- **MediaPipe Face Landmarker** (Google, `face_landmarker.task`): Apache-2.0. Fetched into
  `build/mediapipe/` at run time and used by the tools only (the portrait factory's fit,
  `tools/paint/align.py`); not in the repo or the game.
- **Blender** (`bpy` 5.0.1): GPL, a tool run headless; nothing of it ships.
- **NumPy** (BSD-3), **SciPy** (BSD-3), **Pillow** (MIT-CMU): Python libraries the tools use.
- The portrait factory's reference pictures (`docs/concept/style/factory/`): made by Sean in ChatGPT.
