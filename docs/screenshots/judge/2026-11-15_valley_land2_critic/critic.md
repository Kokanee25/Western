# Blind critic, 2026-11-15_valley_land2

1. **The town is unfinished grey boxes, with no porches, signs, props or people**
   - Renders: render_town_height (crop `368 300 400 140`, render_town_height_blank_buildings.png); render_street_noon (crop `520 290 230 90`, render_street_noon_blank_buildings.png)
   - Seen: from the rise, nearly the whole town is plain untextured white-grey blocks, and only one brick building has any material. At street level the far end of the street goes to flat white slabs. Nowhere is there an awning, a sign, a barrel, a hitching rail, a horse or a person. The target street is packed with boardwalks, lettered false fronts, lamps, barrels and figures.
   - Cheapest fix: give every placeholder block at least a wood siding material and a false front with a sign plank. Put the existing porch, barrel and rail props along both sides of the street before adding more detail anywhere else.

2. **Cold, neutral daylight instead of a warm golden haze, even at sunset**
   - Renders: render_street_golden (crop `560 120 720 420`, render_street_golden_cold_grade.png), and all of them
   - Seen: at "sunset" the sky stays saturated noon blue. The sun is a small white disc, and the street and the left buildings go to dark, flat silhouette. Nothing glows orange. Both targets are drenched in orange and amber, with warm light raking the dirt, sun-warmed timber, a hazy sky with warm clouds and long warm shadows that still hold detail.
   - Cheapest fix: at golden hour, tint the sky gradient and the fog/aerial perspective toward amber near the sun, warm the sun colour hard (~2000-2500 K), and raise warm ambient or fill so shadows stay brown, not black. A warm colour grade on the final image would cover most of the gap.

3. **The ground is hard-edged flat patches and roads cut like trenches**
   - Renders: render_town_height (crop `352 352 704 336`, render_town_height_ground_patches.png); render_sheriff_road (crop `320 368 416 352`, render_sheriff_road_road_trench.png); also camp_approach and cabin
   - Seen: from the rise the town sits on big ruler-straight brown rectangles and stripes that end in sharp edges and a pointed tongue, like decals on the sand. Out on the range the wagon road is a sunken dark band with vertical walls and a crisp parallel edge, more like a ditch than a worn track. The target road is warm, loose dirt with ruts, pebbles, hoofprints and grass blending into its edges.
   - Cheapest fix: feather the edges of the dirt and street masks with noise over a few metres. Make road ruts shallow, rounded dips rather than steep cuts. Scatter pebbles and edge grass along the track borders.

4. **The far horizon reads as a lake or sea, and distant hills are smooth cones**
   - Renders: render_sheriff_road (crop `0 300 1120 64`, render_sheriff_road_horizon_sea.png); render_cabin (crop `1060 280 200 80`, render_cabin_cone_hill.png); render_town_height
   - Seen: a flat, pale blue-white band sits under the distant mesas across the whole horizon and looks like water. In the cabin shot the nearer hill is a perfectly smooth dark-violet cone with no rock or texture. The target backdrop is red-rock buttes and warm, hazy ridges.
   - Cheapest fix: blend the backdrop's base into the terrain colour, so it is warm tan haze rather than blue-white. Tint the distant ranges toward rust or ochre. Give the cone hill a rock or dirt material and some noise in its shape.

5. **The stone buildings wear a blotchy purple and blue camouflage texture**
   - Renders: render_street_noon (crop `0 280 520 220`, render_street_noon_stone_texture.png); render_street_golden
   - Seen: the block walls on the left of the street have large tiled squares mottled in purple, blue and khaki. The repeat is obvious, and it looks more like a debug or camouflage pattern than stone or adobe. Nothing in the target has cool hues. Its timber and stone are warm browns, tans and greys.
   - Cheapest fix: fix the stone or adobe material's albedo (remove the cool hue variation, desaturate it toward warm tan-grey) and break up the tiling with a larger-scale variation layer.
