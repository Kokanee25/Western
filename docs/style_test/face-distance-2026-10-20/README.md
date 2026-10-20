# His face by distance (2026-10-20, characters, no paid calls)

Sean: "up close the bold cowboy's face looks good, further away not so much. Test why."

`sheet.jpg`: `bold_cowboy_whole_a2` (round 3 isn't merged) at 1.2, 3, 6, 10 and 20 m, in the saloon
at night (it's shorter than 20 m) and the street at golden hour, rendered at the game's 1280x720 and
shown x3 nearest. Distances run across and versions of his head texture run down. Above each scene,
Sean's front portrait is box-shrunk so his eye-to-chin is the man's in game pixels (44, 18, 9, 5, 3 px).

| Row | His head texture |
|---|---|
| as now | imported without mipmaps: every screen pixel is one texel |
| mipmaps on | Godot's averaged mips (`Image.generate_mipmaps`) |
| painted mips | `head_mips.py`: 2x2 blocks; a block touching his moustache, a brow or an eye keeps its darkest feature texel, any other block keeps its medoid (no blended colours); skin in 16 colours from level 2 |
| + value pass | the same, with brow shadow x0.78, eye sockets x0.82 (whites kept), moustache x0.8 first |
| **hybrid** (added) | as now for levels 1–4, painted mips from level 5 (`--plain-to=4`) |

## Why he falls apart further away

1. **His face texture is far finer than the game draws it.** On his face it's 0.4 mm a texel, so
   one screen pixel covers 6.5 texels at 1.2 m, 16 at 3 m, 32 at 6 m, 53 at 10 m and 108 at 20 m
   (mip levels 2.7, 4.0, 5.0, 5.7 and 6.8). Without mipmaps each pixel is one texel picked out of
   those, so by 6 m his moustache and brows come out as scattered dark dots instead of shapes.
2. **Plain mipmaps don't fix that; they average the features into his skin.** Speckle barely moves
   (saloon 0.24–0.28 for every version; the portrait is 0.18–0.22), and at 6 m his moustache has
   faded more than as-now.
3. **The paint isn't the cause; the light is a large share.** Measured on his face from brows to
   chin:

   | | skin value (median) | darks (p10) | saturation |
   |---|---|---|---|
   | his head texture | 0.374 | 0.104 (brows, moustache) | 0.63 |
   | the portrait | 0.28–0.37 | 0.07 | 0.71–0.76 |
   | saloon, 1.2 m | 0.23 | 0.04 | 0.94 |
   | street at golden hour, 1.2 m | **0.09** | 0.01 | 0.94 |

   In the street most of his face is in shadow, so his moustache and brows have no light skin to
   show against: they sink into one dark mass by 6 m. In both scenes he renders much redder than
   his paint (0.94 against 0.63). Those are art's (notes below).
4. **The portrait has a hat.** At 10–20 m it's the hat brim's dark band over a light face that
   still says "a man's head", and a2 is bare-headed (Sean's call), so the far columns can't match
   on that.

## The versions side by side

- **As now:** right at 1.2 m and 3 m. At 6 m his eyes are gone and his moustache is faint; by 10 m
  his face is noise.
- **Mipmaps on:** softer everywhere; worse than as-now at 3 and 6 m.
- **Painted mips:** at 6 and 10 m his moustache, brows and eyes stay as dark marks, the nearest of
  the four to the shrunk portrait. But at 1.2 m the game is already reading level 2–3, so the
  thickened moustache turns heavy and black where Sean likes him as he is.
- **+ value pass:** heavier still; at 1.2 m his eye sockets become dark masks. No.
- **Hybrid:** at 1.2 m it looks like as-now (on his face it differs from as-now by 4–6 of 255 a channel, from the
  painted mips by 5–8: only where the point samples fall). At 6 m and beyond it's identical to the
  painted mips. At 3 m (right on the level 4/5 switch) it's partly each, slightly busier.

## Recommendation: the hybrid

He stays as he is up close and gets painted mips from about 6 m out. It's a texture change only,
in characters' files; no shader or lighting change. Once Sean OKs it:

- make each man's chain with `head_mips.py --man=<id> --out=… --plain-to=4` as a step of the recipe;
- ship it as his head texture with those mips. Godot's importer can't take painted mips, so either
  a saved resource built from the levels (`Image.create_from_data` with mipmaps, as
  `PeopleBodies._head_variant` builds it now) or the loader reading the levels; the loader way
  costs a few ms a man at load;
- `--plain-to` is the dial: 5 would start the painted mips at about 10 m, with 3 m clean.

It won't make him read like the portrait at 10–20 m by itself: the light (below) matters as much.

## Notes for art (the light, not characters' to change)

- **Golden hour in the street:** from this view his face is mostly in shadow (skin median 0.09
  against 0.37 in his paint). At small sizes a face reads by its light skin against dark features;
  a fill or bounce on faces (or a sun angle that reaches them) would do more at 6–10 m than any
  texture.
- **Saturation:** faces render at 0.94 saturation against the paint's 0.63, in both scenes (the
  lamps' and the sun's warmth on skin, the tone map). The saloon's orange is a known art note; the
  street does it too.
- **Squares:** at 6–10 m the world behind him draws in big squares (`BOLD_MIN_SQUARE_PX` 4) while
  his face is drawn pixel by pixel. That's a look call for art; painted mips are characters' answer
  on the texture side.

## Files

- `tools/characters/head_mips.py`: the painted mip chains (`--value`, `--plain-to=N`).
- `tools/characters/distance_renders.sh`: the renders (9 a version, ~4.5 min each on lavapipe).
- `tools/characters/distance_sheet.py`: this sheet and the speckle numbers.
- `PeopleBodies.head_variant` (off by default) and `screenshots.gd --head-variant=` (which also
  prints `man_head_px`).
