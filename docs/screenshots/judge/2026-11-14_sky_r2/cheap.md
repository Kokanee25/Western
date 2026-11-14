# Cheap judge, 2026-11-14_sky_r2

## a
- 1 Flat light: PASS (`760 170 520 330`: the porch throws a hard, readable blue-grey shadow across the boardwalk; sun direction is obvious)
- 2 No atmosphere: PASS (`540 290 260 100`: the far end of the street pales into a light haze)
- 3 Too clean: FAIL (`800 40 480 420`; `a_blank_walls.jpg`)
- 4 Too straight: FAIL (`760 170 520 330`; `a_ruler_porch.jpg`)
- 5 Floating objects: FAIL (`0 430 300 160`; `a_boardwalk_no_contact.jpg`)
- 6 Repetition: PASS (porch posts repeat, but no more than a real porch would)
- 7 Empty: FAIL (`0 380 1280 340`; `a_empty_street.jpg`)
- 8 Scale tells: PASS (doors, porches and the one far figure agree)
- 9 Edges of the world: FAIL (`540 290 260 100`; `a_street_end_no_range.jpg`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
  Why: the grey-box town decides it, but the sky alone is the most finished thing in the frame. Sky: a clean, believable blue gradient from deep overhead to pale at the horizon, reads real. Clouds (`340 50 480 230`, `a_midday_clouds.jpg`): small soft wisps with no shaded underside or volume, flat white cut-outs pasted on; they read cheap next to the sky. Light: hard noon sun with crisp shadows, convincing direction, but the shadow side is a cool blue with no bounce from the bright ground. Air: a mild fade at the street end, no dust in the sun. Range: none visible down the street; the low hills behind the far buildings are pale blobs with stair-stepped edges.
1. **Bare grey walls and floor** (tell 3, `800 40 480 420`): huge untextured planes take two-thirds of the frame. Cause: material. Cheapest fix: any plank/plaster texture with a dirt gradient at the base.
2. **Nothing alive in the street** (tell 7, `0 380 1280 340`): one tiny figure, no wagons, troughs, barrels or tracks in the dirt. Cause: dressing. Cheapest fix: wheel ruts and hoof-churned patches in the ground texture.
3. **Street ends in a blank horizon** (tell 9, `540 290 260 100`): past the town there is a flat pale band, no mountains, while the near hills behind the roofs are jagged-edged white blobs. Cause: geometry. Cheapest fix: let the distant range show through the street axis and soften the near hills' silhouette.
4. **Clouds without volume** (tell 2, `340 50 480 230`): flat white smears, same brightness top and bottom, no grey bellies. Cause: light. Cheapest fix: darken the cloud underside away from the sun.
5. **Boardwalks hover** (tell 5, `0 430 300 160`): no dark line or dirt where the timber meets the ground. Cause: light. Cheapest fix: contact AO / a dark dirt decal under every edge.

## b
- 1 Flat light: FAIL (`0 400 1280 320`; `b_flat_ground_light.jpg`)
- 2 No atmosphere: PASS (`0 290 700 120`: the range is paler and bluer than the ground, some aerial fade)
- 3 Too clean: FAIL (`0 420 1280 300`; `b_bare_ground.jpg`)
- 4 Too straight: FAIL (`0 368 1280 40`; `b_ruler_horizon.jpg`)
- 5 Floating objects: PASS (the post is too small to read its foot)
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 360 1280 360`; `b_empty_plain.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 290 700 120`; `b_mountains_flat_band.jpg`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
  Why: half the frame is sky and it is the best half; the range and ground below it are what sinks it. Sky: good gradient, deep blue to warm-pale at the horizon, reads real. Clouds: puffy cumulus fragments with a lit side, the most convincing clouds of the midday set, but they all float at the same thin, sharp-edged flatness, more painted decal than vapour. Light: the plain is one even sheet, no shadow shapes, so the noon sun does nothing to the land. Air: a believable haze over the far range. Range (`b_mountains_flat_band.jpg`): the big left mountain is a smeared grey wedge with horizontal streaks and stair-stepped silhouette, a stretched texture on a low-poly shape; the rest of the range is a thin even row of teeth with flat white snow slabs; a dark dashed seam sits between range and ground.
1. **Mountains are smeared and stepped** (tell 9, `0 290 700 120`): the nearest peak shows horizontal streaks and jagged stair-step edges, like a stretched heightmap. Cause: geometry. Cheapest fix: smooth the silhouette and sample its texture by height/slope, not stretched UVs.
2. **A dark seam under the range** (tell 4, `0 368 1280 40`): a dashed near-black line rules the whole horizon dead straight. Cause: geometry. Cheapest fix: fog/blend the ground's far edge into the range's base.
3. **The ground has no shape** (tell 1, `0 400 1280 320`): a uniform beige sheet from feet to horizon; no ripples, stones, brush, or shadow. Cause: material. Cheapest fix: low-frequency undulation plus scattered brush casting small shadows.
4. **Empty to the horizon** (tell 7, `0 360 1280 360`): a single red post in an endless plane. Cause: dressing. Cheapest fix: sage clumps and a trail.
5. **Snow patches are flat white tiles** (tell 9, `0 290 700 120`): at the range's base, flat bright rectangles with no shading. Cause: material. Cheapest fix: tint and shade the snow with the same haze as the rock.

## c
- 1 Flat light: FAIL (`0 330 1280 390`; `c_facet_lit_ground.jpg`)
- 2 No atmosphere: PASS (`0 250 1280 120`: the range fades blue-grey)
- 3 Too clean: FAIL (`0 380 720 300`; `c_clean_water_banks.jpg`)
- 4 Too straight: FAIL (`0 330 1280 300`; `c_straight_banks.jpg`)
- 5 Floating objects: PASS (the trestle sits into the gully)
- 6 Repetition: FAIL (`560 325 250 70`; `c_trestle_lattice.jpg`)
- 7 Empty: FAIL (`0 330 1280 390`; `c_empty_gully.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 250 1280 120`; `c_range_and_trestle.jpg`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
  Why: same split as b. Sky: clean gradient, real. Clouds: sharper, more numerous cumulus wisps; individually pleasing, but none cast a shadow on the land and they have no darker cores, so they read as painted onto a dome. Light: the banks are lit only by their facet angle; no cloud shadow, no texture to catch it. Air: decent fade on the range, but the trestle in the middle distance is as sharp and noisy as anything near. Range (`c_range_and_trestle.jpg`): the long left ridge shows horizontal smear-streaks and a stepped crest; the flat white snow lens shapes along the base look like paper cut-outs.
1. **Trestle is a shimmering noise patch** (tell 6, `560 325 250 70`): the bents alias into a crawling moiré instead of timbers. Cause: geometry. Cheapest fix: MSAA/TAA on thin members or a LOD with fewer, thicker bents.
2. **Streaked, stepped mountains** (tell 9, `0 250 1280 120`): smeared horizontal bands and stair-step ridgelines. Cause: geometry. Cheapest fix: smoother range mesh and height-based shading.
3. **Water is a flat blue ribbon** (tell 3, `0 380 720 300`): no reflection of the sky, no wet bank, no stones. Cause: material. Cheapest fix: a darker wet margin and sky reflection on the water.
4. **Banks cut with a ruler** (tell 4, `0 330 1280 300`): two straight diagonal edges, perfectly planar slopes. Cause: geometry. Cheapest fix: noise on the bank heights and erosion gullies.
5. **Slopes lit by facet only** (tell 1, `0 330 1280 390`): two tones, left bank and right bank. Cause: material. Cheapest fix: ground texture with grass/scree so the sun has something to catch.

## d
- 1 Flat light: PASS (`760 170 520 330`: long low shadows, the porch shadow stripes the boardwalk, sun clearly ahead)
- 2 No atmosphere: PASS (`560 200 320 160`: a soft sun glow sits in the sky and lightens the street end)
- 3 Too clean: FAIL (`800 40 480 420`; `d_blank_walls.jpg`)
- 4 Too straight: FAIL (`760 170 520 330`; `d_ruler_porch.jpg`)
- 5 Floating objects: FAIL (`0 430 300 160`; `d_boardwalk_no_contact.jpg`)
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 380 1280 340`; `d_empty_street.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`540 290 260 100`; `d_street_end_dome.jpg`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
  Why: the best-lit of the street views: a low sun in the frame, a soft bloom round it and long shadows give it mood. But it is not golden. Sky (`560 200 320 160`, `d_sun_no_glow.jpg`): blue overhead fading to a pale cream at the sun; no orange or pink band at the horizon, so it reads late afternoon, not golden hour. Clouds: thin wisps with a faint warm rim near the sun, the right idea, too faint to sell it. Light: the sunlit ground is grey-cream and the shadows a cold slate blue; no warm wash on anything, no rim light on the porch posts. Air: a pleasant haze round the sun, but no dust lit in the street, which is the very thing golden hour in a dirt town should have. Range: none down the street; a smooth white dome hill sits behind the left buildings like a placeholder.
1. **Golden hour without gold** (tell 2, `560 200 320 160`): the sun is a white disc in a blue sky; ground and walls stay grey. Cause: light. Cheapest fix: warm the sun colour and add an orange horizon band, plus lit dust/fog in the sun's direction.
2. **Bare grey walls** (tell 3, `800 40 480 420`): untextured planes, the shadows on them flat slate. Cause: material. Cheapest fix: weathered board texture.
3. **Empty street** (tell 7, `0 380 1280 340`): no people, carts or tracks. Cause: dressing. Cheapest fix: ruts and scattered dressing.
4. **Placeholder hill and blank horizon** (tell 9, `540 290 260 100`): a smooth white dome behind the town, nothing beyond. Cause: geometry. Cheapest fix: real range silhouette in that gap.
5. **Ruler-straight porch and street** (tell 4, `760 170 520 330`): every post vertical, every beam level. Cause: geometry. Cheapest fix: a degree or two of lean and sag.

## e
- 1 Flat light: FAIL (`0 400 1280 320`; `e_flat_ground_light.jpg`)
- 2 No atmosphere: PASS (`0 280 1280 140`: the far range is hazed and bluer)
- 3 Too clean: FAIL (`0 420 1280 300`; `e_bare_ground.jpg`)
- 4 Too straight: FAIL (`0 368 1280 40`; `e_ruler_horizon.jpg`)
- 5 Floating objects: PASS
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 360 1280 360`; `e_empty_plain.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 280 1280 140`; `e_golden_horizon_cold.jpg`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
  Why: the ground does take a warm pinkish cast, the one sign of a low sun. Sky (`0 0 1280 380`, `e_golden_sky_blue.jpg`): a mid blue at the top fading to pale near the horizon, cool all over; no warmth where the sun should be, so it reads midday-with-a-filter. Clouds: soft cumulus at upper left, lit but without warm rims or long shadows, and a few flat grey stripes near the horizon that look like smudges. Light: the plain is uniformly lit, no long shadows from anything, so the low sun does not show. Air: OK haze on the range. Range (`e_golden_horizon_cold.jpg`): the big left mountain again smeared and stepped with streaks; the rest a low even row of peaks with flat white snow chips; dark seam beneath.
1. **Sky not golden** (tell 2, `0 0 1280 380`): cool blue sky over a warm-tinted ground; the two don't agree. Cause: light. Cheapest fix: warm the lower sky and horizon in the sun's half.
2. **Smeared mountain** (tell 9, `0 280 1280 140`): stretched streaks and a stepped silhouette on the near peak. Cause: geometry. Cheapest fix: smoother mesh and slope-based shading.
3. **No shadows on the plain** (tell 1, `0 400 1280 320`): low sun yet no long shadows anywhere. Cause: dressing. Cheapest fix: scattered brush/rocks so the low sun draws shadow lines.
4. **Ruled horizon seam** (tell 4, `0 368 1280 40`): dead-straight dark dashes along the horizon. Cause: geometry. Cheapest fix: blend the ground into the range with fog.
5. **Empty plain** (tell 7, `0 360 1280 360`). Cause: dressing. Cheapest fix: sage, a trail, a fence line.

## f
- 1 Flat light: PASS (`0 330 1280 390`: a long shadow fills the gully; the sun side and shade side are clearly read)
- 2 No atmosphere: PASS (`0 240 1280 110`: the range is hazed)
- 3 Too clean: FAIL (`0 330 800 340`; `f_blue_shadow_water.jpg`)
- 4 Too straight: FAIL (`0 330 1280 300`; `f_straight_banks.jpg`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`560 325 250 70`; `f_trestle_lattice.jpg`)
- 7 Empty: FAIL (`0 330 1280 390`; `f_empty_gully.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 240 1280 110`; `f_range_streaks.jpg`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
  Why: the shadow across the gully is the strongest light shape in the set. Sky: blue at top to pale at the horizon, again no golden band. Clouds: soft lit cumulus, nice shape, no warm edges. Light (`f_blue_shadow_water.jpg`): the shade is a flat dark slate slab and the water in it a saturated royal blue, too strong for a shadowed creek; the lit dune is a warm grey with no texture. Air: haze on the range is fine; none in the gully. Range: smeared and stepped on the left as in c.
1. **Over-saturated blue water in shade** (tell 3, `0 330 800 340`): a vivid blue band, no reflection, no bank. Cause: material. Cheapest fix: darken/desaturate water in shadow and reflect the sky only where lit.
2. **Trestle moiré** (tell 6, `560 325 250 70`). Cause: geometry. Cheapest fix: anti-aliasing or thicker LOD.
3. **Stepped, streaked range** (tell 9, `0 240 1280 110`). Cause: geometry. Cheapest fix: smoother range mesh.
4. **Planar banks** (tell 4, `0 330 1280 300`). Cause: geometry. Cheapest fix: noise and erosion.
5. **Empty gully** (tell 7, `0 330 1280 390`): no rocks, brush or driftwood. Cause: dressing. Cheapest fix: scattered rocks along the water.

## g
- 1 Flat light: FAIL (`0 400 1280 320`; `g_black_void_ground.jpg`)
- 2 No atmosphere: FAIL (`480 260 360 160`; `g_night_street_crushed.jpg`)
- 3 Too clean: FAIL (`0 100 480 250`; `g_flat_box_faces.jpg`)
- 4 Too straight: FAIL (`160 230 320 120`; `g_ruler_boxes.jpg`)
- 5 Floating objects: N/A (too dark to see any contact)
- 6 Repetition: PASS
- 7 Empty: FAIL (`480 260 360 160`; `g_no_life_windows.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`520 300 300 100`; `g_street_end_black.jpg`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
  Why: a player sees a black screen with stars and two glowing blue boxes. Sky: pure black down to the roofline, no moon in view and no glow at the horizon; the buildings don't separate from it. Clouds: none. Stars: an even sprinkle, all one size, reads like a default starfield. Light: moonlight lights only the box tops in a flat saturated blue; the street, the porches and the people are crushed to 0; the few lit windows (orange at right) throw no pool on the ground. Air: no mist, no glow round the windows. Range: invisible. The overall effect is "the lights failed", not "moonlit night".
1. **Crushed to black** (tell 1, `0 400 1280 320`): the whole lower half is pure black; you can't read the street you stand in. Cause: light. Cheapest fix: raise the moon's ambient/fill so the ground is a dim readable blue.
2. **No sky glow at the horizon** (tell 2, `480 260 360 160`): the sky is as black at the roofline as overhead, so the town has no silhouette. Cause: light. Cheapest fix: a faint blue-grey glow in the lowest 10 degrees of the night sky.
3. **Lit windows light nothing** (tell 7, `480 260 360 160`): orange slits, no warm pool on the boardwalk, nobody about. Cause: light. Cheapest fix: a small warm omni light at each lit window/door.
4. **Glowing blank boxes** (tell 3, `0 100 480 250`): the only lit shapes are untextured walls in a flat electric blue. Cause: material. Cheapest fix: texture plus desaturate the moonlight.
5. **Street ends in a void** (tell 9, `520 300 300 100`): no horizon, no range, just black. Cause: light. Cheapest fix: the horizon glow above, so the range shows as a silhouette.

## h
- 1 Flat light: FAIL (`0 400 1280 320`; `h_flat_navy_ground.jpg`)
- 2 No atmosphere: FAIL (`0 290 1280 110`; `h_black_to_horizon.jpg`)
- 3 Too clean: FAIL (`0 420 1280 300`; `h_bare_ground.jpg`)
- 4 Too straight: FAIL (`0 368 1280 30`; `h_ruler_horizon.jpg`)
- 5 Floating objects: PASS
- 6 Repetition: PASS (stars are evenly spread but not a visible tile)
- 7 Empty: FAIL (`0 360 1280 360`; `h_empty_plain.jpg`)
- 8 Scale tells: PASS (the moon's size is about right)
- 9 Edges of the world: FAIL (`0 290 1280 110`; `h_range_edge.jpg`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
  Why: the night sky is the prettiest thing here, the land the cheapest. Sky (`300 150 560 260`, `h_moon_milkyway.jpg`): a Milky Way band with dark dust lanes rising from the horizon, real-looking and the best sky element in the set; the stars are an even sprinkle of near-identical points, slightly too uniform. Moon: a small, soft-haloed glowing ball low over the range; no face, no phase; reads like a lamp rather than a moon. Clouds (`300 240 300 110`, `h_sky_smudges.jpg`): a few flat grey lens-shaped smears hang in the black, they look like render artifacts. Light: the plain is one even navy sheet, no moon-shadows, no highlight toward the moon. Air: none; the sky is black right down to the range and the range's lit snow edge is crisp. Range: lit blue-white slopes on the left, otherwise a thin dark strip.
1. **Ground is one navy sheet** (tell 1, `0 400 1280 320`): no gradient toward the moon, no shapes. Cause: material. Cheapest fix: a moon-facing sheen on the ground and some brush casting shadows.
2. **No airglow at the horizon** (tell 2, `0 290 1280 110`): black sky meets the range with no haze; moonlit nights have a pale band there. Cause: light. Cheapest fix: a faint horizon glow and a little fog on the range.
3. **Grey smudges in the night sky** (tell 2, `300 240 300 110`): flat lens-shaped streaks among the stars, like misplaced day-cloud sprites. Cause: light. Cheapest fix: darken night clouds to near-black silhouettes, or remove the flat ones.
4. **Moon reads as a lamp** (tell 9, `300 150 560 260`): a uniform glowing disc. Cause: material. Cheapest fix: a moon texture with maria and a sharper edge.
5. **Empty to the edge** (tell 7, `0 360 1280 360`). Cause: dressing. Cheapest fix: silhouettes of brush and a fence against the horizon.

## i
- 1 Flat light: PASS (`0 330 1280 390`: moonlight separates the lit dune crest from the dark gully)
- 2 No atmosphere: PASS (`550 200 300 140`: the moon's glow and the Milky Way warm the horizon above the trestle)
- 3 Too clean: FAIL (`0 330 1280 390`; `i_bare_ground.jpg`)
- 4 Too straight: FAIL (`0 330 1280 300`; `i_straight_banks.jpg`)
- 5 Floating objects: PASS
- 6 Repetition: PASS (the trestle's moiré is hidden by dark)
- 7 Empty: FAIL (`0 330 1280 390`; `i_empty_gully.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 250 1280 90`; `i_range_band.jpg`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
  Why: the best night frame: the moon just above the trestle with the Milky Way rising behind it is a genuine composition. Sky: Milky Way convincing, stars uniform. Moon: glowing disc, no surface. Clouds: none. Light: moon gives the dune a crest highlight, otherwise a flat navy. Air: some glow at the horizon round the moon, nothing in the gully. Range: a pale blue band with streaky smeared slopes on the left.
1. **Flat navy ground** (tell 3, `0 330 1280 390`): untextured slopes. Cause: material. Cheapest fix: texture with grass/scree.
2. **Smeared range** (tell 9, `0 250 1280 90`): the left slopes streaked. Cause: geometry. Cheapest fix: smoother range mesh.
3. **Planar banks** (tell 4, `0 330 1280 300`). Cause: geometry. Cheapest fix: noise and erosion.
4. **Empty gully** (tell 7, `0 330 1280 390`). Cause: dressing. Cheapest fix: rocks, brush, a fire on the bank.
5. **Moon without a face** (tell 2, `550 200 300 140`): a soft lamp, not a moon. Cause: material. Cheapest fix: a moon texture.

## j
- 1 Flat light: FAIL (`0 250 1280 470`; `j_shadowless_overcast.jpg`)
- 2 No atmosphere: PASS (`400 280 480 140`: the far street dissolves into grey haze; the far fronts soften)
- 3 Too clean: FAIL (`800 40 480 420`; `j_blank_walls.jpg`)
- 4 Too straight: FAIL (`760 170 520 330`; `j_ruler_porch.jpg`)
- 5 Floating objects: FAIL (`0 430 300 160`; `j_boardwalk_no_contact.jpg`)
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 380 1280 340`; `j_empty_street.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: PASS (`400 280 480 140`: the end of the street fades into haze rather than stopping)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
  Why: of the street views this has the most believable air. Sky: a heavy, soft grey deck, brighter toward the horizon; reads like a real overcast day. Clouds: streaky, slightly brushed texture with gentle variation; good, though it lacks darker, lower masses so it feels thin. Light: correctly soft and directionless, but with no ambient occlusion under porches, in corners or where things meet the ground, so the scene goes flat and grey-box shows worst here. Air (`j_overcast_street_end.jpg`): the street end and far fronts fade into haze convincingly, the best depth in the set. Range: none; the near hills behind the far roofs are pale ghost shapes with jagged edges.
1. **No soft shadows under overcast** (tell 1, `0 250 1280 470`): porches, eaves and corners are as bright as the open walls. Cause: light. Cheapest fix: SSAO / baked AO so overcast reads as soft, not absent.
2. **Bare grey walls** (tell 3, `800 40 480 420`). Cause: material. Cheapest fix: weathered boards.
3. **Boardwalks float** (tell 5, `0 430 300 160`). Cause: light. Cheapest fix: contact darkening.
4. **Empty street** (tell 7, `0 380 1280 340`). Cause: dressing. Cheapest fix: ruts, puddles (it's overcast), a wagon.
5. **Thin cloud deck** (tell 2, `0 0 1280 280`): one even grey with streaks; no low heavy masses to give it weight. Cause: light. Cheapest fix: a second, darker low cloud layer.

## k
- 1 Flat light: FAIL (`0 400 1280 320`; `k_flat_ground_light.jpg`)
- 2 No atmosphere: PASS (`0 290 1280 110`: the range is pale with distance)
- 3 Too clean: FAIL (`0 420 1280 300`; `k_bare_ground.jpg`)
- 4 Too straight: FAIL (`0 368 1280 40`; `k_ruler_horizon.jpg`)
- 5 Floating objects: PASS
- 6 Repetition: PASS
- 7 Empty: FAIL (`0 360 1280 360`; `k_empty_plain.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 290 700 110`; `k_mountains_smeared.jpg`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
  Why: the sky is the most convincing sky in the set. Sky (`0 0 1280 400`, `k_overcast_sheet.jpg`): a full overcast with streaked, layered cloud structure and soft variation; reads real. Clouds: a touch too evenly lit and brush-streaked, like a painted matte, and no darker rain-bearing patches. Light: the flat even light is right for overcast, but the beige plain has nothing to show it. Air: fine haze on the range. Range: the left peak is still a smeared, streaked wedge; and its snow stays bright white as if sunlit under a grey sky.
1. **Smeared mountain under grey sky** (tell 9, `0 290 700 110`): streaks and steps, and the snow bright as noon. Cause: geometry. Cheapest fix: smooth the mesh and dim the range with the sky.
2. **Ruled horizon seam** (tell 4, `0 368 1280 40`). Cause: geometry. Cheapest fix: fog the ground's edge into the range.
3. **Ground a flat sheet** (tell 1, `0 400 1280 320`). Cause: material. Cheapest fix: ground texture and undulation.
4. **Empty plain** (tell 7, `0 360 1280 360`). Cause: dressing. Cheapest fix: brush and a trail.
5. **Cloud deck evenly lit** (tell 2, `0 0 1280 400`): no thicker, darker parts. Cause: light. Cheapest fix: vary cloud density/darkness.

## l
- 1 Flat light: FAIL (`0 330 1280 390`; `l_facet_lit_ground.jpg`)
- 2 No atmosphere: PASS (`0 240 1280 110`: the range fades)
- 3 Too clean: FAIL (`0 380 720 300`; `l_clean_water_banks.jpg`)
- 4 Too straight: FAIL (`0 330 1280 300`; `l_straight_banks.jpg`)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`560 325 250 70`; `l_trestle_lattice.jpg`)
- 7 Empty: FAIL (`0 330 1280 390`; `l_empty_gully.jpg`)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 240 1280 110`; `l_range_streaks.jpg`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
  Why: the overcast sky is again good and the light under it consistent (grey-blue water that matches the sky, which reads better than the midday and golden water). Sky: layered overcast, real. Clouds: soft, streaky, a bit painted. Light: soft, but the slopes show only two flat facet tones. Air: fine on the range, none in the gully. Range: the left ridge smeared and stepped; the snow lens shapes at its base flat and bright.
1. **Trestle moiré** (tell 6, `560 325 250 70`). Cause: geometry. Cheapest fix: anti-aliasing / thicker LOD.
2. **Smeared range** (tell 9, `0 240 1280 110`). Cause: geometry. Cheapest fix: smoother range mesh, snow toned to the sky.
3. **Flat slopes** (tell 1, `0 330 1280 390`). Cause: material. Cheapest fix: ground texture.
4. **Planar banks and water** (tell 4, `0 330 1280 300`). Cause: geometry. Cheapest fix: noise and erosion.
5. **Empty gully** (tell 7, `0 330 1280 390`). Cause: dressing. Cheapest fix: rocks and brush.

## Ranking
From least to most cheap-looking: j, d, i, k, a, l, h, f, c, b, e, g
