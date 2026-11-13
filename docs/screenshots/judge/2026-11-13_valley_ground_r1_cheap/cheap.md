# Cheap judge, 2026-11-13_valley_ground_r1_cheap

## a
- 1 Flat light: FAIL (`0 400 1280 320`; `a_blank_ground.png`): the street is one smooth beige plane with no shadow shapes on it; the right-hand building is a dull, even shade; the light's direction can't be read from the ground.
- 2 No atmosphere: PASS (`560 300 160 80`): the far end of the street goes soft and pale.
- 3 Too clean: FAIL (`0 400 1280 320`; `a_blank_ground.png`): the ground has no ruts, prints, stones or dirt at all; the stone wall (`0 270 330 230`; `a_wall_tiles.png`) is a blotchy camouflage pattern with blue and purple squares, the same from end to end.
- 4 Too straight: FAIL (`300 290 260 130`; `a_straight_boardwalk.png`): the boardwalk runs ruler-straight to the vanishing point; every roofline is a dead-level box edge.
- 5 Floating objects: FAIL (`980 340 300 60`; `a_base_contact.png`): the saloon front and its tables sit on the blank ground with no dirt, kick-up or darkening where they meet it.
- 6 Repetition: FAIL (`0 270 330 230`; `a_wall_tiles.png`): the same stone-block tile and its same blotches repeat block after block.
- 7 Empty: FAIL (`380 330 520 300`; `a_empty_street.png`): a main street with one tiny distant figure, no horses, wagons, barrels, troughs or litter.
- 8 Scale tells: PASS (`90 420 220 70`): steps, boardwalk and doors read at a plausible size.
- 9 Edges of the world: FAIL (`0 0 1280 330`; `a_sky_posterised.png`): the sky is a flat-filled, posterised cloud pattern in a few hard-edged tones, reading as a painted backdrop; far-left buildings are plain grey boxes (`520 310 100 60`).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The ground is a blank plane** (tell 3, `0 400 1280 320`): half the frame is untextured beige with nothing on it, like a level before the art pass. Cause: material. Cheapest fix: put a trodden dirt material with ruts and hoof prints on the street.
2. **Camouflage stone wall** (tell 6, `0 270 330 230`): the nearest wall is huge blocks of blue-purple-tan pixel blotches, the loudest "placeholder texture" in the frame. Cause: material. Cheapest fix: replace it with a real sandstone or adobe material without the coloured blotches.
3. **Posterised sky** (tell 9, `0 0 1280 330`): the clouds are hard-edged bands of flat colour, toy-like next to the realistic buildings. Cause: light. Cheapest fix: smooth the cloud shading (no colour steps) and give it soft gradients.
4. **Empty street** (tell 7, `380 330 520 300`): no people, animals or clutter: nobody lives here. Cause: dressing. Cheapest fix: a hitched horse, a wagon and a few barrels and crates along the boardwalks.
5. **Flat, sourceless light** (tell 1, `760 180 520 210`): the saloon front is one even grey-brown with no sun on it and no cast shadows anywhere. Cause: light. Cheapest fix: lower the sun so the façades and porch posts throw shadows onto the street.

## b
- 1 Flat light: FAIL (`760 180 520 210`; `b_flat_facade.png`): the ruts now have shading, but the saloon front is still an even dull shade and the porches throw no shadow onto the street.
- 2 No atmosphere: PASS (`560 300 160 80`): a light haze softens the far street.
- 3 Too clean: FAIL (`0 270 330 230`; `b_wall_tiles.png`): the ground is now worn (ruts, prints, straw), but the walls are uniform from end to end and the building bases are spotless.
- 4 Too straight: FAIL (`300 290 260 130`; `b_straight_boardwalk.png`): ruler-straight boardwalk and dead-level box rooflines.
- 5 Floating objects: FAIL (`700 360 580 60`; `b_base_contact.png`): the saloon's base meets the dirt in a clean line, and the ground in front of it is a lighter, un-trodden strip; the tables sit with no shadow under them.
- 6 Repetition: FAIL (`0 270 330 230`; `b_wall_tiles.png`): the same camouflage stone tile repeats block after block.
- 7 Empty: FAIL (`380 330 520 300`; `b_empty_street.png`): the ruts say traffic, but there is none: no people, horses or props.
- 8 Scale tells: PASS (`300 500 700 220`): ruts, hoof prints and steps agree in size.
- 9 Edges of the world: FAIL (`0 0 1280 330`; `b_sky_posterised.png`): posterised, flat-banded sky like a painted backdrop.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Camouflage stone wall** (tell 6, `0 270 330 230`): blue-purple pixel blotches on giant blocks, right next to the camera. Cause: material. Cheapest fix: a real stone or adobe material.
2. **Empty street** (tell 7, `380 330 520 300`): wheel ruts lead through a town with no one in it. Cause: dressing. Cheapest fix: a wagon in the ruts and a horse at the rail.
3. **Posterised sky** (tell 9, `0 0 1280 330`): flat colour bands, toy-like. Cause: light. Cheapest fix: smooth gradients in the cloud shading.
4. **Buildings lit by nothing** (tell 1, `760 180 520 210`): the façades are flat grey-brown slabs with no sun or cast shadow. Cause: light. Cheapest fix: a sun angle that puts light on one side of the street and porch shadows on the dirt.
5. **Clean seams where walls meet the street** (tell 5, `700 360 580 60`): the boardwalks and walls stand on the dirt with no drifted dust, wear or dark contact line. Cause: dressing. Cheapest fix: a dark, dusty blend along every building base and boardwalk edge.

## c
- 1 Flat light: PASS (`600 220 160 160`): a low sun behind the street; the post's long shadow and the shaded right side of the street say where the light comes from.
- 2 No atmosphere: PASS (`560 220 220 160`): the sun glows in haze and the far buildings fade.
- 3 Too clean: FAIL (`0 480 1280 240`; `c_blank_ground.png`): the street is a smooth orange gradient with nothing in it: no ruts, stones or prints.
- 4 Too straight: FAIL (`300 290 260 130`; `c_straight_boardwalk.png`): ruler-straight boardwalk and box rooflines.
- 5 Floating objects: PASS (`700 360 580 120`): the saloon's shadow side and base sit down on the street.
- 6 Repetition: FAIL (`0 270 330 230`; `c_wall_tiles.png`): the stone-block tile and its blotches repeat across the wall.
- 7 Empty: FAIL (`380 340 600 300`; `c_empty_street.png`): one seated figure on the saloon porch; the street itself has nothing.
- 8 Scale tells: PASS (`90 420 220 70`): steps and boardwalk read right.
- 9 Edges of the world: FAIL (`300 0 700 260`; `c_sky_posterised.png`): the sunset clouds are posterised into hard-edged orange, cream and lilac patches; far-left buildings are featureless boxes (`520 310 100 60`; `c_grey_boxes.png`).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Blank ground under a dramatic sun** (tell 3, `0 480 1280 240`): the light has mood but falls on nothing: a smooth plastic plane. Cause: material. Cheapest fix: the rutted dirt material, so the low sun can rake across it.
2. **Posterised sunset sky** (tell 9, `300 0 700 260`): the clouds look like a cheap paint filter, not air. Cause: light. Cheapest fix: remove the colour stepping; soft gradients toward the sun.
3. **Camouflage stone wall** (tell 6, `0 270 330 230`): a repeating tiled block pattern. Cause: material. Cheapest fix: a real stone material with variation from block to block.
4. **Empty street** (tell 7, `380 340 600 300`): a golden-hour street with no one on it. Cause: dressing. Cheapest fix: a rider or wagon backlit in the haze.
5. **Box buildings at the far end** (tell 9, `520 310 100 60`): plain grey blocks with no windows or trim. Cause: geometry. Cheapest fix: give the far buildings false fronts and porches, even simple ones.

## d
- 1 Flat light: PASS (`450 380 400 200`): the low sun rakes along the ruts and catches their rims; long shadows; clear back-light.
- 2 No atmosphere: PASS (`560 220 220 160`): warm haze around the sun and down the street.
- 3 Too clean: FAIL (`0 270 330 230`; `d_wall_tiles.png`): the ground is worn, but the walls are uniform and the building bases unmarked.
- 4 Too straight: FAIL (`300 290 260 130`; `d_straight_boardwalk.png`): ruler-straight boardwalk, perfectly square rooflines.
- 5 Floating objects: PASS (`700 360 580 120`): the saloon and its tables sit in their shadow on the dirt.
- 6 Repetition: FAIL (`0 270 330 230`; `d_wall_tiles.png`): the same stone-block tile repeats along the wall.
- 7 Empty: FAIL (`380 340 600 200`; `d_empty_street.png`): one figure on the porch; the rutted street itself is deserted.
- 8 Scale tells: PASS (`450 550 400 170`): hoof prints, ruts and steps agree.
- 9 Edges of the world: FAIL (`300 0 700 260`; `d_sky_posterised.png`): posterised, flat-banded sunset clouds.
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Posterised sky** (tell 9, `300 0 700 260`): the top half of a well-lit frame is flat colour patches, the most "cheap filter" thing in it. Cause: light. Cheapest fix: smooth the cloud gradients.
2. **Camouflage stone wall** (tell 6, `0 270 330 230`): a loud tiled block pattern in the foreground. Cause: material. Cheapest fix: a real stone or adobe material.
3. **Empty street** (tell 7, `380 340 600 200`): the ruts and the lit lamp promise life the street doesn't show. Cause: dressing. Cheapest fix: a figure or horse silhouetted in the haze down the street.
4. **Ruler-straight boardwalk and boxes** (tell 4, `300 290 260 130`): every edge is perfect. Cause: geometry. Cheapest fix: a slight sag and uneven board ends on the boardwalk; a lean on a post or two.
5. **Unworn walls** (tell 3, `760 180 520 210`): the saloon's planks are one even red from top to bottom, with no sun bleaching, dust at the base or weathered edges. Cause: material. Cheapest fix: a grime and dust gradient up from the ground on every façade.

## e
- 1 Flat light: FAIL (`0 380 1280 340`; `e_blank_ground.png`): an evenly lit beige plane; no shadow shapes at all.
- 2 No atmosphere: PASS (`0 320 1280 60`): the horizon is hazy and pale.
- 3 Too clean: FAIL (`0 380 1280 340`; `e_blank_ground.png`): no texture, stones, grass or tracks; just a smeared gradient.
- 4 Too straight: FAIL (`0 320 1280 60`; `e_flat_horizon.png`): the horizon is one dead-flat ridge running edge to edge.
- 5 Floating objects: PASS (`620 330 60 40`): almost nothing stands on the ground to float.
- 6 Repetition: PASS (`0 380 1280 340`): nothing to repeat.
- 7 Empty: FAIL (`0 380 1280 340`; `e_blank_ground.png`): a lone stick figure on an unmarked plain; no plants, track or sign of anyone.
- 8 Scale tells: N/A
- 9 Edges of the world: FAIL (`0 320 1280 60`; `e_flat_horizon.png`): a flat grey wall of a ridge closes the world; the sky above is posterised (`0 0 1280 330`; `e_sky_posterised.png`).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Nothing on the ground** (tell 3, `0 380 1280 340`): two-thirds of the frame is an untextured plane. Cause: material. Cheapest fix: the desert ground material and scattered scrub.
2. **Posterised sky** (tell 9, `0 0 1280 330`): hard-edged flat cloud colours. Cause: light. Cheapest fix: smooth the cloud shading.
3. **A wall for a horizon** (tell 9, `0 320 1280 60`): a single flat ridge band with no peaks or layers. Cause: geometry. Cheapest fix: break the horizon with a few hills or buttes at different distances.
4. **No light shape** (tell 1, `0 380 1280 340`): no shadows, no form, no sun direction. Cause: light. Cheapest fix: terrain undulation so the sun shades slopes.
5. **No sign of life** (tell 7, `0 380 1280 340`): no track, fence or plant. Cause: dressing. Cheapest fix: a wagon track leading to the figure.

## f
- 1 Flat light: PASS (`300 380 700 340`): the ruts are shaded and the light reads as hazy noon; soft but not featureless.
- 2 No atmosphere: PASS (`640 320 640 60`): the trees and far ridge sit back in haze.
- 3 Too clean: PASS (`300 500 600 220`): the track has ruts, pebbles and a hoof print; the ground varies.
- 4 Too straight: PASS (`300 380 700 340`): the ruts wander a little; the track has an uneven edge.
- 5 Floating objects: FAIL (`0 400 300 200`; `f_bushes_no_shadow.png`): the scrub has no shadow or contact darkening and looks pasted on; a dark object hangs in mid-air in the nearest bush.
- 6 Repetition: FAIL (`0 340 1280 120`; `f_repeated_scatter.png`): the same dark-blue blob bush and the same grass tuft repeat across the plain at even density.
- 7 Empty: PASS (`300 380 700 340`): a worn track says people pass; empty open range is the point.
- 8 Scale tells: PASS (`640 320 640 60`): the trees and post read at distance.
- 9 Edges of the world: FAIL (`0 0 1280 330`; `f_sky_posterised.png`): half the frame is posterised flat-colour cloud; the horizon is a flat grey band (`640 320 640 60`; `f_tree_row.png`).
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Posterised sky** (tell 9, `0 0 1280 330`): flat, hard-edged colour patches fill half the picture and fight the realistic ground. Cause: light. Cheapest fix: smooth cloud gradients.
2. **Scrub with no shadows** (tell 5, `0 400 300 200`): the bushes sit on the ground like stickers, and something dark floats inside one. Cause: light. Cheapest fix: turn on shadows (or a contact blob) for the scatter.
3. **Repeated bush blobs** (tell 6, `0 340 1280 120`): the same dark blue-black bush, cloned, evenly spaced. Cause: dressing. Cheapest fix: two or three bush shapes in varied sizes, clumped rather than spread.
4. **Bush colour off** (tell 6, `700 360 580 80`): the bushes are an inky blue-black that reads as unlit, not as sage. Cause: material. Cheapest fix: a lit sage-green/olive base colour.
5. **Flat horizon band** (tell 9, `640 320 640 60`): a grey wall behind the trees. Cause: geometry. Cheapest fix: break it with layered hills.

## g
- 1 Flat light: FAIL (`0 380 1280 340`; `g_blank_ground.png`): an evenly lit beige plane, no shadows.
- 2 No atmosphere: PASS (`0 300 1280 90`): the ridges fade into haze.
- 3 Too clean: FAIL (`0 380 1280 340`; `g_blank_ground.png`): no texture, stones, plants or tracks.
- 4 Too straight: FAIL (`0 300 1280 90`; `g_flat_ridges.png`): two ridges as straight planes meeting in a V, like folded cardboard.
- 5 Floating objects: PASS (`0 380 1280 340`): nothing stands on the ground.
- 6 Repetition: PASS (`0 380 1280 340`): nothing to repeat.
- 7 Empty: FAIL (`0 380 1280 340`; `g_blank_ground.png`): nothing at all in the frame but ground and sky.
- 8 Scale tells: N/A
- 9 Edges of the world: FAIL (`0 300 1280 90`; `g_flat_ridges.png`): flat, featureless ridge planes close the view; posterised sky above (`0 0 1280 330`; `g_sky_posterised.png`).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Nothing in the picture** (tell 7, `0 380 1280 340`): a blank plane and a sky; it reads as an unfinished level. Cause: dressing. Cheapest fix: ground material and scrub scatter.
2. **Cardboard ridges** (tell 9, `0 300 1280 90`): the valley walls are flat planes with straight edges. Cause: geometry. Cheapest fix: noise and erosion on the ridge lines.
3. **Posterised sky** (tell 9, `0 0 1280 330`): hard flat colour bands. Cause: light. Cheapest fix: smooth cloud gradients.
4. **Untextured ground** (tell 3, `0 380 1280 340`): smooth beige with nothing on it. Cause: material. Cheapest fix: the dirt material.
5. **No light shape** (tell 1, `0 380 1280 340`): no shadow, no slope shading. Cause: light. Cheapest fix: undulating terrain so the sun models it.

## h
- 1 Flat light: PASS (`300 420 600 120`): bushes cast crisp shadows to the left; the light direction is clear.
- 2 No atmosphere: PASS (`0 270 1100 100`): the tree line steps back into haze.
- 3 Too clean: PASS (`450 450 400 270`): ruts, pebbles, tufts, varied ground.
- 4 Too straight: PASS (`450 360 400 360`): the track wavers and its edges are soft.
- 5 Floating objects: PASS (`380 420 120 100`): the bushes sit in their shadows.
- 6 Repetition: FAIL (`0 270 1100 100`; `h_tree_row.png`): every tree is the same stacked-disc "poodle" shape, standing at even spacing.
- 7 Empty: PASS (`450 360 400 360`): a used track through open range.
- 8 Scale tells: PASS (`0 270 1100 100`): the tree line reads at a plausible distance.
- 9 Edges of the world: FAIL (`0 0 1280 330`; `h_sky_posterised.png`): posterised flat-colour clouds; the near right tree is a flat, unlit dark cut-out (`1100 20 180 300`; `h_near_tree.png`).
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Topiary trees** (tell 6, `0 270 1100 100`): every tree is the same stack of flat discs, like a toy-train set. Cause: geometry. Cheapest fix: two or three irregular tree shapes, varied in size and lean.
2. **Posterised sky** (tell 9, `0 0 1280 330`): flat colour patches. Cause: light. Cheapest fix: smooth cloud gradients.
3. **Black cut-out tree** (tell 9, `1100 20 180 300`): the near tree is one flat dark silhouette with no light, depth or leaf detail, with ragged pixel edges. Cause: light. Cheapest fix: let the sun and sky light the near foliage (not just the edges).
4. **Even scatter** (tell 6, `0 360 1280 120`): the bushes are spread at an even density across the plain. Cause: dressing. Cheapest fix: clump the scrub and leave bare patches.
5. **Floating shadow** (tell 1, `900 380 380 25`): a long dark shadow lies on the plain with nothing visible to cast it. Cause: light. Cheapest fix: make sure the caster is in frame or soften it as a cloud shadow.

## i
- 1 Flat light: FAIL (`0 380 1280 340`; `i_blank_ground.png`): an evenly lit beige plane, no shadow shapes.
- 2 No atmosphere: PASS (`700 330 450 40`): the mesa is pale with distance.
- 3 Too clean: FAIL (`0 380 1280 340`; `i_blank_ground.png`): no texture, plants or tracks.
- 4 Too straight: FAIL (`0 340 1280 40`; `i_flat_horizon.png`): a dead-flat horizon and a flat-topped grey mesa.
- 5 Floating objects: PASS (`620 330 60 40`): almost nothing stands on the ground.
- 6 Repetition: PASS (`0 380 1280 340`): nothing to repeat.
- 7 Empty: FAIL (`0 380 1280 340`; `i_blank_ground.png`): a blank plain with one post.
- 8 Scale tells: N/A
- 9 Edges of the world: FAIL (`0 0 1280 330`; `i_sky_posterised.png`): posterised sky; a flat line for a horizon (`0 340 1280 40`).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Blank ground** (tell 3, `0 380 1280 340`): an untextured plane over most of the frame. Cause: material. Cheapest fix: the dirt material and scrub.
2. **Posterised sky** (tell 9, `0 0 1280 330`): flat, hard colour patches. Cause: light. Cheapest fix: smooth cloud gradients.
3. **Flat horizon** (tell 4, `0 340 1280 40`): a ruler line with one grey slab of mesa. Cause: geometry. Cheapest fix: layered hills at different distances.
4. **No light shape** (tell 1, `0 380 1280 340`): nothing to tell where the sun is. Cause: light. Cheapest fix: terrain undulation and scatter that throws shadows.
5. **Empty** (tell 7, `0 380 1280 340`): no track or sign of people. Cause: dressing. Cheapest fix: a track leading to the post.

## j
- 1 Flat light: PASS (`680 400 120 80`): the bush casts a clear shadow; ruts are shaded.
- 2 No atmosphere: PASS (`700 330 450 40`): the mesa is soft and pale with distance.
- 3 Too clean: PASS (`0 380 600 340`): ruts, pebbles, varied tone.
- 4 Too straight: PASS (`0 360 600 360`): the track bends and its edges are soft.
- 5 Floating objects: PASS (`700 400 120 80`): the bush sits in its shadow.
- 6 Repetition: FAIL (`0 340 1280 120`; `j_repeated_scatter.png`): the same few tufts and bushes, spread evenly to the horizon.
- 7 Empty: PASS (`0 360 600 360`): a used track across open range.
- 8 Scale tells: PASS (`700 400 120 80`): the bush and tufts agree.
- 9 Edges of the world: FAIL (`0 0 1280 330`; `j_sky_posterised.png`): posterised sky; the mesa is a flat grey silhouette with stepped pixel edges and boxes on top (`700 330 450 40`; `j_flat_mesa.png`).
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Posterised sky** (tell 9, `0 0 1280 330`): half the frame is flat colour patches. Cause: light. Cheapest fix: smooth cloud gradients.
2. **Cardboard mesa** (tell 9, `700 330 450 40`): a flat grey cut-out with no rock faces or light on it. Cause: geometry. Cheapest fix: give the mesa lit faces and shadowed sides.
3. **Even scatter** (tell 6, `0 340 1280 120`): the same tufts at even density. Cause: dressing. Cheapest fix: clump the scrub and vary the species.
4. **Leftover squares in the ground** (tell 3, `600 500 680 220`): the dirt reads as fine noisy pixels rather than grains and stones at this distance. Cause: material. Cheapest fix: larger stones and patches of different soil.
5. **No focal point** (tell 7, `700 360 580 100`): one bush is the only subject. Cause: dressing. Cheapest fix: a fence line, dead tree or skull along the track.

## k
- 1 Flat light: FAIL (`0 400 1280 320`; `k_blank_ground.png`): the plain is one even beige; the town's boxes are grey on all sides.
- 2 No atmosphere: PASS (`380 320 420 110`): heavy haze over the town (too heavy: the town drowns in it).
- 3 Too clean: FAIL (`0 400 1280 320`; `k_blank_ground.png`): an untextured plain.
- 4 Too straight: FAIL (`380 320 420 110`; `k_box_town.png`): rectangular boxes in neat rows.
- 5 Floating objects: PASS (`380 320 420 110`): the boxes sit on the ground.
- 6 Repetition: FAIL (`380 320 420 110`; `k_box_town.png`): the same grey box over and over.
- 7 Empty: FAIL (`0 400 1280 320`; `k_blank_ground.png`): nothing around the town: no fields, fences, trails or trees.
- 8 Scale tells: FAIL (`540 360 420 280`; `k_giant_shadow.png`): long dark bars hundreds of metres long cross the plain with nothing visible to cast them, dwarfing the town.
- 9 Edges of the world: FAIL (`0 280 1280 60`; `k_flat_horizon.png`): a flat, empty horizon line.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A town of grey boxes** (tell 6, `380 320 420 110`): from above the town is blank blocks with no roofs, colour or detail. Cause: geometry. Cheapest fix: roofs and false fronts on the far versions of the buildings.
2. **Mystery shadow bars** (tell 8, `540 360 420 280`): huge dark stripes with no caster. Cause: light. Cheapest fix: find and remove or show what casts them.
3. **Blank plain** (tell 3, `0 400 1280 320`): untextured ground. Cause: material. Cheapest fix: the ground material and scatter.
4. **Posterised sky** (tell 9, `0 0 1280 280`): flat colour patches. Cause: light. Cheapest fix: smooth cloud gradients.
5. **Empty horizon** (tell 9, `0 280 1280 60`): a straight line with nothing on it. Cause: geometry. Cheapest fix: hills and a tree line.

## l
- 1 Flat light: FAIL (`0 300 1280 400`; `l_grey_veil.png`): a grey veil over everything lifts the darks; the town's boxes are evenly pale.
- 2 No atmosphere: PASS (`0 300 1280 400`): plenty of haze.
- 3 Too clean: FAIL (`380 320 420 110`; `l_box_town.png`): the buildings are clean pale blocks with no roofs, wear or colour.
- 4 Too straight: FAIL (`380 320 420 110`; `l_box_town.png`): boxes in neat parallel rows.
- 5 Floating objects: PASS (`380 320 420 110`): the boxes sit on the ground.
- 6 Repetition: FAIL (`380 320 420 110`; `l_box_town.png`): the same box repeated.
- 7 Empty: FAIL (`0 400 1280 300`): the plain around the town is bare: no fields, fences or traffic.
- 8 Scale tells: FAIL (`520 360 440 310`; `l_giant_shadow.png`): a huge dark spear-shaped streak with a thin spike at its end, far bigger than the town, with no visible caster.
- 9 Edges of the world: FAIL (`0 280 1280 60`; `l_flat_horizon.png`): a flat horizon line with tiny trees pasted along it; posterised sky above (`0 0 1280 280`; `l_sky_posterised.png`).
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A town of blank blocks** (tell 6, `380 320 420 110`): pale boxes with no roofs; from above it looks like a greybox. Cause: geometry. Cheapest fix: pitched roofs and colour on the distant buildings.
2. **The spear-shaped shadow** (tell 8, `520 360 440 310`): an enormous dark streak with a thin spike, no caster in view; it pulls the eye more than the town. Cause: light. Cheapest fix: show or remove its caster.
3. **Grey veil** (tell 1, `0 300 1280 400`): the haze turns everything to a low-contrast grey-brown with no deep darks. Cause: light. Cheapest fix: thin the haze near the camera so the foreground keeps its darks.
4. **Posterised sky** (tell 9, `0 0 1280 280`): flat colour patches. Cause: light. Cheapest fix: smooth cloud gradients.
5. **Flat horizon** (tell 9, `0 280 1280 60`): a straight line with a few tiny trees. Cause: geometry. Cheapest fix: hills at different distances.

## Ranking
From least to most cheap-looking: d, h, j, f, b, c, l, a, k, i, e, g
