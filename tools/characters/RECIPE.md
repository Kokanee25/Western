# Recipe: a man in the portrait style (the Rodin portrait route)

How every man in the painted-block look is made, start to finish, so any session can make the
next one the same way. Sean, 2026-10-14: "I love where we're at". Decisions and evidence behind
it: `docs/briefs/portrait-factory.md`, `docs/briefs/character-style-fidelity.md`.

**The idea in one line:** his *shape* comes from plain photographs (Rodin builds a 3D bust from
them); his *paint* comes from five style portraits of him (each texel of his head takes its
colour from the portrait facing it squarest); then the shape is pulled to where the portraits
put his face, the moustache and brows are raised where the paint says hair, and the paint is cut
into patches that follow its edges.

**The approved state** is the git tag `look/portrait-men-2026-10-14` (see "Going back" below).

## 1. What Sean makes (ChatGPT, free)

Per man, in `docs/concept/style/factory/<man>/`:

- **Four plain pictures** (the shape): `front.png`, `left.png` (faces the picture's left),
  `right.png`, `back.png`. Hatless, flat even light, plain grey ground, square (~1254 px), the
  same man, hair and clothes in all four.
- **Five style portraits** (the paint): `style_front.png`, `style_three_quarter.png` (turned ~40°,
  facing the **picture's left**), `style_profile_left.png` (facing the picture's left),
  `style_profile_right.png`, `style_back.png`. The prompt, with the bold cowboy's five portraits
  (`docs/concept/style/portrait-cowboy-*.png`), the man's four plain pictures attached:

```
Paint this man as five portraits in exactly the style of the attached bold-cowboy portraits:
the same chunky square-pixel painting, the same warm lamplight, the same dark brown
background. The man is the one in the attached plain photographs: keep his face, build,
hair and moustache exactly as they are there. [HIS LINE]

Make five separate 16:9 pictures, one at a time, of the same moment:
1. Front: facing straight at the viewer.
2. Three-quarter: turned about 40 degrees, facing the picture's left.
3. Profile left: a true side view, facing the picture's left.
4. Profile right: a true side view, facing the picture's right.
5. From behind: the back of his head and shoulders.

Keep these identical in all five, because the pictures will be wrapped around a 3D head
and any difference shows as a seam:
- the same hat, worn the same way, low on the brow, the same band;
- the same clothes, hair colour and hair length;
- the same light: one warm lamp in front of him and a little to his right, soft fill on
  the other side, no hard black shadows across his face;
- the same framing: head and shoulders, his head the same size and at the same height
  in every picture, his eyes level, about 40% down from the top;
- the same square size as the attached portraits.

His expression is calm and closed-mouthed, eyes open, looking the way he faces. Nobody
else in the picture, nothing in front of his face, no text.
```

  `[HIS LINE]` is a sentence of who he is (age, build, face, hair, facial hair, clothes), e.g.
  "A lean young man of about twenty-two: narrow face, light stubble, tousled brown hair over his
  ears, a faded red patterned bandana knotted at his neck; brown canvas coat over a cream shirt."
  If one view drifts (another hat, another face), redo just that view.

## 2. His entry in `assets/people/portrait.json`

Copy an existing man's entry (`young_lean_cowboy` for a clean-shaven man, `bold_cowboy` for a
moustache) and change: `pictures`, `style`, `style_views`, `paint_views` (the five files),
`what` (his line, for Rodin), `outfit` (garment colours; `cravat` is the neckcloth),
`hair_fill` (`"grey"` default, `"dark"` for dark hair), and `fidelity`:

| key | approved value | what it does |
|---|---|---|
| `shape_fit` | `true` | warp his mesh to where all five portraits put his face's landmarks (`style_shape.py`) |
| `patches`, `patch_m`, `patch_compact` | `"anatomy"`, `0.003`, `12.0` | 3 mm patches grown along his paint's edges, not cut across eyes and lips |
| `keep_features` | `true` | eyes painted whole from the front portrait, not de-lit, the face never taken for the backdrop |
| `unsquare` | `3` | the median (px) that takes the portraits' own squares out; 9 wiped the irises |
| `moustache_m` | `0.004`–`0.005`, `0` if none | how far the moustache stands off his lip |
| `brows_m` | `0.002` | how far the brows stand off |

Remove `fidelity` and he's built as on main at build 1016 (before this pass).

## 3. The workspace (once per container)

```sh
apt-get install -y libegl1 mesa-vulkan-drivers   # MediaPipe; Vulkan for Godot (else GL3 silently)
python3.11 -m venv ~/bpyenv && ~/bpyenv/bin/pip install bpy==5.0.1 numpy==1.26.4 scipy pillow mediapipe==1.1.0
godot --headless --import
(cd addons/saltcreek_native && cargo build --release && mkdir -p bin && cp target/release/libsaltcreek_native.so bin/)
```

MediaPipe's model downloads itself to `build/mediapipe/` on first use.

## 4. Making him

1. **The shape ($1.60, the only paid step):** Actions → People → `style: rodin`, `characters:
   <man>`. Rodin Gen-2.5 on fal builds a bust from his four plain pictures; the workflow commits
   `assets/people/tripo/test/<man>_rodin.glb`. (FAL_KEY is a repo secret, not in the workspace.)
   Pull it.
2. **The paint:** `~/bpyenv/bin/python tools/characters/rodin_portrait.py paint --man=<man>`
   (~2.5 min) → `build/rodin_portrait/<man>_paint.png`, `_mesh.npy`, `_report.json`. Check the
   report: `views.*.landmarks_mm` (good: front ~1, others under ~2 after `shape_fit`),
   `shape_fit`, `relief` (moustache vertices: a few dozen or more if he has one).
3. **Into the game, renders and his sheet:** `tools/characters/render_man.sh <man> build/r_<man>`
   (~15 min: the build → `assets/people/<man>_rodin.glb`, `_head.png`, `.json`; the import; renders
   at 1.2 m at each portrait's turn and in the saloon; `docs/screenshots/portrait/<man>_rodin_sheet.png`).
4. **Tests:** `godot --headless --fixed-fps 60 -s res://tests/run_tests.gd -- --only=test_bodies`
   (his eyes on the anatomy's, within 1.5 cm).
5. **Measure him against his portraits:**
   `~/bpyenv/bin/python tools/characters/style_probe.py --man=<man> --game=build/r_<man> --out=build/probe --tag=after`
   (every panel framed exactly as each portrait: clay, paint, game neutral, saloon; the numbers
   in `<man>_after.json`). For a before/after, run it on the old state too
   (`--work=DIR` with the old `build/rodin_portrait` files, `--tag=before`) and
   `python3 tools/characters/style_compare.py --man=<man> --dir=build/probe`.
6. **Sean's eye is the gate:** send him the sheet. Copy sheets and numbers to
   `docs/screenshots/portrait/` and `docs/screenshots/portrait/probe/`; commit the man's assets
   (`assets/people/<man>_rodin*`, the `.import` files after Godot's import).

## 5. What good looks like (the bold cowboy, approved)

Against his portraits, means over front, three-quarter, profile: proportions off ~6 %; brow, eye,
nose and mouth landmarks off ~1.6 % of eye-to-chin, jaw ~9 %; paint patches ~2.5 % of eye-to-chin
(the portrait's own ~2.5 %); in neutral light tones ~17 and detail ~6–7 (portrait 14, 6.6).

## 6. Traps

- After a build, `godot --headless --import` before rendering, or the old man draws
  (`render_man.sh` does it).
- The three-quarter portrait must face the **picture's left**, or its camera starts the wrong way.
- Portraits that disagree (hat, hair, light) show as seams: redo the odd one out.
- A grey moustache lighter than his skin is barely found by the relief's hair test (the older
  man: 28 vertices); his face's light in the saloon runs hot (the art session's lamp).
- MediaPipe sometimes can't find a far-turned game profile (the young man's): that probe row is
  blank, nothing is wrong with him.

## 7. Going back

- **The whole approved look:** `git checkout look/portrait-men-2026-10-14 -- assets/people
  tools/characters` (then `godot --headless --import`) puts every man and the pipeline back as
  approved. `git diff look/portrait-men-2026-10-14 -- assets/people` shows what has changed since.
- **One man, one setting:** each `fidelity` key is off when absent; rebuild him (steps 2–3).
- **Before this pass (build 1016's men):** remove his `fidelity` block and rebuild.
