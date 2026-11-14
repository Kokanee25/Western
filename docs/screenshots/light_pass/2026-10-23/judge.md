# Light pass, blind judge round 2 (2026-10-23)

Two fresh sub-agents (`tools/critic.py judge`'s rubric and Sean's reference set, light and colour only), eight renders each named a-h in a shuffled order; the key below was kept from them. Round 1 is not kept: its renders were taken a second after a clock jump, before the sky's ambient had rebuilt under the software renderer, so some shade was black by accident.

Unblinded ranking (most finished first): noon A > B > today > C; afternoon A > B > today > C; golden hour A > B > C > today; saloon at night A > today > B > C.

Shared complaint: the shade is warm grey, never cool; the saloon has no deliberate night blue, its floor carries curved shadows from the lamp shades and a blue strip shows at the bar's corner.


## Key (day)
- a: B noon_road
- b: today afternoon
- c: C noon_road
- d: A afternoon
- e: today noon_road
- f: C afternoon
- g: A noon_road
- h: B afternoon


## Verdict (day)

# Verdict: Light (and colour) only, judge2_day

Judged on trait 3 of the rubric (warm key and cool fill, readable darks, light from a source you
can name) plus the colour grade. Shapes, paint and people are not judged here. All boxes are
`x y w h` in 1280x720. Cuts are in this folder (`<name>_<slug>.png`).

What every frame shares, against the authority and refs 3, 4, 7: the shade is never cool. Every
shaded face (building sides, the jail front, the road beside the right-hand boardwalk) is a flat
warm-grey or mauve-grey with almost no chroma (saturation 0.04-0.18), so there is no warm/cool
split and the darks read as "grey" instead of "shade". In the references the darks are deep but
coloured, and the shade is pushed toward blue sky or toward warm bounced light, never neutral.

## a

**Light: FAIL.** Deciding region: the jail front and the building side right of it
(`880 100 400 360`): dead mauve-grey shade (lightness 0.28, saturation 0.04), no sky fill and
no warm bounce off the bright road under it.

1. **Shade with no cool fill** (`880 100 400 360`, cut `a_jail.png`): the right-hand side wall is
   a uniform purple-brown, the jail's sign front a colourless grey; it is neither lit nor
   shaded, so the sun has no direction you can read on the buildings. Fix: tint the ambient/sky
   fill toward a clear sky blue in the shade, and add warm ground bounce on undersides of eaves
   and porch roofs.
2. **Sky washed to grey-cream** (`0 0 1280 260`, cut `a_sky.png`): the sky is nearly colourless
   (saturation 0.06), reading overcast while the road says hard sun; so there is no cool anywhere
   in the frame against the warm road. Fix: deepen the blue at the zenith, keep the horizon pale
   and warm.

## b

**Light: FAIL.** Deciding region: the jail front in shade (`1040 120 240 420`): warm-grey, no
cool fill; and the whole frame lit as if from behind the viewer although it looks into the sun.

1. **High-key and flat, nothing backlit** (`0 380 1280 340`, cut `b_road.png`): the road's lit and
   shaded parts are nearly one value, cast shadows faint; looking toward the sun, nothing facing
   us goes into shade and no edge gets a rim. Reads like an untreated default render. Fix: pull
   exposure down, deepen the cast shadows, rim-light edges that face the sun.
2. **The sun doesn't glow** (`820 0 300 120`): a white disc in a lavender-grey sky with no warm
   aureole and no warm gradient down to the horizon, so the source isn't felt in the air (refs 3
   and 4 build the whole picture round it). Fix: a warm halo/bloom round the disc and a sky that
   warms toward it.

## c

**Light: FAIL.** Deciding region: the whole frame's grade, seen most in the road
(`0 380 1280 340`, cut `c_road.png`): a grey, desaturated cast over everything.

1. **A greying grade** (`0 380 1280 340`): the road is cream-grey (saturation 0.58 vs 0.76 in a),
   the sky's blue gone yellow-grey (saturation 0.02, cut `c_sky.png`); the picture looks filtered,
   not lit. Fix: remove the desaturation from the grade; put the chroma back in the key light.
2. **Shade with no cool fill** (`880 100 400 360`, cut `c_jail.png`): same dead mauve-grey side
   wall and grey jail front as a. Fix: sky-blue ambient in the shade, warm bounce under the eaves.

## d

**Light: FAIL** (the closest of all eight). Deciding region: the jail front in shade
(`1040 120 240 420`, cut `d_jail.png`): grey-brown (saturation 0.07), not cool, while the sky
above it already has blue-violet cloud shadows; the shade doesn't take that colour.

1. **No cool fill in the shade** (`1040 120 240 420`): the building faces turned from the sun are
   neutral grey; the one cool note in the frame (the cloud shadows, `250 0 700 200`) stops at the
   roofline. Fix: carry the sky's blue-violet into the shaded faces as fill.
2. **The sun is a disc, not a light** (`820 0 300 120`, cut `d_sun.png`): no warm halo, the sky
   round it a cool grey-cream; and no warm dust glow down the street toward it (`480 230 420 170`,
   cut `d_far.png`, clear but neutral). Fix: aureole round the sun and a warm haze that thickens
   toward it at street level (refs 3, 4).

## e

**Light: FAIL.** Deciding region: the foreground road (`0 380 1280 340`): blown out, 4.3% of
the frame clipped.

1. **Blown road** (`0 380 640 340`, cut `e_roadleft.png`): the near road burns to a flat bright
   cream, its painted patches lost; the hottest picture of the set and it looks cheap, not
   sunny. Fix: drop exposure about a third of a stop or roll the highlights off with a shoulder.
2. **Stock blue sky that never reaches the shade** (`0 0 1280 260`, cut `e_sky.png`; and
   `880 100 400 360`, cut `e_jail.png`): a saturated cyan-blue sky (saturation 0.42) clashing with
   the references' warm palette, while the shade under it is still mauve-grey. Fix: a softer,
   warmer blue sky, and let its colour into the shade as fill.

## f

**Light: FAIL.** Deciding region: the whole frame veiled grey, most in the far street
(`480 230 420 170`, cut `f_far.png`) and the road (`0 380 1280 340`, cut `f_road.png`).

1. **A grey fog filter, not warm dust** (`480 230 420 170`): the far street, mesa and sky go to
   one milky grey-cream; the road below is dull grey-brown (saturation 0.25); it reads overcast
   and muddy, the cheapest of the four. Fix: make the haze warm ochre, thin near the camera and
   thick only far down the street, and restore the road's chroma.
2. **Darks crushed** (`0 300 300 340`): the horse at left is near black (lightness 0.14), 1.5% of
   the frame under 20/255, with no colour in the dark. Fix: lift the shadow floor and tint it
   cool so you can read into it (the authority's coat in shade).

## g

**Light: FAIL** (the best noon). Deciding region: the jail front and the building side
(`880 100 400 360`, cut `g_jail.png`): neutral grey and mauve shade, no cool fill.

1. **Shade with no cool fill** (`880 100 400 360`): the sky here is a believable blue but none of
   it gets into the shaded faces; the side wall is the darkest, flattest patch in the frame
   (lightness 0.24, saturation 0.05). Fix: sky-blue ambient into the shade; warm bounce under
   the porch roofs from the bright road.
2. **Neutral distance** (`480 230 420 170`): the far end of the street and the mesa sit in a
   colourless grey veil, so there's no warm desert air; the mesa looks pasted on. Fix: tint the
   distance haze warm near the ground, fading to the sky's blue above the horizon.

## h

**Light: FAIL.** Deciding region: the far street (`480 230 420 170`, cut `h_far.png`): one
milky veil over street end, mesa and sky.

1. **The haze reads as a screen filter** (`480 230 420 170`): warmer than f's, but laid evenly over
   the mid and far distance so the mesa, the far buildings and the sky are one value; it flattens
   depth instead of building it. Fix: less haze overall, warmer, and only at street level toward
   the sun, with a height falloff.
2. **Shade neither cool nor readable** (`1040 120 240 420`, cut `h_jail.png`; horse `0 300 300 340`):
   the jail front a warm grey, the horse near black (lightness 0.16). Fix: cool fill in the shade
   and a lifted, coloured shadow floor.

## Ranked

**Noon (a, c, e, g), most finished to cheapest:**
1. **g**: a believable blue sky over a warm, unclipped road; balanced exposure; only the shade
   and the distance let it down.
2. **a**: warm road and good exposure, but the washed grey sky leaves the frame with no cool at
   all.
3. **e**: punchy, but the road blows out and the saturated stock-blue sky clashes; looks like
   default settings.
4. **c**: a greying grade over everything; the sky and road both drained, reads as filtered.

**Afternoon (b, d, f, h), most finished to cheapest:**
1. **d**: the best contrast and depth, clear far street, the only frame with real cool notes
   (the cloud shadows) against a warm road.
2. **h**: a warm air that gestures at the references' backlit dust, but laid on as an even veil
   that flattens depth.
3. **b**: bright and warm but high-key and flat, with no backlight while looking into the sun.
4. **f**: a grey fog over a dull road and crushed darks; muddy and overcast.

**What the best still gets wrong:** g and d both leave the shade a neutral warm-grey, so there is
no warm-key/cool-fill split, which is the whole of the references' light. And d's sun is a disc
with no glow and no warm dust down the street toward it, so looking into the sun never feels
backlit.


## Key (night)
- a: C golden
- b: A saloon_night
- c: today golden
- d: B saloon_night
- e: B golden
- f: today saloon_night
- g: A golden
- h: C saloon_night


## Verdict (night)

# Light (and colour): the eight treatments

Judged on the rubric's trait 3 only (warm key, cool fill, readable darks, light from a source
you can name) plus colour, against ref_1 (authority) and ref_2..7. Boxes are `x y w h` in
1280x720. Crops are in this folder as `<name>_<slug>.png`.

A note on the references: their darks are warm, not neutral (shadow B/R about 0.12-0.21), the
median is low (0.17-0.28) and the top end stops well short of white (99th percentile ~0.70-0.77).
The cool fill is in the night windows and moon (ref_1, ref_6) and the upper sky (ref_3, ref_4).

## a

**Light: FAIL.** Deciding region: the shade, jail front `1020 80 260 400` and the general grade.
Its shade is neutral grey-brown (shadow B/R 0.50, against the references' ~0.15-0.2) and its
saturation is low (0.47, against 0.64-0.72). The street reads as an overcast late afternoon,
not golden hour. The pole's backlit shadow on the road is right.

1. **Sky and canyon end, `560 120 520 260`** (`a_sky_end.png`). Around the sun the sky is pale
   lemon-cream and blown. The clouds are pastel mauve-pink, and a grey-beige veil lies over the
   canyon end, so the far town dissolves. The references have a deep orange-to-red sky with
   dark-bellied clouds, a small hot sun and a dark, warm mesa silhouette.
   *Fix:* bring the sky down about 0.7 stop near the sun, make the haze a saturated amber
   instead of grey-beige, and darken the cloud undersides.
2. **Jail front in shade, `1020 80 260 400`** (`a_jail_front.png`). The facade is cream-grey
   with a violet mottle and no warm bounce, and it is the brightest flat thing in the town.
   In the references, fronts in shade are warm brown, picking up orange from the street and
   glow from the lamps. *Fix:* tint the shade fill warm (orange bounce from the ground) and lower it.

## b

**Light: FAIL.** Deciding region: the floor, `560 380 600 340`. Huge soft shadow shapes
(crescents, an S-curve and a pale disc) lie across the boards, and no lamp a viewer can see
explains them. There is no cool fill anywhere. The darks themselves are well judged:
deep, readable, and a black point close to ref_1's.

1. **Floor blotches, `560 380 600 340`** (`b_floor_rings.png`). The big curved shadow and light
   shapes read as stains or clouds, not lamp pools. A fine dotted grid also runs over the whole
   floor, like a screen dither. In ref_1 the light pools sit under the lamps that make them, on
   the tables and the floor near them. *Fix:* find the caster (likely the hanging lamp shades or
   fixtures shadowing the sconces) and stop it casting, centre the pools under their lamps, and
   remove the dot pattern.
2. **Bar front, `200 330 340 260`** (`b_bar_front.png`). A blue-violet glowing strip runs down
   the bar's corner. It is the only cool light in the room and it reads as a bug. The bar face is
   almost black, while ref_1's bar and back bar glow warm. *Fix:* kill the blue leak, add warm
   fill from the back-bar lamps onto the front, and put the room's cool in deliberately (night
   blue in the gable gaps or windows, as ref_1 does).

## c

**Light: FAIL.** Deciding region: the left shade, `0 300 560 300`. The blacks are lifted
(2nd percentile 0.084, against the references' 0.03-0.05), so a milky veil sits over the whole
frame. The horse and the porch shadows go tan, and the darks lose their weight.

1. **Lifted shade, `0 300 560 300`** (`c_left_shade.png`). The horse, the porch interior and the
   cast shadows are all raised to mid tan, and nothing is deep. *Fix:* drop the black point back
   to around 0.03, keep the shade warm, and lift contrast in the low mids.
2. **Sky and canyon end, `560 120 520 260`** (`c_sky_end.png`). This has the same blown pale
   lemon around the sun as a, and the lifted grade flattens the canyon into the haze even more.
   *Fix:* as in a, lower the sky near the sun and make the haze amber, not milk.

## d

**Light: FAIL.** Deciding region: the bar and the people on it, `200 330 340 260`. It is b
darkened by about a third (median 0.10). The man on the stool and the two at the bar are lit
only at the rim, so they are near-silhouettes, which the rubric rules out. The floor blotches
remain.

1. **People and bar underlit, `200 330 340 260`** (`d_bar_front.png`). The seated man's face and
   coat sink into the bar's black. The blue strip on the bar corner still glows. *Fix:* raise
   exposure about 0.4 stop or add warm fill from the back bar, and remove the blue leak.
2. **Floor blotches, `560 380 600 340`** (`d_floor_rings.png`). Darker, the curved shapes read
   as wet stains across the floor. *Fix:* as in b.

## e

**Light: PASS** (narrowly). Deciding region: the road, `300 420 700 300`. It is lit from the low
sun ahead: the pole's long shadow runs at the camera, the stones are rimmed orange, and the
shade is warm and readable (shadow B/R 0.20, matching the references). The key's direction is
nameable and the grade is in the references' range (median 0.25, saturation 0.65).

1. **Sky and canyon end, `560 120 520 260`** (`e_sky_end.png`). This is better than a, but the
   sun's surround is still pale cream rather than a hot orange, and the canyon end is still
   veiled grey-beige. *Fix:* the same sky and haze push as in a, at half the strength.
2. **Jail front, `1020 80 260 400`** (`e_jail_front.png`). The facade is still cream-grey with
   violet flecks. It is the one dead, cold-looking surface, and it reads as a different light
   from the street beside it. *Fix:* warm and lower the shade fill on sunless fronts.

## f

**Light: FAIL.** Deciding region: the sconces and ceiling, `0 0 520 240`. It is b lifted
(black point 0.07, median 0.22). The pools are gone and everything is lit to the same glowing
orange, so the light no longer comes from somewhere. The ceiling is a washed beige.

1. **Sconce bloom, `0 0 520 240`** (`f_sconces.png`). The wall lamps are big white-orange
   blobs that burn the planks around them, and the fixtures barely read. ref_1's flames are
   small and hot, with lit glass and a quick falloff to rich dark between lamps.
   *Fix:* raise the bloom threshold and cut its radius, keep the flame core small, and let the
   wall fall off between lamps.
2. **Floor blotches and dot grid, `560 380 600 340`** (`f_floor_rings.png`). Lifted, the dotted
   grid and the curved shadow shapes are at their most visible. *Fix:* as in b.

## g

**Light: PASS.** Deciding region: the road, `300 420 700 300`. It has the same backlit road
as e, slightly warmer and more saturated (0.69, inside the references' range). The low sun
reads as the key across the whole street, and the darks are warm and readable.

1. **Sky and canyon end, `560 120 520 260`** (`g_sky_end.png`). This is the best of the four,
   but the sun's surround is still blown pale lemon and the clouds are pastel mauve. The
   references' sky is deep orange-red with dark cloud bellies, and their mesa is a strong dark
   warm shape where g's is hazed. *Fix:* lower the sky near the sun, saturate it toward
   orange, darken the cloud undersides, and thin the grey in the far haze.
2. **Single-hue shade, `0 300 560 300`** (`g_left_shade.png`). The horse and the store's shade
   go to one orange-brown mud, with no cool counterpoint anywhere below the sky (the jail front,
   `1020 80 260 400`, is the only non-orange surface, and it is grey). *Fix:* keep the warm
   shade but add a slight blue-violet sky fill on the up-facing and away-facing planes, as in
   the references' upper sky, so key and fill separate.

## h

**Light: FAIL.** Deciding region: the floor and the right half, `560 380 600 340`. It is
crushed (median 0.034, 10th percentile 0.01). The floor, the gaming table and the men are black,
and only the lamps and the near wall survive. The darks are not readable.

1. **Crushed floor and room, `560 380 600 340`** (`h_floor_rings.png`). The floor goes black and
   only the blotch edges show. ref_1 keeps the floor warm brown and full of light. *Fix:* raise
   exposure about 1.5 stops or raise the fill, and keep the black point near 0.025.
2. **Bar and man, `200 330 340 260`** (`h_bar_front.png`). The seated man is a silhouette and the
   bar is gone, while the blue strip on its corner now glows brighter than anything around it.
   *Fix:* as in d, warm fill on the bar, and remove the blue leak.

## Ranked

**Street (a, c, e, g):**
1. **g**: the warmest and richest. The low sun clearly lights the road from ahead, the shade is
   warm and readable, and the grade sits in the references' saturation and tone.
2. **e**: the same light as g, a touch cooler and flatter. It is credible, but the sky glows
   less and the town looks a shade more washed.
3. **a**: the shade is neutral grey and the colour is thin. It reads as overcast afternoon
   with a painted sunset pasted behind.
4. **c**: lifted blacks put a milky veil over everything, so the darks have no weight. It reads
   as a cheap tone-map.

Best (g) still wrong: the sky around the sun is blown pale lemon with pastel clouds, and the
canyon end sits under a grey veil, where the references have a deep orange-red sky and a dark,
warm mesa. The shaded jail front stays cream-grey, and the frame has no cool fill to set
against the orange.

**Saloon (b, d, f, h):**
1. **b**: deep but readable darks with a black point like ref_1's, and lamps that make some
   local light. It is the closest to a lit room at night.
2. **f**: readable and warm, but lifted. The pools are gone, the ceiling is washed beige and the
   sconces bloom into blobs, so it looks evenly lit and flat.
3. **d**: b darkened. The men at the bar sink to silhouettes and the floor blotches read as stains.
4. **h**: crushed to black. The room and the people are unreadable, and only the lamps and the
   blue bug show.

Best (b) still wrong: the floor is covered in large curved shadow shapes and a dotted grid that no
visible lamp explains. The room has no deliberate cool fill (ref_1's night-blue windows and
moon), only a blue leak on the bar corner. The bar front is near-black, and the sconces bloom as
soft blobs instead of ref_1's small, hot flames with rich warm light between them.
