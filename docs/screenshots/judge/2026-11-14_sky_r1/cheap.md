# Cheap judge, 2026-11-14_sky_r1

## a
- 1 Flat light: PASS (`960 380 320 260` the right boardwalk's shadow is hard, blue and well placed; the sun is clearly high left)
- 2 No atmosphere: PASS (`560 320 180 60` the street's far end does pale out a little; only just)
- 3 Too clean: FAIL (`0 420 1280 300`; `a_ground.jpg`: the street is one flat cream sheet, no ruts, hoofprints, tracks or dirt at the boardwalk foot)
- 4 Too straight: FAIL (`160 240 320 200`; `a_boxes.jpg`: dead-square blocks, ruler-level eaves and posts)
- 5 Floating objects: PASS (`760 370 520 150` boardwalks cast shadow and sit on the ground)
- 6 Repetition: FAIL (`760 370 520 150`; `j_boardwalk.jpg` shows the same skirt: one dark grime blotch stamped at even spacing along every boardwalk skirt)
- 7 Empty: FAIL (`0 420 1280 300`; `a_ground.jpg`: a whole main street at noon with nobody, no wagon, no trough, no litter)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`560 320 180 60`; `a_streetend.jpg`: the street ends in a pale void with a smeared grey hill shape poking up behind the blocks like a cut-out)
- **Verdict: cheap indie**
1. **The clouds are flat stickers** (tell 6, `160 0 760 360`; `a_clouds.jpg`): small white wisps of one size sprinkled evenly over the whole dome, each lit the same from edge to edge, no grey underside, no thickness, no larger mass anywhere; they read as a tiled decal on a blue gradient, not weather. The blue gradient itself (deep at the top, paler at the horizon) is the one part of the sky that reads as real. Cause: light. Cheapest fix: fewer, bigger cloud masses with a shaded underside and a lit top, varied in size, thinning toward the horizon.
2. **The ground is a bare sheet** (tell 3, `0 420 1280 300`; `a_ground.jpg`): half the frame is one cream value with no texture, so the good sunlight has nothing to fall on. Cause: material. Cheapest fix: a dirt texture with wheel ruts and darker trodden bands.
3. **The air is clean** (tell 2, `560 320 180 60`; `a_streetend.jpg`): noon in a desert street with no dust hanging or heat shimmer; the far buildings are nearly as crisp and saturated as the near ones. Cause: light. Cheapest fix: a warm, low dust haze that thickens with distance along the street.
4. **The far land is a cut-out** (tell 9, `560 320 180 60`; `a_streetend.jpg`): the hill visible past the blocks is a grey smeared silhouette with a stepped edge, no ridges or slope, so the town has no real horizon. Cause: geometry. Cheapest fix: a higher-detail far ridge with a lit side and a shadow side.
5. **An empty street** (tell 7, `300 330 700 390`): no person, horse or object to give scale or life. Cause: dressing. Cheapest fix: one wagon and a hitched horse halfway down.

## b
- 1 Flat light: FAIL (`0 420 1280 300`; `b_ground.jpg`: the plain is one even value; nothing casts a shadow, so the noon sun has no evidence on the ground)
- 2 No atmosphere: PASS (`0 280 1280 140` the far range is pale and blue with distance)
- 3 Too clean: FAIL (`0 420 1280 300`; `b_ground.jpg`: no stones, scrub, cracks or tracks on a whole plain)
- 4 Too straight: FAIL (`0 370 1280 50`; `b_line.jpg`: the ground meets the far land along one ruler-straight line with a dark seam)
- 5 Floating objects: PASS (`640 370 30 50` the lone post sits on the ground)
- 6 Repetition: FAIL (`0 0 1280 380`; `b_sky.jpg`: the same small white cloud wisp repeated at the same size across the sky)
- 7 Empty: FAIL (`0 420 1280 300`; `b_ground.jpg`: one post on an empty floor)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 280 1280 140`; `b_horizon.jpg`: the mountains are smeared horizontal streaks, stair-stepped edges, flat white slabs along their foot and a dark line where they meet the ground)
- **Verdict: cheap indie**
1. **The far land is smeared and stair-stepped** (tell 9, `0 280 1280 140`; `b_horizon.jpg`): the big range on the left looks like a stretched low-resolution picture: horizontal smears, jagged pixel steps on the ridge, flat white strips (snow?) lying along the base like paper, and a dark seam between them and the plain. It reads as a broken backdrop, not mountains. The haze on it (paler and bluer than the foreground) is right. Cause: geometry. Cheapest fix: a finer far-terrain mesh (or a clean painted ridge card) with the white strips removed and the seam blended by haze.
2. **A debug message across the frame** (tell 9, `0 610 1280 40`; `b_overlay.jpg`): "The game stalled over 5 s just now..." in yellow over the picture. A player sees a broken build before anything else. Cause: camera. Cheapest fix: keep the stall notice out of screenshots (or off-screen in release).
3. **The clouds are uniform confetti** (tell 6, `0 0 1280 380`; `b_sky.jpg`): dozens of same-sized white flecks, evenly spread, no large cloud, no shading, no perspective toward the horizon (they don't flatten or bunch as they recede). Cause: light. Cheapest fix: a cloud layer with scale (big near overhead, flattened bands near the horizon) and lit/shaded sides.
4. **No shadow, no ground** (tell 1/3, `0 420 1280 300`; `b_ground.jpg`): the plain has no texture or shape, so it reads as a floor plane. Cause: material. Cheapest fix: dirt and scrub texture plus a few bushes or rocks casting shadows.
5. **The sky's light doesn't reach the ground** (tell 1, `0 420 1280 300`): a strong blue sky but a pale beige ground with no blue in its shade and no warm in its light. Cause: light. Cheapest fix: a stronger sky-coloured ambient in shade and a warmer sun.

## c
- 1 Flat light: FAIL (`0 300 1280 420`; `c_ground.jpg`: both banks and the slope are the same cream; you can't read which side faces the sun)
- 2 No atmosphere: PASS (`0 240 1280 120` the far hills and the trestle soften with distance)
- 3 Too clean: FAIL (`0 300 1280 420`; `c_ground.jpg`: no stones, mud line or vegetation at the river)
- 4 Too straight: FAIL (`0 380 700 300`; `c_river.jpg`: a ruler-straight channel with an even flat water strip)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 0 1280 330`; `c_sky.jpg`: the same scattered wisp clouds at even size and spacing)
- 7 Empty: FAIL (`0 300 1280 420`; `c_ground.jpg`: no reeds, rocks, trees or wildlife along a river)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 240 1280 120`; `c_hills.jpg`: far land again smeared with flat white strips lying at its foot and a hard seam line)
- **Verdict: cheap indie**
1. **The water is a pale flat strip** (tell 4, `0 380 700 300`; `c_river.jpg`): no reflection of the bright sky, no ripple, no wet dark bank; it reads as a blue-grey ribbon painted on the floor. Cause: material. Cheapest fix: reflect the sky (fresnel) and darken the wet bank edge.
2. **The far land has white slabs and a seam** (tell 9, `0 240 1280 120`; `c_hills.jpg`): the range itself has nice haze and soft ridgelines, but white strips lying along the base and the dark ground seam give the backdrop away. Cause: geometry. Cheapest fix: remove the white strips or tuck them up the slopes as snow, and fade the seam into haze.
3. **Clouds are stickers** (tell 6, `0 0 1280 330`; `c_sky.jpg`): evenly spread small wisps, no mass or shade. Cause: light. Cheapest fix: as in a.
4. **The banks don't take light** (tell 1, `0 300 1280 420`; `c_ground.jpg`): the slope and the far bank are lit identically, so the land has no shape. Cause: light. Cheapest fix: a lower sun angle or a texture with normal detail so slopes shade.
5. **A river with nothing at it** (tell 7, `0 300 1280 420`): no plants, rocks or debris. Cause: dressing. Cheapest fix: reeds and stones along the water line.

## d
- 1 Flat light: PASS (`760 370 520 150` long low-sun shadows across the street; the sun is in frame)
- 2 No atmosphere: FAIL (`560 220 300 200`; `d_sun.jpg`: a low sun with no glow around it, no warm dust in the street, the facade beside it as crisp as the near ones)
- 3 Too clean: FAIL (`0 420 1280 300`; `d_ground.jpg`: the street is one smooth sheet)
- 4 Too straight: FAIL (`160 240 320 200`; `d_boxes.jpg`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`760 370 520 150`; `j_boardwalk.jpg`: the same grime blotch repeated along the boardwalk skirts)
- 7 Empty: FAIL (`0 420 1280 300`; `d_ground.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`680 340 200 60`; `d_streetend.jpg`: a flat pale slab and a grey cut-out hill at the street's end)
- **Verdict: cheap indie**
1. **Golden hour without gold** (tell 2, `560 220 300 200`; `d_sun.jpg`): the sun sits low and the shadows are long, but the sky stays midday blue, the sun is a small white disc with only a faint halo, the clouds are white rather than lit orange underneath, and the shaded walls go cold grey. It reads as noon with a low sun, not evening. Cause: light. Cheapest fix: warm the sky near the sun and the horizon, tint sunlight amber and light the clouds' undersides from below.
2. **No air in the low sun** (tell 2, `560 220 300 200`; `d_sun.jpg`): a low sun down a dusty street is where shafts and a glowing haze should be; here the air is empty. Cause: light. Cheapest fix: a sun-coloured haze that brightens toward the sun's direction.
3. **The far land is a cut-out** (tell 9, `680 340 200 60`; `d_streetend.jpg`): pale grey hill shapes behind the street with stepped edges and no lit side. Cause: geometry. Cheapest fix: as in a, and let the sun silhouette the ridge.
4. **Bare street** (tell 3, `0 420 1280 300`; `d_ground.jpg`): the long shadows fall on a texture-less floor. Cause: material. Cheapest fix: dirt texture with ruts.
5. **Repeated grime blotches** (tell 6, `j_boardwalk.jpg`): a stamp repeated evenly along the skirts. Cause: material. Cheapest fix: vary the stain per board.

## e
- 1 Flat light: FAIL (`0 420 1280 300`; `e_ground.jpg`: one smooth warm-grey ground with no long shadows except the post's thin one)
- 2 No atmosphere: PASS (`0 290 1280 60` the horizon glows warm-pale and the far range is hazed)
- 3 Too clean: FAIL (`0 420 1280 300`; `e_ground.jpg`)
- 4 Too straight: FAIL (`0 370 1280 50`; `e_line.jpg`: the ground edge is one straight line with a dark seam)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`0 0 1280 380`; `e_sky.jpg`: the same small wisp clouds, still white at golden hour)
- 7 Empty: FAIL (`0 420 1280 300`; `e_ground.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 290 700 130`; `e_hills.jpg`: the left range is stair-stepped horizontal smears with dotted dark lines through it and a white strip at its base)
- **Verdict: cheap indie**
1. **The far range breaks apart** (tell 9, `0 290 700 130`; `e_hills.jpg`): pixel stair-steps on the ridge, rows of dark dots across the slope, horizontal smearing, and a dark seam at its foot. Up close it looks like a corrupted texture. Cause: geometry. Cheapest fix: a smoother far mesh or a properly sampled height texture.
2. **Golden-hour sky that is still blue** (tell 6, `0 0 1280 380`; `e_sky.jpg`): the horizon warms a little (the best touch in the picture), but the dome is the noon blue and the clouds are white-grey flecks with no warm underside. Cause: light. Cheapest fix: a warmer, more saturated horizon band and clouds lit from below by the low sun.
3. **The ground does take the warmth** (tell 1, `0 420 1280 300`; `e_ground.jpg`): the plain has a warm cast (good), but no shape or shadow on it. Cause: material. Cheapest fix: texture and scrub that throw long shadows.
4. **A ruler horizon** (tell 4, `0 370 1280 50`; `e_line.jpg`): the edge of the plain is dead flat with a dark line. Cause: geometry. Cheapest fix: let the ground roll and blend into the far land with haze.
5. **Empty** (tell 7): one post. Cause: dressing. Cheapest fix: scrub, rocks, a track.

## f
- 1 Flat light: PASS (`0 340 600 300` the left bank in deep cool shadow against a warm lit slope: light with shape)
- 2 No atmosphere: PASS (`0 240 1280 120` the far range and the trestle fade with distance)
- 3 Too clean: FAIL (`0 340 1280 380`; `f_ground.jpg`: banks smooth with no rocks or texture)
- 4 Too straight: FAIL (`0 380 600 300`; `f_river.jpg`: a straight channel, water one flat colour)
- 5 Floating objects: PASS
- 6 Repetition: PASS (`0 0 1280 330` clouds here are larger and more varied)
- 7 Empty: FAIL (`0 340 1280 380`; `f_ground.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`520 300 300 120`; `f_trestle.jpg`: flat white slabs lying along the horizon behind the trestle, a dark seam under the far range)
- **Verdict: cheap indie**
1. **The water is a saturated blue slab** (tell 4, `0 380 600 300`; `f_river.jpg`): in the shadowed cut the river is a strong royal blue with no reflection or depth, the most artificial colour in the set. Cause: material. Cheapest fix: reflect the actual sky colour and darken it in shade.
2. **White slabs on the horizon** (tell 9, `520 300 300 120`; `f_trestle.jpg`): pale flat strips behind the trestle read as unfinished geometry. The far range above them is good: soft, hazed, varied ridge. Cause: geometry. Cheapest fix: remove or blend those strips.
3. **The sky isn't golden** (tell 2, `0 0 1280 330`; `f_sky.jpg`): the clouds are bigger and better here but still white, the dome still midday blue; the warm light on the slope doesn't come from anything visible in the sky. Cause: light. Cheapest fix: warm the horizon band and tint the clouds.
4. **Smooth banks** (tell 3, `f_ground.jpg`): no rocks or erosion lines. Cause: material. Cheapest fix: a rocky bank texture.
5. **Nothing alive by the river** (tell 7): no plants or animals. Cause: dressing. Cheapest fix: reeds and a few trees.

## g
- 1 Flat light: FAIL (`0 100 500 260`; `g_moonlit.jpg`: the moonlit tops are one flat saturated blue; everything below crushed to pure black, so moonlight has no gradient or shape)
- 2 No atmosphere: FAIL (`300 0 700 400`; `g_stars.jpg`: pure black sky down to the rooftops, no horizon glow, no moonlit haze)
- 3 Too clean: N/A (too dark to read)
- 4 Too straight: FAIL (`160 240 320 200`; `g_boxes.jpg`)
- 5 Floating objects: N/A
- 6 Repetition: FAIL (`300 0 700 400`; `g_stars.jpg`: one even sprinkle of near-identical dots, no Milky Way, no brighter stars)
- 7 Empty: FAIL (`300 280 700 150`; `g_street.jpg`: one faint orange window; no lamps, no lit saloon at night)
- 8 Scale tells: N/A
- 9 Edges of the world: FAIL (`300 0 700 400`; `g_stars.jpg`: the sky is a black dome with stars right down to the street, the far land invisible)
- **Verdict: cheap indie**
1. **A black sky with an even star sprinkle** (tell 6/2, `300 0 700 400`; `g_stars.jpg`): stars of the same size and spacing all the way down, pure black behind them; no band of the Milky Way, no deep-blue gradient toward the horizon, no moon glow. It reads as a screensaver. Cause: light. Cheapest fix: a dark blue-to-black gradient, a faint Milky Way band, stars that thin near the horizon.
2. **The moonlight is a flat blue paint** (tell 1, `0 100 500 260`; `g_moonlit.jpg`): lit faces are a single saturated blue; the street and everything in shade is black, so the scene is unreadable. Cause: light. Cheapest fix: a less saturated, brighter moon key and a little cool ambient so shadows keep detail.
3. **No lamps** (tell 7, `300 280 700 150`; `g_street.jpg`): a night street with no warm pools of light; the one window barely shows. Cause: light. Cheapest fix: lit windows and a few street lamps.
4. **No horizon at night** (tell 9, `g_stars.jpg`): the far hills that exist by day are lost; the sky doesn't silhouette anything. Cause: light. Cheapest fix: a faint horizon glow so the ridgeline reads.
5. **Grey-box blocks in blue** (tell 4, `g_boxes.jpg`): untextured boxes. Cause: geometry. Cheapest fix: the real facades.

## h
- 1 Flat light: FAIL (`0 380 1280 340`; `h_ground.jpg`: an even navy plain, no moon shadows)
- 2 No atmosphere: FAIL (`300 250 500 160`; `h_moon.jpg`: the moon has no halo, the sky has no glow near the horizon; faint vertical banding stripes in the sky)
- 3 Too clean: N/A (too dark to read)
- 4 Too straight: FAIL (`0 370 1280 50`; `h_line.jpg`: ruler-straight ground edge with a dark band)
- 5 Floating objects: N/A
- 6 Repetition: FAIL (`300 250 500 160`; `h_moon.jpg`: even star sprinkle)
- 7 Empty: FAIL (`0 380 1280 340`; `h_ground.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`300 250 500 160`; `h_moon.jpg`: a floating debug text label above the post at the horizon; dark seam under the far hills)
- **Verdict: cheap indie**
1. **The moon is a small peach dot with no light around it** (tell 2, `300 250 500 160`; `h_moon.jpg`): a tiny warm disc low in the sky, no halo, no brighter sky near it, no moon-path or rim on the land. And the land is lit evenly from above, not from where the moon sits. Cause: light. Cheapest fix: a larger, cooler moon with a soft halo and sky brightening around it.
2. **Vertical stripes in the sky** (tell 2, `300 250 500 160`; `h_moon.jpg`): faint columns of lighter and darker black, like a banding artefact or a shaft effect gone wrong. Cause: light. Cheapest fix: dither the sky gradient / turn off the shaft pass at night.
3. **Floating text and a stall message** (tell 9, `300 250 500 160` and `0 610 1280 40`; `h_moon.jpg`): a white label hovers over the post at the horizon, and the yellow stall warning sits over the frame. Cause: camera. Cheapest fix: hide debug labels and the stall notice in screenshots.
4. **The far hills do read** (tell 9): the ridge has a moonlit blue edge (the best part of the night shots), but a dark seam separates it from the plain. Cause: geometry. Cheapest fix: blend the seam with a haze band.
5. **A flat navy floor** (tell 1, `h_ground.jpg`): no shading, no texture. Cause: material. Cheapest fix: texture and the moon's shadows.

## i
- 1 Flat light: PASS (`0 330 1280 390` the dune slopes shade from lit to dark; the moon has some direction)
- 2 No atmosphere: FAIL (`450 200 500 200`; `i_moon.jpg`: moon with no halo, vertical banding in the sky, no glow at the horizon)
- 3 Too clean: N/A (too dark to read)
- 4 Too straight: FAIL (`0 330 800 300`; `i_channel.jpg`: the cut is perfectly straight)
- 5 Floating objects: N/A
- 6 Repetition: FAIL (`450 200 500 200`; `i_moon.jpg`: even star sprinkle)
- 7 Empty: FAIL (`0 330 1280 390`; `i_ground.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`450 200 500 200`; `i_moon.jpg`: a dark flat slab under the far ridge, the trestle's far end merging into it)
- **Verdict: cheap indie**
1. **The moon is a sticker** (tell 2, `450 200 500 200`; `i_moon.jpg`): a small flat peach disc with no glow, no sheen on the water below. Cause: light. Cheapest fix: halo and a cool, brighter moon.
2. **Banding stripes in the sky** (tell 2, `i_moon.jpg`): vertical light columns over the trestle. Cause: light. Cheapest fix: dither the sky / drop the shaft pass at night.
3. **Far ridge silhouette works, its base doesn't** (tell 9, `i_moon.jpg`): a believable moonlit ridgeline against the stars, with a patch of snow catching the light; under it a hard dark slab. Cause: geometry. Cheapest fix: blend the base.
4. **Uniform stars** (tell 6, `i_moon.jpg`). Cause: light. Cheapest fix: varied brightness, a Milky Way band.
5. **Overlay text** (tell 9, `0 610 1280 40`): the stall notice over the frame. Cause: camera. Cheapest fix: hide it.

## j
- 1 Flat light: FAIL (`0 330 1280 390`; `j_ground.jpg`: overcast with no soft occlusion; ground and walls one even value)
- 2 No atmosphere: PASS (`560 300 180 80` the far end of the street does fade into grey haze, convincingly)
- 3 Too clean: FAIL (`0 330 1280 390`; `j_ground.jpg`: no mud or puddles under an overcast sky)
- 4 Too straight: FAIL (`160 240 320 200`; `j_boxes.jpg`)
- 5 Floating objects: PASS (`760 370 520 150`; a faint contact shade where boardwalks meet the ground)
- 6 Repetition: FAIL (`760 370 520 150`; `j_boardwalk.jpg`: the same grime blotch repeated along the skirt)
- 7 Empty: FAIL (`0 330 1280 390`; `j_ground.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 0 1280 330`; `j_sky.jpg`: the sky is one even grey, no cloud form at all)
- **Verdict: cheap indie**
1. **Overcast is a grey fill, not clouds** (tell 9, `0 0 1280 330`; `j_sky.jpg`): a single flat grey with a faint gradient: no darker rolls, no brighter thin spots where the sun sits, no structure. Real overcast has texture and a brighter patch. Cause: light. Cheapest fix: a stratus layer with soft lighter and darker bands and one brighter zone toward the sun.
2. **No soft contact shading** (tell 1, `0 330 1280 390`; `j_ground.jpg`): under a dome of grey light, corners and undersides should darken softly; here everything is evenly lit. Cause: light. Cheapest fix: stronger ambient occlusion.
3. **The ground is dry and bare** (tell 3, `j_ground.jpg`): an overcast day with no damp or mud. Cause: material. Cheapest fix: darker damp patches and ruts.
4. **The haze is the good part** (tell 2, `560 300 180 80`): the far street goes soft into grey. Cause: light. Cheapest fix: none needed; keep it.
5. **Repeated grime blotches** (tell 6, `j_boardwalk.jpg`). Cause: material. Cheapest fix: vary the stain.

## k
- 1 Flat light: FAIL (`0 420 1280 300`; `k_ground.jpg`)
- 2 No atmosphere: PASS (`0 290 1280 60` far range washed out with distance)
- 3 Too clean: FAIL (`0 420 1280 300`; `k_ground.jpg`)
- 4 Too straight: FAIL (`0 370 1280 50`; `k_line.jpg`)
- 5 Floating objects: PASS
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 420 1280 300`; `k_ground.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 290 1280 140`; `k_horizon.jpg`: smeared far range with white slabs at its foot, dark seam; flat grey sky `0 0 1280 370`, `k_sky.jpg`)
- **Verdict: cheap indie**
1. **Nothing in the sky** (tell 9, `0 0 1280 370`; `k_sky.jpg`): half the frame is a featureless grey. Cause: light. Cheapest fix: a stratus layer with structure.
2. **The far land is smeared** (tell 9, `0 290 1280 140`; `k_horizon.jpg`): the same stretched range with white slabs and a dark seam. Cause: geometry. Cheapest fix: as in b.
3. **Nothing on the ground** (tell 7, `k_ground.jpg`): an empty floor and one post. Cause: dressing. Cheapest fix: scrub and rocks.
4. **Ruler horizon** (tell 4, `k_line.jpg`). Cause: geometry. Cheapest fix: rolling ground.
5. **The stall overlay** (tell 9, `0 610 1280 40`). Cause: camera. Cheapest fix: hide it.

## l
- 1 Flat light: FAIL (`0 330 1280 390`; `l_ground.jpg`)
- 2 No atmosphere: PASS (`0 240 1280 120` the trestle and range wash out with distance)
- 3 Too clean: FAIL (`0 330 1280 390`; `l_ground.jpg`)
- 4 Too straight: FAIL (`0 380 700 300`; `l_river.jpg`)
- 5 Floating objects: PASS
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 330 1280 390`; `l_ground.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 240 900 120`; `l_hills.jpg`: stair-stepped smears, specks and flat white slabs on the left range; flat grey sky `0 0 1280 250`, `l_sky.jpg`)
- **Verdict: cheap indie**
1. **The far range is corrupted-looking** (tell 9, `0 240 900 120`; `l_hills.jpg`): horizontal smears, pixel steps and dark specks over the left range, a pale slab at its foot. Cause: geometry. Cheapest fix: a cleaner far mesh/texture.
2. **Flat grey sky** (tell 9, `0 0 1280 250`; `l_sky.jpg`): no cloud form. Cause: light. Cheapest fix: a structured stratus layer.
3. **The river is a dull flat strip** (tell 4, `0 380 700 300`; `l_river.jpg`): under grey sky the water should mirror that grey and darken its banks; it's an even blue-grey band. Cause: material. Cheapest fix: sky reflection and a wet edge.
4. **No soft shading** (tell 1, `l_ground.jpg`): the banks barely separate. Cause: light. Cheapest fix: ambient occlusion and a darker cut face.
5. **The stall overlay** (tell 9, `0 610 1280 40`). Cause: camera. Cheapest fix: hide it.

## Ranking
From least to most cheap-looking: f, d, a, j, i, c, e, l, g, b, h, k
