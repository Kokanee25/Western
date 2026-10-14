# Brief: character style fidelity (the characters session)

Sean, 2026-10-14 (a prompt from ChatGPT he passed on). Follows `portrait-factory.md`: the
Rodin route (Rodin's shape from the plain views, painted from the style portraits) is on main
(#112, build 1016) and is "the closest we've had yet". This brief is the next iteration: find
and fix what still separates the man in the game from his portraits, **in the reusable
pipeline**, not by hand on one cowboy.

## Goal

A fully 3D, animated, dynamically lit man who reads as built from deliberate, chunky,
hand-painted blocks of colour, as the portraits are, from the front, three-quarter and profile.
Not a photographic face with squares over it; not more pixelation or contrast for its own sake.

## References

- The bold cowboy's five style portraits (`docs/concept/style/portrait-cowboy-*.png`); the older
  and young men's (`docs/concept/style/factory/<man>/style_*.png`).
- Our men: `assets/people/{bold,older_heavyset,young_lean}_cowboy_rodin.glb`, built by
  `tools/characters/rodin_portrait.py` (paint) and `rodin_portrait_build.py` (into the game).
- The game's drawing of people: `src/bodies/shaders/body_skin*` and `src/render/tiles.gdshaderinc`
  (art's files: per-texel flat light, `tile_light`), the screen mosaic (off since 2026-10-06).

## Phases

1. **Diagnose, with evidence.** Render our head framed exactly as each portrait (its fitted
   camera), in stages that separate the causes: shape alone (clay, landmarks), the projection
   before squares, the final paint, the game's drawing in neutral light and in the saloon.
   Measure each against the portrait: landmark and proportion errors (geometry); patch size,
   tonal levels, sub-block detail ("noise"), palette (the painting language); brightness,
   chroma and clipping (light). Name the three largest causes.
2. **Fix the largest, in the pipeline:** geometry (brow, sockets, lids, nose and cheek planes,
   a raised moustache, ears, jaw), the painting language (patches placed by anatomy, few
   controlled tones, no photographic detail under them, the same from every view, holding up
   as he turns and animates and under the game's light), whichever the evidence says first.
   Parameterised, per man by data (`assets/people/portrait.json`), never one-off.
3. **Validate:** a before/after sheet, reference vs ours at matched framing for front,
   three-quarter and profile, neutral light and the saloon; each axis scored separately
   (proportions, silhouette, colour-cluster quality, view consistency, style fidelity).

## Rules

- No runtime generative rendering; NPC-friendly cost (a texture and a mesh per man, the
  existing shaders). Facial deformation and the skeleton stay compatible.
- Shaders and lighting are the art session's: changes there are proposed to them (or asked of
  Sean), not made here; this session's levers are the mesh, the paint and the build.
- Reversible: new behaviour behind per-man settings; the merged men stay buildable as they are.
- Increased pixelation, contrast or lower resolution alone don't count as improvement.

## Done looks like

The three causes named with numbers and crops; the highest-impact fixes in the pipeline,
applied to all three men; the before/after sheet; what's left and the next iteration. Sean's
eye on the sheet is the gate.

## Notes as it goes

### Phase 1: the three largest causes (2026-10-14, `tools/characters/style_probe.py`)

Our head drawn through each portrait's own fitted camera (so framed exactly as the portrait), in
stages: clay, the projection before squares, the final paint, the game in neutral light and in
the saloon (laid onto the portrait by face landmarks). Sheets and numbers:
`docs/screenshots/portrait/probe/<man>_before_sheet.png`, `<man>_before.json`. Patch size is the
median run of one colour as % of eye-to-chin; tones, the k-means colours needed to come within
ΔE 6; detail, RMS under a median at the portrait's own patch size.

1. **The saloon's light burns the face** (all three men, the art session's lamp and skin shader).
   The light on his face (game ÷ his paint, same frame) is 1.7–2.0× at the median and ~5× at the
   90th percentile; 26–50 % of face pixels clip a channel (the portraits: none; neutral light:
   0–3.5 %). Against the portrait: L* +16–18, chroma +17–20, tones up to 3× (32 against 10),
   detail ~2×. In neutral light our face already sits near the portraits (L* 30–42 against
   32–44; tones 16–20 against 10–24; detail 3.7–5.8 against 4.6–7.1).
2. **The shape is the plain photos' face, not the painted one.** Rodin built him from the plain
   views; the paint only lines up from the portrait's own camera. The bold cowboy worst: chin
   (lower lip to chin) 0.25 of nasion-to-chin against the portrait's 0.35, nose 0.49 against
   0.41, cheeks 18 % wide, jaw landmarks 8–18 % of eye-to-chin off; the young man between (chin
   0.28 / 0.33), the older man close (jaw 3–11 %). None has a moustache or brow in the mesh: the
   forms the game's light picks out are the photo face's (clay panels).
3. **The squares stage throws the features away.** 4 mm cubes in 3D, each the median of whatever
   falls in it, cut across lids, irises, brows and the lip line: patches come out 1.6× the
   portraits' (3.1–4.1 % against 1.5–2.9 %; the projection before it, 1.4–2.4 %), and the eyes
   and brows smear (front row, "final paint").

Scale: at 1.2 m in the game his face is ~45 px eye-to-chin, about one game pixel per painted
patch (one game pixel ≈ 10 portrait pixels); in the saloon close view 2.5–3.5 px per patch. So
in play each pixel must land on the right patch's colour: detail finer than a patch is noise.

Plan from it: (2) and (3) are this session's (the mesh and the paint); (1) goes to the art
session with these numbers.

### Phase 2–3: what changed (2026-10-14; per man in portrait.json `fidelity`, off when absent)

- **Shape fit** (`style_shape.py`, `shape_fit`): each landmark's 3D place solved from every
  portrait at once through its fitted camera (a landmark counts only in views that face it; a
  pull of 0.15 back to Rodin's place keeps the depth no portrait sees), put back on Rodin's by the
  closest similarity, the mesh warped to it (Gaussian falloff 1.8 cm, at most 1.8 cm a landmark),
  cameras fitted again; two rounds. Bold cowboy: landmark error 1.8–4.0 mm → 1.0–1.4 mm.
- **Relief** (`moustache_m`, `brows_m`): the moustache and brows raised along the surface where
  the paint is his hair rather than his skin there, softened into a mass (bold 4 mm, older 5 mm,
  young none; brows 2 mm).
- **Patches by anatomy** (`patches: "anatomy"`, `patch_m` 3 mm): superpixels on his surface (SLIC's
  idea, position and colour together) in place of 4 mm cubes, so a patch keeps to one side of a
  lid, an iris, a brow or the lip line; each still the median of its texels.
- **Features kept whole** (`keep_features`): found while checking why his eyes came out pale.
  The projection's backdrop test (a sample near the portrait's ground colour is not him) threw
  out 28 % of the bold cowboy's eye box (his dark sockets are the ground's dark brown), and a
  profile painted them with its eye white; and an eyeball's sideways half went to a profile too.
  Now the face is never backdrop, the front portrait paints within 1.4 cm of each eye, and the
  de-light leaves the eyes' painted darks. Eye box mismatch with the portrait: 17 % → 1.4 %.
- `unsquare` 3 (was 9): the portraits' small darks (irises) survive the median.

### Phase 4: results

Sheets: `docs/screenshots/portrait/probe/<man>_before_after.png` (portrait | game before | game
after | shape before | shape after, per view; the saloon; the numbers). Bold cowboy, means over
the three views, before → after (portrait):

| axis | measure | before | after | portrait |
|---|---|---|---|---|
| proportions | mean of 6 ratios off | 22.9 % | 5.8 % | – |
| landmarks | jaw / the rest, % eye-chin | 13.4 / 2.5 | 8.8 / 1.6 | – |
| patches | paint, % eye-chin | 3.71 | 2.50 | 2.47 |
| tones, detail | game, neutral | 17.3, 5.7 | 17.3, 6.7 | 14.0, 6.6 |
| light | saloon L*, chroma, highlights % | 48, 56, 8.0 | 50, 55, 8.6 | 33, 35, 0 |

Unresolved: the saloon's light (art's, below); the grey at his temples comes out dark brown
(the hat region's hair fill); a flat band of forehead under the game's hat where the portrait
has the brim's shadow; ragged hair pixels at his outline; the game's black bowler against his
portrait's brown wide-brimmed hat with its studded band; ears untouched.

### For the art session (the saloon's light on faces)

Measured on all three men in `shot_match_close` (the light on his face = the game ÷ his unlit
paint, the same frame): median 1.7–2.0×, 90th percentile ~5×, 26–50 % of face pixels with a
channel clipped; L* 48–59 against the portraits' 33–44. Neutral light: 0.6–0.8×, clipping
0–3.5 %. Asked: hold a face's light so the 90th percentile stays under ~1.3× its paint with no
clipping (the table lamp's energy or falloff on people, or a skin-side cap in `body_skin`).
