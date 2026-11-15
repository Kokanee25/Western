# Cheap judge, 2026-11-13_valley_ground_r2_cheap

## a
- 1 Flat light: FAIL (`780 150 500 240`; `a_flat.png`)
- 2 No atmosphere: PASS (the far end of the street pales into haze)
- 3 Too clean: FAIL (`0 270 320 225`; `a_clean.png`)
- 4 Too straight: FAIL (`70 370 490 120`; `a_straight.png`)
- 5 Floating objects: FAIL (`700 355 580 40`; `a_base.png`)
- 6 Repetition: FAIL (`320 290 210 105`; `a_tile.png`)
- 7 Empty: FAIL (`560 330 400 200`; `a_empty.png`)
- 8 Scale tells: PASS (steps, boardwalk and the hotel's doors and windows sit right for each other)
- 9 Edges of the world: FAIL (`560 310 140 70`; `a_end.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Camouflage-pattern stone wall** (tell 3, `0 270 320 225`): the stone building on the left is covered in a pixelated, blotchy texture with blue and purple smears. It reads as military camo or a broken texture, not stone. The blocks are visible squares with no mortar depth, chipping or dirt at the foot. Cause: material. Cheapest fix: replace it with a real sandstone or adobe material (warm, low saturation, mortar lines, darkening near the ground).
2. **Empty street at noon** (tell 7, `560 330 400 200`): a wide main street with no people, horses, wagons, barrels, hitching rails or litter. The one table set on the right only makes the emptiness more obvious. Cause: dressing. Cheapest fix: hitching rails, a wagon and a few barrels and crates along both boardwalks.
3. **Right-hand buildings in a dull grey shade** (tell 1, `780 150 500 240`): the whole hotel front is one even, lifted blue-grey. There are no shadow shapes from the balcony or eaves, and nothing shows where the sun is. The ground in front of it has no cast shadow from the buildings either. Cause: light. Cheapest fix: a lower sun angle so the fronts cast long shadows across the street, and deeper ambient occlusion under the balconies.
4. **Ruler-straight boxes** (tell 4, `70 370 490 120`): the boardwalk is a perfectly level slab and the stone blocks are clean cuboids. Nothing sags, leans or steps out of line. Cause: geometry. Cheapest fix: give the boardwalk uneven boards with a slight sag between posts, and break the stone rooflines.
5. **Buildings pasted on the ground** (tell 5, `700 355 580 40`): the hotel's base meets the dirt in one hard line with no darkening, kicked-up dirt or weeds. Cause: light. Cheapest fix: a dark contact band and a dusty skirt along every wall's foot.

## b
- 1 Flat light: PASS (low sun behind the street, long shadows, warm rim on the hotel)
- 2 No atmosphere: PASS (the sun glows through haze at the end of the street)
- 3 Too clean: FAIL (`0 270 320 225`; `b_clean.png`)
- 4 Too straight: FAIL (`70 370 490 120`; `b_straight.png`)
- 5 Floating objects: PASS (the hotel and the table set now cast shadows onto the dirt)
- 6 Repetition: FAIL (`320 290 210 105`; `b_tile.png`)
- 7 Empty: FAIL (`560 330 400 200`; `b_empty.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 0 800 260`; `b_sky.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Posterised sky** (tell 9, `0 0 800 260`): the clouds are hard-edged flat bands of orange, cream and purple, like a posterised photo or a swirl filter. It is the first thing a player sees and it reads as a painted dome, not air. Cause: light. Cheapest fix: remove the colour banding (more steps, or dithering) and soften the cloud edges so they grade into the sky.
2. **Camo stone texture** (tell 3, `0 270 320 225`): even in warm light, the left building is the same blotchy, pixelated pattern on every block, with no dirt or wear at the base. Cause: material. Cheapest fix: a real stone or adobe material with grime rising from the ground.
3. **Nobody lives here** (tell 7, `560 330 400 200`): a lovely sunset street with no figure, horse, wagon or crate in it. The single lit lamp on the right table hints at life and then nothing follows. Cause: dressing. Cheapest fix: a rider or two silhouetted against the sun, and rails and barrels on the boardwalks.
4. **Clean-cut boxes** (tell 4, `70 370 490 120`): a perfectly level boardwalk slab and box-shaped stone buildings. Cause: geometry. Cheapest fix: uneven boards and posts, broken rooflines, an awning or two.
5. **The same block texture repeating** (tell 6, `320 290 210 105`): the same blotch layout repeats block after block down the wall. Cause: material. Cheapest fix: randomise the texture offset per block and vary the tint.

## c
- 1 Flat light: PASS (shrubs cast clear shadows, the ruts have shape)
- 2 No atmosphere: PASS (the tree line fades into haze)
- 3 Too clean: FAIL (`700 450 580 270`; `c_ground.png`)
- 4 Too straight: FAIL (`330 360 400 360`; `c_straight.png`)
- 5 Floating objects: PASS (bushes sit in their own shadows)
- 6 Repetition: FAIL (`0 360 600 120`; `c_shrubs.png`)
- 7 Empty: PASS (an open trail across a plain; the distant gate and tree line give it a destination)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`300 0 700 280`, `900 300 380 70`; `c_sky.png`, `c_horizon.png`)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Posterised sky** (tell 9, `300 0 700 280`): half the frame is clouds made of flat, hard-stepped colour bands. It looks like a filter over a photo, not weather. Cause: light. Cheapest fix: smooth the sky's gradients and soften the cloud edges.
2. **Dead-flat horizon with a band behind the trees** (tell 9, `900 300 380 70`): the land ends in a ruler line, and a flat grey strip sits behind the trees on the right like a wall. Cause: geometry. Cheapest fix: distant low hills or a ridge line in haze, broken up rather than straight.
3. **Black shrub clones** (tell 6, `0 360 600 120`): the same dark, near-black bush repeats across the plain at the same size. The bushes are unlit, so they read as cut-out silhouettes in full daylight. Cause: material. Cheapest fix: two or three bush variants with a lit, sage-green top and random scale.
4. **One even ground colour** (tell 3, `700 450 580 270`): the sand is the same tone and grain from the foreground to the horizon. There are no darker patches, washes, rocks or grass clusters. Cause: material. Cheapest fix: large-scale colour variation (darker gravel patches, paler washes) blended over the ground.
5. **Road straight to the vanishing point** (tell 4, `330 360 400 360`): the twin ruts run perfectly straight and parallel to the horizon. Cause: geometry. Cheapest fix: a gentle curve and a dip so the road follows the land.

## d
- 1 Flat light: PASS (shadows from the bushes and a large tree shadow across the right)
- 2 No atmosphere: PASS (layers of trees step back into haze)
- 3 Too clean: FAIL (`700 450 580 270`; `d_ground.png`)
- 4 Too straight: FAIL (`450 360 380 360`; `d_straight.png`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 260 1100 110`; `d_trees.png`)
- 7 Empty: PASS (a track through scattered trees and brush)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`300 0 700 280`; `d_sky.png`)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Posterised sky** (tell 9, `300 0 700 280`): flat stepped bands of grey, cream and blue with smeared, swirled edges. It reads as a filtered texture over the whole top of the frame. Cause: light. Cheapest fix: remove the banding and let the clouds grade softly.
2. **Cloned lumpy trees** (tell 6, `0 260 1100 110`): every tree is the same stacked-blob shape with pixelated edges. Copies stand in a row at similar spacing, flat grey with no lit side. Cause: geometry. Cheapest fix: three or four tree shapes with random scale and rotation, and a sunlit side on each canopy.
3. **Uniform sand** (tell 3, `700 450 580 270`): the same sandy tone everywhere, with no gravel patches, washes or tufts clustering anywhere. Cause: material. Cheapest fix: large-scale tone variation and some rocks.
4. **Arrow-straight track** (tell 4, `450 360 380 360`): the road runs dead straight to the vanishing point over perfectly flat land. Cause: geometry. Cheapest fix: a curve and a rise in the ground.
5. **Same tuft everywhere** (tell 6, `700 400 500 120`): the dry grass tufts are one model at one size scattered evenly. Cause: dressing. Cheapest fix: vary their size and density, and cluster them along the road edges.

## e
- 1 Flat light: PASS (bushes cast shadows; the road's ruts are shaded)
- 2 No atmosphere: PASS (the mesa is faded by distance)
- 3 Too clean: FAIL (`600 500 680 220`; `e_ground.png`)
- 4 Too straight: FAIL (`0 360 600 360`; `e_straight.png`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`600 360 680 120`; `e_shrubs.png`)
- 7 Empty: FAIL (`0 360 1280 360`; `e_empty.png`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`700 320 450 50`, `300 0 700 280`; `e_mesa.png`, `e_sky.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Posterised sky** (tell 9, `300 0 700 280`): more than half the frame is a sky of hard-edged flat colour patches. It is the loudest cheap tell here. Cause: light. Cheapest fix: smooth the gradients and soften the cloud edges.
2. **Cardboard mesa** (tell 9, `700 320 450 50`): the one landmark is a smooth, flat-topped grey shape with a tiny chimney on it. It has no rock faces, ledges or light and shade, so it looks like a cut-out on the horizon. Cause: geometry. Cheapest fix: give the mesa cliff faces with a sunlit side and a shadowed side, eroded steps and talus slopes.
3. **Nothing to look at** (tell 7, `0 360 1280 360`): a flat plain of one ground colour with evenly spaced bushes. There is no fence, rock, carcass, telegraph pole or rider, so it feels unfinished rather than lonely. Cause: dressing. Cheapest fix: one designed foreground subject (a dead tree, fence posts, a cattle skull or rocks) to give the frame a focus.
4. **Same bush, evenly spread** (tell 6, `600 360 680 120`): one creosote-like bush repeated at one size on an even scatter. Cause: dressing. Cheapest fix: variants, random scale and clustering.
5. **Uniform ground and a ruler road** (tell 3/4, `600 500 680 220`): the ground has the same grain and tone everywhere, and the road is dead straight across flat land. Cause: material. Cheapest fix: tone variation patches, and a curve in the road.

## f
- 1 Flat light: FAIL (`0 450 1280 270`; `f_flat.png`)
- 2 No atmosphere: PASS (heavy haze; if anything too much)
- 3 Too clean: FAIL (`380 330 380 100`; `f_boxes.png`)
- 4 Too straight: FAIL (`380 330 380 100`; `f_rows.png`)
- 5 Floating objects: PASS (the boxes cast shadows)
- 6 Repetition: FAIL (`380 330 380 100`; `f_boxes.png`)
- 7 Empty: FAIL (`0 420 600 300`; `f_empty.png`)
- 8 Scale tells: FAIL (`520 400 380 270`; `f_shadow.png`)
- 9 Edges of the world: FAIL (`0 280 1280 50`, `300 0 700 240`; `f_horizon.png`, `f_sky.png`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Untextured grey boxes for a town** (tell 3, `380 330 380 100`): the buildings are blank, identical white-grey cuboids in neat rows, with no roofs, windows or colour. They read as placeholder blockout. Cause: geometry. Cheapest fix: use simple low-detail building models (pitched roofs and false fronts in timber colours) for distant buildings.
2. **Muddy, lifted, grey-brown everything** (tell 1, `0 450 1280 270`): the whole ground is one hazy brown with lifted blacks. You can't tell the time of day or where the sun is. Cause: light. Cheapest fix: cut the fog density at this range and restore contrast, so the shadows are darker and the ground keeps some form.
3. **A giant shadow from nowhere** (tell 8, `520 400 380 270`): a huge dark blob, longer than the town is wide, lies across the plain with no visible caster. The trees on the horizon are tiny next to it. Cause: light. Cheapest fix: find the object casting it (probably a nearby tree out of frame) and scale it right, or keep it out of this view.
4. **Flat horizon and posterised sky** (tell 9, `0 280 1280 50`): the land ends in a dead-flat line under a banded, filter-looking sky. Cause: geometry. Cheapest fix: a far ridge or hills, and a smooth sky gradient.
5. **Vast blank plain** (tell 7, `0 420 600 300`): the foreground is a big field of one-tone ground with no tracks, brush, fences or herds. Cause: dressing. Cheapest fix: scatter brush, cattle trails and fence lines out from the town.

## Ranking
From least to most cheap-looking: c, d, b, e, a, f
