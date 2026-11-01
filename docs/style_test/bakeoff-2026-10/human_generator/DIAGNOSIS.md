# The Human Generator man: diagnosis, and one corrected head (#522)

**Sean (2026-11-01) on `hg_bold_cowboy`: "unacceptable as a Salt Creek character."** No more
characters are generated. The goal from here: Human Generator for anatomically convincing base
meshes, body variation and rigging; the face's geometry and rendering are our established men's.
This file says exactly how the rejected man was built, measures him against the approved man
(`bold_cowboy_s3_talking`), and shows one corrected bald, clean-shaven head (`head_sheet.jpg`).
**Waiting on Sean: is the underlying face acceptable?** Nothing goes further until he says so.

## How the rejected man was built (every input)

| part | what was used |
|---|---|
| base preset | Human Generator's **Theo** (`models/male/Caucasian/Theo.json`), **with all of Theo's own face sliders kept** (random-looking values, some past the usual ±1: `jaw_location_vertical` -1.78, `lip_offset` -1.14, `cheek_zygomatic_bone` -0.87, `cheek_zygomatic_proc` 0.88, `eyelid_shift_vertical` 0.85, `eye_height` 0.89, `nose_tip_angle` -0.80, `eye_orbit_size` -0.60) |
| my face changes on top | `browridge_center_size` 0.8, `browridge_loc_vertical` -0.3, `forehead_size` 0.1, `jaw_width` 0.5, `chin_width` 0.35, `chin_size` 0.1, `cheek_fullness` -0.6. Picked by hand, not measured against the bold cowboy |
| age | "set 40", `age_wrinkles` 0.55, `age_color` 0.25. **Human Generator's age shapes came out at 0.067** (`aged_male`): 40 is barely aged in it, so his face stayed young |
| body | height 180, `muscular` 0.45, `skinny` 0.25, `overweight` 0.1, `Shoulder Width` 0.35, `Chest Width` 0.2, `Neck Thickness` 0.35 |
| skin material | its `textures/male/Default 4K/Male 05.png` (Theo's), tone 0.95, redness 0.25, splotches 0.25, normal strength 3.2, cavity 0.4, beard shadow 0.55, moustache shadow 0.6. Baked by Cycles to its colour only, plus 0.65 of its own shading under an even sky. **Its normal maps and subsurface light, where its realism lives, don't exist in our renderer** |
| rendering | `smooth_texels` on: drawn smooth, **not in the established texel look** every Studio man has |
| hair | its **"Medium Side Part"** (`hair/head/male/Long`, 9 particle systems), lightness 0.12, redness 0.55, as tubes baked flat onto his scalp ("haircap only", my code). Hair colour constants mine |
| eyebrows | its `Eyebrows_003`, lightness 0.08, baked as tubes 0.7 mm thick |
| facial hair | my set "Mutton_Chops" of its `HG_FH_Collection_1.blend` systems: `fh_Mustache_High` (length 1.0), `fh_sideburns_low` (1.0), `fh_Side_Lines` (0.8); colour mine |
| eyes | its eye mesh, inner ball only; Theo's brown iris |
| clothes | its Extra Outfits pack's **Pirate** shirt, trousers and boots |

## Measured against the bold cowboy

MediaPipe's 478 landmarks found on each head's mesh (Studio `tools/humgen/face_fit.py`), each
measure a share of the face's height (brow to chin), so size doesn't count. "Stands out" is how
far a point is in front of the eye corners (negative: behind them).

| measure (share of face height) | bold cowboy | rejected man | corrected head |
|---|---|---|---|
| eye spacing (centres) | 0.448 | 0.473 | 0.453 |
| eye width | 0.213 | 0.220 | 0.221 |
| eye opening | 0.058 | 0.083 | 0.061 |
| eyes' height in the face (from chin) | 0.815 | 0.839 | 0.840 |
| brow above the eyes | 0.137 | 0.189 | 0.150 |
| brow stands out (over the eyes) | 0.054 | 0.058 | 0.028 |
| nose length (nasion to base) | 0.357 | 0.370 | 0.362 |
| nose width (wings) | 0.314 | 0.304 | 0.319 |
| nose stands out (tip) | 0.210 | 0.283 | 0.247 |
| mouth width | 0.377 | 0.410 | 0.390 |
| nose base to mouth | 0.148 | 0.154 | 0.149 |
| chin height (lip to chin) | 0.469 | 0.347 | 0.426 |
| chin stands out | -0.213 | 0.115 | -0.081 |
| jaw width (angles) | 0.836 | 0.869 | 0.855 |
| cheek width | 1.027 | 1.102 | 1.033 |
| jaw width / cheek width | 0.814 | 0.788 | 0.827 |
| face height (m) | 0.149 m | 0.135 m | 0.144 m |

| landmark group | rejected man (mm) | corrected head (mm) |
|---|---|---|
| jaw and chin | 20.2 | 4.9 |
| mouth | 4.9 | 1.8 |
| nose | 7.7 | 1.9 |
| eyes | 4.5 | 1.6 |
| brows | 5.5 | 2.1 |
| cheeks and outline | 16.8 | 10.2 |
| forehead | 8.7 | 3.9 |

**What was wrong with him, in those numbers:** a **short, wide, young face** where the bold cowboy's is
long and deep-set. His face 10% shorter; **chin 26% shorter and ~4.6 cm further forward** (the bold
cowboy's chin sits back under his moustache); **brows 38% higher above the eyes** (the bold
cowboy's sit low and heavy); **eyes 43% more open**; nose 35% further forward; mouth 9% and
cheeks 7% wider. Jaw landmarks 20 mm off. On top of that, the rendering: no painted light, smooth
instead of texel squares, a flat haircap for hair, modern clothes. **Skull:** both read as normal
skulls; the bold cowboy's head is larger in the frame (his hair's volume and the Studio men's
head size, 0.110-0.140 of their height), the corrected head's face about 5% smaller in the game.

**The bold cowboy's own geometry is rough** (a Rodin surface, `head_sheet.jpg`'s shape row): his
character is mostly his paint (dark heavy brows, shadowed deep-set eyes, painted cheek planes).
So "his facial geometry" can only mean his proportions, and his "rendering" is his painted
texture and the game's texel look.

## The corrected head (`head_sheet.jpg`)

Bald, clean-shaven, no clothes, in the Studio turntable's neutral light (one sun, warm ambient),
drawn the established way (texel look, `smooth_texels` off). Built by Studio
`tools/humgen/face_fit.py` then `hg_man.py --man=hg_head`:
1. **Human Generator's own preset with its face sliders at zero** (not Theo's), age 50 (so its age
   shapes show), the same body.
2. **Its sliders fitted to the bold cowboy's landmarks** (bounded least squares, pulled toward zero
   so none runs to its end; all stay under ±0.3).
3. **The rest of the way by a smooth field from 448 landmarks** moving only the face, fading out
   2-7 cm from it (ears, scalp, neck and body stay Human Generator's), smoothed along its own
   edges; the eyeballs move with their sockets. Left out: the face's outline at the temples (on
   the bold cowboy those points sit in hair) and the inner lips (they tore the mouth's corners).
   Kept the version that crumples least with the landmark groups within 3 mm: crumple p99 0.65.
   Its mesh, UVs, rig, skull and ears are Human Generator's.
4. **Skin matched to the bold cowboy's painted skin** at the same face points (cheeks, forehead,
   nose bridge, chin): CIELAB mean and spread moved to his (L 54.8 -> 53.7, a 19.0 -> 22.6,
   b 19.2 -> 26.7; spread 5.7 -> 7.1), the whole texture by one rule.

**What's still off (my read):**
- **Without brows and paint he reads as a mannequin.** The bold cowboy's look is his paint. A bald,
  brow-less realistic face can't carry it.
- **His eyes stare:** a ring of white all round small irises. The bold cowboy's are painted dark
  and shadowed under the brow.
- The chin stands out less far back than the reference's (-0.122 against -0.213) and the brow
  less far forward (0.035 against 0.054): the smoothing traded those for a clean surface.
