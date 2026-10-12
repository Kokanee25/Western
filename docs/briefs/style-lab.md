# Style lab: three looks on the same assets (Prompt 07)

Sean, 2026-10-11: "Ok go", after the character-sheet trial's two rounds
(`docs/screenshots/review/2026-10-11_sheet_style_*.png`). An experiment on
`claude/art-style-sheet-test`: nothing in the game's look changes, nothing is migrated, no golden
image is touched, and nothing new is paid for.

## What's fixed and what's being reconsidered

Fixed (DESIGN.md, not reopened here): first person; real 3D with realistic motion, ragdolls and
wounds; pixel-art textures at a fixed density on the surfaces, nearest filtering; the light with
range (dark rooms, true emitters, golden-hour haze); no screen filter (Sean, 2026-10-06: "no
filters, the look has to be the art"). Being reconsidered (DESIGN.md §4's note of 2026-10-10): how
the squares are made and lit, and how big, on the people and the world. Adopting any candidate
needs Sean's yes.

## The three candidates

All three use the same meshes (the fitted men, the code-modelled props, the member-built saloon and
façade), the same lights and the same cameras. Only what's painted on the surfaces and how a
fragment is lit change.

- **A, today:** the game's default. The factory's textures at 32 texels a metre (the drawn woods
  where they exist), lit a texel at a time (`tile_light`, `min_square_px` 2); people in their style
  repaints, lit a square at a time by `body_skin`.
- **B, painted squares, smooth light** (the sheet trial's round 2 winner): the same painted
  textures, nearest, but Godot's ordinary light running across the squares, and the models' own
  normal maps on the people; the world from the factory's smooth set cut to 16 texels a metre.
  (`--sheet-style=painted`)
- **C, restrained illustrative realism:** no squares anywhere. The models' own realistic colour
  (Rodin's, Tripo's) and normal maps, the factory's smooth set at 128 texels a metre, ordinary
  light. It shows what the squares are buying. (`--sheet-style=real`)

## The scope (the same for each)

1. Two characters, face, outfit and headgear: the stylised stranger (`stranger2s`, Rodin) and the
   Kid (Tripo, his hat its own piece). Front, three-quarters, side, back and a head close-up.
2. A chair, a barrel and a table (`PropModels`).
3. The saloon corner: the shot's table, lamp and the doorway (`shot_match_saloon`).
4. A façade: the saloon's front (`shot_match_street` and the same front at noon).

Each under neutral daylight, warm lamplight and golden hour where the scene allows, from at least
two distances, and one short camera path through the saloon (`tools/probe_walk.gd`'s walk, frames
kept in `build/`, a strip of them on the board; no video in git).

## How it's judged

- **Style (subjective), kept apart:** a blind critic (a fresh agent) gets the boards with the
  candidates shuffled and named X, Y, Z, and the concept paintings; it ranks them and names each
  one's worst visual failures. The judges' scores (`judge.py` on both shots, `judge_man.py` on the
  seated man) go beside it, not in place of it.
- **Production (measured), per candidate:** paid cost per new man and per new prop; steps a
  person or an AI has to get right, and how ambiguous each instruction is; what the textures need
  (UVs, sizes); material editability; draw cost (`tools/look_cost.gd`); rig and wound
  compatibility (does the shader keep openings, the hat shot off, the ragdoll?); time to make the
  second example (the Kid after the stranger); what can be validated automatically; regressions
  against today.
- **The success test:** say how the hundredth asset is made, in steps another session could follow.

## What done looks like

`docs/screenshots/style_lab/`: a board per scene (A | B | C), the camera-path strips, the blind
critique, the judges' numbers; this brief's findings below: the rubric filled in, the cost and
time per candidate including failures, the top visual failures, a recommendation (keep A, adopt
one subject to Sean's yes, or keep researching) and a draft style bible (face density and form,
materials, palette, highlights and shadows, texel rules, geometry budgets, what's not allowed).

## Findings (2026-10-11)

Rendered under lavapipe by `tools/style_lab.sh` (each look ~20 minutes); boards by
`tools/style_lab.py boards` in `docs/screenshots/style_lab/` (named) and `.../blind/` (shuffled; the
key in `build/style_lab/blind_key.json`: X = C, Y = A, Z = B). Nothing paid for; no default, golden
or shader of the game's changed.

### Style (subjective), the blind critic (`blind/critic.md`)

Ranked **A first, B second, C last**. A: "the only one with the targets' mosaic everywhere"; its
worst failure the seated man's face (blocks on jaw, collar and moustache too big and uneven, a hot
orange mask). B: the men nearly A's, but the world coarser and noisier (the noon siding "blue-white
confetti", the JAIL sign's lettering lost at 16 texels a metre). C: plain realistic game rendering,
floors smeared into streaks; its faces the cleanest close up. Where they're the same: the street
shot, the saloon front and the Kid down the street barely differ (the façades' drawn woods are
shared: the smooth set has none, so C falls back to them), and all three share one light and one
colour; the differences are the faces and the close surfaces.

### The judges (lower is closer)

| | A today | B painted, smooth light | C realism |
|---|---|---|---|
| Saloon shot (`judge.py` v2 against saloon-blocks.png) | 0.342 | 0.338 | 0.320 |
| Street shot (against street-golden-hour.png) | 0.502 | **0.461** | 0.633 |
| The seated man alone (`judge_man.py`) | 0.501 | **0.407** | 0.513 |
| The stranger standing, daylight, against the character sheet (`sheet_judge.py`) | **0.640** | 0.692 | 0.808 |

The man's judge splits it: light 0.77 / 0.78 / 0.93, squares 0.46 / **0.14** / 0.30. B's squares
are the painting's (A's are flatter than the painting's, one tone edge to edge: the per-square
light; C's have light running across them and no squares). Every candidate's top fault is the same
and isn't the style: his face's lit parts L* 79-82 against the painting's 55, and too much deep
shadow (0.47 against 0.31). C's street is worst by far: the smooth road and sky at 128 a metre
read as grain where the painting has blocks. The sheet judge is light-dominated (each one's face
L* 34-41 to the sheet's 17 in the lineup's daylight).

### Production (measured)

| | A | B | C |
|---|---|---|---|
| Paid, a new man (Rodin $1.60, three views ~$0.15, head + body repaint ~$0.35-1.00 with retries) | ~$2.1-2.8 | ~$2.1-2.8 (A's textures) | ~$1.75 (no repaint) |
| Paid, a new prop | $0 (code) | $0 | $0 |
| Steps, a new man | 11: picture, views, model, stylise, fit, head repaint, body repaint, bake (cells, skin, eyes), shot fit, eye gain, lineup | A's 11 + a normal map | 6: picture, views, model, fit, eye gain, lineup |
| Ambiguous steps | the repaint's words (four tries for the Kid's hair), the bake's knobs | as A | the front picture only |
| Texture memory, the two men (PNG) | 5.7 MB | 7.9 MB (+ normal maps) | 29 MB (Rodin's 4K, Tripo's 2K + normals) |
| World textures | 2.6 Mpx factory + drawn woods | 0.03 Mpx at 16/m (box-averaged from the smooth set) | 1.9 Mpx smooth set + drawn woods |
| Editing a material | paint, reduce, palette | the same paintings, one box-average | the same paintings, no cut |
| Wounds, eye gain, shade tint | yes (`body_skin`) | **no** (trial shader) | **no** |
| Hat shot off, ragdoll, layers | yes | yes (the copy keeps its material) | yes |
| The second man (the Kid) | a session (runs 38-46) | seconds once A's paint exists | seconds |
| Goldens and checks | in place | none yet | none yet |
| Draw calls, saloon / street (`look_cost.gd`) | 3,442 / 14,707 | 3,116 / 12,574 | 3,943 / 17,215 |
| Render CPU ms, saloon / street (lavapipe here) | 4.4 / 13.7 | 4.5 / 12.1 | 5.1 / 15.2 |
| Raster (lavapipe's GPU stand-in) ms | 481 / 981 | 496 / 965 | 487 / 979 |

B and C as built are a **trial shader** (`sheet_man.gdshader`): Godot's light and a normal map, no
wound openings (`_apply_openings` would set uniforms it doesn't have, silently), no `eye_gain`, one
material shared by every piece of a shape. Adopting B means giving `body_skin` a normal map and an
option to light smoothly (the tile globals at 0 already turn its per-square light off), not shipping
the trial shader. B's 16-a-metre world cuts the sign boards' lettering (SignArt's boards would keep
their own density), and the factory's paintings box-averaged to 16 are the "confetti" on the noon
wall; the drawn woods (32 a metre) read better. The draw counts follow how many materials the
world ends up with (StaticBatch groups by material: B's fewer textures batch more, C's more batch
less); the raster is a wash. The street's ~14,700 draw calls in today's look (against ~3,700 when
the frame budget was measured) are Main Street's new buildings, already reported to gameplay.

### Recommendation (Sean's to approve)

**Keep A as the base, and take two things from B into it** (one merge each, judged as usual):
1. **People lit smoothly over their painted squares, with their normal maps** (`body_skin`: a
   normal map uniform and per-square light off for painted men): the only change all four judges
   and the critic don't contradict (the man's judge 0.501 → 0.407, squares 0.46 → 0.14; the men
   otherwise look the same to the critic).
2. **The world stays at 32 a metre in drawn or factory squares**, not B's 16 (the critic's worst
   B failure; the street's gain from 16 is the road alone, which can be drawn coarser on its own).

Not C: it loses the mosaic the critic and the paintings rank first, and its realism isn't cheaper
where it counts (it skips the repaint but needs 4x the texture memory and a new shader too). Keep
researching, separately: the light on his face (every candidate's top fault, the shot's light: the
art session's), and the seated man's face drawn for the block size (the critic's top A failure).

### Candidate D: the sheet's own look (added 2026-10-12)

Sean, on the character sheet: "let's see if we can get it closer to the sheet". Close up, the sheet's
man isn't cut into squares: his realistic texture is broken into irregular flat patches, each a
shade off its neighbours, with his eyes left fine; only the ground is in square blocks. **D**
(`--sheet-style=sheet`, `tools/sheet_style.py sheet`): the models' own colour in Voronoi patches in
body space (6 mm face, 9 head, 14 body, each pushed 1.8x from its surround and its lightness
jittered, the eyes kept), the world in wrapped patches of 3 cm and the road in 6 cm blocks, all at
128 a metre, Godot's light and the normal maps.

A fresh blind critic over all four (`blind/critic_4.md`; key W = B, X = A, Y = C, Z = D):
- **against the character sheet:** D, C, A, B. D "keeps a realistically modelled man under a
  broken, patchy surface"; A and B's face blocks are four or five times the sheet's.
- **against the two paintings:** A, B, D, C (A "square blocks on every surface, keeps the plank
  seams and the lettering crisp"; D "reads as a watercolour filter").
- **what still separates D from the sheet:** its patches are soft and ragged where the sheet's
  read as small crisp marks of a steady size; the light (the sheet's hard warm key and near-black
  shadows against our flat, bright lighting, in every candidate); the colour (the sheet's muted
  charcoal, rust and oxblood with grime, against the stranger's even orange-brown coat).

The judges, D: saloon 0.318, street 0.486, the seated man 0.537, against the sheet 0.822 in the
lineup's daylight. In the sheet's own darker turnaround light (the first round's), A / D: 0.633 /
0.725, squares 0.320 / **0.271**, light 1.06 / 1.14, colour 0.40 / 0.67: D's surface is the nearer,
its colour (Rodin's paler, greyer realism) the further. Draw cost: 3,943 / 17,215 draw calls,
5.3 / 14.9 ms render CPU (saloon / street), as C. Production: as C (no repaint, ~$1.75 a man,
4x A's texture memory) plus a minute of patch-cutting a man.

**Reading:** the sheet's look is reachable as a surface rule (D is the critic's closest to it),
but it isn't the paintings' look (the critic ranks it third of four against them), and what's left
between D and the sheet is mostly light and the men's own colour and wardrobe, not the patches.
So the choice is Sean's between two targets: the paintings (keep A, the recommendation above) or
the sheet (D, with crisper patches, the sheet's light and darker, grimier clothes painted into the
men).

### The hundredth asset (A with smooth light on people), in steps

A man: 1) Sean's front picture (ChatGPT, A-pose, flat light, grey ground); 2) three views painted
from it on fal (`paint_full_length.py`, `given`); 3) Rodin (`rodin.py`, $1.60) or Tripo; 4)
`fit_tripo.py` (his joints found, eyes onto the anatomy's); 5) `head_paint.py` head and body in the
style, `bake` with cells (8 / 9 / 2.7 mm), skin evened, eyes drawn; 6) `people_lineup.gd` in the
three lights (no tears, eyes level); 7) `judge_man.py` and the art session's look. A prop: modelled
in code in `PropModels` on the texel grid, its materials from the factory (paint once, `reduce.py`).

### Style bible (draft)

- **Faces:** ~20 squares across the face (the painting's man), eyes drawn finer than the squares
  (whites either side of a dark iris, a glint), brows and moustache bold dark masses; skin evened
  of painted light; lit parts no brighter than L* ~55 in the saloon.
- **Cloth and hats:** squares 7-9 mm, each one shade off its neighbours (the painting's ~5 L*),
  folds and seams drawn in the squares, light running smoothly across them over the model's own
  normals.
- **World:** 32 squares a metre; boards drawn square by square, each board its own strip, squares
  two to six long along the grain; signs lettered on the square grid at their own density; no
  noise that isn't a drawn thing (no confetti).
- **Palette:** warm earths, a few close shades a material (10-28), chroma rising with lightness
  (the painting's chroma-L* correlation ~0.6); no grey highlights.
- **Light:** smooth light across every square; deep shadow ~0.3 of a lit room; only true emitters
  bloom; golden hour gold, not orange.
- **Geometry:** a principal man ~25-33k triangles (Rodin), a townsman ~7.7k; props in code, a few
  hundred to a thousand faces.
- **Not allowed:** screen filters over the frame; squares that change size with distance; textures
  finer than the squares under them (C's grain); squares lit flat one at a time on people.
