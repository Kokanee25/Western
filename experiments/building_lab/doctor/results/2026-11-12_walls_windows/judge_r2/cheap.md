# Cheap judge, judge_r2

## a
- 1 Flat light: PASS (`0 560 800 160`: a hard sun patch with the window's cross-bars on the floor, the room falls off into dark corners; you can tell where the light comes from)
- 2 No atmosphere: FAIL (`590 140 210 160`, `a_sky.jpg`; `0 560 800 160`, `a_floor.jpg`): the sky is posterised into flat bands of three or four colours, and the sunbeam crossing the room to the floor shows no dust or air at all. The distant haze outside is the one good note.
- 3 Too clean: FAIL (`880 0 400 720`, `a_wall.jpg`): the beadboard is one even grey-green from ceiling to skirting, with no grime, handprints, water stains or sun fade; only a few specks near the floor
- 4 Too straight: FAIL (`440 0 420 640`, `a_frame.jpg`): the window frame, muntins, boards and skirting are all ruler-perfect and evenly spaced; nothing sags, warps or sits out of square
- 5 Floating objects: FAIL (`540 120 80 400`, `a_post.jpg`): the porch post outside ends in mid-air above bare sand, with no floor, footing or shadow under it
- 6 Repetition: PASS (the beadboard repeats, but that is what beadboard is; no tiled stain or prop copied)
- 7 Empty: FAIL (`0 560 800 160`, `a_floor.jpg`): a bare room with no furniture, no curtain, nothing on the sill and nothing on the floor; nothing says anyone uses it
- 8 Scale tells: PASS (window, boards and skirting read at a plausible human size)
- 9 Edges of the world: FAIL (`500 310 300 250`, `a_ground.jpg`): outside the window is a flat, featureless beige plain with a smudged horizon and a porch whose floor is only a stray corner of planks at the bottom right
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The porch post hangs in the air** (tell 5, `540 120 80 400`): through the window, the post holding up the porch roof stops short of anything, with sand under it and no porch floor. This one is the first thing a player spots, and it reads as unfinished. Cause: geometry. Cheapest fix: run the porch deck under the window (or extend the post down to a footing on the ground) so the post stands on something.
2. **A blank world outside** (tell 9, `500 310 300 250`): beyond the glass is a smooth beige plane to a blurred horizon, with no road, scrub, fence, ruts or neighbouring building. It looks like a test level. Cause: dressing. Cheapest fix: put a few pieces of ground cover and one building or fence line in the window's view.
3. **A posterised sky** (tell 2, `590 140 210 160`): the clouds are stepped into hard flat bands of colour, a painted, toy-like finish next to the realistic wood. Cause: material. Cheapest fix: use a smooth-gradient sky texture (or drop the colour quantisation on the sky).
4. **An empty, unused room** (tell 7, `0 560 800 160`): bare floor, bare walls, no curtain or sill clutter, so the nice sun patch has nothing to fall on. Cause: dressing. Cheapest fix: a chair or cabinet in the corner and a curtain or blind at the window.
5. **Walls and frame too clean and too true** (tells 3 and 4, `880 0 400 720`): the beadboard is one even tone end to end and every line is perfect; only the black frame shows a little chipped paint. Cause: material. Cheapest fix: a grime/fade pass on the wall's lower third and near the window (dirt at the skirting, sun bleaching around the frame).

## Ranking
From least to most cheap-looking: a
