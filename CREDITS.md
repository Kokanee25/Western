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
- **Hyper3D Rodin** Gen-2.5 (Deemos), through **fal.ai**: paid API generations, output owned by the
  customer with commercial use allowed (as understood; the terms pages couldn't be opened from the
  workspace, shipped on that basis with Sean's OK, 2026-10-21). The meshes and paint of
  `bold_cowboy_s0`, `old_rancher_s1`, `young_drifter_s1`, `hothead_lyle_s1`, `barkeep_s1`, `widow_s1` and
  `sean_s2`, `doctor_s1` (and the earlier Rodin men).
- `bold_cowboy_s0`, `old_rancher_s1`, `young_drifter_s1`, `hothead_lyle_s1`: made by the Character Studio
  (Kokanee25/saltcreek-characters) from pictures by Sean (ChatGPT) and views drawn from them by
  Google's Gemini 3 Pro Image (through OpenRouter); fitted, rigged and written by the Studio's code.
- `barkeep_s1`, `widow_s1`, `sean_s2`, `doctor_s1`: made by the Character Studio the same way, their pictures by Sean
  (ChatGPT) or OpenAI's GPT-5.4 Image 2 (through OpenRouter), `sean_s2` from Sean's own photo.

## Motion (the gameplay session)

- **CMU Graphics Lab Motion Capture Database** (mocap.cs.cmu.edu): "free for use in research and
  commercial projects worldwide". The data used in this project was obtained from
  mocap.cs.cmu.edu; the database was created with funding from NSF EIA-0196217. In B. Hahne's 2010
  BVH conversion (cgspeed.com; no further restrictions), fetched by
  `experiments/mocap_walk/fetch.sh` into `build/cmu/`. The walk (35_01) and run (35_17) are
  retargeted onto our rig in `experiments/mocap_walk/clips/` (an experiment, off by default).
