# Art judge, critic

## a
- Shapes: FAIL (the tender/cab at right, `610 0 350 390`: a huge black slab with a box cut out, no cab windows, roof, coal or tank edges readable; the engine itself reads as a locomotive)
- Painted surface: FAIL (boiler `180 160 520 120` and drivers `160 295 600 135`: square camouflage mottle that ignores the cylinder's curve and the wheel's spokes)
- Light: FAIL (the low sun is behind the engine; everything under the boiler line and the whole tender sink to near-black with nothing to read into, unlike the authority's warm-lit, readable darks)
- People: N/A
- One hand: FAIL (the painted sunset sky is a soft, fine painting; the engine is coarse noisy squares and flat untextured black: two different hands)
- **Verdict: FAIL**
1. **Camouflage mottle on boiler and drivers** (`180 160 520 120`): the rust/iron texture is random square blotches of light and dark, not painted patches following the boiler's round form (the authority's mugs carry squares that turn with the surface; the lamp brass catches a highlight band). Cause: paint. Fix: repaint the boiler as broad bands along its length (lit top, warm mid, dark underside) with squares only inside those bands; give the drivers spokes and a lit rim instead of noise.
2. **Tender and cab a featureless black mass** (`610 0 350 390`): the biggest shape in the frame has no edges, planks, windows or rivets; against the sky it is a cut-out hole. Cause: shape and light. Fix: model the cab's windows, roof overhang and tender's coal/tank rim, and add a cool sky fill so its side planes read dark-brown, not black.
3. **Running gear and ground lost in shadow** (`0 380 960 160`): the ties, rails and roadbed are a flat brown band with no ballast or wear; the rails have no glint of the sunset. Cause: light and paint. Fix: add a warm bounce/fill from the ground and a painted ballast texture with stones and dirt patches.

## b
- Shapes: PASS (the engine `420 120 540 400`: stack, domes, cylinders and drivers read as a 4-4-0 at a credible scale; the track runs true)
- Painted surface: FAIL (boiler `480 195 480 115`: the same square mottle; desert `0 220 450 320`: a near-blank tan plane with a faint grid noise)
- Light: PASS (low sun at right with rays, warm key on the boiler's side, a long cool-brown shadow across the embankment; you can name the light)
- People: N/A
- One hand: FAIL (the sky is rich and painted; the ground is an empty flat colour and the embankment a smooth gradient wedge: no paint in them)
- **Verdict: FAIL**
1. **Desert floor empty and unpainted** (`0 220 450 320`): a smooth tan plane with only a faint pixel grain; no scrub, ruts, stones or colour shifts like the authority set's street with grass tufts and wheel ruts. Cause: paint. Fix: give the ground a painted dirt texture with broad warm/cool patches, scrub clumps and stones, and break the horizon with distant mesas.
2. **Boiler mottle** (`480 195 480 115`): random light/dark squares across the boiler read as camouflage, not rust or paint following the curve. Cause: paint. Fix: band the boiler's tone along its length (top light, underside dark) and paint wear as long streaks.
3. **Embankment a dark smooth wedge** (`0 260 960 280`): the roadbed is one flat brown gradient, no ballast, tie ends or edges, so the track floats on a ramp. Cause: shape and paint. Fix: model a shallow ballast shoulder with a lit top edge and paint stones on it.

## c
- Shapes: FAIL (the engine and tender `200 185 210 110`: a dark clump with no readable stack, cab or boiler; the ore cars read well)
- Painted surface: FAIL (desert `0 220 300 320`: large blocky bands of coarse squares next to the smooth sky and a smooth embankment; the ore cars' boards `355 235 605 210` are clean, photo-ish grain with knots, not painted patches)
- Light: PASS (sun at right, warm key on the car sides, shadowed embankment; readable)
- People: N/A
- One hand: FAIL (sky painted fine, ground coarse squares, cars near-photographic wood grain, engine a muddy blot: three hands)
- **Verdict: FAIL**
1. **Coarse blocky ground beside smooth work** (`0 220 300 320`): the shadows/patches on the desert are large stair-stepped squares, exactly the "coarse squares beside smooth work" the rubric names. Cause: paint (texel size at a low angle) and light (shadow resolution). Fix: hold the ground's square size to the rest of the frame at grazing angles, and soften or paint the cloud shadows.
2. **Engine unreadable at distance** (`200 185 210 110`): the locomotive is a dark smudge with stray light blocks; no silhouette of stack, dome and cab. Cause: shape and light. Fix: check the engine's far LOD/mipmaps and give it a lit rim from the sun so its silhouette holds.
3. **Ore cars too clean** (`355 235 605 210`): the boards are evenly lit, new-looking planks with tidy knots; no dirt, ore spill, iron strapping or wear like the authority's weathered timber. Cause: paint. Fix: paint the cars with ore dust and dark grime low, bleached tops, and add iron corner straps.

## d
- Shapes: FAIL (the coach `230 95 490 220`: a long dark box with a sagging roof line and flat window holes; the flatcar `0 270 250 150` reads as planks floating on posts)
- Painted surface: FAIL (the coach's side a dark streaky texture with no painted planes; ground `700 300 260 240` coarse squares)
- Light: FAIL (the coach's whole side, facing away from the sun, sinks to near-black with no cool fill; windows show no lit interior)
- People: FAIL (passengers in the windows `250 200 450 50`: a row of tiny flesh and tan blobs, no heads, hats or faces readable)
- One hand: FAIL (painted sky versus a black unpainted car and coarse-square ground)
- **Verdict: FAIL**
1. **Coach side in black shade** (`230 95 490 220`): a near-black silhouette with only faint streaks; the authority's shadows are deep but you can read the wood, trim and lettering in them. Cause: light. Fix: raise the cool sky fill on shade-side faces and paint the coach's panels, trim and lettering in a mid tone.
2. **Passengers as blobs** (`250 200 450 50`): the people in the windows are pale smudges cut off at the sill; nothing of the authority's modelled faces and hats. Cause: light and shape. Fix: light the coach interior so faces carry warm light through the glass, and seat them so heads and shoulders show.
3. **Flatcar and ground blocky** (`0 270 250 150`, `700 300 260 240`): the near flatcar's planks and the desert break into large stair-stepped squares and hard shadow steps. Cause: paint and light. Fix: keep the square size even at grazing angles and soften the shadow map's steps.

## e
- Shapes: PASS (the coach interior `240 150 480 390`: aisle, benches, end door and lamp read in credible proportion)
- Painted surface: FAIL (walls `0 0 330 540`: smooth stretched grain streaks, warped along the curve; ceiling `150 0 660 170` smeared texture)
- Light: FAIL (one lamp, yet the room is nearly black: walls and benches crushed, the lamp itself a flat yellow oval with no glow on what's near it)
- People: FAIL (passengers `355 205 250 90`: dark hat shapes with no faces; you see backs only, unlit)
- One hand: FAIL (the lamp is a flat graphic oval; walls a stretched photo grain; people small blocky figures)
- **Verdict: FAIL**
1. **Interior crushed to black** (`0 0 960 540`): with the lamp lit the room should glow warm like the authority's saloon; instead the walls, benches and people are near-black with no readable darks. Cause: light. Fix: give the ceiling lamps real range and a warm fill, and lift the shadow floor so the wood reads.
2. **Stretched wall and ceiling grain** (`0 0 330 540`): the wood texture is smeared along the boards and warped, like a photo stretched over the curve, not painted planks. Cause: paint (UVs). Fix: map the boards per plank at true scale and use the game's painted interior wood.
3. **Lamp a flat oval** (`430 20 100 100`): the lamp glass is a solid yellow ellipse, with no chimney, brass or flame like the authority's lamp. Cause: shape. Fix: model chimney glass with a brass base and a white flame core, lit from within.

## f
- Shapes: PASS (the same interior; aisle, benches, end door read)
- Painted surface: FAIL (walls `0 0 330 540`: glossy orange photographic wood grain; ceiling `150 0 660 170` smeared streaks; seats `545 375 190 125` plastic with a sheen)
- Light: FAIL (the lamp blows out the ceiling; everything is one saturated orange with no cool fill, no shadow under the seats you can read, no shape from light)
- People: FAIL (passengers `355 210 250 90`: blocky backs and hats, faces hidden, figures lost in the orange)
- One hand: FAIL (plastic glossy seats, photo-grain walls and blocky people; nothing like the authority's painted surfaces)
- **Verdict: FAIL**
1. **Saturated orange glare everywhere** (`0 0 960 540`): every surface is the same burnt orange at near full value; the authority's lamplight is warm but sits in deep brown darks with cool from the windows. Cause: light. Fix: cut the lamp's energy and the room's exposure, add cool window fill and let the corners and under-seats go dark.
2. **Glossy photographic wood** (`0 0 330 540`): high-contrast photographic grain with a varnish sheen and black seam lines; no painted patches. Cause: paint. Fix: use the game's painted interior wood with low sheen.
3. **Plastic seats** (`545 375 190 125`): the bench backs are smooth sheens with a specular stripe, like plastic. Cause: paint. Fix: drop the specular and paint worn edges and grain patches on the seat boards.

## Top three across all
1. The wood and iron are not painted in the authority's hand: square camouflage mottle on the engine's boiler and drivers (a, b), photographic glossy grain inside the coach (e, f), clean photo-planks on the ore cars (c).
2. The light fails at both ends: the shade side of every car outside and the coach interior at night go to unreadable black (a, d, e), while the lit interior blows out to one saturated orange (f); no cool fill, no readable darks.
3. Coarse stair-stepped squares on the ground and flatcar beside the finely painted sky, and an empty unpainted desert (b, c, d): the frame has two or three hands, and the far engine and the passengers dissolve into blobs.
