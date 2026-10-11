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

## Findings

(filled in as the lab runs)
