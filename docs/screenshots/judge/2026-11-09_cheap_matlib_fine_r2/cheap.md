# Cheap judge, 2026-11-09_cheap_matlib_fine_r2

## a
- 1 Flat light: PASS (`380 60 700 160` the two lamp pools on the back wall shape the room; blacks stay black at the sides)
- 2 No atmosphere: PASS (`380 60 700 160` the lamps bloom softly into the air around them)
- 3 Too clean: FAIL (`460 370 490 260`; `a_a_clean_base.png`): the rail, posts and floor patch have no worn edges, no scuffs where boots and elbows would go, no grime at the foot of the panel
- 4 Too straight: FAIL (`495 170 385 210`; `a_a_straight_panel.png`): a dead-flat sheet, every board the same plane, the top edge ruler-straight
- 5 Floating objects: PASS (`470 590 480 40` the floor patch casts a thin shadow line; posts and man have cast shadows)
- 6 Repetition: PASS (`495 170 385 360` board tones and figure vary)
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS (`320 220 640 400` the rail sits at the man's hip, bar height)
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **The panel glows evenly orange like a lit sign** (tell 3, `495 170 385 360`): the varnished boards are the same bright amber top to bottom, with no specular sheen or reflection of the lamps that a varnish would give; it reads as matte veneer lit from inside. Cause: material. Cheapest fix: give the varnish a real glossy specular lobe so each lamp leaves a soft highlight streak on the boards.
2. **Speckled grain and dark dashes** (tell 3, `495 170 385 210`; `a_a_straight_panel.png`): up close the grain is pixel noise and the seams are rows of black dashes, not continuous gaps. Cause: material. Cheapest fix: filter the grain texture (mips/anisotropy) and draw seams as a continuous shaded groove.
3. **Stair-stepped shadows on the pale floor** (tell 1, `470 540 620 180`; `a_floor_shadow_steps.png`): the rail and posts throw shadows with jagged sawtooth edges on the bright patch. Cause: light. Cheapest fix: raise shadow-map resolution or soften with PCF for this light.
4. **No wear where the bar is used** (tell 3, `460 370 490 260`; `a_a_clean_base.png`): rail top, post feet and floor in front are pristine, no rubbed varnish or dirt. Cause: material. Cheapest fix: a wear mask that dulls and lightens the rail top and the floor in front of it.
5. **Ruler-flat board wall** (tell 4, `495 170 385 210`): not a single board cupped or proud of its neighbour. Cause: geometry. Cheapest fix: tiny per-board offsets/tilts in the normal or mesh.

## b
- 1 Flat light: FAIL (`300 0 600 400`; `b_b_dark_wash.png`): a near-black red wash with a faint falloff; you cannot say where the light is or what it is catching
- 2 No atmosphere: N/A (a close-up of a wall)
- 3 Too clean: FAIL (`0 0 1280 720`; `b_b_whole_clean.png`): one uniform dark red surface, no wear, scratches, dust or finish breaks
- 4 Too straight: PASS (`300 0 600 720` the grain wanders; no board edges are visible at all)
- 5 Floating objects: N/A (no contacts in view)
- 6 Repetition: PASS (`0 0 1280 720` no visible tile)
- 7 Empty: N/A (test setup)
- 8 Scale tells: N/A (nothing to compare)
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Underexposed to mush** (tell 1, `300 0 600 400`; `b_b_dark_wash.png`): the panel is almost black with a red cast; a player sees a dark red smear, not wood. Cause: light. Cheapest fix: lift exposure / give the close view a lamp it can read by.
2. **No varnish response** (tell 3, `0 0 1280 720`; `b_b_whole_clean.png`): at this angle a varnished board should mirror the lamps in a long highlight; there is none, so it reads as dyed felt. Cause: material. Cheapest fix: glossier roughness on the varnish layer.
3. **Smeared, streaked grain** (tell 3, `300 0 300 500`): the figure looks stretched and melted rather than cut wood, the knot-like shape at left dissolves into streaks. Cause: material. Cheapest fix: a higher-resolution grain source with crisp pores at close range.
4. **Saturated oxblood hue** (tell 1, `600 0 600 400`): pure red in the darks, not the brown of real mahogany or walnut. Cause: material. Cheapest fix: desaturate the albedo toward brown.
5. **No boards, no seams** (tell 3, `0 0 1280 720`): no board edges show, so it reads as one sheet of laminate. Cause: geometry. Cheapest fix: make the seams catch light at close range.

## c
- 1 Flat light: PASS (`230 380 1050 220` low sun, long cast shadows from man and panels)
- 2 No atmosphere: FAIL (`0 30 520 230`; `c_c_mesa_sharp.png`): the mesa is as crisp and saturated as the foreground panels; no haze between
- 3 Too clean: FAIL (`465 380 480 250`; `c_c_clean_base.png`): floor patch, posts and rail free of dust or wear in a desert; no sand drift at the base
- 4 Too straight: FAIL (`495 170 385 360`; `c_c_straight_panel.png`): perfectly plumb boards, identical seam spacing, dead-flat panel
- 5 Floating objects: PASS (`465 600 480 40` the patch and the man's boots sit with shadows)
- 6 Repetition: PASS (`0 170 1280 460` three identical panels are the test setup; boards vary in tone)
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS (`320 220 640 400` rail at the man's hip)
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Fire-engine red wood** (tell 3, `495 170 385 360`; `c_c_straight_panel.png`): the boards are a saturated orange-red that no varnished hardwood takes in daylight; it reads as painted plastic. Cause: material. Cheapest fix: pull the albedo toward a brown mahogany and drop saturation.
2. **Noisy speckle on the boards** (tell 3, `750 170 130 360`): several boards are sprinkled with pixel noise, as if a low-res texture were sharpened; it shimmers and looks cheap. Cause: material. Cheapest fix: filter/mipmap the grain and lose the speckle.
3. **Distance as sharp as the foreground** (tell 2, `0 30 520 230`; `c_c_mesa_sharp.png`): the mesa has full contrast and colour, so the world looks like a backdrop pasted close. Cause: light. Cheapest fix: aerial perspective/fog that pales and blues the far rock.
4. **Clean bar and floor in the desert** (tell 3, `465 380 480 250`; `c_c_clean_base.png`): no dust settled on the floor boards or the rail top. Cause: material. Cheapest fix: a dust layer on up-facing wood, heavier near the ground.
5. **Dashed seams, flat plane** (tell 4, `495 170 385 360`): seams are broken black dashes and every board lies in the same plane. Cause: geometry. Cheapest fix: continuous groove shading and slight per-board relief.

## d
- 1 Flat light: PASS (`380 60 700 160` lamp pools on the wall; the room falls off to black)
- 2 No atmosphere: PASS (`380 60 700 160` the lamps bloom into the air)
- 3 Too clean: FAIL (`465 370 480 260`; `d_d_clean_base.png`): the rail, posts and floor show no wear, nothing rubbed, nothing spilled
- 4 Too straight: FAIL (`495 170 385 210`; `d_d_straight_panel.png`): one flat, perfectly rectangular sheet
- 5 Floating objects: PASS (`465 590 480 40` the patch and posts have shadows on the pale floor)
- 6 Repetition: FAIL (`500 170 380 360`; `d_d_streak_repeat.png`): the same fine vertical streak runs evenly over the whole panel like a combed pattern
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS (`320 220 640 400`)
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **The panel reads as a red velvet curtain** (tell 6, `500 170 380 360`; `d_d_streak_repeat.png`): saturated crimson with even vertical streaks and no board edges; a player would not call it wood. Cause: material. Cheapest fix: browner albedo and visible board seams.
2. **The rail and posts crushed to black** (tell 3, `465 370 480 260`; `d_d_clean_base.png`): the bar rail, the very thing on test, is a black silhouette with no grain or sheen. Cause: light. Cheapest fix: let the lamps rake the rail top so its varnish catches a highlight.
3. **Glow at the panel's top corners only** (tell 3, `495 170 385 210`): hot orange edges where the lamps hit, the middle dark, no specular shape. Cause: material. Cheapest fix: a varnish specular so the lamps show as reflections, not a tint.
4. **Jagged shadows on the pale floor** (tell 4, `480 600 500 100`): sawtooth shadow edges from rail and posts. Cause: light. Cheapest fix: softer, higher-resolution shadows for the lamp.
5. **Dead-flat wall** (tell 4, `495 170 385 210`; `d_d_straight_panel.png`): no warp or relief anywhere. Cause: geometry. Cheapest fix: per-board relief.

## e
- 1 Flat light: PASS (`0 0 1280 500` the light falls off down the panel; grooves catch thin highlights)
- 2 No atmosphere: N/A (a close-up)
- 3 Too clean: FAIL (`300 0 700 500`; `e_e_clean.png`): no scratches, dents, worn edges or dust on any board; the finish uniform end to end
- 4 Too straight: FAIL (`560 0 500 400`; `e_e_even_grooves.png`): grooves evenly spaced, equally deep, perfectly straight
- 5 Floating objects: N/A (no contacts readable; the black blob lower left is shadow)
- 6 Repetition: PASS (`0 0 1280 720` the figure differs board to board)
- 7 Empty: N/A (test setup)
- 8 Scale tells: N/A
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: good indie**
1. **Very dark, little to read** (tell 1, `0 0 1280 720`): the panel sits near black-purple; the wood is believable but you have to squint. Cause: light. Cheapest fix: lift exposure or fill in the shade.
2. **Perfect even grooves** (tell 4, `560 0 500 400`; `e_e_even_grooves.png`): every bead the same depth and spacing, no board wider, cupped or opened up. Cause: geometry. Cheapest fix: vary board widths and groove depths slightly.
3. **No wear at all** (tell 3, `300 0 700 500`; `e_e_clean.png`): no knocks, worn edges or dust in the grooves. Cause: material. Cheapest fix: dust/grime packed into the grooves and dulled edges.
4. **Purple-red cast** (tell 3, `300 0 700 500`): the darks drift toward purple, unlike brown hardwood. Cause: material. Cheapest fix: shift the albedo hue toward brown.
5. **Crushed black corner** (tell 1, `0 480 300 240`): a featureless black blob with no detail. Cause: light. Cheapest fix: a little fill so shadows keep shape.

## f
- 1 Flat light: PASS (`0 480 1280 160` sun with crisp cast shadows on sand and floor patch)
- 2 No atmosphere: FAIL (`0 20 530 240`; `f_f_mesa_sharp.png`): the mesa is as crisp as the near panel, and the sky's clouds are flat posterised shapes
- 3 Too clean: FAIL (`465 380 480 250`; `f_f_clean_base.png`): no sand blown onto the floor patch, no worn rail, no scuffs
- 4 Too straight: FAIL (`495 170 385 360`; `f_f_straight_panel.png`): all boards plumb, evenly spaced, flat
- 5 Floating objects: PASS (`465 600 480 40` the patch, posts and boots all sit with shadows)
- 6 Repetition: PASS (`0 170 1280 460` three panels are the setup; boards vary)
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS (`320 220 640 400`)
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Matte, not varnished** (tell 3, `495 170 385 360`; `f_f_straight_panel.png`): a believable dark stained board, but with no sheen at all in full sun it reads as rough barn siding, not fine bar wood. Cause: material. Cheapest fix: glossier varnish roughness with a visible sun highlight.
2. **Posterised sky and a crisp mesa** (tell 2, `0 20 530 240`; `f_f_mesa_sharp.png`): flat-edged cloud shapes and a far cliff with no haze. Cause: light. Cheapest fix: aerial haze on the distance; a softer sky.
3. **Spotless floor patch in the desert** (tell 3, `465 380 480 250`; `f_f_clean_base.png`): no dust, sand or footworn path. Cause: material. Cheapest fix: dust on up-facing boards.
4. **Dashed seams on the floor** (tell 4, `465 520 480 110`): the floor board gaps are black dashes, stair-stepped at the far edge. Cause: material. Cheapest fix: continuous seam lines with filtering.
5. **Ruler-straight boards** (tell 4, `495 170 385 360`): no warp, no lean, no board standing proud. Cause: geometry. Cheapest fix: per-board offsets.

## g
- 1 Flat light: PASS (`0 320 1280 90` a soft sheen along the rail; the rest falls into dark)
- 2 No atmosphere: N/A (a close-up)
- 3 Too clean: FAIL (`180 410 960 310`; `g_g_clean_floor.png`): the floor in front of the bar has no scuffs, spills or worn path
- 4 Too straight: FAIL (`180 410 960 310`; `g_g_straight_floor.png`): floor boards dead parallel, equal width, no warp
- 5 Floating objects: PASS (`0 400 1280 40` the rail's underside throws a dark band onto the floor)
- 6 Repetition: FAIL (`0 320 1280 90`; `g_g_rings_repeat.png`): the glass rings repeat along the rail at even spacing and identical size
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS (`0 80 1280 330` rings sized to a glass against the hand)
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: cheap indie**
1. **Stamped glass rings** (tell 6, `0 320 1280 90`; `g_g_rings_repeat.png`): thin bright circles at metronome spacing; a player sees a decal pattern, not years of glasses. Cause: material. Cheapest fix: vary ring size, opacity and spacing, cluster them where a drinker stands.
2. **Crushed and red** (tell 3, `180 410 960 310`; `g_g_clean_floor.png`): the floor and panel are a black-red murk. Cause: light. Cheapest fix: more lamp reach onto the bar area.
3. **No rubbed varnish on the rail** (tell 3, `0 320 1280 90`): the top is uniform apart from the rings; no elbow-worn dull band at the front edge. Cause: material. Cheapest fix: a worn band along the customer edge.
4. **Floor boards perfectly regular** (tell 4, `180 410 960 310`; `g_g_straight_floor.png`): same width, same gap. Cause: geometry. Cheapest fix: vary board widths and gaps.
5. **Blown-out white wedge** (tell 1, `1050 445 230 275`): the floor beyond is a flat, textureless bright shape against the black. Cause: light. Cheapest fix: texture and darken the test floor.

## h
- 1 Flat light: PASS (`180 560 980 120` hard sun with a clear rail shadow across the floor)
- 2 No atmosphere: N/A (a close-up)
- 3 Too clean: PASS (`0 320 1280 90` glass rings and a fine crackle on the rail; weathered pale patches on the panel's left edge)
- 4 Too straight: FAIL (`180 420 980 300`; `h_h_straight_floor.png`): floor boards dead parallel, equal width, perfectly flat
- 5 Floating objects: PASS (`0 260 1280 380` the panel and floor cast shadows on the sand)
- 6 Repetition: PASS (`0 320 1280 90` the rings vary here)
- 7 Empty: N/A (test setup)
- 8 Scale tells: PASS (`0 260 300 320` rail against hand and boot)
- 9 Edges of the world: N/A (test setup)
- 10 Stiff people: N/A (a still)
- **Verdict: good indie**
1. **Speckled grain on the floor** (tell 4, `180 420 980 300`; `h_h_straight_floor.png`): board grain is pixel noise rather than grain; it shimmers. Cause: material. Cheapest fix: filter/mipmap the floor texture.
2. **Sawtooth shadow edges** (tell 4, `500 580 660 80`): the rail's shadow has a stair-stepped edge. Cause: light. Cheapest fix: higher sun shadow resolution / softer filter.
3. **Crackle drawn like a map** (tell 3, `400 330 880 70`): the varnish cracks are thin uniform lines in jigsaw shapes, a bit graphic. Cause: material. Cheapest fix: break up crack width and fade them into the grain.
4. **Rail and floor still matte** (tell 3, `0 320 1280 120`): in full sun a varnished rail should show a sheen; it reads oiled at best. Cause: material. Cheapest fix: a gloss lobe on the rail top.
5. **Perfect floor boards** (tell 4, `180 420 980 300`): no cupping, no gap variation, no board end. Cause: geometry. Cheapest fix: vary gaps and add butt joints.

## Ranking
From least to most cheap-looking: h, e, f, a, g, c, d, b

## The man and the wood
- **a** (the whole man, night): partly. Same warm lamp key on both, but the man is sharper with more detail per metre (vest weave, face modelling), while the panel is a speckled, evenly glowing amber sheet with no varnish highlight.
- **c** (the whole man, low sun): no. The man is in natural, muted browns with soft shading and scuffed boots; the wood is saturated fire-engine red with noisy speckle and dashed seams, and looks like it came from a cheaper game.
- **d** (the whole man, night): no. The man is lit and readable; the panel is a crimson streaked curtain and the rail is crushed black, a different colour world and much less detail.
- **f** (the whole man, day): partly. Colour and sun agree (both browns, same shadows), but the man carries more detail and wear per metre than the uniform, matte boards with dashed seams.
- **g** (his sleeve and hand only, night): partly. The sleeve and hand are lit warm and detailed while the rail and floor sink into black-red; the rail's stamped rings look more graphic than his cloth.
- **h** (his sleeve, hand, trousers and boot, day): yes. Same sun, similar sharpness; only the floor's speckled grain is noisier than his cloth.

Overall: in daylight with the browner wood (f, h) the man and the wood sit in one game; the saturated red woods and the night lighting (a, c, d, g) put the man in a better-made game than the wood beside him.
