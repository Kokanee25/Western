# Brief: character art convergence (the characters session; one man first) — PAUSED

Paused 2026-10-14 before any result: Sean is sending a new experiment. Kept: the test scene
(`art_lab.gd`, works: game vs painted material, neutral vs warm light) and the painted-texture
script (`painted_texture.py`, never run). Finding: the skin shader's painted mode already gives
the material side (self-lit paint, capped lamp, stepped light) without a new shader.

Sean, 2026-10-14 (a prompt he passed on). The bold cowboy (`bold_cowboy_rodin`) as it stands
is the baseline; the aim is a man who reads as a deliberately painted Salt Creek character, not a
shaded 3D model under a pixel filter. One man only, nothing propagated until Sean approves.

## What's built (isolated, switchable)

- **The test scene:** `tools/characters/art_lab.gd`. Him at the portraits' three-quarter (and
  front, both profiles), hat on, in neutral light or a warm interior made to the portraits (a
  warm lamp front-right, a dim fill, dark brown ground, little ambient). `--material=game` is the
  game's own; `--material=painted` the experiment; `--texture=` another head texture.
- **The painted texture:** `tools/characters/painted_texture.py`, from his existing paint: his
  colours fully de-lit, then a painted light laid back on from his shape (one key from the
  portraits' lamp, in a few hard bands, warm in the light, brown in the shade, darkest in his
  sockets, under his nose, lip and cheekbones), the colours snapped to the portraits' own palette,
  at a low resolution read nearest. The same light all round his head, so no portrait's light
  makes a seam.
- **The material:** no new shader. The skin shader's painted mode (`uv_rect`, `self_lit`,
  `paint_gain`, `paint_limit`, `paint_wrap`, `light_steps`, `paint_ambient`; art's file, used, not
  changed): the painted light carries him, the scene's light only a capped share, in steps, no
  sheen. Set by the test scene only.

## Judged by

Sean's eye on matched sheets: (1) as now, (2) painted texture under the game's lighting, (3)
painted texture with the painted material, (4) all of it with the hat in the warm interior; then
front, three-quarter and both profiles of (4).

## Notes as it goes

(Parameters, findings and what's left are added here.)
