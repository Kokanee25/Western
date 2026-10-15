# Painted light on people (roadmap 1.2, art's half; 2026-10-15)

The characters session's brief `docs/briefs/painted-light.md` (on `claude/characters-portrait-factory`):
a painterly man keeps his painting, and each light changes only his colour and amount.

`v5_lights.jpg`: his head in `tools/characters/art_lab.gd`'s five lights (neutral, noon, campfire at
night, powder smoke, warm lamp), three-quarter and front:
- **Self-lit 0.85** (the brief's): the same man in every light.
- **The game's material:** orange planes under the fire and the lamp.
- **Painted light (v5):** the painting kept. The campfire warms the side facing it and the rest
  falls into night; the lamp warms him without planes; smoke veils him; neutral and noon read as
  the painting. The noon post's shadow doesn't fall on him in the lab yet (a known lab fault).

## What changed in `body_skin.gdshaderinc`

- `paint_tint` (default 0 = as before): how much of each light's own colour reaches a painted part.
  Eased channel by channel towards `paint_limit`, so a hot orange lamp warms him without driving
  his face to flat orange.
- No wet-eye glint on painted heads: their glints are painted in, and the eyeball's radius reached
  the lower lid, which glinted white (the brief's side item).

## The look (v5)

`self_lit 0.12, paint_gain 1.6, paint_wrap 0.25, paint_limit 1.6, light_steps 0, paint_ambient 0.5,
paint_tint 0.75`

```sh
xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/characters/art_lab.gd -- \
  --out=build/pl --id=bold_cowboy_painterly_lit_rodin --turns=5,-45 \
  --lights=neutral,noon,fire,smoke,warm --materials=painted --hat=none \
  --look=self_lit:0.12,paint_gain:1.6,light_steps:0,paint_wrap:0.25,paint_limit:1.6,paint_ambient:0.5,paint_tint:0.75
```

## What it needs to reach the game

In the game his head is drawn with the ordinary material: a person is painted only when
`assets/people/<model>_paint.json` and its `paint_<shape>` textures exist (`people_bodies.gd`), as the
outlaw is. And every painted person shares one look, `HumanBody.paint_look` (the outlaw's hybrid
finish: self_lit 0, paint_gain 2.2, ambient 1). So:
1. Characters: `bold_cowboy_painterly_lit_rodin_paint.json` (each shape's `uv_rect` 0,0,1,1) and
   its paint textures, so the game draws him painted.
2. A look per model: v5 above for him while the outlaw keeps his. For example, a `"look"` in the
   paint json, read by `people_bodies.gd` (characters) and laid over `paint_look` by
   `human_body.gd` (gameplay's, a few lines).

The remaining brief items are not done here. Faces' chroma in the saloon (ACES +13, warm lamps +9)
needs measuring with him painted. `scenes/test_street.tscn`'s misspelt
`volumetric_adjustment_enabled` changes the whole street's contrast and saturation once fixed, so
it needs a look review and new goldens of its own.

## In the game (roadmap 1.2's sheet, 2026-10-15, after the characters session's merge, PR #124)

`in_game.jpg`: the painterly cowboy (`bold_cowboy_painterly_lit_rodin`, drawn painted with his own
look, v5) beside his portrait, at the card table at night (`shot_match_close`) and standing in the
street at golden hour (`face_street_golden`, a new view: the low sun behind you, framed on his face),
each with his face as the game draws it and as painted (unlit). Rendered on main (d4b25b1) plus only
the new view. Numbers from `tools/face_light.py` (`*_face.json`; the hold: p90 under ~1.3, nothing
clipped):

| | face light median | p90 | clipped | L* game (paint) |
|---|---|---|---|---|
| saloon at night | 1.03 | 1.16 | 0% | 48 (47) |
| street, golden hour | 0.61 | 0.78 | 0% | 34 (47) |

- **Saloon:** passes. His painting holds under the lamp: no burnt orange, no clipping, eyes readable
  under the brim, a lit and a shadow cheek.
- **Street:** doesn't yet. He's drawn at about 0.6 of his paint (L* 34 to 47) and redder, though he
  faces the low sun. Likely `paint_tint` 0.75 taking the golden-hour sun's deep orange, which cuts
  his green and blue; not yet tested. That's art's knob, the next 1.2 fix if Sean wants him lighter.

```sh
xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd -- --out=DIR \
  --only=shot_match_close,face_street_golden --model=bold_cowboy_painterly_lit_rodin --face-probe --fresh
python3 tools/face_light.py DIR --view=face_street_golden
```
