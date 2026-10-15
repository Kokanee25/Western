# Brief: painted light on people (for the art session; from the characters session, 2026-10-15)

## Why

Sean's second style for people (painterly, his paintings `docs/concept/style/portrait-painterly-*`)
is the direction ("it's fucking mint … that's fucking it"). The characters session paints his
head from the paintings with their own light mostly kept (`portrait.json`
`bold_cowboy_painterly_lit`: `delight` 0.15, no squares or patches). Drawn **self-lit** (the skin
shader's painted mode: `self_lit` 0.85) he reads like a finished illustrated character, the look
Sean and ChatGPT both picked out as Salt Creek's identity. But self-lit he barely reacts to the
scene: at a campfire at night he looks as he does at noon, pasted in. Drawn with the **game's
normal material** he reacts (a fire-lit side, the night round him) but the illustration breaks
into blotchy orange planes under the fire and the saloon lamp.

Evidence (all `art_lab.gd`, his head only, the same man and pose):
- `docs/style_test/painterly-2026-10-15/p3_blend.png`: self-lit 0.85 / half (0.5) / the game's
  material, in neutral, campfire at night, powder smoke, warm lamp.
- `p3_lights.png`: the same five lights, front and three-quarter.
- `p2_sheet.png`, `p2_measures.png`: against his paintings (`tools/characters/fidelity_compare.py`).

## What's wanted

His painted shading stays the base of how he looks; each scene light changes only his overall
**colour and amount**, never redraws his form:
- **Shadow** (sun or lamp, his own hat brim included): darkens him, a little cooler, his painted
  shading still readable inside it.
- **Firelight and lamps:** warm the side facing them (a soft, wide wrap, not hard terminators),
  without turning his face into flat orange planes or past his painting's own brightest.
- **Sun and sky:** noon lifts and cools him, dusk warms him; night darkens him to the ambient.
- **Smoke and haze:** veil him like everything else (already on top; just not undone by
  self-lighting).
- One look across people: skin, hair, and the clothes painted the same way (the characters
  session's layered-people brief will paint garments from the paintings too).

A likely shape (yours to choose): in `body_skin.gdshaderinc`'s painted mode, light as a
**low-frequency tint** rather than shading: per light, colour × a smoothed, wrapped amount
(`paint_wrap` wide), its shadow term kept; summed, capped (`paint_limit`) and multiplied onto the
painted colour with a floor (`self_lit` as the floor in the dark, not a fixed add). No light steps
on painted people (`light_steps` 0 looked no different there).

## How to test

```sh
xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/characters/art_lab.gd -- \
  --out=build/pl --id=bold_cowboy_painterly_lit_rodin --turns=5,-45 \
  --lights=neutral,noon,fire,smoke,warm --materials=painted,game --hat=none \
  --look=self_lit:0.85,paint_gain:0.5,light_steps:0,paint_wrap:0.5,paint_limit:1.15,paint_ambient:0.3
```
`--materials=painted` uses the shader's painted mode with `--look`'s values (the lab sets them on
his head only); `game` the game's own. Known lab faults (the characters session's, being fixed):
the noon "post" casts no shadow on him yet; the background after a smoke run can come up white.
Then in the game: the saloon close shot with him seated (`screenshots.gd --only=shot_match_close
--model=bold_cowboy_painterly_lit_rodin`), the street at noon and at dusk.

## Done looks like

On one sheet, his three-quarter in the five lights: he reads as the same illustrated man in all
five (Sean's eye, beside `p3_blend.png`'s top row) **and** each light is plainly there: the
campfire side warm and the rest in night, the noon shadow across his face, the smoke over him, the
lamp's warmth without orange planes. Then the same in the saloon and the street. Frame budget
unchanged (the people row).

## Also from the characters session (already in `character-style-fidelity.md`)

- The white glint under his eyes: `body_skin`'s wet-eye block glosses everything within the
  eyeball's radius + 2 mm; on these heads the lower lid sits nearer the eye's middle than the iris,
  so gloss only eye-coloured paint (or none on painted heads).
- Faces' chroma in the saloon: ACES adds ~13, the warm lamps ~9.
- `scenes/test_street.tscn` spells `volumetric_adjustment_enabled`: its contrast 1.15 and
  saturation 1.12 never apply.
