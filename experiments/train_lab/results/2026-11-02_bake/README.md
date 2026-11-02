# The train's paint, baked (#577)

Sean's pick E (#569: realistic, working-dirty, "closer to Red Dead Redemption 2"), the Studio's
4800 x 3584 repaint of the clay layout (`experiments/train_lab/paint/real_dirty.png`, from its
`claude/studio-train-paint`, not merged), baked onto the engine and tender and drawn in the game.

    ~/bpyenv/bin/python experiments/train_lab/blender/engine.py                 # glbs with UVs
    ~/bpyenv/bin/python experiments/train_lab/blender/paint_views.py build/train_paint --scale=2
    ~/bpyenv/bin/python experiments/train_lab/blender/paint_bake.py build/train_paint
    godot --headless --import

## What's here

- `sheet_golden_hour.jpg`, `sheet_night.jpg`: step 3's sheet (left, before the shape pass) beside
  this one (right), the same views (`experiments/train_lab/sheet.txt`); `sheet/` every view.
- `distances.jpg`, `distances_crops.jpg` (1:1 middles): the engine and tender from the sunlit side
  at 3, 6 and 10 m (`experiments/train_lab/distances.txt`).
- `films/rods_start.mp4`: the rods film re-shot (`films/rods_start.txt`, 24.6 s): the paint turns
  with the drivers and rides with the rods.
- `register.jpg`: each panel's clay outline (cyan) laid on the painting by its fit; `bake.json` the
  fits (scale and offset an axis), the overlaps (IoU 0.955-0.998 fitted, 0.935-0.983 before) and
  each car's numbers; `coverage_*.png` which panel each texel took most from (dark grey: no panel
  sees it, its material's mean colour).
- `critic/verdict.md`: the blind critic (`tools/critic.py judge`, a fresh sub-agent).

## The bake

- Atlases 2048 (BC7, mipmapped): the engine ~102 texels a metre (59% of the atlas used; ~2,000
  small parts, so the spokes and rods are one island round, a 2 px margin), the tender ~158.
- Each texel's world point and face normal by rasterising the glb's own triangles into its UVs; each
  panel's z-buffer from the same triangles (2 px a layout pixel); a texel takes paint from the
  panels that see it (depth within 2 cm plus the slope's), weighted by dot(normal, toward)^2 (none
  under 0.12), sampled 1.2 cm inside its part. Seen: 33% of the engine's texels, 31% of the
  tender's: the rest are inside faces (frames, the backs of the wheels, the deck's underside, the
  cab's inside) and take their material's mean colour.
- Registration: the clay's mask fitted to the painted silhouette (the ground within 14 of grey 128)
  by a scale and an offset an axis, searched for the best overlap: the painting sits 3-10 layout px
  higher than the clay and ~0.5-1% taller.

## How much of E survives (golden hour, `distances_crops.jpg`)

- 3 m: the rust streaks, the patched and stained jacket, the brass bands, the cab's weathered red
  boards and the tender's rivet rows all read; the texel squares (1 cm on the engine) are about a
  screen pixel and a half.
- 6 m: the streaks and blotches, bands and boards hold; rivets and the finer rust go.
- 10 m: a dirty grey boiler with dark smudges, brass bands and domes, a red cab, a rusty tender:
  the colours, not the detail.
- The painting's own light (soft, from above) is baked in, as the guns' was; the game lights it
  again. In the low sun from behind (the sheet's side and front views) the side in shadow goes
  near-black, as it did in step 3: the critic's first fault in a, b and e (light, not the paint).

## The critic (all five FAIL, as step 3's did)

Shapes pass now (step 3's a and c failed them). Its faults are light first (the backlit engine a
silhouette, the night engine black, shadow aliasing on the desert in c and d), then the ground (an
unpainted gradient), then the paint: "the boiler jacket soft cloudy smudges like a photographed
dirty tank, not angular patches following the cylinder". That's E's realism against the game's
illustrated look; Sean picked E knowing it, so the look is his and art's call, not changed here.

## Notes

- The coal reads as rows of dots (E painted the clay's lumps); not fixed (no more paid calls).
- The texel grid's grime and bleach (by world height, the street at y 0) are on this material too,
  as on every grid material: on the line's grades the band moves up and down the car as it climbs
  (art's call; the painting has its own dirt low, so `grime_*` could leave the train alone).
- The headlight's lens and the cab's glass keep their own materials (`TrainModels.lamp`/`glass`).
- The painting has a number on the guide yoke ("1534"-ish) and a few marks that weren't in the clay:
  E's, kept.
- Frame cost (`experiments/train_lab/cost.txt`, the whole train at 25 km/h, 14 passengers): 646 draw
  calls and 2.25 M primitives as before, draw 0.33 ms here (step 3: 0.40); the same. Texture memory:
  +~11 MB (two 2048 BC7 atlases with mips; the five TRIPLANAR metal textures stay for the cars).
