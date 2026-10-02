# Art review: why Salt Creek doesn't look like the paintings yet, and the shortest way there

Reviewed 2026-10-02 by a fresh session that had not seen the art work before. Scope: a review
only. Nothing in the game was changed; the experiments below were rendered from an untracked copy
of `tools/screenshots.gd` and their renders were scored with the judge's own measures without
writing a round. Pictures are in `docs/screenshots/art_review/`.

Read first: DESIGN.md §4, the art status entries in CLAUDE.md from 2026-09-28 on, the judge's
history (`docs/screenshots/judge/history.md`), judge round 25, the character lab rounds, the
backdrop sheet, and the code that makes the look (`src/render/`, `body_skin.gdshaderinc`,
`ground.gdshader`, `sky.gdshader`, `pixel_art.gd`, `backdrop.gd`, `main.gd`, `judge.py`,
`reduce.py`, `finish.py`).

## 0. The answer in short

The squares are not the problem any more. The paintings are **cinematic, photoreal pictures with a
mosaic laid over them**: deep shadows, blooming lamps and sun, haze with distance, every surface
full of real detail, and then blocks of colour. We built the blocks first and best, and the picture
under them is flat, mid-grey-brown, sharp to the horizon and filled with random noise where the
painting has folds, boards and ruts. Five root causes, in order of how much a viewer sees them:

1. **The light has no range.** Our frames have fewer deep shadows and more blown highlights than
   the paintings, no bloom round anything, and no haze down the street. Several of our brightest
   things (lamp chimneys, the painted man, the backdrop) are deliberately clamped under display
   white, so they can never glow.
2. **The squares are filled with noise, not detail.** The texture factory divides the painting's
   light out of each material and pushes random square-to-square differences back in; the code
   textures, the ground, the sky and the people's paint all add random mosaic. The painting's
   squares differ because the thing under them differs.
3. **Our blocks are the wrong kind far away.** The painting's blocks are big and soft-edged up close
   and fade into a smooth, hazy picture at distance; ours are hard, flat, and made *chunkier* far
   away (`min_square_px`, the backdrop's 0.3° texels, the sky's 100 squares a radian, the clouds).
4. **The man is a mannequin wearing a photocopy.** Projecting the painting's lit pixels onto a body
   that doesn't match them, then taking the dominant colour per square and lighting him in four
   steps, gives a flat, blotchy face however many rounds are spent on the parameters. Eleven lab
   rounds and about 22 commits went into this pipeline; it has reached its ceiling.
5. **The frame's big shapes are placeholders.** Boxes for horses, clones for every townsperson, the
   same plank texture repeating every two metres, flat cloud slabs. The paintings' character is in
   exactly these shapes.

The judge has helped with (1) a little and hurt with (2) and (3): its "mosaic" and "tile size"
measures reward random block noise (adding 6 px random blocks to round 25 scores **0.434**, better
than any real round), and it compares the two pictures region by region although their
compositions differ, so it has asked for chunkier far squares where the painting has a near sign.

The basic approach (textures at a fixed density on 3D surfaces, nearest filtering, 1280×720 or
native) is right and should stay. What's missing sits on either side of it: a cinematic picture
underneath (light, haze, real detail, real shapes) and a light screen-space finish on top (bloom,
grade, soft block edges). The shortest route: a light-and-grade pass first (one session, the
largest visible change), then fix the judge so it can't be gamed, then textures with real detail,
then the characters by image-to-3D when the Tripo key arrives, then props.

## 1. What the paintings are, looked at closely

Both paintings were studied at 3× (crops in `docs/screenshots/art_review/`, left halves).

**The blocks.** They are screen-aligned rectangles with slightly ragged, soft edges, like dabs, not
tiles glued to the surfaces: the lamp chimney, the hand, the cup and the face are all cut into
axis-aligned blocks that do not tilt with the surface (`01_lamp`, `02_face`, `05_table_hand`).
Their size falls with distance roughly as perspective would make a fixed real size fall (the near
ground in the street is ~11 px at 1280 wide, the coat 6–8 px, the horse 3–4 px, the men down the
street 2–3 px), so a texel density fixed in metres gives about the right *sizes*. But far off the
blocks dissolve: the bartender, the far mountains, the far street and the sky are nearly smooth and
soft (`04_far_bar`, `08_mountains_sky`, `10_far_street`). Inside a block the colour is not flat: a
gentle gradient and faint texture survive (measured below). The painting is sharp where it is
near and soft where it is far, like a photograph with depth of field and haze.

**The colour in a surface.** The coat is dozens of browns in the shape of folds and lapels; the
boards of the general store are each a different grey-tan, weathered unevenly; the ground is
light and dark in ruts and hoof marks with pebbles and grass tufts (`03_coat`, `06_boards_sign`,
`07_ground`). Square-to-square variation is large (the judge's "detail" is 5.7–6.8 dE) but it is
*structure*: nowhere in the paintings is there random mosaic noise on a flat field.

**The light.** Deep, warm shadows (the saloon has 41 % of its pixels under L* 10), a few very bright
things (lamps, moon, sun) that **bloom** into the air round them, lamp glow on the table and the
faces, atmospheric haze that dims and warms the far room and turns the far street to dust and
silhouettes, long sunlit porches with dark undersides in the street. In the street, the brighter a
thing is the more colourful it is (correlation of chroma with lightness 0.56); the sky is warm even
at the top (b* +16), the clouds are cream-gold heaps near the horizon, not white slabs.

**Edges.** No drawn outlines. Silhouettes are strong because the values on either side differ
(dark hat against lit wall, lit hand against dark coat), and the quantiser snaps those edges to
block boundaries.

**Detail and where it goes.** Every object is a specific thing: a saddle with stitching, a hay bale
with straw, a bentwood chair, bottles with labels, a stag head, framed pictures, a rug, cards on
felt. The detail is densest on the near subject and the lit mid-ground, and dissolves far off.

Numbers (both pictures at 1280×720, CIE L*, whole frame):

| | L* 1 % | 5 % | 50 % | 95 % | 99 % | share < L* 10 | share > L* 80 | chroma | chroma–L* correlation |
|---|---|---|---|---|---|---|---|---|---|
| saloon painting | 0 | 1 | 12 | 43 | 75 | 40.6 % | 0.6 % | 22.7 | 0.85 |
| ours, round 25 | 2 | 4 | 15 | 56 | 76 | 28.2 % | 0.8 % | 22.8 | 0.76 |
| street painting | 1 | 6 | 37 | 71 | 84 | 8.5 % | 1.6 % | 26.5 | 0.56 |
| ours, round 25 | 4 | 8 | 37 | 85 | 89 | 6.9 % | 9.8 % | 24.3 | 0.12 |

The street's last two columns are the clearest single statement of the light problem: our bright
things are pale (sky, clouds, far fronts) where the painting's are gold.

How flat the blocks are (mean horizontal run of near-identical colour, px at 1280, by region of a
6×8 grid): the paintings run 2–5 px at a tight threshold and 5–30 px at a loose one, everywhere,
including the sky; ours run 3–20 px tight and 10–150 px loose, with the sky, ground and boards as
large perfectly flat fields. Our blocks are flat and hard; the painting's carry a little gradient
and texture inside and have soft edges. The eye reads the first as a game, the second as paint.

## 2. What ours is, looked at the same way

`00_saloon_whole`, `00_street_whole` and the crops' right halves.

- **Saloon:** everything is the same mid brown at the same brightness: the back wall, the bar, the
  far people and the man's coat sit within a narrow value band. The lamp's chimney and the bottle
  have no glow round them. The room reads as fully lit by a soft ambient with lamps as decorations.
  The man's face is a flat orange with brown blotches and painted-on eyes (`02_face`); his coat is
  camouflage blobs, not folds (`03_coat`). The far people are the same man, same paint, in vests.
  The table top's grain is fine and low contrast with a smooth light falloff across it.
- **Street:** the frame is high-key and pale. The sky is a blue-grey gradient under white-cream
  cloud slabs that look like Minecraft clouds; the sun is a flat disc. The far mountains are a
  short, hard-blocked, saturated strip with no haze (`08_mountains_sky`). The boards are a pale
  grey-tan 2 m texture repeating with blotchy noise (`06_boards_sign`). The ground is a flat ochre
  with a repeating pebble pattern; the ruts barely read (`07_ground`). Horses are boxes, people are
  clones in identical poses (`09_porch_people_horse`). Nothing is dim or soft with distance
  (`10_far_street`). The boardwalk under the saloon's porch is black where the painting's is sunlit
  (the sun runs along the porches at 17.6).

What a viewer notices first, in order: the flat light and missing glow; the pale sky and cloud
slabs; the clones and boxes; the man's face; then, a long way behind, anything about square size.
The judge's ranking is nearly the reverse (tile sizes and mosaic first, light fourth).

## 3. Root causes

### 3.1 The light has no range (`01_lamp`, `11_grade_mock_saloon`, `11_grade_mock_street`)

Causes in the code:

- `config/day_cycle.tres`: `ambient_energy_night` 2.5 (with `ambient_light_sky_contribution` 1.0),
  so the night room is filled from a dark sky scaled up; the saloon's own `night_ambient` 0.1 plus
  24 shadowless lamps (`SaloonDressing`) fill the rest. Nothing in the room is dark.
- Glow is on (`glow_intensity` 0.6, `glow_bloom` 0.05, `glow_hdr_threshold` 1.2) but almost nothing
  crosses the threshold, because the brightest things are **clamped under display white on
  purpose**: the chimney glass (`chimney_glass.gdshader`), the painted man (`body_skin`,
  `painted_to_scene`) and the backdrop all run their colours through `aces_inverse()` so they land
  exactly at a chosen sRGB value. That inverse maps display white to a scene value of exactly 1.0
  (checked against the shader's constants), so nothing drawn that way can ever reach the 1.2 glow
  threshold: tonemap-proof and bloom-proof. The painting's single most characteristic feature, the
  halo round every lamp and the moon, cannot happen on them.
- Street: `fog_density` 0.0035 and `fog_aerial_perspective` 0.25 give no visible aerial haze; the
  sky shader draws its own haze band only. The far mountains and far street are as sharp and
  saturated as the near ones. The sun is a disc (`sun_color * 8.0`) with a painted halo, no bloom.
- Grade: ACES at exposure 0.85–1.0 with `adjustment_contrast` 1.08 lands the street at median L* 37
  (right) but with 9.8 % of pixels over L* 80 (the painting 1.6 %) and bright things desaturated.
- Sun path: at 17.6 the sun runs along the porches (`sun_tilt_degrees` 35 on an east–west street),
  so the boardwalks are in shadow where the painting's are lit. Already noted as open with Sean.

A mock grade in Python on round 25 (blacks pulled down, a power curve, bloom off anything bright,
+15 % saturation) moves the saloon most of the way to the painting's mood in one step
(`11_grade_mock_saloon`). It is crude and overdone (and the judge scores it *worse*, see §5), but
no texture or square change in 25 rounds moved the picture as far. Engine versions of these changes
are in §4.

### 3.2 Squares filled with noise, not detail (`03_coat`, `06_boards_sign`, `07_ground`, `12_judge_blocknoise`)

- `tools/textures/reduce.py`: `flatten()` divides out the painting's broad light at `FLATTEN` 0.85
  (so per-board colour differences, the thing the painting shows, are mostly removed), then
  `mosaic()` pushes each texel's difference from a 1 px blur by `MOSAIC` 2.0 (random fine noise
  amplified), then a 10–14 colour palette. The result is a 64×32 texel (2 m × 1 m) tile that repeats
  across every wall: a plank wall shows the same knot every two metres, and no board differs from
  its neighbour the way the painting's do.
- `PixelArt._mosaic()` (code textures), `ground.gdshader` (`hash` pebbles and `fine` noise),
  `sky.gdshader` (`sky_mosaic` per cell), `finish.py` (dominant colour per square), the backdrop's
  "gentle mosaic": each adds *random* square-to-square variation to satisfy the judge's "detail"
  measure. Random variation on a flat field reads as static or dirt, never as paint.
- The judge probe proves the trap: round 25 plus random 6 px block noise scores 0.434, the best
  score ever recorded, and looks worse (`12_judge_blocknoise`).

What the painting does instead: the square-to-square change is the surface's real structure
(folds, board edges, weathering, ruts, the lamp's falloff) quantised. The texture factory's
principle ("realistic detail first, then tiles") is right; `reduce.py` undoes the first half.

### 3.3 The wrong kind of blocks far away (`04_far_bar`, `08_mountains_sky`, `10_far_street`)

- `min_square_px` 4 (`tiles.gdshaderinc`, trial C, round 20) makes far surfaces *chunkier*: squares
  of 2–8 texels, each one texel's colour, so the far street is a hard mosaic where the painting's
  is a soft hazy picture. Trial C beat A and B on the judge by 0.03, which is inside the judge's
  noise (a 60 px shift of the painting against itself scores 0.15).
- The backdrop is cut at 0.3° per texel (~7 px at 1280) with a palette per layer and no haze over
  it (the shader's own `haze` mixes a flat colour): the painting's far spires are soft, low-contrast
  and violet-pink with atmosphere, ours are a crisp saturated strip.
- The sky is snapped to 100 cells a radian (~7 px squares) and the clouds are drawn in those cells
  with three flat tones: slabs. The painting's clouds are soft heaps with their blocks only at the
  edges, and its sky is a smooth gradient.
- Our block edges are perfectly hard and the colour inside perfectly flat (nearest texels, one
  colour lit as one). The painting's blocks are soft-edged dabs with a little gradient inside.
  `tile_ragged` moves the edges but keeps them hard.

The 2026-10-01 reading "tiles of a fixed real size on the surfaces, each lit as one flat colour"
got the near field right and the far field wrong: in the painting, distance makes things soft, not
blocky, and the blocks are screen-aligned dabs rather than surface tiles. This review reopens that
part of DESIGN.md §4 ("What the painting's pixels are") and says so explicitly; the per-texel
lighting itself is harmless and can stay.

### 3.4 The man is a mannequin wearing a photocopy (`02_face`, `03_coat`, character lab round 11)

The pipeline: MakeHuman body → image model paints him in six views (and six head views) → outlines
and faces warped to fit the clay guides → projected into UV space → dominant colour per square →
drawn over with `face_draw.py` (eyes, brows, moustache, mouth drawn texel by texel) → shown with
`paint_look` (self-lit 0.35, gain 4, light stepped in 4 levels, no ambient, matt). Each step was
reasonable on its own; together they guarantee a flat, blotchy man:

- The painted views carry the painting's lighting baked in, so the game cannot light him. The
  shader then half-lights him anyway ("by brightness only", eased off at `paint_limit`), and
  posterises the result into four steps. A painting lit twice and posterised reads as paint by
  numbers.
- The views never agree with the mesh or each other (overlap 0.47–0.98, head cells shuffled every
  run, a goatee in some), so the projection smears; the fixes (`MIN_OVERLAP`, `face_warp`,
  `MAX_FACE_FIT`, hand-drawn eyes) treat symptoms.
- "Dominant colour per square" throws away the gradient inside each block that the painting keeps,
  and `SHAPE_COLOURS` (coat 12, face 16) flattens the dozens of browns the painting's coat has.
- The MakeHuman face is a different face from the painting's; the painting's shading (cheekbone,
  brow shadow, eye socket) is drawn onto the wrong geometry.

Compare `02_face`: the painting's face is a lit portrait under blocks; ours is blocks with a face
drawn on them. Eleven lab rounds moved the overlap and the eye positions and did not change that.
Everyone else in both frames wears this same man.

### 3.5 The frame's big shapes are placeholders (`09_porch_people_horse`, `06_boards_sign`, `08_mountains_sky`)

Horses are boxes with box legs; hay is a box; every townsperson is the outlaw's body in his paint
with a vest; the wagon, barrels and crates are the simplest shape in one repeating texture; the
clouds are slabs; the store boards are one 2 m tile. The paintings are full of specific, well-made
objects, and "low-poly" in DESIGN.md means readable simple models, not boxes. The painting's horse
at 1280 wide is ~150 px tall; a 500-triangle horse with a baked texture reads at that size.

## 4. Is the basic approach right? (experiments)

**Yes, as the base; no, as the whole.** Textures at a fixed density on 3D surfaces, nearest
filtering, rendered at 1280×720 or native, give blocks of the right size that tilt and shrink with
perspective, which is what the painting's near field shows. The things to change sit under and
over it, not in it:

- **Under:** a cinematic picture. Lighting with range (dark room, bright lamps that bloom, warm
  bounce), haze with distance, real detail in the textures, real shapes for props and people.
- **Over:** a light screen-space finish. Bloom and a grade (contrast, saturation of lit colours);
  later, possibly, a soft edge on block boundaries and a per-material palette snap. Not a
  screen-space mosaic: trial A (round 15) was right to lose. The blocks should stay where the
  textures put them.

Experiments rendered here (Forward+ on lavapipe, from the untracked harness; scored with the
judge's measures; renders in `docs/screenshots/art_review/exp_*`):

| render | saloon score | street score | saloon: median L\*, share < L\* 10, share > L\* 80 | street: median L\*, share > L\* 80, chroma–L\* corr. | what the eye says |
|---|---|---|---|---|---|
| the painting | | | 12, 41 %, 0.6 % | 37, 1.6 %, 0.56 | |
| baseline (round 25, re-rendered) | 0.572 | 0.650 | 15, 28 %, 0.8 % | 36, 9.0 %, 0.13 | as round 25 |
| per-texel light off, min square 0 (`14_exp_flat_*`) | 0.597 | 0.644 | 15, 28 %, 0.8 % | 36, 9 %, 0.13 | saloon all but identical (10 % of pixels change by more than 12/255, mostly the lamp's brass); the street's far field goes finer and *closer* to the painting's soft distance |
| glow screen 0.7, threshold 1.0, hdr scale 1, room ambient ×0.35, lamps ×1.4, contrast 1.15, saturation 1.12; street exposure 0.75, fog ×2.5, aerial 0.7 (`13_exp_glow_*`, middle) | 1.124 | 1.015 | 25, 5 %, 1.9 % | 49, 11.8 %, −0.07 | the whole frame blooms: brighter, not deeper |
| glow additive 0.9, threshold 0.85, hdr scale 2, levels 1–5, ambient ×0.2, lamps ×1.7, contrast 1.22, saturation 1.15 (`13_exp_glow_*`, right) | 1.842 | 1.392 | 42, 0.3 %, 7.7 % | 61, 24 %, −0.30 | a wash of orange light |
| sun tilt 10 instead of 35 (`15_exp_sunsouth_street`) | | 0.692 | | 36, 9 %, 0.13 | the sun sits higher and left; the boardwalk under the saloon's porch is still in shadow; inconclusive on its own |
| the Python mock grade of §3.1 (`11_grade_mock_*`), for comparison | 0.693 | 0.749 | 10, 48 %, 1.1 % | 33, 3 %, 0.41 | much closer in mood; the sky still wrong |

What the experiments say:

- **The per-texel lighting and the far-square rule are nearly invisible.** Turning both off changes
  the saloon by a hair and the judge by 0.02, and moves the street's far field toward the painting
  (`14_exp_flat_street`). Two full sessions (2026-10-01 texel lighting, the merge, and item 3's
  five trials) went into them. They can stay on, but they are not where the look lives.
- **Bloom cannot simply be switched on.** Both engine grades flooded the frame, because with the
  lamps lighting every near surface close to white in scene-linear, a glow threshold at or under
  1.0 blooms the table, the man and the walls, and the interior probe's ambient cut and the lamps'
  boost add light rather than depth. The painting's halo belongs only to true emitters. To build it
  (recommendation 1) the chimneys, flames, the moon and the sun must be *un-clamped* to well above
  white (3–6 in scene-linear) while the glow threshold sits above lit surfaces (1.5–2.0) and the
  exposure comes down so the room's midtones sit where the painting's do (median L\* 12, not 15).
  That is shader work on `chimney_glass`, the flame material and `sky.gdshader`, not an
  environment toggle: still one session, but a careful one. The Python mock stands as the target
  for its result: its bloom came only off the brightest 15 % of the frame.
- **The judge punishes every one of these grades**, the good mock included, because darker shadows
  and brighter lamps move the 3×3 region means. It would have vetoed the lighting pass. See §5.
- **The sun's tilt alone does not light the boardwalks**; the painting's sun is slightly left of the
  street's axis and a hand's width up. This needs the street's heading or the sun's azimuth
  changed with it, with Sean (gameplay's `day_cycle.tres`), and is small either way.

Notes on the alternatives asked about:

- **A different internal resolution:** no. The painting's near blocks are 6–11 px at 1280; at
  640×360 they would be 3–5 px and smear (round 5 showed this). Keep 1280×720 or native. One
  caveat: with `integer_scaling` off, a 1280×720 frame on a 1920×1080 window is nearest-scaled
  by 1.5, so every other pixel is doubled and every edge is uneven. Since the blocks now come
  from the textures, the pixel pipeline's upscale adds nothing and costs cleanliness: render
  native by default, or keep integer scaling on.
- **Density changing with distance:** not needed for size (perspective already does it) and
  wrong in direction if it makes far things chunkier. What distance should do is soften and haze.
- **A post-process palette:** a per-material palette is already in the textures. A global
  palette snap of the frame would flatten the lighting gradients the painting keeps; at most a
  gentle posterise inside materials, tested by eye.
- **Outlines:** no. The paintings have none; their edges come from value contrast, which the
  light pass restores.
- **A different tonemap:** ACES is fine for the midtones; its highlight desaturation is what turns
  the gold sky and clouds pale. Test AgX or Filmic with a lower white, and in any case stop
  clamping emitters under white so bloom can take the top end.

## 5. Where the judge misleads

Probes (round 25's renders modified in Python, scored with the judge's own measures, lower is
"closer"):

| probe | saloon | street | what a viewer would say |
|---|---|---|---|
| the painting itself | 0.023 | 0.031 | identical |
| the painting shifted 60 px | 0.159 | 0.144 | identical style, same picture moved |
| the two paintings swapped | 0.885 | 0.885 | perfect style, wrong picture |
| round 25 (reference) | 0.570 | 0.645 | ours |
| round 25 + random 6 px block noise | **0.434** | **0.562** | uglier, noisier |
| round 25 + per-pixel noise | 0.865 | 0.976 | uglier |
| round 25 blurred 3 px | 1.215 | 1.431 | softer, same light |
| round 25 + the mock grade of §3.1 | 0.693 | 0.749 | much closer in mood |
| the painting in greyscale | 0.965 | 0.973 | right style, no colour |

So:

1. **Random block noise scores better than any real round.** The "mosaic too plain" (dE to a 3 px
   blur) and "tile size" (autocorrelation of high-passed luminance) measures reward any
   square-to-square variation, structured or not. Several rounds added random mosaic to satisfy
   them (`reduce.py` `MOSAIC`, `PixelArt.mosaic`, `sky_mosaic`, the backdrop's mosaic).
2. **Composition outweighs style.** The two paintings swapped score worse than our render, because
   the score is mostly region-by-region means of L*, a*, b* on a 3×3 grid of two different pictures.
   "Top-right tiles down 0.3× the painting's" compared our sky with the painting's livery sign and
   hay, and led to `min_square_px`.
3. **Moving toward the painting's light can score worse.** The grade mock darkens the frame
   (median L* 10 vs 16) and the region means punish it, although every viewer would call it closer.
   Darker shadows and brighter lamps shift means; the judge has no measure of *range*.
4. **Differences of 0.01–0.03 are noise.** Shifting the painting against itself costs 0.15. Rounds
   5–25 chose between trials on differences smaller than that.
5. **Nothing is measured that a viewer notices first:** bloom and glow, the share of deep shadow
   and of blown highlight, whether bright things are colourful (chroma–L* correlation), haze with
   distance, soft versus hard block edges, structured versus random variation, repetition, or
   whether the people and props look like anything.

The judge's *harness* (fixed staged views, side-by-side panels, a kept round per change) is
valuable and should stay. Its *measures* need replacing (§8, recommendation 2).

## 6. The characters

Target: a man who reads, at ~55×60 px of face, as the painting's does: a lit portrait with real
skin shading, dark bold features, a white collar, a coat of many browns in folds, under blocks.

Routes:

- **Current: MakeHuman + paint bake from the painting.** At its ceiling (§3.4). The one thing to
  keep is the staging and the lab harness. Stop iterating the projection, alignment, face-drawing
  and square-rule parameters.
- **Tripo image-to-3D (key coming).** The strongest route to "looks like the painting's man",
  because the mesh and texture are made together from one consistent picture, so the face's
  shading sits on the face's geometry. Risks: topology and rig unknown (the Blender fit to our 17
  segments and hitboxes is real work, 2–3 sessions for the first man, then cheap per man);
  textures come lit, so a de-lighting step is needed (fal's or a simple broad-light division as
  `reduce.py` does, kept gentle); hands will be poor (keep ours). Start with one man and judge him
  in the lab before building the fit for everyone.
- **A hybrid that needs no key:** keep the MakeHuman mesh and fit, but replace the texture source
  with a *flat-lit* full-body turnaround painted by the image model in one sheet (it already follows
  our outline well: round 4), projected as now but **without** the painting's own pixels, without
  dominant-colour squares (keep an average plus the per-shape palette at 24–32 colours), and shown
  with ordinary lighting (`self_lit` 0, `light_steps` 0, ambient on). Then the game's light and the
  finish pass do what the painting's quantiser did. One session; most of the pipeline exists.
- **Whatever the route**, two cheap things fix the frames now: give the stand-in townsfolk their own
  colours and hats (clones are the most visible flaw in both pictures), and light the seated man
  with one strong warm key from the lamp and a dim cool fill, no posterised steps.

Recommendation: the hybrid now (it also tests the lighting and finish on a person), Tripo for the
first real man when the key is in, and the fal style LoRA only for consistency of the image-model
*portraits and turnarounds* (it is not needed for textures or the backdrop).

## 7. Tools: keep, change, stop

| tool | verdict | why |
|---|---|---|
| `ShotMatch` / `StreetMatch` staging, lab stage | **keep** | the fixed views are the review's backbone |
| `tools/judge.py` harness (render, panel, rounds, history) | **keep**, replace the measures | §5 |
| `tiles.gdshaderinc` per-texel lighting, `tile_ragged` | keep, low priority | right in the near field, barely visible (`14_exp_flat_saloon`) |
| `min_square_px` | **turn off** (0) or 2 | makes far things chunkier where the painting goes soft |
| `sky_squares`, `sky_mosaic`, the cloud slabs | **stop** | the painting's sky is smooth; replace with a painted cloud layer and bloom |
| texture factory (`paint_textures.py`) | **keep** | the right idea |
| `reduce.py` flatten + mosaic + 2 m repeat | **change** | keep the light and per-board colour, drop the random push, per-board strips |
| `PixelArt._mosaic`, `squares()` | **stop adding noise** | random mosaic reads as static |
| `PropModels` (code props on the grid) | keep for simple props | lamps, crates, barrels are fine; horses, hay, saddles are not code shapes |
| backdrop (`Backdrop`, `reduce_backdrop.py`) | keep, **re-cut softer with haze** | right idea, wrong finish |
| `paint_bake.gd` / `align.py` / `finish.py` / `face_draw.py` | **stop iterating** | §3.4; keep the bake as a projector for the hybrid route |
| `character_lab.gd` | keep | judge every new man in it |
| `DepthMosaic` (`depth_mosaic.gd/.gdshader`) | **delete** | lost, and the wrong idea |
| `outline.gd/.gdshader` | **delete** | the paintings have no outlines |
| `pixel_screen.gdshader` (F6 banded light + dither) | delete or leave off | the painting has no dither |
| `chimney_glass` / `backdrop` / `body_skin` `aces_inverse` clamping | **change** | keep the colour choice, let the brightest parts exceed white so they bloom |
| Tripo client, fal LoRA trainer | keep, run when the keys arrive | §6 |
| Blockade skyboxes (key coming) | try once for the night sky and a cloud layer | a painted sky is exactly what's missing |

## 8. Recommendations, ranked

Effort is in art sessions (a session being one merge-sized piece of work as in CLAUDE.md).

1. **The light and grade pass** (1 session; the largest visible change).
   What: saloon night ambient down (the interior probe's night value and `ambient_energy_night`,
   to 0.2–0.3 of now) and exposure down so the room's median lands near the painting's L\* 12;
   **emitters un-clamped**: chimney glass, flames, lantern glass, the moon and the sun drawn at
   3–6 in scene-linear instead of through `aces_inverse`, with the glow threshold *above* lit
   surfaces (1.5–2.0, bloom 0.1–0.2, screen blend) so only they bloom (the experiments show a
   threshold at or under 1.0 floods the frame); street: aerial perspective 0.6–0.8 and fog density
   ×2–3 so the far fronts and mountains dim and warm, exposure down a little, contrast 1.15–1.2,
   saturation 1.1–1.15 so lit things go gold not cream, and highlight desaturation tamed (try AgX
   or Filmic against ACES); the boardwalks lit at golden hour (sun azimuth or the street's
   heading, with Sean: gameplay's `day_cycle.tres`).
   Why: §3.1. Expected: deep-shadow share toward 40 % in the saloon, highlight share under 3 % on
   the street, chroma–L* correlation above 0.4 on the street, a halo round every lamp.
   Check: those three numbers (judge v2), and Sean's eye on the two shots.
2. **Judge v2: measure style, not composition** (1 session).
   Replace the 3×3 region means and the tile/mosaic measures with composition-free measures: L*
   percentiles and the deep-shadow / highlight shares; chroma–L* correlation; a structured-vs-random
   test (how much of the square-to-square variation survives a 2-texel median: paint survives,
   noise doesn't); block size against depth from the depth buffer (a near band and a far band,
   expecting big near and dissolved far); soft-edge measure (gradient width at block boundaries);
   a repetition measure (autocorrelation of a wall at its texture's period). Keep the panels and
   rounds. Add a "Sean's pick" field so a human A/B is on record each round. Why: §5. Check: the
   probes in §5 must rank the way a viewer would.
3. **Textures with real detail** (1–2 sessions).
   In the factory: paint per-board strips (a 4 m × 0.25 m board with 6–8 variants) and let members
   pick a variant by ID, so no two boards match; keep the painting's light and per-board colour
   (`FLATTEN` 0.3 or less), drop `MOSAIC` to 1.0 (no push); 24–32 colours; the ground as one 8 m
   top-down tile with ruts, hoof marks and grass, de-tiled by two layers; the table top at the
   painting's warmth and grain contrast. Why: §3.2. Check: structured-vs-random measure up, the
   `06`/`07` crops side by side.
4. **Far field: soft, hazy, smooth** (0.5 session).
   `min_square_px` 0; backdrop re-cut at half the texel size with a haze that follows the fog's
   colour and density, less palette; the sky smooth (`sky_squares` 0), clouds from a painted cloud
   texture on a dome (image model, or Blockade once the key is in) with soft edges and bloom on the
   sun. Why: §3.3.
5. **People now, people later** (0.5 session now; 2–3 sessions when Tripo's key arrives).
   Now: the hybrid of §6 for the seated man (flat-lit sheet, ordinary lighting, no steps, no
   dominant-colour squares) and varied colours, hats and poses for the townsfolk. Later: the first
   Tripo man through the Blender fit, judged in the lab before scaling up.
6. **Props with form** (1–2 sessions). Horse with saddle, hay bales, barrels with hoops, the stag,
   bentwood chairs, bottles with labels: image-to-3D (Tripo or Meshy; props need no rig) or
   Blender-built, decimated, textures reduced through the factory's new reducer. Why: §3.5.
7. **The finish pass** (1 session, experimental). A full-screen pass that softens block edges by
   about one render pixel and adds a faint in-block gradient (from the lighting, not noise), tested
   at native resolution against `02_face` and `05_table_hand`. Only after 1–4; it is the icing.
8. **Native by default** (0.2 session). Render at the window's size unless the frame rate asks for
   less; or turn integer scaling on. Why: §4, the 1.5× nearest upscale.

## 9. Stop doing

- Adding random square-to-square variation anywhere to raise the judge's "detail".
- Choosing between trials on judge differences under 0.15.
- Iterating the man's projection, alignment, face-warp, dominant-colour and face-drawing
  parameters, and repainting head sheets.
- Making far things chunkier.
- Clamping bright things under display white through `aces_inverse`.
- Treating "tiles on the surfaces lit as one colour" as the style. It is the style's smallest part.

## 10. Suggested order for the next merges

1. Light and grade pass, saloon (ambient, lamps, bloom, unclamped chimneys and moon).
2. Light and grade pass, street (haze, exposure, saturation, sun bloom, sun tilt with Sean's OK).
3. Judge v2 measures and the probes as its tests; a human pick per round.
4. Sky and far field (smooth sky, painted clouds, backdrop re-cut with haze, `min_square_px` off).
5. Factory reducer v2 and per-board strips for the street's fronts and the saloon's walls.
6. Ground and table textures through the new reducer.
7. The seated man by the hybrid route; townsfolk varied.
8. Props with form: horse and saddle, hay, barrels, chairs, bottles.
9. The first Tripo man (when the key is in), judged in the lab.
10. The finish pass, at native resolution.

## Appendix A. How the experiments were made

- Godot 4.7.2 Linux, Forward+ on Mesa lavapipe (software Vulkan) under xvfb, 1280×720, the
  shot-match views staged by `tools/screenshots.gd`'s own code. The harness was an untracked copy
  of that file plus an `--exp=` switch applied after a view is staged (the exact settings are in
  the table of §4); it was deleted after the renders. The baseline it rendered is pixel-identical
  to judge round 25 (mean difference 0.23 of 255). The renders are in
  `docs/screenshots/art_review/fwd_base`, `exp_grade+lamps`, `exp_grade2`, `exp_flat`,
  `exp_sunsouth`.
- Scores use `tools/judge.py`'s `measure`, `differences` and `score` as they are, without writing a
  round or a history line.
- Mocks and probes are Python (Pillow, numpy, scipy) on round 25's PNGs.

## Appendix B. The measurements behind §1

Mean horizontal run of near-identical colour (px at 1280; threshold 24 of 765 summed RGB
difference), 6 rows × 8 columns, top row first:

```
saloon painting            ours, round 25
 9.6 14.8 12.0  8.5  7.4  4.8  6.7  7.3      19.7 23.0 17.2 22.2  6.4 10.0  7.5  7.9
 5.1  5.5  6.3  7.7 10.5  7.5  2.9  3.3      13.9 15.2 11.2 11.3 11.1 25.9  5.1  6.6
 5.7  5.0  6.8  5.9  5.2  4.5  5.9  7.4       8.1  7.2  6.9  5.3  9.7 19.9 10.7 17.1
 9.6 28.9  6.9 11.9  9.7  6.3 13.1  9.4       8.7  9.3  7.8  8.9 11.1 11.8 24.3 14.3
 9.8 22.9 10.6  8.3 11.0  6.2  8.5 10.1      10.5 15.8 17.5 10.7 25.6 17.2 35.4 14.9
 9.2 34.1 21.8 18.9 12.4 12.8 11.8 17.1      14.1 16.4 23.4 37.6 22.5 37.9 43.8 29.4

street painting            ours, round 25
 4.0  3.5 10.2 11.2 12.0 17.0  8.4  3.9       8.3  5.3  8.2 23.2 41.6 26.3 30.0 29.4
 6.2  5.1  2.8  2.5 12.7  6.8  3.0  2.8      11.5  6.6  3.6 18.4 30.2 21.9 11.8  5.4
 4.0  4.7  3.1  2.7  5.5  3.3  2.7  3.7       8.1  7.1  5.2  5.0 15.1  6.4  5.1  3.9
 4.3  4.8  2.8  2.3  2.7  3.1  2.6  3.5       7.0  8.1  4.3  5.7  6.0  4.5  3.4  4.2
 5.0  4.3  3.5  3.5  3.5  3.6  3.7  3.0      22.5  8.4  5.9  8.0 16.5  7.8 13.8  9.0
 5.0  4.1  6.0  5.9  5.9  5.8 12.0  8.0       8.3  6.6 10.6 12.1 12.7  7.8 12.0 11.7
```

At a tight threshold (6) the paintings run 1.2–2.8 px nearly everywhere (their blocks carry a
little gradient and texture inside); ours run 3–20 px (flat). At a loose threshold (48) the
paintings' sky and far street still change colour every 5–10 px; our sky runs 30–50 px flat.
