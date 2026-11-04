# Cheap judge, 2026-11-04_cheap_r0_real

## a
- 1 Flat light: FAIL (`0 0 1280 230`, the ceiling as bright as the floor; `cut a_ceiling.png`)
- 2 No atmosphere: FAIL (`620 160 600 280`, the far wall as crisp as the near table, no smoke or haze in the lamplight; `cut a_a_backwall.png`)
- 3 Too clean: FAIL (`40 430 620 290`, the floor one even plank texture with stamped knots, no wear path, dirt or spills; `cut a_a_floor.png`)
- 4 Too straight: FAIL (`0 0 1280 230`, rafters and roof boards at perfect even spacing, nothing sags; `cut a_ceiling.png`)
- 5 Floating objects: PASS (`700 380 450 320`, chairs and table carry soft contact shadows)
- 6 Repetition: FAIL (`680 180 600 140`, the same brass sconce at even spacing down every wall, each throwing the same V of shadow; `cut a_sconces.png`)
- 7 Empty: FAIL (`620 160 600 280`, a barn-sized back wall with one deer head on it, one barkeep in the whole room; `cut a_a_backwall.png`)
- 8 Scale tells: FAIL (`230 220 300 270`, the room is a two-storey barn with no upper floor; the back bar holds ~120 tiny cloned bottles in three rows; `cut a_a_bar.png`)
- 9 Edges of the world: PASS (interior; the gable's board gaps show night, which reads right)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Everything the same orange** (tell 1, `0 0 1280 230`): the ceiling, the walls and the floor sit at one brightness and one hue; no corner falls to black, so the dozen lamps light nothing in particular. Cause: light. Cheapest fix: drop the room's ambient/fill to near zero so the lamps make pools and the ceiling goes dark.
2. **One sconce, cloned** (tell 6, `680 180 600 140`): identical lamps at even intervals, each with the same stencilled V-shadow under it. Cause: dressing. Cheapest fix: remove half of them and break the spacing; let the rest be different fixtures.
3. **The woman's hair is a red clay helmet** (tell 3, `490 240 150 340`): one solid sculpted mass with painted grooves, no strands, no loose ends, the same saturated orange-red as the walls; it fills the middle of the frame. Cause: people. Cheapest fix: a darker, less saturated hair colour with alpha-carded strands at the silhouette.
4. **A clean, new floor** (tell 3, `40 430 620 290`): boards with repeated dark knots, no traffic wear by the bar, no sawdust, spit or dirt along the walls. Cause: material. Cheapest fix: a darkened, scuffed wear decal in front of the bar and along the walking lines.
5. **A barn, not a saloon** (tell 7, `620 160 600 280`): a huge bare plank wall with one trophy, a mostly empty floor, and a dark object (`800 400 220 320`, the held weapon) that reads as a rolled rug or bat. Cause: dressing. Cheapest fix: hang pictures, shelves and a mirror on the back wall and seat a few men at the tables.

## b
- 1 Flat light: FAIL (`0 0 1280 280`, ceiling, walls and floor all evenly lit; `cut b_ceiling.png`)
- 2 No atmosphere: FAIL (`400 280 500 220`, star-shaped flares on the lamps but no haze; the far wall is sharp; `cut b_backwall.png`)
- 3 Too clean: FAIL (`150 470 650 250`, an unmarked floor of identical boards; `cut b_floor.png`)
- 4 Too straight: FAIL (`0 0 1280 280`, rafters in perfect rows to a perfect ridge; `cut b_ceiling.png`)
- 5 Floating objects: PASS (`240 480 260 220`, stools and spittoons cast small contact shadows)
- 6 Repetition: FAIL (`0 290 320 200`, cloned bottles in rows; `400 280 500 220` the same sconce and V-shadow pair on the far wall; `cut b_bottles.png`)
- 7 Empty: FAIL (`150 470 650 250`, a long bare floor down the middle with nobody on it; `cut b_floor.png`)
- 8 Scale tells: FAIL (`680 420 600 300`, the hand is huge and faceted next to a small, blocky revolver gripped by a striped plank; `cut b_hand.png`)
- 9 Edges of the world: PASS (interior)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The hand and gun** (tell 8, `680 420 600 300`): the first thing you see is a low-poly hand with visible facets and flat pink shading, fingers wrapped round a grip textured in vertical stripes, and a blocky gun with smeared texture. Cause: people. Cheapest fix: smooth-shade the hand (normals) and repaint the grip with real wood and checkering.
2. **Even orange everywhere** (tell 1, `0 0 1280 280`): the roof as bright as the floor, no darkness between the lamps, so the room reads as daylight with an orange filter. Cause: light. Cheapest fix: kill the fill so the space between lamps goes dark.
3. **Stencilled lamp shadows** (tell 6, `400 280 500 220`): each wall lamp throws the same hard V-wedge down the planks, repeated across the wall. Cause: light. Cheapest fix: soften the fixtures' shadows or turn shadows off on the bracket meshes.
4. **An empty hall** (tell 7, `150 470 650 250`): a long run of bare floor to a bare end wall; one barkeep, no customers. Cause: dressing. Cheapest fix: tables and people in the middle of the room.
5. **Cloned bottles** (tell 6, `0 290 320 200`): the back bar is three rows of the same bottle, too many and too small. Cause: dressing. Cheapest fix: fewer, larger, varied bottles with gaps, glasses and a few boxes among them.

## c
- 1 Flat light: FAIL (`0 0 1280 250`, the roof lit as evenly as the floor; `cut c_ceiling.png`)
- 2 No atmosphere: FAIL (`540 180 520 240`, the gallery and stair are as crisp as the bar beside you; no smoke; `cut c_back.png`)
- 3 Too clean: FAIL (`880 360 400 360`, the bar's front and top one flat pale plank texture, no rings, scuffs or rail wear; `cut c_bar.png`)
- 4 Too straight: FAIL (`0 0 1280 250`, perfect rafter rhythm; `cut c_ceiling.png`)
- 5 Floating objects: PASS (`110 400 360 230`, the chairs and table sit on their shadows)
- 6 Repetition: FAIL (`1080 230 200 200`, rows of cloned bottles; the same sconce and the same hanging lamp repeated; `cut c_bottles.png`)
- 7 Empty: FAIL (`300 430 600 290`, a big open floor and one woman across the room; `cut c_floor.png`)
- 8 Scale tells: PASS (`540 180 520 240`, the door, stair and woman sit right with each other)
- 9 Edges of the world: PASS (`700 250 80 150`, the doorway shows a night street)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Flat orange room** (tell 1, `0 0 1280 250`): the same even warm fill on every surface; the lamps don't shape anything. Cause: light. Cheapest fix: the fill down and the lamps' falloff tighter, so the room breaks into pools and shadow.
2. **The bar is a plank box** (tell 3, `880 360 400 360`): a pale, evenly textured slab with an over-sharp end grain, no varnish, no foot rail, no wear where elbows go. Cause: material. Cheapest fix: a darker varnished top with a worn, lighter strip at the edge and a brass foot rail.
3. **The hand and gun** (tell 8, `740 440 300 280`): the same faceted hand and striped grip in the corner of every view. Cause: people. Cheapest fix: smooth the hand's shading and repaint the grip.
4. **Nobody here** (tell 7, `300 430 600 290`): one woman with her arms up by the piano and an otherwise empty saloon at night. Cause: dressing. Cheapest fix: men at the tables and at the bar.
5. **Cloned bottles and lamps** (tell 6, `1080 230 200 200`): the back bar is a wall of identical bottles; the same lamp everywhere. Cause: dressing. Cheapest fix: vary and thin the bottles; two or three lamp designs.
(What it does better than a and b: the stair, the gallery, framed pictures and an open door give the room some layers and story.)

## d
- 1 Flat light: FAIL (`0 0 1280 240`, the ceiling as bright as the floor; `cut d_ceiling.png`)
- 2 No atmosphere: FAIL (`620 180 600 280`, the far wall crisp, no air in the lamplight; `cut d_backwall.png`)
- 3 Too clean: FAIL (`40 450 620 270`, an unworn floor with repeated knots; `cut d_floor.png`)
- 4 Too straight: FAIL (`0 0 1280 240`, rafters in perfect rows; `cut d_ceiling.png`)
- 5 Floating objects: PASS (`720 440 360 260`, chairs and table shadowed where they stand)
- 6 Repetition: FAIL (`680 200 600 140`, the same sconce at even spacing with the same V-shadow; `cut d_sconces.png`)
- 7 Empty: FAIL (`620 180 600 280`, a bare back wall and empty tables; `cut d_backwall.png`)
- 8 Scale tells: FAIL (`230 230 300 270`, the barn-high room, rows of tiny cloned bottles; `cut d_bar.png`)
- 9 Edges of the world: PASS (interior)
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **One orange everywhere** (tell 1, `0 0 1280 240`): walls, floor and ceiling at one brightness; no dark corners, no light direction. Cause: light. Cheapest fix: lose the fill so the lamps make pools.
2. **The hair helmet** (tell 3, `500 250 160 340`): a sculpted red mass with painted grooves and no strands, the brightest-saturated thing in the frame, in the middle of it. Cause: people. Cheapest fix: duller, darker hair with carded strands at the edges.
3. **Cloned sconces** (tell 6, `680 200 600 140`): one fixture repeated at even spacing with identical shadow wedges. Cause: dressing. Cheapest fix: fewer lamps, irregularly placed, two or three kinds.
4. **Bare barn** (tell 7, `620 180 600 280`): a two-storey plank wall with a single trophy; the room has no ceiling floor, no gallery on this side, no clutter. Cause: dressing/geometry. Cheapest fix: dress the back wall (mirror, pictures, shelves) and lower the visual ceiling with a gallery or beams in shadow.
5. **New floorboards** (tell 3, `40 450 620 270`): even, clean, unworn planks with the same knots repeating. Cause: material. Cheapest fix: wear and grime decals along walking lines and walls.
(Slightly better than a: a man in front of her adds a bit of life and there is no unreadable object across the frame.)

## e
- 1 Flat light: FAIL (`300 330 700 390`, a noon sun but the road is one washed beige, the blacks lifted, the fronts grey; `cut e_road.png`)
- 2 No atmosphere: PASS (`400 90 500 220`, the far street and the canyon fade into pale haze)
- 3 Too clean: PASS (`880 0 400 300`, weathered boards on the fronts, ruts and droppings in the road)
- 4 Too straight: FAIL (`380 300 520 420`, the ruts run as two dead-straight parallel tracks, like rails, the whole length of the street; `cut e_ruts.png`)
- 5 Floating objects: PASS (`880 300 400 280`, the man and the stones have contact shadows)
- 6 Repetition: FAIL (`880 300 400 280`, the same grass clump planted in a row along each boardwalk and the same faceted stone sprinkled evenly over the road; `cut e_grass.png`)
- 7 Empty: FAIL (`150 180 450 200`, boardwalks with nothing on them: no barrels, crates, signs or people at the doors; `cut e_boardwalk.png`)
- 8 Scale tells: PASS (horses, people and doors agree)
- 9 Edges of the world: FAIL (`540 220 200 100`, a dark, smeared shape hangs over the end of the street in front of the canyon; `cut e_blob.png`)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Stones sprinkled by a script** (tell 6, `880 300 400 280`): one low-poly stone, scattered evenly over the whole road, and one grass clump planted in rows along the boardwalk edges. Cause: dressing. Cheapest fix: cluster the stones at the road's edges and in the ruts, and cut the grass to a few uneven clumps where nobody walks.
2. **Washed-out noon** (tell 1, `300 330 700 390`): the light is grey-beige and soft; for a high sun, shadows under the porches and on the road are weak and the darks are lifted. Cause: light. Cheapest fix: more contrast: deeper porch shade and darker, cooler shadows.
3. **A smear at the end of the street** (tell 9, `540 220 200 100`): a dark brown blot over the street's vanishing point reads as a broken backdrop card. Cause: geometry. Cheapest fix: find and remove or rebuild what that is (it looks like a backdrop or effect layered at the wrong depth).
4. **Rails, not ruts** (tell 4, `380 300 520 420`): two perfectly parallel straight tracks down the middle. Cause: material. Cheapest fix: wander the ruts, break them, and add hoof-churn between.
5. **Empty boardwalks** (tell 7, `150 180 450 200`): fronts with nothing outside them; few people for a town at noon. Cause: dressing. Cheapest fix: barrels, crates, a bench and a man on each porch.
(What holds it in good indie: the haze and the canyon give real depth, and the low camera with horses in frame reads as a place.)

## f
- 1 Flat light: PASS (`0 150 650 330`, a lantern-lit porch against a low sun; light with a source and warm/cool contrast)
- 2 No atmosphere: PASS (`700 300 400 100`, the far street glows in haze)
- 3 Too clean: PASS (`0 0 650 450`, weathered boards, worn posts, a wanted poster)
- 4 Too straight: PASS (`550 380 450 340`, the ruts curve; the fronts step)
- 5 Floating objects: PASS (`1080 340 200 180`, the man and horses sit on their shadows)
- 6 Repetition: FAIL (`0 330 1280 240`, three identical bays with the same saddle, the same grass clump along the porch, the same stones; `cut f_horses.png`)
- 7 Empty: PASS (men on the porches and down the street)
- 8 Scale tells: FAIL (`730 440 360 280`, the faceted hand fills the corner, holding a striped plank grip; `cut f_hand.png`)
- 9 Edges of the world: FAIL (`420 0 860 300`, the sky is an oil painting with visible brushwork, so the town reads as standing in front of a painted backdrop; `cut f_sky.png`)
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **A painted sky** (tell 9, `420 0 860 300`): thick visible brushstrokes in the clouds; next to 3D buildings it looks like a theatre backdrop, and the canyon beside it has the same painted finish. Cause: material. Cheapest fix: a photographic or volumetric sunset sky without brush texture.
2. **The hand and gun** (tell 8, `730 440 360 280`): faceted low-poly skin and a stripe-textured grip in front of a carefully lit street. Cause: people. Cheapest fix: smooth shading on the hand, a repainted grip.
3. **Clone horses** (tell 6, `0 330 1280 240`): the same bay with the same saddle three times; the near one's body is blocky and flat-shaded. Cause: dressing. Cheapest fix: vary coat colour and tack per horse.
4. **A heavy orange grade** (tell 1, `0 0 1280 720`): everything pushed toward one orange; reads more filter than sunset, though the light has direction. Cause: light. Cheapest fix: pull the grade's saturation back and let shadows go cooler.
5. **Grass and stones from one stamp** (tell 6, `100 430 400 160`): the same tuft in rows along the porch and the same stones dotted evenly over the road. Cause: dressing. Cheapest fix: fewer, clustered clumps and stones.
(The best frame of the set: a lit porch, a man under a lantern, haze down the street, a clear time of day.)

## g
- 1 Flat light: PASS (frame 1, `0 0 483 272`: a lantern-lit porch at dusk with long shadows on the ground)
- 2 No atmosphere: PASS (frame 1, `0 30 200 110`: the far mesa is softened somewhat)
- 3 Too clean: PASS (worn porch boards, a barrel, dirt road)
- 4 Too straight: PASS (porch posts and rails, nothing out of place for a building)
- 5 Floating objects: PASS (`130 60 350 200`, hooves and grass sit on the ground with shadow)
- 6 Repetition: FAIL (`130 60 350 200`, two identical bays with identical saddles, side by side; the same grass card repeated; `cut g_horses.png`)
- 7 Empty: PASS (men on the porch, horses at the rail)
- 8 Scale tells: PASS (horses, porch and men agree)
- 9 Edges of the world: FAIL (`0 30 200 110`, behind the porch a flat pale plain with a few dark dots and a painted mesa: a backdrop card; `cut g_backdrop.png`)
- 10 Stiff people: FAIL (`966 0 483 272`, frame 3: across eight frames the horses hold the same pose, tails and heads fixed, while men appear in the doorway in frame 3 and are gone by frame 4; `cut g_frame3.png`)
- **Verdict: cheap indie**
1. **Nothing moves** (tell 10, `130 60 350 200`): over the whole strip the horses barely shift, no tail swish, no head toss, no weight change; the seated man is a statue. Cause: people. Cheapest fix: a horse idle with tail flicks and head turns, offset per horse.
2. **People pop in and out** (tell 10, `966 0 483 272`): three figures fill the doorway in frame 3 and are gone the next frame. Cause: people. Cheapest fix: walk them in and out through the door instead of snapping.
3. **Toy horses** (tell 6, `130 60 350 200`): two identical, blocky, flat-shaded bays with the same chunky orange saddle and bags, like plastic models. Cause: material. Cheapest fix: vary the coats and darken and roughen the leather.
4. **A backdrop behind the porch** (tell 9, `0 30 200 110`): an empty flat plain and a painted mesa with no middle distance. Cause: geometry. Cheapest fix: a few fences, rocks or a shack in the middle distance and haze over the plain.
5. **Stamped grass** (tell 6, `380 170 100 90`): the same yellow tuft clumps by the porch. Cause: dressing. Cheapest fix: mixed, sparser grass of two or three kinds.

## Ranking
From least to most cheap-looking: f, e, c, g, d, a, b
