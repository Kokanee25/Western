# Cheap judge, 2026-11-08_cheap_matlib_fine

## a
- 1 Flat light: PASS (the lamps' pools on the back wall and the panel's warm top-right falloff give a clear source; blacks stay black)
- 2 No atmosphere: FAIL (`380 60 700 200`; `a_a_lamp_air.png`): the lamp glows sit on the wall as flat discs; no air or haze in the beam between lamp and panel
- 3 Too clean: FAIL (`465 370 480 260`; `a_a_rail_clean.png`): rail, posts and floor patch are factory-new; no rub on the rail's top, no dulled varnish where hands and boots would go, no grime at the floor's edge
- 4 Too straight: FAIL (`460 365 500 30`; `a_a_rail_straight.png`): rail dead level, posts plumb, every board edge ruler-true
- 5 Floating objects: PASS (the panel, posts and patch sit with shadow; the man's feet in shade)
- 6 Repetition: PASS (the boards vary in tone and figure)
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS (rail at the man's belt, panel about his height plus a head)
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: good indie**
1. **Varnish with no use on it** (tell 3, `465 370 480 260`): a bar rail and floor patch that look delivered this morning; the boards read as real hardwood, but nothing on them says a hand, glass or boot ever touched them. Cause: material. Cheapest fix: a worn, dulled band along the rail's top and front edge and scuffed, matte varnish on the floor patch where feet stand.
2. **Stair-stepped shadow edges on the floor** (tell 1, `480 600 520 120`): the cast shadows of the rail and posts on the pale floor have jagged, blocky edges, the one thing that screams "engine" in an otherwise soft picture. Cause: light. Cheapest fix: softer/filtered shadow edges (more PCF samples or a larger light size) for the lamps.
3. **No air in the lamplight** (tell 2, `380 60 700 200`): the lamps paint discs on the wall but the room has no volume; RDR2's saloons hold a warm haze between lamp and wood. Cause: light. Cheapest fix: a faint volumetric fog in the room so the beams have a body.
4. **Ruler-straight joinery** (tell 4, `460 365 500 30`): rail and posts perfect; reads as CAD. Cause: geometry. Cheapest fix: round the rail's top edge and break the corners slightly (a bevel catches the lamp and reads as handled wood).
5. **The highlight is a sheen, not a varnish** (tell 3, `495 170 385 360`): the panel brightens toward the lamp but never shows a sharp specular streak or reflection; varnished wood under a lamp would. Cause: material. Cheapest fix: lower roughness on the varnish layer so a lamp's reflection sits on the boards.

## b
- 1 Flat light: FAIL (`300 100 600 500`; `b_b_flat_red.png`): a dim, even red murk; no highlight, no gradient you could point a lamp at
- 2 No atmosphere: N/A (a close-up of one surface)
- 3 Too clean: FAIL (`600 200 500 400`; `b_b_no_wear.png`): no dents, scratches, rings or dulled patches anywhere on a bar face seen from a foot away
- 4 Too straight: PASS (the grain wanders and the figure sways)
- 5 Floating objects: N/A (no contact shown)
- 6 Repetition: PASS (no visible tile at this distance)
- 7 Empty: N/A (test setup)
- 8 Scale tells: N/A (nothing to measure against; but see reason 3)
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Monochrome red murk** (tell 1, `300 100 600 500`): the whole frame is one dark oxblood, crushed toward black; a player can't tell it's varnished, lit, or even what it is. Cause: light. Cheapest fix: let the lamp's specular reach the surface (lower roughness) so the varnish throws a highlight.
2. **Stock-texture look up close** (tell 3, `600 200 500 400`): the grain is noisy, smeared streaks like a stretched photo, with no wear, no pores filled with dirt, no finish. Cause: material. Cheapest fix: a roughness/wear map with handling marks so the surface isn't the same everywhere.
3. **No board seams** (tell 3, `0 0 1280 720`): a wall of "narrow boards" shows no joints at this distance; it reads as one veneer sheet. Cause: material. Cheapest fix: draw the seams (a thin dark groove with a lit edge) in the close-up's mip.
4. **Saturation too high for old varnish** (tell 3, `300 100 600 500`): the red is a pure dyed red rather than an aged amber-brown; old shellac yellows and darkens. Cause: material. Cheapest fix: shift the albedo toward brown/amber and lower its chroma.
5. **Black corners with nothing in them** (tell 1, `1150 380 130 340`): the lower-right falls into flat black with a hard edge; reads as missing light, not shadow. Cause: light. Cheapest fix: a little bounce fill so the off-panel area has form.

## c
- 1 Flat light: PASS (low sun from the left; long shadows from the man and the panels)
- 2 No atmosphere: FAIL (`0 20 530 240`; `c_c_mesa_sharp.png`): the far mesa is as sharp and saturated as the foreground panel; no haze in a desert at low sun
- 3 Too clean: FAIL (`495 170 385 360`; `c_c_panel_clean.png`): the panel is a uniform candy red from top to bottom, no sun bleach, no dust at its foot
- 4 Too straight: FAIL (`460 370 490 260`; `c_c_rail_straight.png`): rail, posts and panels perfectly plumb and level
- 5 Floating objects: PASS (feet, posts and panels throw shadows onto the sand)
- 6 Repetition: FAIL (`230 255 900 50`; `c_c_rocks_repeat.png`): the same grey-green pebble blob scattered across the flat
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS (the man to the rail and panel reads right)
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Light leaking through the board seams** (tell 3, `500 170 380 140`; `c_c_seam_gaps.png`): dozens of pale grey dashes run down the joints of the centre panel, as if sky shows through gaps in the boards; a player reads it as a rendering bug. Cause: geometry. Cheapest fix: close the seams (overlap the boards or put a backing behind them) so no background shows through.
2. **Candy-red wood in desert sun** (tell 3, `495 170 385 360`): the wood reads as glossy red-painted plastic, not varnished hardwood; the colour is too saturated and too even. Cause: material. Cheapest fix: bring the albedo's chroma down and toward brown, and let the sun's specular sit on the varnish.
3. **No air in the distance** (tell 2, `0 20 530 240`): the mesa is crisp and full-colour behind a foreground at the same contrast; RDR2's golden hour fades every layer into warm dust. Cause: light. Cheapest fix: stronger aerial perspective/haze by distance.
4. **Repeated pebbles** (tell 6, `230 255 900 50`): one rock mesh copied all over the flat at one size. Cause: dressing. Cheapest fix: vary the rocks' scale, rotation and tint, or use two or three meshes.
5. **A hard dark block across the man's hip** (tell 5, `400 380 50 20`): a rectangular shadow sits on his right hip and hand with no obvious caster; reads as a shadow artifact. Cause: light. Cheapest fix: check the shadow bias/caster there (likely a self-shadow or a mis-placed shadow mesh).

## d
- 1 Flat light: PASS (same lamps as a: clear source, real shadow)
- 2 No atmosphere: FAIL (`380 60 700 200`; `d_d_lamp_air.png`): the lamp pools are flat discs on the wall; no haze in the beams
- 3 Too clean: FAIL (`495 170 385 360`; `d_d_panel_clean.png`): the panel is one uniform red streak-figure from end to end, no wear or finish variation
- 4 Too straight: FAIL (`460 365 490 260`; `d_d_rail_straight.png`): rail and posts ruler-true
- 5 Floating objects: PASS (the patch and posts sit with shadow)
- 6 Repetition: PASS (the panel's figure doesn't visibly tile)
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Reads as one sheet of red veneer** (tell 3, `495 170 385 360`): the fine, even streaked figure hides every board joint, so the "narrow boards" look like a laminate panel with a saturated red stain. Cause: material. Cheapest fix: let each board have its own tone and show the joints.
2. **Floor patch with stamped dashes and white specks** (tell 3, `470 530 470 100`; `d_d_floor.png`): the floor is a red smear with little regular black dashes and two pale specular blobs floating on it; reads as a texture, not a floor. Cause: material. Cheapest fix: proper board seams and a roughness map so the highlight lies along the boards instead of as two spots.
3. **Stair-stepped shadow edges** (tell 1, `480 600 520 120`): the cast shadows on the pale floor have the same jagged, blocky edges as a. Cause: light. Cheapest fix: softer filtered shadows on the lamps.
4. **No air in the lamplight** (tell 2, `380 60 700 200`): the room has no volume between lamp and wood. Cause: light. Cheapest fix: faint room fog.
5. **Too red, too saturated** (tell 3, `495 170 385 360`): the panel glows a dyed cherry; under warm lamps old varnished hardwood would read deeper and browner. Cause: material. Cheapest fix: lower the albedo's chroma and shift it toward brown.

## e
- 1 Flat light: PASS (the light rakes across the boards and the grooves catch it; a hard cast shadow bottom-left)
- 2 No atmosphere: N/A (a close-up of one surface)
- 3 Too clean: FAIL (`250 0 600 400`; `e_e_no_wear.png`): no scratches, dents or dulled varnish on any board up close
- 4 Too straight: PASS (the boards are visibly separate with grain that wanders)
- 5 Floating objects: N/A (no contact shown)
- 6 Repetition: FAIL (`850 100 430 300`; `e_e_sheen_repeat.png`): the same pale diagonal sheen stripe repeats on every board at the same angle and length
- 7 Empty: N/A (test setup)
- 8 Scale tells: N/A (nothing to measure against)
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Identical sheen stripes on every board** (tell 6, `850 100 430 300`): a row of pale, blurred diagonal streaks, one per board, all alike; reads as a shader artifact rather than a reflection. Cause: material. Cheapest fix: break the highlight up with a per-board roughness variation so no two boards catch light the same way.
2. **White slivers in the seams** (tell 3, `400 0 400 300`; `e_e_seam_light.png`): thin bright lines run down the joints at the top, the same leak as c's dashes. Cause: geometry. Cheapest fix: close the gap behind the seams.
3. **No wear up close** (tell 3, `250 0 600 400`): a bar's face seen from a foot away with not a scratch, ring or dulled patch. Cause: material. Cheapest fix: handling marks and dulled varnish in the roughness map.
4. **Dark oxblood with crushed blacks** (tell 1, `0 0 1280 720`): the wood sits close to black-red; the grain only shows where the light hits it. Cause: light. Cheapest fix: a touch of bounce fill and a less saturated, browner albedo.
5. **Hard black shadow wedge** (tell 1, `0 460 250 260`): the shadow bottom-left is a flat, pure-black shape with a hard edge; no bounce in it. Cause: light. Cheapest fix: softer shadow edge and some fill.

## f
- 1 Flat light: PASS (noon sun from high left-front; short hard shadows under the rail, posts and man)
- 2 No atmosphere: FAIL (`10 25 520 230`; `f_f_mesa_sharp.png`): the far mesa as sharp and contrasty as the panels in front
- 3 Too clean: FAIL (`495 170 385 360`; `f_f_panel_dashes.png`): the panel is an even brown-red with no sun bleach, dust or weathering
- 4 Too straight: FAIL (`460 370 490 260`; `f_f_rail_straight.png`): rail level, posts plumb, panels flat
- 5 Floating objects: PASS (everything sits on its shadow)
- 6 Repetition: FAIL (`230 255 900 50`; `f_f_rocks_repeat.png`): one grey pebble copied across the flat
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Pale dashes scattered over the panel** (tell 3, `495 170 385 360`; `f_f_panel_dashes.png`): dozens of short grey-white slits along the seams, like rain or holes; the first thing a player notices, and it reads as a bug. Cause: geometry. Cheapest fix: close the seams so the sky doesn't show through.
2. **Floor patch with specks and stamped dashes** (tell 3, `470 530 470 100`; `f_f_floor_specks.png`): the floor patch is covered in tiny regular light flecks; reads as a noisy texture, not boards. Cause: material. Cheapest fix: clean board seams and a quieter albedo.
3. **Painted, posterised sky** (tell 2, `0 0 1280 250`): the clouds are flat painted shapes with hard edges, a different style from the realistic mesa and wood; reads as a backdrop. Cause: light. Cheapest fix: a softer, photographic sky or more blur and haze in the clouds.
4. **No haze at distance** (tell 2, `10 25 520 230`): the mesa has no air in front of it. Cause: light. Cheapest fix: distance haze.
5. **Repeated pebbles** (tell 6, `230 255 900 50`): one rock mesh at one size everywhere. Cause: dressing. Cheapest fix: vary scale, rotation and tint.

## Ranking
From least to most cheap-looking: a, d, f, c, b, e

## The man and the wood
- **a: partly.** Under the same lamps the man sits right in tone (warm, dim, dark blacks), but he is soft and smooth, painted-looking with little detail per metre, while the panel beside him is crisp photographic grain and brighter, more saturated orange; the wood looks more "real" than he does.
- **c: partly.** The man is the more believable thing in the frame: his brocade vest, cloth and boots have muted, worn colour and soft daylight on them, while the wood is a glossy, saturated candy red with no sun bleach or dust; the wood looks like a toy beside him (and the leak dashes make it look broken). Sharpness is close; colour and wear differ most.
- **d: partly.** Light and tone match (both dim under the lamps), but the panel's cherry red is far more saturated than anything on him and its fine streaked figure is sharper than his soft, smooth clothes.
- **f: partly.** The muted brown-red wood is closer to his vest's palette than c's, and the sun sits on both alike; but the wood is spotless and noisy (dashes, specks) while he has a little wear and soft, painted shading; the wood's detail is finer per metre than his.

Overall: partly: the light sits on man and wood alike, but the man is soft, matte and lightly worn while the wood is sharper, far more saturated and spotless, so they read as two different asset sources.
