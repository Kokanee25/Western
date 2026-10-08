# The stylised stranger's crispness experiments (characters session, 2026-10-07)

Branch `claude/characters-protected-features`, from `d31f6a1` (round r10's assets). Lead: one
session; the blind critic a fresh sub-agent that sees only a packet of anonymous crops beside the
master's own crops (Sean's reference pack: `01_MASTER_full_saloon.png` and its exact crops
02–08). No paid calls (fal, Rodin, Tripo) in any of this.

Tools (all characters-owned, committed on the branch):

- `tools/characters/man_diag.gd` + `tools/screenshots.gd --man-diag=PASSES [--man-normals=DIR]
  [--man-pose=...]`: the seated man's diagnostic passes from a copy of his shader patched at run
  time (the art session's `body_skin.gdshaderinc` is read, never written). `lit` (his albedo
  grey: the light alone), `id` (each square of his texture its own colour), `wire` (his
  triangles), `fix`/`litfix` (one normal a square), `fixp`/`litfixp` (one normal and one light
  point a square), `_nmsq`/`_nmtx` (the Rodin normal map, a square's mean / texel by texel), `ns`
  (shadows off). The lamps are held at their steady energy and the man held still while the
  passes are drawn.
- `tools/blender/fit_tripo.py --cells=normals:DIR[,normal_map:PNG]`: the textures' rest normals,
  square normals, square offsets and the Rodin normal map carried into the square layout (off by
  default; the assets come out byte for byte the same with or without it).
- `tools/characters/square_split.py DIR --lit=PASS --boxes=...`: how much the light varies inside
  each square on screen.
- `tools/characters/structure_views.py`: grey Cycles renders of the Rodin head with and without
  its normal map, and of the fitted head, with crops framed on his landmarks.
- `tools/characters/critic_pack.py`: the blind critic's packet; the key kept apart.

## E0: the baseline

| | Command | Time |
|---|---|---|
| r10 shot | `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd -- --out=DIR --only=shot_match_saloon --model=stranger2s --fresh --no-mosaic --man-mask` | 590 s |
| r10 bake | `python3 tools/characters/head_paint.py bake --id=stranger2s` | 95 s |
| r10 fit | `~/bpyenv/bin/python tools/blender/fit_tripo.py --only=stranger2s` | 22 s |
| D2r fit | `... fit_tripo.py --only=stranger2s "--cells=face:0.0055,soft.head:0,face_front:80"` | 22 s |
| D2r shot | the r10 shot command + `"--man-pose=head:6,-13.25,0;neck:0,-0.5,0"` (his head upright for this run only; `ShotMatch` untouched) | 467 s |

- The bake and the fit rebuild r10's assets **byte for byte** in this workspace.
- The r10 shot reproduces the committed r10 render (`judge/renders/face_modelled/`) to within
  1/255 on every pixel; his outline mask is identical. `judge_man.py --dry`: committed render
  0.499, this render 0.501 (its palette clustering moves a hair on 1/255 differences).
- **D2r** (D2 reproduced from its recorded command): judge 0.526, against 0.520 recorded for D2.
  Beside Sean's crop `09_CURRENT_D2_face_close.png` it is close but not the same: the earlier D2
  has a bolder, more mottled face (mean difference 12/255, 23 % of pixels more than 24 off;
  `e0/d2r_vs_reference_09.png`, 09 on the left). The recorded command can't have been the whole
  of it (most likely an intermediate working tree). D2r is the reproducible one.
- Blind critic, r10 against D2r (`critic/e0/critic.md`; labels in `critic/e0_key.json`: A = r10,
  B = D2r): A slightly ahead overall (eyes, brows, 3D form), B's squares closer to a steady grid and
  its hat band the most like the master; both far off: the moustache one soft band with no
  philtrum, the eye whites sparkle specks, no ear rim or hollow, a blown collar with black holes,
  slanted stretched squares on the cheek and temple.

## E2: where his 3D form comes from

`~/bpyenv/bin/python tools/characters/structure_views.py --out=DIR --what=a,b,c --size=640
--samples=48` (Cycles CPU, 347 s for the three). `e2/structure_abc.png`: rows a (the Rodin man as
made, grey, with his normal map), b (the same without it), c (the fitted man the game draws,
grey); columns front, three-quarters, side, ear, nose, nostrils, lips, eyelids. The Rodin face
lines up on the fitted one to 0.04 mm (median; 0.06 mm at the 95th percentile) by a rigid move
and one scale: **the fit doesn't change his head's shape at all** (his head isn't cut down: 5,750
triangles, under his 10,000 budget), so a Blender "d" (fitted geometry with the map) is a; the
game's d is the normal map carried into his squares (E1's `nmsq`, `nmtx`).

| Form | Geometry | Normal map | Notes |
|---|---|---|---|
| Skull, brow ridge, cheekbones, jaw, chin | yes | wrinkles, pores | the broad planes are in the mesh |
| Nose: bridge, tip, side planes | yes, soft | crisper edges | the big form reads grey |
| Nostril openings | barely a dent | yes: the rims and the dark openings | |
| Ear: as a flap off the skull | yes (silhouette, a soft lump) | | |
| Ear: outer rim (helix), inner hollow (concha), lobe | no | yes, all of it | the mesh ear is a flat lump |
| Upper lip, lower lip, the line between | no (one smooth mound) | yes | |
| Eyelids, lid creases | no (a smooth socket) | yes | the eyes themselves are only paint |
| Moustache | a soft bulge | hair strands | its shape and dark are texture |
| Stubble, pores, crow's feet, hatband studs | no | yes | noise at our square size |

So the grey mesh can't carry the ear, the nostrils, the lips or the lids. That information is in
Rodin's normal map (and its colour map's baked shading), and today none of it reaches the game.
Also seen: dark fins (folded triangles) in Rodin's own mesh at a nostril, a mouth corner and behind
the ear, in b and c alike.
