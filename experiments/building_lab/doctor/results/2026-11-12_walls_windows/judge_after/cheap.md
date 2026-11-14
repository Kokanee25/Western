# Cheap judge, judge_after

## a
- 1 Flat light: FAIL (`0 560 1280 160`, `a_ground_flat.jpg`): a sunset sky, but the ground is one smooth tan gradient and the porch, steps and posts throw no shadow on it; the front wall is evenly lit from end to end, so you can't tell where the sun is.
- 2 No atmosphere: FAIL (`960 140 320 340`, `a_back_blocks.jpg`): the buildings behind are flat beige boxes, as crisp as the porch, with no haze or dust in the low light.
- 3 Too clean: FAIL (`220 420 760 120`, `a_wall_base.jpg`): no dirt, splash or weeds where the wall and porch meet the ground; the siding is the same cream colour from one end to the other, and the ground has no tracks, stones or ruts.
- 4 Too straight: FAIL (`230 190 740 290`, `a_front_wall.jpg`): every board, post, rafter and window is dead level and evenly spaced. Nothing sags or leans, and the siding shows a fine square grid of lines like a tile.
- 5 Floating objects: FAIL (`0 440 280 200`, `a_post_float.jpg`): the left porch post stops in mid-air well above the ground (the right post at `1040 150 50 350` does the same), and the steps sit on the sand with no contact shadow.
- 6 Repetition: PASS (the posts and steps share one wood texture, but it isn't obviously tiled at this distance)
- 7 Empty: FAIL (`200 460 760 80`): a bare porch and bare ground. No chair, sign, bucket, hitching rail or anything else to say who lives or works here.
- 8 Scale tells: FAIL (`30 470 620 230`, `a_steps.jpg`): the front steps are huge, chunky blocks (each tread about a third of the door's width deep and tall), and the side steps are stacked boxes the size of crates.
- 9 Edges of the world: FAIL (`960 140 320 340`, `a_back_blocks.jpg`): the neighbouring buildings are untextured beige blocks and the left wall is a blank plane, so it reads like a grey-box level behind a finished house.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Porch posts hang in the air** (tell 5, `0 440 280 200`): both outer roof posts end above the ground, holding nothing up. Cause: geometry. Cheapest fix: run the posts down to footings on the ground, with a dark contact patch.
2. **Grey-box surroundings** (tell 9, `960 140 320 340`): flat, untextured beige blocks stand right next to a detailed house. Cause: dressing. Cheapest fix: put siding and roofs on the neighbours, or hide them in haze.
3. **No shadows on the ground at sunset** (tell 1, `0 560 1280 160`): the sand is a smooth airbrushed gradient, and the porch casts nothing on it even with the sun this low. Cause: light. Cheapest fix: turn on cast shadows from the porch and roof, and add a long sun shadow.
4. **Clean, empty and dead level** (tells 3, 7, `200 420 800 140`): no wear at the wall's base, no clutter on the porch, and a uniform ground. Cause: dressing/material. Cheapest fix: add dirt along the base of the wall and two or three porch props (a chair, a bucket, a sign).
5. **Chunky, oversized steps** (tell 8, `30 470 620 230`): the stairs are built from giant blocks and look like a toy. Cause: geometry. Cheapest fix: use stringers with thin treads at about 7 in risers.

## b
- 1 Flat light: PASS (sunlight falls in a patch on the floor, the corner and lower wall go dark, and you can tell where the light comes from)
- 2 No atmosphere: PASS (outside is hazy and soft; the room has no dust in the sunbeam, but that is minor)
- 3 Too clean: FAIL (`860 0 420 720`, `b_beadboard.jpg`): the beadboard is one even grey-green with no stains, scuffs or fading. Only the window frame shows chipped paint.
- 4 Too straight: FAIL (`450 0 410 640`): the window and boards are perfectly plumb and evenly spaced; nothing has warped or settled.
- 5 Floating objects: FAIL (`500 300 300 290`, `b_outside.jpg`): through the glass the porch post hangs in mid-air, its bottom end floating over the sand.
- 6 Repetition: FAIL (`860 0 420 720`, `b_beadboard.jpg`): identical vertical grooves repeat across the wall, and thin bright blue seam lines run down the boards like texture seams or gaps showing through.
- 7 Empty: FAIL (`0 0 1280 720`): an empty room with bare walls and a bare floor. No curtain, furniture or object of any kind.
- 8 Scale tells: PASS (the window, sill and skirting read at a believable size)
- 9 Edges of the world: FAIL (`500 300 300 290`, `b_outside.jpg`): the view out is a featureless beige plain with a flat horizon: no town, fence or road, as if the house stood alone in a void.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Floating post outside the window** (tell 5, `500 300 300 290`): the porch post visibly ends in mid-air, and a player standing at the window will spot it at once. Cause: geometry. Cheapest fix: run the post down to the ground.
2. **Nothing outside** (tell 9, `500 300 300 290`): through the window there is only an empty sand plain and sky. Cause: dressing. Cheapest fix: put a fence, a neighbour's wall or the street in the window's view.
3. **Empty room** (tell 7, `0 0 1280 720`): bare walls and floor with no sign of a doctor, or of anyone. Cause: dressing. Cheapest fix: hang a curtain and put one piece of furniture under the window.
4. **Blue seam lines in the beadboard** (tell 6, `860 0 420 720`): bright bluish lines run down the boards and look like rendering cracks. Cause: material/geometry. Cheapest fix: close the gaps between boards, or put a dark backing behind them.
5. **Uniform, unworn walls** (tell 3, `860 0 420 720`): the paint is one even tone with no grime near the floor or around the window. Cause: material. Cheapest fix: add grime at the floor and around the frame, and a little fading where the light falls.

## Ranking
From least to most cheap-looking: b, a
