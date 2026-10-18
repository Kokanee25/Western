# Art judge, 2026-10-18_views_street

## a
- Shapes: FAIL (the horse `270 320 180 250` is faceted low-poly with stick legs; the hand `720 430 220 290` is a stack of boxes)
- Painted surface: FAIL (the road `300 520 500 200` is photographic grit and noise, not painted patches)
- Light: PASS (low warm sun from down the street, long shadows, cooler shade under the porches)
- People: FAIL (the man on the porch `130 280 100 170` is a dark smudge with no painted face planes)
- One hand: FAIL (a lush painted sunset sky over a photo-textured road and a blocky voxel hand)
- **Verdict: FAIL**
1. **The player's hand** (`720 430 220 290`): coarse cube-built hand and sleeve in big flat squares, nothing like the authority's painted, modelled hand on the mug. Cause: shape. Fix: replace the blocky viewmodel hand with a modelled hand painted in skin planes like the authority's.
2. **The road** (`300 520 500 200`): fine photographic grit and speckle with no brush planes; reads as a scanned dirt photo beside a painted sky. Cause: paint. Fix: repaint the road texture in broad angular patches (ruts as painted strokes), drop the high-frequency noise.
3. **The horse** (`270 320 180 250`): faceted, near-black, stiff stilt legs; no painted muscle or highlight, unlike ref_3/ref_4's horses. Cause: shape. Fix: a better-proportioned horse model with a painted coat that catches the rim light.

## b
- Shapes: FAIL (the horse `290 360 180 140` is a dark faceted block; the hand `760 430 220 290` blocky)
- Painted surface: FAIL (the store facade `680 30 600 450` is photographic wood grain with coarse pixel lettering)
- Light: FAIL (the sun `440 190 100 100` is a flat white disc; the street is evenly orange with no cool fill)
- People: N/A (no person close enough to judge)
- One hand: FAIL (painted sky, photo-textured timber, pixel signs and voxel hand)
- **Verdict: FAIL**
1. **The facades' wood** (`680 30 600 450`): photo-like grain with knots and fine scratch lines, and stair-stepped pixel letters ("GENERAL STORE") beside the soft painted sky; the authority's wood is broad painted strokes. Cause: paint. Fix: repaint the siding as angular painted planks and render the lettering at the same painted resolution as the boards.
2. **The sun** (`440 190 100 100`): a hard, flat white disc stuck on the sky; ref_3/ref_4 paint a glowing sun with rays bleeding into cloud. Cause: light. Fix: paint the sun's glow and bloom into the sky panel rather than drawing a disc.
3. **The horse and hand** (`290 360 180 140`, `760 430 220 290`): faceted dark horse and cube hand, out of place against the painted sky. Cause: shape. Fix: rework both models with painted, lit surfaces.

## c
- Shapes: FAIL (the foreground horse/figure `180 360 140 260` is a featureless black mass)
- Painted surface: FAIL (the sky `700 130 580 300` is three-tone streaky mottle, camouflage rather than painted cloud)
- Light: FAIL (the street `700 420 580 300` sinks into murk; no moonlit cool fill to read into)
- People: FAIL (the figures on the porch and in the street are dark silhouettes)
- One hand: FAIL (posterised sky, warm photo-textured porches, voxel hand)
- **Verdict: FAIL**
1. **The night sky** (`700 130 580 300`): flat posterised streaks of three blues with square stars; the authority's night is a deep, painted blue with a glowing moon. Cause: paint. Fix: a painted night sky panel with soft cloud forms and a moon as the named cool source.
2. **No cool fill** (`700 420 580 300`): the road and canyon are near-black with nothing readable; the authority keeps darks blue and legible. Cause: light. Fix: raise moonlight/ambient as a blue fill so the street and rocks read.
3. **The foreground figure** (`180 360 140 260`): an unlit black silhouette; the authority's figures are lit and modelled. Cause: light. Fix: let porch lamp light and moon fill reach figures (rim or bounce) so their forms read.

## d
- Shapes: PASS (facades, posts and braces are thick and readable)
- Painted surface: FAIL (the sky `0 0 1280 220` is radial smeared streaks; the ground `0 480 1280 240` bleached photo grit)
- Light: FAIL (flat noon white light, no warm key or cool fill anywhere)
- People: FAIL (the men on the saloon porch `250 380 230 200` are small, flat and unmodelled)
- One hand: FAIL (smeared sky, pale photo-wood, pixel signs, voxel hand)
- **Verdict: FAIL**
1. **The light** (whole frame, `0 0 1280 720`): bleached midday white with no warm/cool contrast or deep shadow; nothing like the authority's warm key and blue fill. Cause: light. Fix: warm the sun and add a blue sky fill so shaded sides go cool and lit sides warm.
2. **The sky** (`0 0 1280 220`): clouds smeared in radial streaks like a motion blur toward the camera, not painted cloud masses. Cause: paint. Fix: stop stretching the cloud texture over the dome near the zenith; paint the day sky as a panel like the sunset one.
3. **The ground** (`0 480 1280 240`): pale, washed-out sand with fine photographic grit and white faceted pebbles. Cause: paint. Fix: repaint the ground in broad warm patches with painted ruts and fewer, painted stones.

## e
- Shapes: FAIL (the horse `0 160 320 280` is faceted with stiff tube legs; pebbles `0 380 700 340` are low-poly facets)
- Painted surface: FAIL (the road `0 380 700 340` is photographic noise beside the painted sky)
- Light: PASS (low sun behind the rocks, warm rays, shadows toward the camera)
- People: N/A (only a distant speck down the street)
- One hand: FAIL (a rich painted sky `500 0 500 260` over a photo-textured road and low-poly props)
- **Verdict: FAIL**
1. **The road** (`0 380 700 340`): fine grainy photographic dirt with blur; the authority-style references paint the street in strokes. Cause: paint. Fix: repaint the road texture as broad painted patches and ruts.
2. **The horse** (`0 160 320 280`): flat-shaded faceted body, dark tube legs, no painted coat or highlights. Cause: shape. Fix: a better horse model painted with light on its flank.
3. **Faceted pebbles** (`0 600 200 120`): crisp low-poly stones with flat facets read as 3D primitives, not paint. Cause: shape. Fix: smooth and paint the stones (or fewer, painted into the ground texture).

## f
- Shapes: FAIL (the horse `0 160 320 280` faceted, stiff legs)
- Painted surface: FAIL (the road `0 380 700 340` bleached photographic grit; the sky `0 0 1280 200` flat posterised cloud)
- Light: FAIL (flat midday light, no warm key or cool fill)
- People: N/A (only a distant speck)
- One hand: FAIL (posterised sky, near-photo rocks, photo road)
- **Verdict: FAIL**
1. **The light** (`0 0 1280 720`): even, washed noon light; the scene has no warm/cool and no deep readable shadows. Cause: light. Fix: warmer sun and blue sky fill, deeper shade under the porches.
2. **The road** (`0 380 700 340`): pale sand with photographic speckle and white faceted pebbles. Cause: paint. Fix: repaint in broader warm patches, painted ruts.
3. **The sky** (`0 0 1280 200`): clouds in a few flat posterised tones with hard edges; reads as a filter, not a painting. Cause: paint. Fix: a painted day-sky panel with modelled cloud forms.

## g
- Shapes: FAIL (the man `480 300 180 360` stands in a stiff arms-down pose with splayed claw hands)
- Painted surface: FAIL (the MEALS sign `500 0 760 280` shows coarse stair-stepped squares; the window `0 200 340 520` black with blocky glints)
- Light: PASS (warm lanterns on the porch, cool dusk beyond)
- People: FAIL (the man's face `480 300 180 360` is small and flat, hands unpainted)
- One hand: FAIL (coarse pixel sign and blocky window beside smooth photo-wood boards)
- **Verdict: FAIL**
1. **The MEALS sign** (`500 0 760 280`): huge chunky pixel letters and squared wood; coarse squares beside smooth work, exactly what the rubric rules out. Cause: paint. Fix: render the sign's lettering and board at a higher texel density, painted.
2. **The man** (`480 300 180 360`): stiff mannequin pose, claw-like hands, face without painted planes or moustache weight; the authority's man is modelled in paint. Cause: shape. Fix: an idle pose with relaxed hands and a painted face/head at the authority's level.
3. **The window** (`0 200 340 520`): flat black panes with blocky orange rectangles for lights; no painted reflection or interior glow. Cause: paint. Fix: paint the glass with a warm interior glow and a cool sky reflection.

## h
- Shapes: PASS (the saloon's porch, posts and false front read as solid timber)
- Painted surface: FAIL (the sky `0 0 1280 300` is radial smeared streaks; the door `640 360 160 160` checkered mottle)
- Light: PASS (warm porch lanterns against a purple dusk sky)
- People: FAIL (the men on the porch `380 340 400 200` are dark, flat figures with no faces to read)
- One hand: FAIL (smeared sky, photo-wood front, pixel lettering, voxel hand)
- **Verdict: FAIL**
1. **The dusk sky** (`0 0 1280 300`): orange cloud streaks radiating like a zoom blur with square stars; not painted cloud. Cause: paint. Fix: a painted dusk panel without the dome stretch at the zenith.
2. **The men on the porch** (`380 340 400 200`): near-silhouettes under lanterns, no lit faces or folds; the authority's figures are warmly lit and modelled. Cause: light. Fix: let the porch lamps light the figures' faces and fronts.
3. **The doorway** (`640 360 160 160`): the interior shows as a coarse checkerboard of squares, noise rather than a form. Cause: paint. Fix: paint the interior seen through the door (or raise its texel density).

## i
- Shapes: PASS (the man `560 330 160 320` is credibly proportioned; buildings thick and solid)
- Painted surface: FAIL (the ground `0 560 800 160` is photographic grit with faceted pebbles)
- Light: PASS (warm low sun on the man and street, porch lamps, cooler shade under roofs)
- People: FAIL (the man's face `570 340 100 100` is painted but in coarse squares; hands stiff, A-pose; the porch men `0 250 420 230` are flat)
- One hand: FAIL (painted man and sky, photo ground, pale photo-wood signs)
- **Verdict: FAIL**
1. **The ground** (`0 560 800 160`): photographic dirt with fine noise and low-poly faceted white pebbles; the painted man stands on a photograph. Cause: paint. Fix: repaint the ground as broad warm patches with painted stones.
2. **The man's face and pose** (`560 330 160 320`): face reads as the authority's type but rendered in coarse squares, arms hanging stiff with splayed hands. Cause: shape. Fix: a relaxed idle pose and more texels on the face so the planes and moustache read.
3. **The saloon porch men** (`0 250 420 230`): two flat, dark figures with no painted faces, unlike the lit foreground man. Cause: light. Fix: light the porch figures from the lanterns and give them the same painted faces.
