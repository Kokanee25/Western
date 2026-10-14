# Brief: the render lab (Salt Creek rendering architecture, Phase 1)

Sean, 2026-10-14 (a prompt passed on): can a purpose-built Salt Creek rendering layer on top of
Godot reproduce the paintings more faithfully and steadily than the current configuration, in a
fully animated, physical game? Art session, branch `claude/art-render-lab`. An experiment: no
production shader, default, golden image or asset changed; nothing paid for; no fourth session.
The lab and how to run it: `experiments/render_lab/README.md`.

Read for it: CLAUDE.md, DESIGN.md §4, `docs/briefs/renderer.md` (the surface-blocks trial),
`character-style-fidelity.md`, the unmerged Prompt 07 style lab (`claude/art-style-sheet-test`,
`docs/briefs/style-lab.md` there), `src/render/`, `src/bodies/shaders/`, `src/world/ground.gdshader`,
`src/world/day_cycle.gd`, `scenes/test_street.tscn`'s environment, the newest status entries,
the 2026-10-14_r1 critic. Not read: the golden images, the judge's history.

## 1. The rendering architecture as it is

```
 ASSETS (offline, CPU)                 MATERIAL SPACE (per fragment, Forward+)          SCENE / VOLUME                 SCREEN SPACE
 ────────────────────                  ───────────────────────────────────────          ──────────────                 ────────────
 texture factory (tools/textures):     texel_grid.gdshader(inc) ── the world's one      sun + moon (cascaded           Environment, in order:
  paintings cut to squares, 32/m,       material: nearest texel at texels_per_meter,     shadows), oil lamps            SSAO ─ glow (HDR 1.7,
  drawn woods, lettered signs  ──────►  min_square_px coarsening far off,  ──────────►  (cube shadows, one atlas  ──►  emitters only) ─ tonemap
 ground: drawn in its shader            light worked out at the texel's centre           cell size), volumetric          ACES, exposure by hour ─
 people: Rodin/Tripo glbs + painted     (tiles.gdshaderinc, P), board seams;             fog (froxels), depth           adjustments (contrast 1.15,
  head/body PNGs (characters'           LIGHT: Godot's own Burley + GGX                  fog, sky.gdshader,             saturation 1.12)
  pipeline), body_mesh fallback        ground.gdshader ── own light(): sun wrap,         painted backdrop cards                │
 props: PropModels in code              sky fill                                         (backdrop.gdshader)                   ▼
                                       body_skin.gdshaderinc ── people: painted                                        GameViewport (SubViewport,
                                        colour run back through ACES⁻¹ (paint-                                          native or F2's sizes)
                                        referred), own light(): Lambert stepped                                               │
                                        (light_steps 4), luminance-only for painted                                           ▼
                                        parts, light_cap 1.35 on the summed light,                                     Screen: nearest upscale +
                                        wounds, eye gain, weathered face                                               pixel_screen (finish, off)
                                       StandardMaterial3D ── guns, lamp glass,                                         Off by default, switchable:
                                        flames, props library                                                          DepthMosaic (O), quantise
                                                                                                                       once (I), ProbeMosaic (V);
                                                                                                                       surface blocks (M) is
                                                                                                                       material space
```

By space: **material space** holds nearly all of the look (texel squares and their size, the
per-texel light, seams, min-square coarsening, the surface-blocks soft edges and bands, people's
paint-referred light and cap, wounds). **World space**: the shadows, the volumetric fog, the
backdrop cards; the probe mosaic's blocks are world-anchored but cut in a screen pass.
**Screen space**: SSAO, glow, the tonemapper and grade, the nearest upscale, and the screen
mosaics (all off by default since Sean's 2026-10-06 "no filters").

What Godot already exposes (used or usable without engine work): every surface's fragment and
`light()` functions (the whole look above is built in them); shader globals for one switch over
every material; per light colour, energy, attenuation and shadows; the Environment (five
tonemappers including AgX, exposure, adjustments, glow, fog, volumetric fog, SSAO/SSIL);
`CompositorEffect` (compute passes on the colour, depth and normal-roughness buffers at five
points in the frame); full-screen quads; SubViewports. What it does not expose without native
work or a fork: a hook **after all lights are summed** for a fragment (`light()` runs once per
light; the ambient and fog are added afterwards in the engine's scene shader, so a material can't
shape its total light, only each light's share: body_skin's cap works around it by un-easing and
re-easing the running sum); an **albedo buffer** (Forward+ keeps none, so no screen pass can tell
paint from light); a **tonemapper per material** (one per camera); the ambient term's colour
inside the material (only `AO` and `AO_LIGHT_AFFECT`).

## 2. What's between the paintings and the game (diagnosis)

Measured on the reference-matched views (`shot_match_saloon`, `shot_match_street`, and the lab's
fixed cameras), never on loose screenshots. The new tool is the **paint probe** (`--probe` /
`--world-probe`): the same frame with every light out, a flat white ambient and no grade, so each
pixel is its surface's own paint; the lit frame set against it splits what the light does from
what the asset is. Numbers: `analyse.py light` (lab) and `paint` (regions of the paintings).

| | painting | production | the paint under it |
|---|---|---|---|
| Street below the skyline: chroma (OKLab, median) | 0.076 | **0.097** | 0.067 |
| Street: red-green (a, median) | 0.045 | **0.061** | 0.027 |
| Street: fine detail (log-lum spread) | 0.537 | 0.521 | 0.504 |
| Saloon: chroma | 0.060 | 0.066 | 0.026 |
| Saloon: fine detail | 0.489 | **0.423** | **0.420** |
| Saloon: light ÷ paint (median / p90) | – | 6.8 / 30 | – |
| Noon store front: pixels with a channel clipped | – | **25 %** | – |

**Asset problems** (the largest). The saloon's missing detail is in its textures, not its light:
the paint under the frame already has the frame's detail (0.420 against 0.423; the light keeps
91 % of it), both short of the painting's 0.489; the bar front's squares are 4–5× the painting's;
the background men are smooth mannequins and the seated man's face is hard orange and black
patches (the critics, every round); the bottle, lamp and cup are plain low-poly. The characters
session's own diagnosis of the portrait men (shape from the plain photos, squares cutting across
features) stands; the face's light was fixed on 2026-10-14 (`light_cap`).

**Rendering problems.** (1) *The light's colour replaces the paint's.* The street's paint is
very nearly the painting's own palette (pale grey weathered boards, red brick, a pale road; the
probe board), and the low sun's orange multiplies it into one brown-orange: hue turned 16°,
chroma ×1.46, the red-green axis a third past the painting's. In the lab, golden hour turns hues
23° and inflates chroma ×1.6; the lamps turn them 32° (but darkly). (2) *Noon clips:* a quarter
of the store front and road at noon has a channel at 255 (the lab's façade: half), the ACES
shoulder plus contrast 1.15 over a pale road in a 1.6 sun. (3) *People and world are lit by
three different rules* (Burley on the world; the ground's own wrap and sky fill; people
paint-referred through ACES⁻¹, stepped, capped), so the same lamp treats a coat, a board and the
road differently, and the people's colours are tied to the camera's tonemapper (ACES⁻¹ in
`body_skin`): any change of tonemapper changes every painted man. Temporal stability is no
longer a large problem with the screen mosaic off: on the lab's paths 0.4 % (orbit) and 1.0 %
(walk) of pixels flip back a frame, the surface-blocks look (M) 0.39 % / 0.90 %.

**Composition problems.** The saloon shot's middle is blocked by a wall of standing men and its
back half is murky brown; the street's sky is a lilac overcast and its sun a smudge, its right
side a blank wall, its road loud static with no ruts (the critic's five, both rounds); the lab's
lamplit corner is near-black with no bounce, so lamp scenes need more fill than one table lamp.

**The three biggest verified obstacles**, in order: the room and street's content (people,
dressing, sky: composition and assets, top four of both critics), the textures' own detail and
square size in the saloon (asset: the probe shows it), and the light's colour flattening every
material toward one hue in the street (rendering: the probe shows it).

## 3. The experiment: paint light

The one rendering change the evidence pointed at that Godot's existing controls don't obviously
give: **local colour under coloured light.** Every light still brightens and darkens a surface
exactly as before (its luminance is untouched), but the share of the light's *colour* a surface
takes rises with how lit it is: 0.2 of it in half-light, all of it at full light (`pl_lit` 0.25
of luminance × facing). The painters' rule: the lamp or the low sun shows in the highlights, the
half-lights keep the material's own colour. One rule, the same three numbers (`SPEC` in
`lab_looks.gd`) for the world's texel grid, the ground and the people, with a per-class hook.

Built in material space, as the brief asked, with nothing in the game edited: each production
shader's code is read at run time and its `light()` gets the rule (the texel grid has none, so
Godot's own Burley and GGX are written out for it); the variant is swapped onto the existing
materials in place, and swapped back the same way. The switch is live (`lab.gd --look=base,paint`
renders both in one run; `play.gd`'s L key flips it while you play). A control proves the
variants are faithful: `paint_id` (the variant shaders with the rule off) draws as production to
0.6/255 on average (1.5 % of pixels over 8/255, all on silhouettes and shadow edges). A second
control stands for the existing tools: `paint_flat`, one colour share at every light level, which
is exactly what desaturating every light's colour would do.

## 4. Results

Boards: `docs/screenshots/render_lab/shots_abc.jpg` (A the painting | B production | C paint
light | the control; the paint probe under them), `lab_bc_1.jpg` / `lab_bc_2.jpg` (the man
front, three-quarter and profile, near and far, in lamp, golden and noon light; the props, the
corner, the façade; each beside its paint), `motion_orbit.jpg` / `motion_walk.jpg` (frames of the
two camera paths: production, paint light, surface blocks). Videos of the paths are in
`build/render_lab/motion_*.mp4` (not in git).

| | production | **paint light** | control (lights desaturated) | first tuning |
|---|---|---|---|---|
| Judge v2, saloon (lower is closer) | 0.232 | **0.218** | 0.353 | 0.248 |
| Judge v2, street | 0.696 | **0.617** | 0.606 | 0.609 |
| Street chroma (painting 0.076) | 0.097 | 0.084 | 0.083 | 0.084 |
| Lab: hue turned by the light, all shots | 21.5° | 15.9° | 15.0° | 15.6° |
| Lab: hue turned under the lamps | 31.6° | 17.6° | 18.2° | 18.9° |
| Lab: painted detail kept | 0.96 | 0.96 | 0.95 | 0.95 |
| Lab: pixels flipping back, orbit / walk | 0.42 / 0.97 % | 0.40 / 0.96 % | – | 0.34 / 0.95 % |
| Render CPU / lavapipe raster a frame (lab, alone) | 1.22 / 344 ms | 1.26 / 334 ms | – | – |

The **blind critic** (`docs/screenshots/render_lab/blind/critic.md`, X and Y shuffled per board)
put production a hair ahead on all three boards, "hard to tell", and: "Would a player notice X
against Y without a side-by-side? No." Its five biggest differences from the paintings are the
same for both: the saloon's blocked, murky room; surfaces that aren't the painting's crisp
squares (giant soft squares on the bar, smeared table, plain lamp and bottle); blotchy harsh
faces; the road's static; the street's sky and one-colour frame.

Cost: a wash. The rule is a dozen arithmetic operations a light a fragment; render CPU and the
software raster moved within run-to-run noise. Real-GPU time not measured (no GPU here); expect
well under 0.1 ms at 1080p. Tests: see the status entry.

Two side results from the controls: **AgX** (Godot's other filmic tonemapper, one setting:
`--env=tonemap_mode:4`) takes the noon clipping from 27 % to 0 % and the hue turn from 21.5° to
18.4°, but flattens the painted detail (kept 0.96 → 0.77) and would change every painted man
(their paint is run back through ACES⁻¹); and taking the ambient, fog and grade out shows the
golden-hour cast is the sun's own, not the sky's or the fog's.

## 5. What it improved, and what it can't

Improved, by measure: the street's colour toward the painting (chroma 0.097 → 0.084 against
0.076; judge 0.696 → 0.617), the lamps' hue cast halved in the lab, the saloon judge a little
(0.232 → 0.218), at no cost and with no effect on motion. **Not improved, by eye:** the blind
critic couldn't reliably tell it from production and leaned to production; a player wouldn't
notice. Most of the street's gain is had as well by desaturating the low sun's colour, an
existing control (the control matches it there, 0.606); only in the saloon does the rule's
value-dependence matter (desaturating the lamps flat costs 0.353, the rule gains a little), and
that gain is small.

What a renderer can't do here: put people in the back of the saloon, a balcony and a moonlit
house through the door, ruts in the road, a blue sky and a sun; draw a calmer face; give the
textures the painting's detail and square size. Those are the assets and the composition, the
critics' top five, and what the paint probe shows in the saloon.

## 6. The architectural boundary (a map, not a migration)

- **Stays Godot-native:** the Forward+ renderer, its light loop, shadows (cascades and the lamp
  atlas), volumetric fog, glow, the tonemapper and grade, SubViewports, `CompositorEffect` if a
  screen pass is ever wanted. Nothing measured here needs them changed.
- **Salt Creek should own:** one **material layer**, the shared includes every surface already
  goes through (`tiles.gdshaderinc`, `texel_grid.gdshaderinc`, `body_skin.gdshaderinc`,
  `ground.gdshader`), with **one light rule** in one include (today there are three: Burley on the
  world, the ground's wrap, people's paint-referred stepped light) and **one artistic spec as
  data**: texel density, square size, seams, the light rule's numbers, shade tints and caps, per
  material class (world wood, ground, skin, cloth, hair, metal), in a resource both the
  characters' pipeline and the world read. The lab's `lab_looks.gd` is a working sketch of the
  mechanism: a rule applied over the production shaders with a per-class table.
- **Characters and world on one spec:** the characters' bake already writes per-man numbers
  (`eye_gain`, `light_cap`, `fidelity` in `portrait.json`); the world's are scattered constants
  (`PixelArt.SHADE_TINT`, `Settings.MIN_SQUARE_PX`, per-material uniforms). One spec file per
  material class, read by both, is the boundary: the characters session owns what goes into a
  class's paint, art owns the class's rule.
- **One coupling to cut first:** painted people are run back through **ACES⁻¹** in their shader,
  so the people's colours depend on the camera's tonemapper. The spec should hold the tonemapper
  choice and the inverse together, or the paint should be referred to the scene, not the screen.
- **Where native code would pay:** not in shading (the GPU does it; the rule cost nothing
  measurable). Possibly in CPU-side rendering work the frame budget shows over: the street's draw
  calls (render CPU 2.9 ms at Sean's for the calm street, 6.1–6.4 under the wall scene), i.e.
  batching carved members and chips, which the Rust plugin already half does for voxels. Not shown
  here.
- **What a fork would change, if ever:** a hook after a fragment's lights are summed and before
  ambient and fog (a material shaping its whole light, not each light's share: body_skin's cap
  works round its absence), the ambient's colour inside the material, a tonemap per material, an
  albedo buffer for screen passes. The lab hit none of these as a limit on the result: the rule
  was made with what Godot exposes, and its effect was too small for the missing hooks to matter.
- **Untouched:** NPC minds, structures, fire, blast, ballistics, the people's bodies and rig,
  the characters' pipeline, saves, CI. Nothing here reaches them.

## 7. Recommendation

**Keep the existing renderer.** Don't integrate paint light and don't pursue a deeper Godot
modification: the experiment works, costs nothing and moves the numbers, but a blind viewer can't
see it, and most of its street gain comes as easily from the sun's colour. The answer to Phase
1's question is **no, not now**: a specialised Salt Creek renderer would not make the game
meaningfully closer to the paintings, because what separates them is the content of the frame
(people, dressing, sky, the textures' detail and square size, the faces), not how it is lit or
drawn; and Godot already exposes every hook the measured problems need.

The smallest useful steps, in order, each one merge, judged as usual:
1. (Art, existing controls, no new code) **Desaturate the golden-hour sun's colour** a third of
   the way to its luminance in `config/day_cycle.tres` and judge the street (the control's
   0.696 → 0.606), and **hold noon** (exposure or the sun's energy at noon: a quarter of the noon
   store front clips).
2. (Art) **One light rule in one include** for the world, the ground and the people, when the
   next look change touches them anyway: the boundary above, and the cheapest place for any
   future rule. No new look in it until Sean asks.
3. (Art and characters) the content: the saloon's back half and the men in it, the street's sky
   and right side, the road's detail falling off with distance, the textures' square size.

Stop and report: done. The improvement **cannot demonstrate a meaningful advantage** (the
brief's stop condition), so it stays in `experiments/` and nothing goes into production.
