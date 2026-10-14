# Brief: the portrait factory (the characters session)

Sean, 2026-10-12. Supersedes the scripted-face approach of `character-factory.md` (its trial on
`claude/characters-factory` built a good base head, but faces painted by script came out
doll-like; Sean judged it a failure). Keep that brief's layers, shape names, hitbox rule and
judging; replace how the face is made.

## Why every earlier try looked off

- **AI meshes (Tripo, Rodin):** each man has his own mesh and UVs, so every fix is redone per man,
  and the small forms (ears, eyelids, nostrils, moustache) are whatever the model made.
- **Views repainted separately, then blended:** the painted squares from different views don't
  line up, so the blend smears them into mush.
- **Baked light:** the paintings carry their own lamplight and the game lights him again: a hot,
  mask-like face.
- **Squares applied more than once,** or at the world's size: a face needs about twice the world's
  density (Hytale draws characters at 64 px a unit against 32 for the world). Ours: ~4 mm squares
  on the face, 8 mm in the world.
- **The judge (v2) penalised mosaic contrast,** so sessions smoothed the squares away to score
  better. Sean's eye on side-by-side crops is the gate now; the judge is notes only.

## The route (research, 2026-10-12: Route 1, chosen)

1. **One shared base head:** MakeHuman / MPFB2 base mesh (CC0, v1.2.0, fetched by
   `tools/blender/fetch_makehuman.py`), one frozen UV layout for every man, the small forms
   exaggerated in the geometry so they survive the squares (ears out 15–25° with a rim and bowl,
   nose 10–20 % larger with cut nostrils, an eyelid ledge, a lip line, a heavier brow). Reuse
   `tools/blender/factory.py` from `claude/characters-factory` if it holds up.
2. **Fit to his pictures:** MediaPipe face landmarks (468 points) on the front and both
   profiles; solve MakeHuman's face targets to them (`scipy.optimize.least_squares`, weights
   bounded to the targets' ranges); profile silhouettes for nose, brow and chin depth.
3. **Project his pictures onto the shared UV:** front, both profiles, back. Each texel takes
   its squarest view; blend only in a narrow feathered band at the seams (the cheek, behind the
   ear). Never average two views' detail.
4. **De-light:** take the picture's shading out (divide by a low-pass of its luminance, or fit
   the shading to the head's normals and remove it), so the game's light is the only light.
5. **Squares once, last, in UV space:** ~4 mm on the face, each square one flat colour (the
   median, not a mean, so edges stay hard), eyes and mouth drawn finer, a limited palette per
   region (skin, hair, moustache, eyes, lips). Nothing squared earlier in the pipeline.
6. **Feature stamps on the shared UV** where the projection is weak: eye whites, iris, glint,
   lid line, nostril dark, lip line, moustache underside. Drawn once, placed by the fit's
   landmarks.
7. **Into the game** by the existing fit (`fit_tripo.py` / `make_people.py` route): our 17
   bones, hitboxes, drawn eyes within 1.5 cm of the anatomy's (`tests/test_bodies.gd`), as
   `assets/people/<id>_portrait.glb` beside the existing men.

## Routes held in reserve (don't start without Sean's yes)

- **Route 2, Meshy 7 Retexture API** (`multiview_image_urls`, `enable_original_uv: true`):
  repaints our base head from his pictures on our UVs. Needs a paid Meshy plan.
- **Route 3, open models on a rented GPU:** TRELLIS.2 (MIT) or MV-Adapter (Apache-2.0) with our
  style LoRA; RunPod A100 ~$1.79/hour.
- **Route 4, smooth people in a squared world** (Hytale's answer), if the squares never sit
  right on a face.
- **Avoid:** Hunyuan3D (its licence excludes the EU, UK and South Korea). gpt-image-1.5 leaves
  the API on 2026-12-01: don't build a pipeline step on it.

## The references (`docs/concept/style/factory/`)

Three cowboys, made by Sean in ChatGPT. Each has `front`, `left` (faces left), `right`, `back`:
plain, hatless, flat light, grey ground, 1254×1254.

- `bold_cowboy/`: style targets are `docs/concept/style/portrait-cowboy-*.png` (front,
  profiles, three-quarter, from behind).
- `older_heavyset_cowboy/`, `young_lean_cowboy/`: `style_front.png` is a crop; full size to come.

The plain views are what's fitted and projected; the style portraits are what he should look
like in the end.

## Order and judging

Bold cowboy first, end to end; send Sean his sheet before starting the other two. Then the other
two from the same pipeline: if either needs more than his pictures and a run, the factory is
failing; say so.

Each sheet: style portrait | plain front | our man in the game, front, three-quarter and
profile, plain light and the saloon shot (`screenshots.gd --model=<id>`), 2× crops of eyes, nose,
moustache and ears. No paid calls without Sean's yes to a stated cost. Credit everything in
`CREDITS.md`. Don't touch the art session's files.
