# Cheap judge, 2026-11-12_jail_r1_cheap

## a
- 1 Flat light: PASS (`950 420 330 300`: low sun lands in hard-edged patches on the floor, the right wall throws a real shadow; the far corners go properly dark)
- 2 No atmosphere: FAIL (`950 420 330 300`; `cut a_a_sunpatch.png`: the sun patches sit on the boards but there is no shaft or dust in the air above them; the far wall is as crisp as the near one)
- 3 Too clean: FAIL (`0 60 700 420`; `cut a_a_stone_tile.png`: no grime where wall meets floor, boards uniformly polished; the stone's "dirt" is blue and ochre blotches stamped on every block)
- 4 Too straight: FAIL (`300 0 900 230`; `cut a_a_joists.png`: ceiling joists ruler-straight and evenly spaced, wall courses dead level, nothing sags)
- 5 Floating objects: PASS (wall bases darken into the floor along the back wall `700 380 400 60`)
- 6 Repetition: FAIL (`0 60 700 420`; `cut a_a_stone_tile.png`: the same blotchy stone tile on every block, the pattern repeating across the wall)
- 7 Empty: FAIL (`0 0 1280 720`; `cut a_a_empty_room.png`: a big room with nothing in it but one wall lamp: no desk, chair, stove, bucket, papers)
- 8 Scale tells: PASS (doorway `290 270 90 200` and window read as person-sized)
- 9 Edges of the world: FAIL (`1150 150 130 450`; `cut a_a_right_wall.png`: the right wall's panels misalign and a bright, smeared exterior shows through where the wall should close)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Empty room** (tell 7, `0 0 1280 720`): a large stone-and-board space with no furniture or sign of use; reads as a level blockout. Cause: dressing. Cheapest fix: a desk, chair, stove and a rack of keys or papers in this room.
2. **Camouflage stone** (tell 6, `0 60 700 420`): the stone blocks wear a posterised blue/ochre blotch pattern that repeats block to block, like military camo, not weathered stone. Cause: material. Cheapest fix: replace the stone texture's colour noise with a low-contrast, unsaturated weathering and break the tile per block.
3. **Wall seam showing outside** (tell 9, `1150 150 130 450`): the right wall's panels don't meet and a bright blurred exterior shows through. Cause: geometry. Cheapest fix: close the wall corner so no exterior can be seen through it.
4. **No air in the sun** (tell 2, `950 420 330 300`): sunlight hits the floor with nothing in the air; the room feels vacuum-clean. Cause: light. Cheapest fix: volumetric haze or dust motes in the sun from the openings.
5. **Clean, straight floor and ceiling** (tell 3, `0 430 1280 290`): boards uniform and glossy, joists perfect, no scuffs at the door or dirt in corners. Cause: material. Cheapest fix: a dirt/scuff decal at the doorways and along the wall bases.

## b
- 1 Flat light: PASS (`280 510 420 80`: the barred window casts a clear sun patch on the floor; the room falls off to dark beyond it)
- 2 No atmosphere: FAIL (`780 120 450 470`; `cut b_b_window_noair.png`: the window is a flat bright card and no light shaft crosses the room to the floor patch)
- 3 Too clean: FAIL (`0 430 1280 290`; `cut b_b_bare_floor.png`: the floor is spotless, evenly varnished boards with no traffic wear, no dirt at the wall)
- 4 Too straight: FAIL (`520 0 760 520`; `cut b_b_wall_straight.png`: every stone course perfectly level and evenly sized, the wall plane dead flat)
- 5 Floating objects: PASS (wall-floor junctions darken `530 400 500 80`)
- 6 Repetition: FAIL (`900 100 380 300`; `cut b_b_posterised_stone.png`: the same pixelated blotch pattern, with posterised blue and maroon squares, on every block)
- 7 Empty: FAIL (`0 430 1280 290`; `cut b_b_bare_floor.png`: an empty room with a lamp and a window; nothing to say anyone uses it)
- 8 Scale tells: PASS (door, window and lamp in proportion)
- 9 Edges of the world: PASS (the doorway `160 190 160 290` leads into another room)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Pixel-camo stone** (tell 6, `900 100 380 300`): up close the wall shows blocky leftover squares in blue, maroon and ochre: looks like a low-res placeholder texture. Cause: material. Cheapest fix: a higher-resolution, desaturated stone texture with no colour squares.
2. **Empty room** (tell 7, `0 430 1280 290`): nothing on the floor or walls. Cause: dressing. Cheapest fix: a cot or bench under the window and a bucket in the corner.
3. **Window as a flat card** (tell 2, `780 120 450 470`): the panes are a uniform white with no view or bloom and no beam to the floor. Cause: light. Cheapest fix: a faint dust shaft from the window to the sun patch.
4. **Pristine floor** (tell 3, `0 430 1280 290`): every board the same sheen. Cause: material. Cheapest fix: wear the boards along the path from door to window.
5. **Mechanical courses** (tell 4, `520 0 760 520`): the masonry has no irregular stones, no mortar loss, no settle. Cause: geometry. Cheapest fix: vary block sizes and add slight per-block offset/bevel.

## c
- 1 Flat light: FAIL (`0 0 660 540`; `cut c_c_flat_beadboard.png`: the beadboard wall is lit evenly top to bottom with no falloff and no source; the lamp on it casts nothing)
- 2 No atmosphere: FAIL (`800 250 80 200`; `cut c_c_doorway_sharp.png`: the bright exterior through the door is as crisp as the room; no haze anywhere)
- 3 Too clean: FAIL (`0 0 660 540`; `cut c_c_flat_beadboard.png`: the painted boards are uniform end to end: no grime at hand height, no scuffs above the skirting)
- 4 Too straight: FAIL (`0 0 660 540`; `cut c_c_flat_beadboard.png`: perfectly parallel, evenly spaced beadboard lines and a dead-level skirting)
- 5 Floating objects: FAIL (`1030 0 90 560`; `cut c_c_lone_post.png`: the post meets the floor with no contact shadow, as if set on top of it)
- 6 Repetition: FAIL (`650 150 600 300`; `cut c_c_stone_repeat.png`: the same blotchy blue stone tile repeated across the back wall)
- 7 Empty: FAIL (`0 400 1280 320`; `cut c_c_empty_floor.png`: a bare floor with a single small sun patch in the middle)
- 8 Scale tells: PASS (door and lamp sized right)
- 9 Edges of the world: FAIL (`940 0 340 120`; `cut c_c_roof_gap.png`: a bright light leak where the roof meets the wall plate; the roof reads as unfinished)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Flat painted wall** (tell 1, `0 0 660 540`): half the frame is an evenly lit cream beadboard with no shadow shape; it looks like a texture on a box. Cause: light. Cheapest fix: let the lamp actually light the wall (a warm pool fading to dark) and drop the ambient fill.
2. **Empty room** (tell 7, `0 400 1280 320`): nothing on the floor; a single odd sun patch. Cause: dressing. Cheapest fix: a desk with a chair and papers against the beadboard.
3. **Two walls that don't belong together** (tell 6, `650 150 600 300`): clean cream boards meet camo-blotched stone with no transition. Cause: material. Cheapest fix: tone the stone texture down to match the room's wear level.
4. **Post with no weight** (tell 5, `1030 0 90 560`): the post stands on the boards with no contact darkening. Cause: light. Cheapest fix: contact shadow / ambient occlusion at the post's foot.
5. **Light leaking at the roof** (tell 9, `940 0 340 120`): a bright slit at the top edge says the roof isn't closed. Cause: geometry. Cheapest fix: close the gap between roof and wall plate.

## d
- 1 Flat light: FAIL (`0 0 1280 720`; `cut d_d_blue_fill.png`: an even blue-grey fill over everything, blacks lifted to slate; the wall lamp throws no pool; you cannot say where the light comes from)
- 2 No atmosphere: PASS (the corridor's end `600 200 120 200` softens a little into haze)
- 3 Too clean: FAIL (`400 400 400 320`; `cut d_d_floor_tile.png`: the floor slabs are uniform with no dirt at the cage feet or along the wall)
- 4 Too straight: FAIL (`100 150 500 450`; `cut d_d_cage_repeat.png`: the cage grids are perfect lattices in a perfect line)
- 5 Floating objects: FAIL (`380 480 220 200`; `cut d_d_cage_feet.png`: the cage posts meet the floor with no contact shadow in the flat blue light)
- 6 Repetition: FAIL (`100 150 500 450`; `cut d_d_cage_repeat.png`: identical cages in a row; the same blue-and-yellow blotch tile on every wall block `980 0 300 720`)
- 7 Empty: FAIL (`100 150 500 450`; `cut d_d_cage_repeat.png`: the cells have no bunk, blanket, bucket or prisoner)
- 8 Scale tells: PASS (cage height and corridor width read right)
- 9 Edges of the world: PASS (the corridor ends in a wall with a window)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Blue fill everywhere** (tell 1, `0 0 1280 720`): the whole corridor is washed in an even cold grey-blue; nothing is dark, nothing is lit. Cause: light. Cheapest fix: cut the ambient fill and let the wall lamps make pools with real darkness between.
2. **Camo wall** (tell 6, `980 0 300 720`): the near wall's blocks are saturated blue and yellow blotches, big and soft up close; reads as a placeholder. Cause: material. Cheapest fix: a desaturated, higher-resolution stone texture.
3. **Empty cells** (tell 7, `100 150 500 450`): a jail with nothing in its cells. Cause: dressing. Cheapest fix: a bunk and a slop bucket in each cell.
4. **Clone cages** (tell 6, `100 150 500 450`): the same cage repeated with perfect spacing. Cause: geometry. Cheapest fix: vary one cell (door open, a bar bent, a blanket over the bars).
5. **Clean floor** (tell 3, `400 400 400 320`): the slabs carry the same blotch pattern and no grime where feet go. Cause: material. Cheapest fix: a dirt/straw decal along the corridor and at the cell doors.

## e
- 1 Flat light: PASS (`700 200 80 80`: a warm wall lamp is clearly the key; the cages throw striped shadows across the floor `100 480 400 240`; the far side falls to near black)
- 2 No atmosphere: FAIL (`660 190 140 120`; `cut e_e_lamp_noglow.png`: the lamp is a bright point with no glow or haze around it; the air in the corridor is clean)
- 3 Too clean: FAIL (`400 480 380 240`; `cut e_e_floor_tile.png`: the floor slabs carry a posterised blotch pattern but no real grime, straw or wear)
- 4 Too straight: FAIL (`100 150 520 450`; `cut e_e_cage_repeat.png`: the cages are perfect identical lattices in a straight line)
- 5 Floating objects: PASS (the cage feet sit in their own shadows `400 480 200 200`)
- 6 Repetition: FAIL (`100 150 520 450`; `cut e_e_cage_repeat.png`: the same cage repeated; the same floor tile repeated)
- 7 Empty: FAIL (`100 150 520 450`; `cut e_e_cage_repeat.png`: empty cells, no prisoner, bunk or belongings)
- 8 Scale tells: PASS (lamp, cages and corridor in proportion)
- 9 Edges of the world: PASS (the corridor closes at the back wall)
- 10 Stiff people: N/A
- **Verdict: cheap indie** (the closest of the set to good indie: the light here has shape)
1. **Empty cells** (tell 7, `100 150 520 450`): the moody light shows off cells with nothing in them. Cause: dressing. Cheapest fix: a bunk, blanket and bucket in each cell, one occupied.
2. **Stray black shadow blob** (tell 1, `680 470 80 70`; `cut e_e_lamp_shadow.png`): a hard, pure-black rounded shadow on the floor below the lamp with nothing to cast it. Cause: light. Cheapest fix: find and remove the hidden caster, or soften that shadow.
3. **Posterised floor** (tell 3, `400 480 380 240`): the slabs show pixel blotches of brown and red rather than worn stone. Cause: material. Cheapest fix: a cleaner, higher-resolution stone floor texture with dirt in the joints.
4. **No glow in the lamplight** (tell 2, `660 190 140 120`): the lamp lights the wall but the air around it is empty. Cause: light. Cheapest fix: a small halo/volumetric fog around the lamp.
5. **Clone cages** (tell 6, `100 150 520 450`): identical cages, identically spaced. Cause: geometry. Cheapest fix: vary the cells (an open door, a rag on the bars).

## f
- 1 Flat light: FAIL (`0 500 1280 220`; `cut f_f_flat_ground.png`: the ground is one even orange-tan sheet with no shadow, and the building front is evenly lit despite a low sun; no cast shadow from the building)
- 2 No atmosphere: FAIL (`0 0 1280 330`; `cut f_f_sky.png`: the sky is a busy posterised pattern of hard-edged orange, cream and navy blobs; no dust in the low light, the horizon a ruled line `930 380 200 120`)
- 3 Too clean: FAIL (`340 220 600 300`; `cut f_f_wall_tile.png`: no dirt or sand drift at the wall base, no wear on the porch or step)
- 4 Too straight: FAIL (`340 220 600 300`; `cut f_f_wall_tile.png`: a perfect box with a level roofline and a perfectly level porch)
- 5 Floating objects: FAIL (`320 460 680 70`; `cut f_f_porch_base.png`: porch and walls meet the ground with no contact darkening; they look set down on a flat plane)
- 6 Repetition: FAIL (`340 220 600 300`; `cut f_f_wall_tile.png`: the same blotchy block tile repeated across the whole facade and the side wall)
- 7 Empty: FAIL (`0 500 1280 220`; `cut f_f_flat_ground.png`: no hitching rail, sign, barrel, track or person in front of the jail)
- 8 Scale tells: PASS (door, windows and step read as human-sized)
- 9 Edges of the world: FAIL (`1100 260 180 220`; `cut f_f_blank_box.png`: an untextured grey box stands on the right; beyond the building the land is an empty flat plane to a ruled horizon)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Posterised sky** (tell 2, `0 0 1280 330`): the sky is loud, hard-edged colour blobs like a filter on a photo; the first thing a player notices. Cause: light. Cheapest fix: a smooth sunset gradient with soft, unposterised clouds.
2. **Flat ground and no shadows** (tell 1, `0 500 1280 220`): the street is one flat colour and the building casts nothing in the low sun. Cause: light. Cheapest fix: let the sun cast the building's shadow across the ground and add tonal variation (ruts, darker sand) to the street.
3. **Grey blank box** (tell 9, `1100 260 180 220`): a featureless grey block to the right reads as an unfinished or missing asset. Cause: geometry. Cheapest fix: texture it or take it out of shot.
4. **Shoebox jail** (tell 4, `340 220 600 300`): a perfect rectangle with a repeating camo-blotch stone and no roof detail, sign or chimney. Cause: geometry. Cheapest fix: a sign board and a parapet/roof edge to break the box.
5. **Nothing in the street** (tell 7, `0 500 1280 220`): no rail, barrel, wagon tracks or horse. Cause: dressing. Cheapest fix: a hitching rail and a water trough by the porch, wheel ruts in the street.

## Ranking
From least to most cheap-looking: e, b, a, c, d, f
