# Art judge, critic

## a
- Shapes: PASS (the engine's boiler, domes, stack, spoked drivers and rods read as a credible, heavy 2-8-0; the coach's planked side is solid)
- Painted surface: FAIL (the boiler jacket, `180 150 520 130`: soft cloudy smudges like a photographed dirty tank, not angular patches following the cylinder)
- Light: FAIL (the running gear, `0 290 780 150`: the near side is almost all near-black against a lit sky; no warm key falls on the engine, no cool fill opens the shadows)
- People: N/A (no one in frame)
- One hand: FAIL (the sky is a rich painted sunset; the engine below it is a dim smudged render and the ground a flat brown band)
- **Verdict: FAIL**
1. **Engine backlit into a silhouette** (`0 290 780 150`): wheels, rods and frame sink into brown-black with only rim glints. In the authority, darks are deep but you can still read into them, and warm key light models every form. Cause: light. Fix: add a warm low-sun key from the camera side, or raise the sky fill on the engine, so the drivers and rods get a lit face and a readable shadow side.
2. **Boiler paint is smudge, not strokes** (`180 150 520 130`): grey-blue cloudy blotches with soft edges, like a weathered photo texture or airbrush. The authority's metal (the tin mugs, the lamp's brass) is broad angular planes of colour with clean edges that follow the curve. Cause: paint. Fix: repaint the jacket as a few hard-edged bands along the cylinder (light top, mid flank, dark underside), with grime as flat shapes rather than soft clouds.
3. **Ground and track bed empty** (`0 380 960 160`): a flat brown strip, with ties as bright stepped slats and no ballast, earth or stroke in it. The authority's floor boards are painted grain and wear. Cause: paint. Fix: give the ballast and earth a painted texture of angular stones and ruts, warm where the sun touches it.

## b
- Shapes: PASS (the engine's mass, stack, bell, domes and cowcatcher read; the line running to the horizon gives scale)
- Painted surface: FAIL (the desert, `0 220 420 320`: a smooth airbrushed gradient with no strokes; the boiler, `420 190 540 120`, is cloudy mottle)
- Light: FAIL (the engine's side, `370 280 420 220`: the sun is low and warm, but the train's near side is a dull uniform brown-black with no cool fill or bounce from the bright sand)
- People: N/A (no one in frame)
- One hand: FAIL (the sky is painted, the ground is a plain render gradient, and the engine is a smudged texture: three hands)
- **Verdict: FAIL**
1. **Desert is a blank airbrush gradient** (`0 220 420 320`): half the frame is smooth tan with no form, stone, scrub or stroke, and a hard dark-brown slab for the embankment. In the street references the ground is ruts, tracks and grass tufts in painted patches. Cause: paint. Fix: paint the ground in broad angular patches (ruts, scrub tufts, stones) and give the embankment a ballast texture with lit and shaded faces.
2. **Running gear lost in shadow** (`370 280 420 220`): the drivers, rods and pilot are a murky brown mass. The sand would bounce warm light up into them and the sky would add cool fill, and neither appears. Cause: light. Fix: add ground bounce and sky fill on the engine's shadow side so the spokes and rods read.
3. **Boiler mottle** (`420 190 540 120`): the same soft grey-blue camouflage blotches as in a, with brass bands as the only clean shapes. Cause: paint. Fix: repaint the jacket in hard-edged form-following bands, with warm sun on the top plane.

## c
- Shapes: PASS (the tender, cab and flatcar planks are credible and heavy; the tender's coal bunker reads)
- Painted surface: FAIL (the tender top, `480 250 280 230`: a smooth rusty plate with soft blotches and a pure-black void, not painted planes)
- Light: FAIL (the sand, `0 180 280 320`: hard stair-stepped bright rectangles across the shaded ground; the tender's rear opening is a dead black hole)
- People: N/A (no one in frame)
- One hand: FAIL (the soft painted sky against a smooth CG desert with blocky light patches)
- **Verdict: FAIL**
1. **Blocky stepped shapes on the sand** (`0 180 280 320`): big stair-stepped light rectangles and dashes cut across the ground's shadow. They are coarse squares that follow no form (shadow-map aliasing), beside smooth gradients: the camouflage the rubric names. Cause: light. Fix: raise the shadow resolution or soften and filter the sun's shadow on distant ground, so the shadow edge is clean.
2. **Tender's black void and plastic plate** (`480 250 280 230`): the rear opening is pure black with nothing readable inside, and the deck plate is smooth and slightly glossy, with soft rust clouds. The authority's darks always hold some colour and form. Cause: light (and paint). Fix: give the interior some fill, lifting the black to a dark warm brown with visible edges, and paint the plates as flat planes with hard-edged wear.
3. **Engine far off reads as a dark lump** (`300 100 200 160`): cab and boiler merge into one dark reddish mass under a thin wisp of smoke, with no warm rim from the low sun. Cause: light. Fix: put a warm sun rim on the cab roof and boiler top, and thicken the smoke into a painted plume shape.

## d
- Shapes: FAIL (the train, `40 230 900 75`: at this distance the cars are flat boxes with ragged, broken edges; the engine is a tiny crumbled shape)
- Painted surface: FAIL (the ground, `400 290 360 250`: huge stepped light and dark bars, like a pixel road, on smooth tan)
- Light: PASS (the low sun ahead and warm haze come from a nameable source; the far haze reads)
- People: N/A (no one in frame)
- One hand: FAIL (the sky, `0 0 960 230`: a lavish painted sunset over a CG ground and a stencilled train)
- **Verdict: FAIL**
1. **Ground cut by giant stepped bars** (`400 290 360 250`): a long column of bright stair-stepped rectangles runs to the camera, with more slabs left and right. They read as a pixelated road, not a desert, and follow no form. Cause: light (aliased shadows from the train, projected long). Fix: filter the long-shadow edges, or fade far shadows, so the ground's light reads as a clean soft shadow.
2. **Train silhouette crumbling** (`40 230 900 75`): the car edges are ragged, with dashes and gaps along the roofs and trucks, and the engine is a muddled clump. The authority holds strong, clean silhouettes even in the background figures. Cause: shape (thin geometry and alpha at distance). Fix: give the cars a distant LOD with solid outlines, and stop thin parts dropping out at range.
3. **Sky and ground in two different hands** (`0 0 960 230`): the sky is dense, detailed painted cloud with sun rays, while the ground is an empty smooth gradient. The authority's sky and room are painted with the same density and stroke. Cause: paint. Fix: paint the desert with as much stroke as the sky (scrub, ruts, distant mesas), or calm the sky to match.

## e
- Shapes: PASS (the engine's stack, domes and boiler still read against the sky as a credible locomotive)
- Painted surface: FAIL (the sky, `0 0 960 210`: posterised flat cloud cutouts with dots for stars; the ground, `0 220 440 320`, is a flat grey slab)
- Light: FAIL (the engine, `400 120 560 320`: almost pure black; a single cold blue point on the cylinder; no moonlight modelling the boiler, no warm lamp or firebox glow)
- People: N/A (no one in frame)
- One hand: FAIL (the cut-paper cloud sky over a flat grey CG ground and a black engine)
- **Verdict: FAIL**
1. **Engine an unreadable black mass** (`400 120 560 320`): everything below the boiler line is black, and only the stack and domes read as silhouettes. The authority's night has blue moonlight you can read into, plus warm lamplight. A night engine would also have its headlamp, cab or firebox glow. Cause: light. Fix: add cool moonlight to the boiler's top planes, and a warm glow from the headlamp, cab window and firebox, so the forms read warm against cool.
2. **Sky posterised into flat cutouts** (`0 0 960 210`): the clouds are hard-edged flat blue shapes like cut paper, with uniform star dots. That is a screen filter, not painted cloud that follows form, and unlike the authority's soft moonlit night sky. Cause: paint. Fix: repaint the night clouds with modelled light from the moon (lit edges, darker bellies) instead of flat quantised tones.
3. **Ground a flat grey slab** (`0 220 440 320`): the desert and embankment are plain grey planes with no stroke or texture and a cold, neutral colour. Cause: paint and light. Fix: give the ground painted earth texture, and a blue-violet moonlight tint with darker warm shadows.
