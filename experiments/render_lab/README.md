# The render lab (art, Phase 1 of the Salt Creek rendering architecture)

Brief and findings: `docs/briefs/render-lab.md`. Nothing here changes the game: no production
shader, scene, setting, golden image or asset is edited. Every look is applied to the game's own
materials at run time by `lab_looks.gd` and taken off again the same way.

## What's here

| File | What it does |
|---|---|
| `lab.gd` | The stage: a Rodin portrait man (`bold_cowboy_rodin`, hat and all), the code-modelled chair, barrel and card table, a saloon corner and a street façade built from the game's own board members, materials and oil lamps, the game's sky, sun, moon, grade and day cycle (taken from `scenes/test_street.tscn`). Fixed cameras: the man front / three-quarter / profile, near (0.85 m) and far (4 m); the props; the corner; the façade. Lights: `lamp` (22:00, the corner's two lamps), `day` (12:30) and `golden` (17:36) from the day cycle. ~1 minute a look under lavapipe. |
| `shots.gd` | The game's own fixed views (`tools/screenshots.gd`, extended, not edited) under a lab look, plus the paint probe over the whole frame. |
| `play.gd` | The game with a live switch: **L** flips between the game's look and the experiment while you play. |
| `lab_looks.gd` | The looks and the paint probe. The experiment ("paint light") lives here. |
| `analyse.py` | The measures: `light` (what the light does to the paint), `paint` (the same on a painting's region), `motion` (shimmer on the camera paths), `sheet` (side-by-side boards). |

## Run it

```sh
# The stage, three looks in one run (switched live), each with its paint probe and the two camera paths:
xvfb-run -a godot --path . --rendering-driver vulkan -s res://experiments/render_lab/lab.gd -- \
    --out=build/render_lab/run --look=base,paint_flat,paint --probe --motion
python3 experiments/render_lab/analyse.py light build/render_lab/run/base build/render_lab/run/paint
python3 experiments/render_lab/analyse.py motion build/render_lab/run/base build/render_lab/run/paint

# The game's saloon and street shots under the experiment, with the probe (~15 min each here):
xvfb-run -a godot --path . --rendering-driver vulkan -s res://experiments/render_lab/shots.gd -- \
    --out=build/render_lab/shots_paint --fresh --only=shot_match_saloon,shot_match_street \
    --face-probe --world-probe --lab-look=paint

# Play it (on a real GPU): L switches the look.
godot --path . -s res://experiments/render_lab/play.gd
```

Looks: `base` (the game as it is), `paint` (the experiment), `paint_flat` (the control: the same
colour share at every light level, which is exactly what desaturating every light's colour with
the existing controls would do), `paint_id` (the variant shaders with the rule switched off: must
draw as `base`; measured 0.6/255 mean difference, 1.5 % of pixels over 8/255, all at silhouettes
and shadow edges). The existing surface-blocks look (M) runs with `--blocks` on the command line.

## The paint probe

`--probe` (lab) and `--world-probe` (shots) save, beside each frame, the same frame with every
light out, an even white ambient of 1 and no grade: each pixel is its surface's own colour as it
enters the lighting. `analyse.py light` sets the frame against it: how much brighter the light
makes things (`ratio`), how far it turns their hue (`hue`), how much it inflates their chroma
(`chroma`), how much painted detail survives (`keep`) and how much of the difference between
materials survives (`matkeep`). Painted people (the shot's stylised stranger) draw black in the
probe (their ambient is 0 by design) and are left out of the measures.
