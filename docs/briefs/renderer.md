# Brief: our own renderer, the mosaic on the surfaces

Sean, 2026-10-05: a look nobody else has, steady in motion, closer to the paintings than the
screen mosaic. Art session, Part B. Behind a setting, off by default; Sean's eye is the gate.

## What's wrong with what we have

- **The screen mosaic** (`DepthMosaic`, the default since 3 Oct) cuts the finished frame into a
  grid of screen blocks. The grid is pinned to the screen, so every camera move re-rolls which
  bit of the world each block shows: the picture crawls and shimmers (the flicker probe measured
  flip-backs up 0.196 % → 0.347 % on a slow pan). Far off, a block is one sample of whatever is
  under it, so the saloon's back half, all small lit things, turns to speckle and brown streaks
  (the critic's first point), and 14 tones of light flatten what's left.
- **Quantise once (I)** averages those same screen blocks: smoother, still screen-pinned, still
  crawls, and the averages lift the darks.
- **The texel tiles underneath** (`tiles.gdshaderinc`, P) are already the right idea: each texel
  of a surface is a block of a fixed real size, lit as one. But they chunk far surfaces into
  2/4/8-texel squares with a hard jump at each band (`min_square_px`), their edges are hard
  (a block edge crossing a screen pixel pops on and off as the camera moves), and the light on
  them is smooth, so nothing in the frame has a palette.

## The design: blocks that live on the surfaces

Everything happens in the materials; there is no screen pass. The block is the texel.

1. **Anchored.** A block is a texel of the surface's texture (32 a metre on the world, the
   paint's squares on people), so it sits still on the wall or the coat when the camera turns.
   Nothing is snapped to the screen.
2. **Lit as one, with a faint gradient.** Light, shadow and fog are worked out at the block's
   centre (as now, `LIGHT_VERTEX`), eased `tile_gradient` of the way back toward the fragment
   so each block carries a hint of the real falloff, never a smooth ramp across it.
3. **Soft edges.** The colour and light are blended across a block's edge over about one
   render pixel (from screen derivatives, like a texture's own anti-aliasing), so an edge
   neither pops nor shimmers as it slides across the pixel grid. This is what makes the surface
   steady in motion; the Pixel-factory test's anchored blocks showed the gain.
4. **A palette per material, applied once.** The texture's colours are the material's palette
   already (the factory's 28 a material). The light on them is cut into bands in the material's
   `light()` (each light's share snapped to `light_bands` steps, so their sum is stepped too),
   and each band takes the material's own shade tint (warm brown in wood's shadows, warm in
   skin's, cooler in cloth's) rather than grey. Wood, skin and cloth keep rich shading, and no
   two materials share a mud.
5. **Distance softens and hazes.** Where a texel would be smaller than ~2 render pixels the
   texture's mip takes over through the same soft blend (no 4/8-texel squares, `min_square_px`
   0), and the scene's haze does the rest, as the paintings' far streets do.
6. **Silhouettes.** With the screen pass gone, silhouettes are the mesh's edges at the render
   resolution. The painting's are stepped at its block size, so the setting is judged twice:
   at native, and with the internal resolution at half (F2's 960×540: a render pixel is two
   screen pixels at 1080p, blocks of 2–3 render pixels are the painting's 4–6), where the
   silhouettes step at the block size and the soft edges keep the blocks steady under
   resampling. That is the perspective form of what t3ssel8r-style renderers do with an
   orthographic camera snapped to the texel grid (they can snap the camera; a first-person
   perspective camera can't, and texel splatting's cubemap re-capture is too costly for a scene
   full of moving people).

How it differs from DepthMosaic and quantise once: those cut the lit frame on the screen;
this cuts nothing after the fact. The blocks are the surfaces' own, the light is banded on
them with a material's own colours, and the frame is left alone.

What it won't do: make the man's drawing better (that's his texture), or give the sky and
backdrop blocks (they're painted; left smooth).

## Sources (ideas only, no code; named in the shader comments)

t3ssel8r's 3D pixel art (texel-aligned textures, an orthographic camera snapped to the texel
grid, banded light); Rune Skovbo Johansen's surface-stable fractal dithering (a pattern that
lives in UV space and keeps a constant screen size by screen derivatives); Lucas Pope's Obra
Dinn (a dither pinned to the world round the camera for stability); Texel Splatting (Ebert,
2026: texels as world-space quads from a cubemap at a snapped origin).

## How it's judged

- **The two shots** against the painting, by judge v2 and the blind critic, against the current
  default and the I key: `docs/screenshots/review/<date>_renderer.png` (painting | current |
  quantise-once | new, 3× crops of his face, the back bar and the far street).
- **Motion**: a 10-second pan of each shot as frames (`tools/flicker_probe.gd --pan`): the share
  of pixels that change a frame and that flip back, for all three looks; a frame strip or clip
  on the sheet. The new look must crawl and flicker less than both.
- **Cost**: render CPU against the frame budget (4 ms; this look removes a full-screen pass,
  so it should cost less), and the GPU time of a frame on lavapipe before and after, with an
  estimate for a real GPU.
- **Sean's eye** decides. It becomes the default only on his yes, in one merge with its golden
  images.

## Stop and report if

The design can't beat the current look on both shots; it costs more than the budget allows;
or about two days go by without a clear win.
