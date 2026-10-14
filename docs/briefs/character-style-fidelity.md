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

The other two (same settings; the young man no moustache): **young** proportions 13.8 → 7.2 %,
features 3.0 → 2.5 %, paint patches 3.70 → 2.09 % (portrait 1.90), eyes and brows clearer; but
the warp dents the corners of his mouth a little, and the game's profile of him isn't found by
MediaPipe (that row is blank). **Older** a wash: he was close already (proportions 5.4 → 6.6 %,
jaw 6.8 → 5.3, features 2.4 → 1.5, patches 3.19 → 2.13 against 1.73); his grey walrus moustache
is lighter than his skin, so the hair test found only 28 vertices of it and it hardly rose.

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

### The fidelity investigation (2026-10-14, Sean's five tasks; nothing in the pipeline changed)

Tools (lab only): `art_lab.gd` (now `--fov --dist --global --set --mip --mipdir --grade
--hat=lab:NAME`), `fidelity_compare.py` (portrait vs renders, landmark-cropped, style_probe's
measures), `hat_proto.py`, `moustache_probe.py`. Sheets: `docs/style_test/fidelity-2026-10-14/`.
The approved man as `assets/people/lab/bold_cowboy_approved` (a copy of main's, git-excluded).

**1. The light cap (art's `light_cap`/`light_knee`) on the approved man, `shot_match_close`:**
light ÷ paint median 1.74 → 0.69, p90 4.85 → 0.77, clipped 25.9 % → 0.1 %; face L* 30–32 (portrait
32). Brightness and clipping: fixed. Chroma not (style_probe: 48–50 vs the portrait's 40). Not
the texture (his paint unlit, no grade: L* 35, chroma 39, the portraits' level) and not the
material. Sources (art_lab `--grade`, unlit and lit, neutral and warm): the **ACES tone mapper**
lifts everything's chroma +13 and L* +4.6 (the saloon's unlit paint pass, chroma 52.5, is exactly
this), the **warm lamps** add ~+9 and turn the hue ~6° redder. Also found: `scenes/test_street.tscn`
spells `volumetric_adjustment_enabled`, not `adjustment_enabled`, so its contrast 1.15 and
saturation 1.12 never apply (with them chroma would be 65 unlit). Remedies are art's: a skin-side
chroma hold under ACES, lamp colour on people, or the tone mapper. Still in his paint: a white
speck under his left eye (a catchlight) and, under the game's hat in the saloon, a flat brown
band of the hat-hair fill on his forehead (gone on the branch's hatless build).

**2. Screen blocks at 1.2 m** (block = style_probe's median one-colour run, % of eye-to-chin):
portrait 2.3; his paint itself 3.9 (mean 7.2: patches by anatomy merge more than the
portrait's); at 1.2 m one pixel is already 2.6 % (eye-to-chin ~38 px at 1280×720, 75°); unlit
there 4.5; lit in neutral light 6.7 (tones 16 → 10, L* 20: the dark, flat light merges neighbours);
in the warm light 3.1; in the saloon's close shot 2.2. Light steps and tile light change nothing
measurable. His head texture is imported **without mipmaps**, so at 1.2 m each pixel is one texel
of ~7 (point sampled: it shimmers as he turns); with mips the shader reads level 2–3.
Tried at 1.2 m (`t2_sampling.png`: point | averaged mips | medoid mips, each level's texel one of
its four real colours): blocks 6.6 / 6.3 / 6.5 %, tones 8 / 8 / 8, detail 6.1 / 4.9 / 6.7. Mips
don't make the blocks smaller: averaged ones only soften (less pixel noise, a little blur), the
medoid ones stay crisp like point sampling. Turned a degree, ~22 % of face pixels change in all
three (the turn moves him; this measure doesn't separate shimmer from motion).
So: at conversation distance the frame can't hold the portrait's blocks; the paint's own
blocks and the light's darkness make them bigger still. What would help: paint blocks sized to
the distance they're seen at, and a light that keeps a face's tones apart (the warm one does).

**3. The hat:** `style_hat._ring` put every ring's back half in front (`where(cos > 0, -hf, hb) *
cos`), so the old hat had **no back**: its brim stopped behind the crown, his hair showed through
(the "hat sucks"). `hat_proto.py` patches it for itself only (the approved build's hat-hair line
comes from the folded ring, so `style_hat.py` is unchanged until Sean says). The prototype
(`assets/people/lab/hat_cattleman_*`, worn by `art_lab --hat=lab:hat_cattleman`; the game's hat
untouched): fitted to Sean's brim and band marks (rms 44 → 23 px once the brim may droop at the
sides), crown 12 cm, band 16 mm with brass studs, tipped back 15°, a designed paint (the portraits'
browns in 16 mm squares, a lighter bound edge, a darker underside) instead of the portraits'
colours projected. In the warm light the brim shades his brow and eyes and both stay readable.
Left: the forehead's hat-hair fill shows under the brim front-on; the crown a little tall;
not yet in the game build.

**4. Features:** *grey moustache*: the test "darker or greyer than skin, upper lip only" found 105
of the older man's vertices; "differs from skin (ΔE > 16), lips left out, grown over the surface
into the drooping ends" finds 534 (all of it), and 527 on the bold cowboy (his ends too).
*Hair colour*: 44 % of his hair is seen by no portrait and filled (dark, L* 19); what the portraits
paint is L* 16–30 by view against their grey hair's L* 44 (de-light, the brim's shadow, the
backdrop at the edges). *Silhouette*: ragged where the projection takes the backdrop at grazing
angles and where views alternate along thin triangles. *Profile jaw*: his chin matches the
profiles within 5 mm; under it his throat stands 25–43 mm forward of theirs (the bust fills in
under the jaw). Fixes proposed, not made: the colour-independent moustache test in relief; hair
matched per source to the portraits' hair and unseen hair filled from seen hair; the profiles'
silhouettes as shape-fit targets for the jaw and throat.

**5. Controlled comparison** (`t5_three_quarter.png`, `t5_front.png`; same man, pose, framing):
the warm light made to the portraits is closest on every measure but chroma (three-quarter: L*
30 vs 31.6, L sd 16.6 vs 17.2, tones 16 vs 16, patches 3.1 vs 2.3, chroma 47 vs 40); neutral is
far off (L* 20, tones 8, chroma 26); the saloon matches lightness but runs hot and noisy (chroma
50, detail 13 vs 9). The hat changes the face's numbers little; its look is the sheet's.

**Sean, 2026-10-14, after the investigation:** "I'm not worried about the hairstyle or colour being
the same nor the character looking exactly the same — this is just the art style." So likeness
(hair colour, the jaw's line, the exact moustache) is not the aim; the painted look is: block
size and shape, tones, clean edges, the light's warmth and contrast, colour strength.
