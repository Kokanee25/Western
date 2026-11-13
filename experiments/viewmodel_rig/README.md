# The viewmodel rig lab: Harlan's first-person hands, option 2 (#896)

Sean, 2026-11-13, on the arms' fallback (#890's comment, option 2): "I like 2 - can we start an
experiment doing that". The usual first-person way: the MetaHuman's **hands cut at the wrist**, with
**modelled sleeves** (his shirt's cuff and his coat's sleeve), on a **first-person rig of their own,
posed per gun from data**, not driven by the full body's skeleton. #890 is putting the full MetaHuman
arms in the game; this lab builds option 2 beside it so Sean can compare the two and pick.
**Nothing in the game changes:** no file under `src/` is touched; `src/weapons/` is #890's.

## Run it

```sh
# 1. The arms (Blender as a module, ~1 min). Needs the Studio attached (../saltcreek-characters) and
#    Sean's MetaHuman in its frozen/ (git-lfs or a free `studio rebuild`); writes the PRIVATE glb.
~/.venvs/studio/bin/python tools/blender/fp_arms.py \
    --src=../saltcreek-characters/frozen/sean_metahuman_s3/sean_metahuman_s3.glb \
    --out=experiments/viewmodel_rig/private
godot --headless --import
# 2. Pose by eye on the plain stage (a floor, a sky, the sun; ~1 min for every pose):
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver vulkan --resolution 1280x720 \
    -s res://experiments/viewmodel_rig/views.gd -- --out=build/vmr/plain [--only=saa:idle,win73:lever] \
    [--extra [--far-side] [--close-left]] [--kick] [--hands=fp|held|both]
# 3. The comparison under the real look: Main Street at 16:00 and by an oil lamp at 21:30, the new rig
#    and today's HeldHand, the five views and their close-ups (~10 min to load the town, ~1 min a shot):
xvfb-run ... -s res://experiments/viewmodel_rig/views.gd -- --out=build/vmr/real --stage=real --hands=both \
    --only=saa:idle,saa:aim,saa:cock,win73:aim,win73:lever --extra
python3 experiments/viewmodel_rig/sheet.py --pair DIR_A DIR_B OUT.jpg --names=... --labels=A,B
```

`VMR_GUNS=a,b` renders other pose files (`poses/a.json`), for trying variants side by side.

## What's here

- `tools/blender/fp_arms.py` (characters' Blender tools): from the Studio's MetaHuman glb, the two
  hands kept from the fingertips to 9.5 cm up the forearm, chosen by **his own weights** (his hands
  hang by his thighs: distance would take thigh), the twist bones folded into the forearm; the rig
  trimmed to `forearm_<s>` (a root now), `hand_<s>` and the 15 finger bones a side (the game
  skeleton's names: 30 finger bones in all); the shirt's cuff (a band 6.8 cm long, 5.5 mm off his
  widest wrist, a turned hem, a bone button on the little finger's side) and the coat's sleeve (to
  25.5 cm up the forearm, 12.5-24 mm off his skin, its hem turned, folds bunched where it rests on
  the cuff and a slight sag underneath), sized from his own forearm's sections at each height; both
  skinned to the forearm, 2.2 and 1.2 mm thick.
  Out: `private/harlan_fp.glb` (**git-ignored**: his hands are the MetaHuman's mesh and skin, which
  never go in this public repo, #692; never used to train anything) and `private/harlan_fp.json`.
- `cloth/`: the cloth, made by the same script (numpy, seeded, seamless 512 px a 3 cm tile): a worn
  brown **wool twill** for the coat (2/2 diagonal wales ~1 mm apart, the yarn's twist, fuzz, mottle)
  and an unbleached **linen** plain weave for the shirt (slubbed threads ~0.6 mm). Albedo, normal and
  roughness. **The material library has no cloth yet** (`config/material_library.json` is woods), so
  these stand in; they are ours and committed.
- `fp_arms.gd`: the rig in Godot. HeldHand's hand space (so a pose reads the same on both and the gun
  lab's placements carry over): `place(side, at, along, palm)` puts the index knuckle, the wrist's
  line and the palm's facing; `aim_elbow` turns the forearm (and the sleeve on it) about the wrist
  towards where the elbow would be; `curl`/`grasp` bend each finger joint about its own across-axis
  (from his bones' rest lines: positive closes towards the palm, both hands checked by numbers and a
  render), `spread`, `thumb(root, bends)`. His skin keeps the MetaHuman's own maps (albedo, normal,
  roughness) with a little subsurface light.
- `fp_rig.gd`: the rig **posed per gun from data**. A pose file names, per pose, the gun's state
  (set through the gun lab's own rigs, `saa_rig.gd` and `win73_rig.gd`: hammer, gate, ejector,
  lever, the rounds), where the gun hangs under the camera (down the sights, or a marker at a place,
  turned), and each hand in the gun's space. A hand `in` a moving part rides it (the Winchester's
  right hand rides the lever's loop). **Recoil stays procedural:** the game's `GunKick` spring on the
  held node (`fire()`, `step()`), with each gun's peaks in its pose file. The same data drives today's
  `HeldHand` for the side-by-side (`--hands=held`).
- `poses/saa.json`: the Colt: `idle` (low, the hip), `aim` (one hand, down the sights), `cock` (the
  thumb over the hammer's spur, hammer part back), `reload` (the gun in the left hand, gate open,
  half cock, the right at the gate).
  `poses/win73.json`: the Winchester: `idle` (the low ready), `aim` (down the buckhorn), `lever`
  (the loop 60% thrown, the right hand riding it), `reload` (turned to the gate, the right thumb
  pushing a round in).
- `views.gd`: the renders (plain stage, or the town by day and by lamp); `sheet.py`: the sheets.

## Results (2026-11-13)

See `results/2026-11-13/` and the pick issue (#896's "which goes in the game?").

## What it costs

The hands are 21,161 triangles (the MetaHuman's body mesh is dense at the hands), the cuffs 2,232 and
the sleeves 5,568: ~29k for both arms, one skeleton of 34 bones. A game version would decimate the
hands (they fill a corner of the screen) and bake the forearm part away.

## Traps

- The private glb must exist before `godot --headless --import`, or the lab's scenes find nothing
  (`fp_arms.gd` warns and draws no arms).
- The MetaHuman's rest hands are already curled (`finger_rest_curl: 0` in his report): 70 degrees of
  `grasp` is a fist, not a grip; most grips here sit at 55-70.
- In a `-s` script nothing typed can name game classes (they compile before the autoloads); the
  scripts load each other with `load()`.
- `_set` is a method of `Object`: a SceneTree script can't define its own.
- One lavapipe render at a time; wait in one blocking command.
