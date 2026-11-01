# The deer head's fidelity: which step loses it (issue #524, 2026-11-01)

How it was made: `experiments/prop_lab/deer_fidelity/README.md`. Spend: $0 (Rodin's master re-used).

- `sheet_stand.jpg`: every version (rows: the ladder from the game's deer to Rodin's master) in
  every view (columns: front, three-quarter, profile, close at the player's eye and lens, across the
  saloon at 9 m, daylight, night by lamplight), the same camera and light for each; each cell the
  same square round the deer, scaled with nearest neighbour so the game's pixels show.
- `sheet_game.jpg`: the same versions in the game itself (B and D): the kit's deer_head on the
  saloon's back wall, built of each version, at noon and at night, from a couple of steps off (the
  player's 75 degree lens, and a 25 degree one to see it close) and across the saloon.
- `sheet_game_standardmaterial_refused.jpg`: the first in-game round, when the PBR versions were
  handed to the kit as a StandardMaterial3D (finding 4).
- `costs.md` / `costs.json`, `d_checks.json`, `variants.json` (the master's sha256, triangles),
  `split_mask.jpg` (the roughness classes on Rodin's atlas: cyan antler, red eye, magenta nose,
  green plaque).

## Which steps lose the quality

**1. The game's grid shader, above all its min-square coarsening.** *Observed* (stand rows C0,
C1, C1f, C1fl, C2). The game's deer (C0) and the same 6k mesh and same 1k paint drawn by a plain
filtered material (C2) differ more than any other pair on the sheet: C0's plaque is speckled
with bright orange flecks, the fur is blotchy, and across the saloon it breaks into a sparkle of
light and dark squares. Taking the shader apart:
- mipmaps on (C1): a small gain, the sparkle at 9 m a little calmer;
- the min-square coarsening off as well (C1f: `fixed_squares`, a texel a square, mipmaps on):
  **the big step**: the speckle, the blotches and the sparkle go, and the game's own deer comes
  within a hair of C2 and of the master (A) at every view, the game's look otherwise kept;
- lighting per pixel instead of per texel (C1fl): next to no change.
The grid shader also draws the deer warmer and more saturated than the standard material does
(C0 against C2; *observed*; why, *guessed*: its specular 0.2 against 0.5 and its texel lighting).
*Guessed, not proven:* why the min-square speckles here when it doesn't on the town's boards.
`min_square_px` (2) merges texels into squares at least two screen pixels wide and each square
takes one texel, unfiltered; Rodin's atlas is a patchwork of small islands with blocky padding between them,
so a coarse square near an island's edge takes a texel of the padding or the next island.

**2. Not the triangles, the paint's size or the dropped maps (much).** *Observed* (stand rows C2
to C7 and A; in-game rows C2, C4, C7, A). At the player's eye the deer is about 200-250 px tall a
couple of steps off and 40-50 px across the saloon, in the game's 720-line frame: the 1k paint
already has more texels than the screen shows. 6k against 15k against 30k triangles shows only
in the antler tips' outline on the narrow-lens stand views. Rodin's normal map (baked onto the cut
meshes, or its own on the master) adds a little fur relief in the studio light and is lost in the
saloon's; roughness by surface gives the plaque a varnish sheen (in the saloon at noon it catches
the blue of the windows) and the eyes and nose a glint too small to see past a step or two.

**3. The saloon's own light (B) flattens every version, the master too.** *Observed* (stand A
against game A). At noon the room is dim and blue, the head lit from below and mostly in its own
shade; at night it goes one orange. In the game the master and C1f are near enough the same; the
gap that's left is the room's light, not the model. That is art's lane (the light pass) and holds
for every prop, not only the deer.

**4. D: a standard material is refused by the kit.** *Observed* (`sheet_game_standardmaterial_refused.jpg`;
script error "Trying to return a value of type StandardMaterial3D from a function whose return
type is ShaderMaterial"). `PropModels.model_paint()` is typed to return a ShaderMaterial, so the
kit's `model:deer_head` look draws a PBR material as none: an untextured white deer. A PBR deer
needs `model_paint` to return `Material` (one line) or its material written as a shader (as this
lab's `pbr_shader()` is). Not a fault of the grid route (C1f stays a ShaderMaterial).
Everything else about D behaves: the game's four deer tests pass for every version (game, C1f, C4,
A); each hangs on its two nails, falls and splits into its four members when its board goes,
burns away in 156.5 s, and takes shots the same, as the members are the same boxes and only what's
drawn changes. (One run-order effect: in one process the fourth run's shot leaves the plaque
whole whichever version is fourth; checked by running A first and fourth.)

**Not tested:** lighting baked into Rodin's colour map. *Guessed* minor: the paint carries soft
painted shading and the eyes' catchlights; with the master's own maps on (A) it reads no flatter
than the rest.

**Which findings depend on #505** (whether the pixel squares stay): finding 1 is all about the grid
shader; if #505 drops it, the deer is C2 for nothing more than finding 4's one line. Findings 2 and
3 hold either way.

## Costs (`costs.md`)

| | Triangles | Textures (VRAM) | Lavapipe frame, deer alone, close | Draws |
|---|---|---|---|---|
| C0 the game's deer now | 5,999 | 4.0 MB (its paint imported lossless, no mipmaps) | 17.1 ms | 1 |
| C1f grid shader, mipmaps, no min-square | 5,999 | 5.3 MB lossless, or 1.3 MB BC7 | 19.6 ms | 1 |
| C2 standard material, the game's paint | 5,999 | 1.3 MB BC7 | 19.8 ms | 1 |
| C4 6k, 2k paint, baked normals, Rodin's roughness | 5,999 | 13.3 MB BC (64 MB uncompressed) | 20.1 ms | 1 |
| C7 15k, 2k, baked normals, roughness by surface | 14,998 | 13.3 MB BC | 23.0 ms | 1 |
| A Rodin's master | 29,630 | 53.3 MB BC (256 MB uncompressed) | 27.8 ms | 1 |

Lavapipe rasterises on the CPU: the figures include its own cost of a frame, so only the differences
mean anything, and a real card's will be far smaller (Sean's F3 gives his).
Every version is one material and so one draw in its batch. Headless, the hung deer's tick is
0.011-0.012 ms a frame for every version; making one takes 5-17 ms (A the slowest: its parts are
cut from 30k triangles).

## The recommendation

**C1f: keep the game's 6k mesh and 1k paint; draw it with mipmaps and without the min-square
coarsening** (`model_paint`: `use_mipmaps` true and `fixed_squares` true; the paint imported with
mipmaps, and BC7 if the memory matters). $0, no new files, no more triangles or draws, +1.3 MB of
texture lossless (or 2.7 MB less than now as BC7). It changes every Rodin prop drawn through
`model_paint` (the steer skull too), so Sean picks before it's applied. The PBR routes (C4, C7)
add little the player can see in the saloon's light, cost 10-50 times the texture memory and wait
on #505. The master (A) shows nothing at the game's distances that C1f doesn't.
