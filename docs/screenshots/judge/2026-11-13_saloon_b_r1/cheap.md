# Cheap judge, 2026-11-13_saloon_b_r1

## a
- 1 Flat light: PASS (`30 500 1020 100`: one hard sun shadow with the railing's shape in it; the front itself is all in flat shade)
- 2 No atmosphere: FAIL (`0 280 400 240`; `a_a_atmos.png`: the grey blocks and the far tower are as crisp as the porch, no dust or haze)
- 3 Too clean: FAIL (`0 520 1280 200`; `a_a_clean.png`: the ground is one smooth beige with no ruts, stones or dirt where posts and steps land)
- 4 Too straight: FAIL (`400 160 620 200`; `a_a_straight.png`: every post, baluster, window and the roofline dead level and evenly spaced)
- 5 Floating objects: PASS (`260 480 760 60`: posts and steps sit in the shadow; the far table set at `1065 465 70 40` is thin on contact)
- 6 Repetition: PASS (windows and posts repeat as a real front would)
- 7 Empty: FAIL (`440 180 480 50`; `a_a_empty.png`: a blank signboard, a bare porch, one man, nothing in the street)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`1000 300 280 220`; `a_a_edge.png`: untextured grey boxes for neighbours and a flat, empty horizon)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Grey placeholder blocks beside the building** (tell 9, `0 290 230 210` and `1090 325 190 170`): the neighbours are plain grey boxes, so it reads as an unfinished test level. Cause: geometry. Cheapest fix: frame the shot so they're out of it, or give them the same plank material and a roofline.
2. **A ground with nothing on it** (tell 3, `0 520 1280 200`): half the picture is a smooth beige sheet with no texture, ruts or scatter. Cause: material. Cheapest fix: a dirt texture with wheel ruts and a darker, trodden band along the porch.
3. **A flat, posterised sky** (tell 2, `0 0 1280 280`): the clouds are banded in four flat tones like a cut-out, and nothing between here and the horizon has air in it. Cause: material. Cheapest fix: a smooth-gradient sky and distance haze on the far blocks.
4. **A blank sign and a bare porch** (tell 7, `440 180 480 50`): the signboard has no lettering and the porch has no bench, barrel or hitch rail. Cause: dressing. Cheapest fix: letter the sign and put three props on the porch.
5. **A front in flat shade** (tell 4, `400 160 620 360`): the whole facade is one dark value with ruler-straight trim, so the woodwork's detail doesn't read. Cause: light. Cheapest fix: turn the sun so it rakes the front, or add bounce from the ground under the porch.

## b
- 1 Flat light: FAIL (`0 40 520 400`; `b_b_light.png`: the building glows orange from no visible source under a dusk sky, and the ground is one even dark red with no cast shadow)
- 2 No atmosphere: FAIL (`960 340 320 180`; `b_b_atmos.png`: the far buildings are flat silhouettes, no dust or lamp glow in the air)
- 3 Too clean: FAIL (`0 520 1280 200`; `b_b_clean.png`: the ground is a featureless dark sheet)
- 4 Too straight: FAIL (`280 180 780 240`; `b_b_straight.png`: railing, cornice and posts perfectly regular)
- 5 Floating objects: PASS (`260 480 740 110`: the porch's piers and steps read as resting on the ground)
- 6 Repetition: PASS
- 7 Empty: FAIL (`690 90 290 180`; `b_b_empty.png`: a blank signboard; no one and nothing outside but one figure)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 400 300 120`; `b_b_edge.png`: a dead flat horizon line on the left, plain boxes on the right)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A cartoon sky over a realistic building** (tell 2, `0 0 1280 400`): flat orange cloud shapes and square white pixels for stars; it looks like a different, cheaper game's sky. Cause: material. Cheapest fix: soft-edged clouds and stars as small dim points, not squares.
2. **Light from nowhere** (tell 1, `280 60 780 480`): the saloon is lit bright orange on two sides with no sun in the sky and no lamps outside, and it throws no shadow. Cause: light. Cheapest fix: drop the fill and let the windows and a porch lamp light the porch boards.
3. **A blank ground and horizon** (tell 9, `0 400 1280 320`): the ground is one dark red flat plane out to a ruled horizon. Cause: geometry. Cheapest fix: distant hills as a silhouette and a ground texture that catches the window light.
4. **A blank sign, an empty street** (tell 7, `690 90 290 180`): the sign has no name and the night street has no horse, lamp or people. Cause: dressing. Cheapest fix: letter the sign and hang one lit lamp by the door.
5. **Windows that don't spill light** (tell 1, `380 380 600 120`): the windows are lit but nothing falls on the porch or the ground outside. Cause: light. Cheapest fix: a warm light pool on the porch from each lit window.

## c
- 1 Flat light: FAIL (`360 180 600 350`; `c_c_light.png`: both walls nearly the same value, only a thin shadow at the foot, no shadow shapes on the walls)
- 2 No atmosphere: FAIL (`900 300 380 140`; `c_c_atmos.png`: the far blocks are sharp grey boxes, no haze or dust)
- 3 Too clean: FAIL (`0 480 1280 240`; `c_c_clean.png`: clean red boards straight down into clean sand, no splash, stain or rubbish)
- 4 Too straight: FAIL (`360 180 600 160`; `c_c_straight.png`: a perfect box with identical windows on a ruled line)
- 5 Floating objects: PASS (`560 430 440 110`: stairs and steps have shadow under them)
- 6 Repetition: PASS (the windows are one window copied, but as a real building's would be)
- 7 Empty: FAIL (`0 520 1280 200`; `c_c_empty.png`: a back yard with no privy, woodpile, barrels, washing or tracks)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`0 320 380 140`; `c_c_edge.png`: long untextured grey walls and a flat empty horizon)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A box on a beige plane** (tell 9, `0 320 1280 400`): a single building standing in blank sand with grey placeholder blocks behind; this is what an asset-flip test scene looks like. Cause: geometry. Cheapest fix: don't show this view until the neighbours and ground exist, or texture both.
2. **Nothing behind a saloon** (tell 7, `0 440 1280 280`): no privy, woodpile, crates, bottles or path; the back of a working building is where the mess is. Cause: dressing. Cheapest fix: a woodpile, a barrel and a trodden path to each door.
3. **Walls too clean and too even** (tell 3, `370 190 570 330`): the red boards are one colour top to bottom and corner to corner, with no weathering, no splash-back at the ground. Cause: material. Cheapest fix: a dirt gradient at the foot and sun-fade toward the top.
4. **Even light** (tell 1, `360 180 600 350`): the two walls are close in value and nothing casts a shape on them, so the building reads as a flat-shaded model. Cause: light. Cheapest fix: a lower sun so one wall falls into real shade and the stairs throw a shadow on the wall.
5. **Posterised sky** (tell 2, `0 0 1280 330`): banded cut-out clouds, no haze at the horizon. Cause: material. Cheapest fix: a smooth sky and horizon haze.

## d
- 1 Flat light: PASS (`560 440 560 110`: sun patches on the floor, shadows from chairs and posts, dark corners)
- 2 No atmosphere: PASS (`520 270 600 180`: the bar sits back in haze)
- 3 Too clean: FAIL (`60 220 260 200`; `d_d_clean.png`: the wall boards are one even pale green with no smoke stain, scuffs or marks; the floor is evenly glossy)
- 4 Too straight: FAIL (`300 150 780 150`; `d_d_straight.png`: joists, beams and boards ruled and identical)
- 5 Floating objects: PASS (chairs and posts throw shadow on the floor)
- 6 Repetition: FAIL (`30 400 380 240`; `d_d_repeat.png`: the same chair and the same green table copied at every setting, all squared up)
- 7 Empty: FAIL (`660 280 440 170`; `d_d_empty.png`: the back bar's shelves are bare; no bottles, glasses, cards, people)
- 8 Scale tells: PASS (the post brackets at `570 150 120 80` and `880 30 290 140` are oversized blocks, but doors, chairs and tables agree)
- 9 Edges of the world: PASS (the doorway at `0 330 60 100` and the window at `1230 270 50 150` show only blank pale outside; minor)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **A saloon with nothing in it** (tell 7, `660 280 440 170`): the back bar is empty shelving, the tables are bare, nobody is here; it reads as a furnished shell, not a place. Cause: dressing. Cheapest fix: bottles and glasses on the back bar, cards and glasses on two tables.
2. **Identical chairs, squared to the tables** (tell 6, `30 400 380 240`): every chair is the same model at the same angle and pale colour. Cause: dressing. Cheapest fix: turn and pull out a few, tip one, darken some.
3. **Clean, even walls** (tell 3, `60 220 260 200`): pale green boards with no grime at hand height, no smoke above the lamps, nothing hung on them. Cause: material. Cheapest fix: a soot and grime gradient, and pictures or notices on the walls.
4. **Blocky brackets on the posts** (tell 4, `880 30 290 140`): the posts end in big plain blocks with the grain stretched across them, which look like placeholder cubes. Cause: geometry. Cheapest fix: shaped braces or a smaller cap, with the grain running the right way.
5. **Blank outside** (tell 9, `1230 270 50 150`): windows and the doorway show flat pale nothing. Cause: camera. Cheapest fix: blow the windows out to a glow with a little bloom so the outside isn't readable.

## e
- 1 Flat light: PASS (`600 380 420 80`: window light pools on the floor and fades into dark; but most of the frame is near-black)
- 2 No atmosphere: PASS (`400 230 700 200`: haze in the far room)
- 3 Too clean: FAIL (`60 380 600 340`; `e_e_clean.png`: the bar top is a featureless dark slab, no rings, wear or shine)
- 4 Too straight: FAIL (`0 100 700 180`; `e_e_straight.png`: the ceiling and walls are ruled stripes)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`460 370 560 100`; `e_e_repeat.png`: the same table-and-chairs set four times)
- 7 Empty: FAIL (`60 380 600 340`; `e_e_empty.png`: a bar with two lamps and nothing else, an empty room)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`50 260 560 160`; `e_e_edge.png`: the windows are blank off-white panes or show a plain grey box outside)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Half the frame is a black slab** (tell 3, `60 380 600 340`): the bar in the foreground is a dark, textureless block with no highlight, wear or anything on it. Cause: light. Cheapest fix: a lit lamp on the bar (these are unlit) so the top takes a sheen, plus glasses and a bottle.
2. **Blank windows** (tell 9, `50 260 560 160`): the big window is flat cream panes and the next shows a grey placeholder box outside. Cause: camera. Cheapest fix: dirty glass that glows, hiding the outside.
3. **Too dark to read, not moody** (tell 1, `0 0 1280 250`): the ceiling and right side are crushed to black while no lamp is lit; it looks underlit rather than lit on purpose. Cause: light. Cheapest fix: light the wall lamps for warm pools against the cool window light.
4. **Nobody and nothing** (tell 7, `400 360 640 120`): bare tables, no people, no bottles. Cause: dressing. Cheapest fix: dress two tables and the bar.
5. **Copied table sets** (tell 6, `460 370 560 100`): the same set repeated in a row. Cause: dressing. Cheapest fix: vary chair count and angles.

## f
- 1 Flat light: PASS (`180 400 560 200`: a pool of light on the floor from the door, dark roof above)
- 2 No atmosphere: PASS (`640 270 420 140`: a little haze at the far end; thin)
- 3 Too clean: FAIL (`180 250 480 180`; `f_f_clean.png`: walls one even green from end to end, no marks)
- 4 Too straight: FAIL (`100 60 900 240`; `f_f_straight.png`: rafters and boards ruled; nothing sags)
- 5 Floating objects: PASS
- 6 Repetition: FAIL (`180 420 700 300`; `f_f_repeat.png`: the same loud swirl of wood grain on board after board)
- 7 Empty: FAIL (`180 400 880 320`; `f_f_empty.png`: a whole upstairs floor with nothing on it)
- 8 Scale tells: PASS
- 9 Edges of the world: FAIL (`100 30 300 110`; `f_f_edge.png`: white specks of daylight through the roof like gaps in the model; a flat untextured orange slab at `1060 200 220 520`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **An empty floor** (tell 7, `180 400 880 320`): no beds, rooms, trunks, rugs; a bare hall. Cause: dressing. Cheapest fix: partition walls or furniture, or don't show it yet.
2. **A flat orange slab in the foreground** (tell 9, `1060 200 220 520`): what must be an open door fills the right edge as a plain orange rectangle with no panels or grain. Cause: material. Cheapest fix: a panelled door material, or shut it.
3. **Light leaking through the roof** (tell 9, `100 30 300 110`): rows of white dashes between the roof boards read as holes in the mesh, not as a real roof. Cause: geometry. Cheapest fix: close the roof gaps or back it with a dark layer.
4. **Fake-looking floor grain** (tell 6, `180 420 700 300`): the grain is big, high-contrast and the same swirl on every board, like a printed laminate. Cause: material. Cheapest fix: lower the grain's contrast and offset it per board.
5. **Even, clean walls** (tell 3, `180 250 480 180`): unmarked pale green everywhere. Cause: material. Cheapest fix: grime toward the floor and around doors.

## g
- 1 Flat light: PASS (`60 440 520 280`: strong window light and railing shadows across the floor)
- 2 No atmosphere: PASS (`440 280 360 120`: the room below sits in a little haze; none in the sunbeams)
- 3 Too clean: FAIL (`240 160 800 540`; `g_g_clean.png`: the railing is fresh uniform orange wood, like new plastic, beside a weathered grey beam)
- 4 Too straight: FAIL (`240 180 520 300`; `g_g_straight.png`: every baluster identical and exactly spaced)
- 5 Floating objects: PASS
- 6 Repetition: PASS (`100 440 480 280`: the floor grain varies enough here; the shadow edges are stair-stepped)
- 7 Empty: FAIL (`0 100 760 160`; `g_g_empty.png`: bare floor all round the gallery, one table below)
- 8 Scale tells: PASS (the newel at `585 380 85 320` is heavy but believable)
- 9 Edges of the world: FAIL (`0 0 420 60`; `g_g_edge.png`: daylight specks through the roof boards; a flat orange door at `1130 70 130 150`)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A plastic-looking railing** (tell 3, `240 160 800 540`): the railing that fills the frame is bright, even orange with faint grain and no wear on the handrail, next to old grey timber; it looks like an untextured asset. Cause: material. Cheapest fix: darken and age it to match the floor, with wear on the rail's top.
2. **Jagged shadow edges** (tell 1, `100 440 480 280`): the window light's edge on the floor is saw-toothed. Cause: light. Cheapest fix: more shadow resolution or a softer filter on this light.
3. **Empty gallery** (tell 7, `0 100 760 160`): nothing on the upper floor or walls. Cause: dressing. Cheapest fix: a bench, a rug and a picture by the doors.
4. **Flat orange door and roof leaks** (tell 9, `1130 70 130 150`): the open door is a plain lit slab, and the roof at top left has white specks. Cause: material. Cheapest fix: a panelled door; seal the roof.
5. **Identical balusters** (tell 4, `240 180 520 300`): machine-perfect spacing, none bent, missing or mended. Cause: geometry. Cheapest fix: knock one out or mend one with a mismatched stick.

## Ranking
From least to most cheap-looking: d, g, e, b, f, a, c
