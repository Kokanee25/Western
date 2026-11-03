# Cheap judge, 2026-11-03_cheap_r1

## a
- 1 Flat light: FAIL (`620 200 520 220`; `cut a_backwall.png`): every wall the same glowing orange from floor to rafters; the sconces make small hot spots but no pools of dark between them, no deep corners, the ceiling lit as brightly as the floor.
- 2 No atmosphere: FAIL (`620 200 520 220`; `cut a_backwall.png`): fourteen-odd lamps and no haze, smoke or glow in the air; the far wall is as crisp as the near one.
- 3 Too clean: FAIL (`0 380 260 340`; `cut a_floorleft.png`): the floor is one even plank texture with scattered dark specks; no traffic wear, no grime at the walls or under the bar.
- 4 Too straight: FAIL (`620 200 520 220`; `cut a_backwall.png`): rafters, wall boards and the bar all dead straight and evenly spaced; nothing sags or leans.
- 5 Floating objects: FAIL (`330 380 180 100`; `cut a_stools.png`): the bar stools and chair legs meet the floor with no contact darkening; they look set on top of it.
- 6 Repetition: FAIL (`1100 220 180 100`; `cut a_sconces.png`): the same twin brass sconce repeated all round the room at the same height; the hanging lamps identical.
- 7 Empty: FAIL (`620 200 520 220`; `cut a_backwall.png`): a barn-sized hall with two tables, a deer head and bare wall; one barman for the whole room.
- 8 Scale tells: FAIL (`620 0 660 400`; `cut a_backwall.png`): the roof is a barn's, two storeys of open rafters over a small bar; the room reads far too big for what's in it.
- 9 Edges of the world: PASS (`620 60 520 200`): interior; the gable's board gaps show light, which reads as intended.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **A cavernous empty barn** (tell 7, `620 200 520 220`): the room is huge, high and bare; a player sees a shell waiting for dressing, not a saloon anyone drinks in. Cause: dressing. Cheapest fix: drop a ceiling or balcony over the back half and fill the far wall with people, a piano, pictures and a stair.
2. **One even orange over everything** (tell 1, `620 200 520 220`): walls, floor and ceiling all the same warm value; nothing in shadow, so the lamps don't tell a story. Cause: light. Cheapest fix: cut the room's ambient fill hard so the space between lamps and the rafters go dark brown.
3. **No air in the lamplight** (tell 2, `620 200 520 220`): no smoke haze around the lamps or toward the back; the depth is all sharp. Cause: light. Cheapest fix: a thin warm volumetric haze that thickens with distance and blooms round each flame.
4. **Furniture sitting on the floor, not in it** (tell 5, `330 380 180 100`): stools and chairs have no ambient-occlusion shadow at their feet. Cause: light. Cheapest fix: contact shadows/AO under props.
5. **Copy-pasted sconces** (tell 6, `1100 220 180 100`): the same fixture, spacing and height round every wall. Cause: dressing. Cheapest fix: vary the fixtures (mix sconces, pictures, a mirror, shelves) and their heights.

## b
- 1 Flat light: FAIL (`860 280 420 260`; `cut b_rightwall.png`): the side wall is a uniform lit orange end to end; the ceiling as bright as the floor.
- 2 No atmosphere: FAIL (`400 280 480 200`; `cut b_bar.png`): no haze down the length of the room; the back wall reads at full clarity.
- 3 Too clean: FAIL (`0 280 480 400`; `cut b_bar.png`): the bar front is one long sheet of the same wood grain, no scuffs at the foot rail, no rings or spills on top.
- 4 Too straight: FAIL (`0 280 480 400`; `cut b_bar.png`): the bar, shelves and bottles run in perfect lines; the shelves are rows of identical spaced bottles.
- 5 Floating objects: FAIL (`240 460 260 220`; `cut b_bar.png`): the stools and spittoon have no contact shadow on the floor.
- 6 Repetition: FAIL (`0 280 480 400`; `cut b_bar.png`): the same bottle model stamped hundreds of times along the back bar; identical stools; identical sconces.
- 7 Empty: FAIL (`400 280 480 200`; `cut b_bar.png`): not one person in the room; two tables in a hall the size of a barn.
- 8 Scale tells: FAIL (`760 540 330 180`; `cut b_hand.png`): the player's hand is huge and pink, the fingers float off the grip as separate blobs and the revolver's grip texture is smeared into streaks.
- 9 Edges of the world: PASS (`400 160 480 160`): interior; the far gable is closed.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **The player's hand** (tell 8, `760 540 330 180`): a smooth pink rubber hand with fingers detached from the gun and a stretched, streaked grip; it is the first thing a player sees and it reads unfinished. Cause: geometry. Cheapest fix: re-pose the fingers wrapped round the grip and fix the grip's UV stretch.
2. **An empty hall** (tell 7, `400 280 480 200`): no one at the bar or tables in a room this big. Cause: dressing. Cheapest fix: populate it (drinkers at the bar, a card game, a barman).
3. **Stamped bottles** (tell 6, `0 280 480 400`): hundreds of the same bottle in even rows. Cause: dressing. Cheapest fix: three or four bottle shapes, varied heights, gaps, some fallen or half-empty.
4. **Even orange fill** (tell 1, `860 280 420 260`): no dark between the lamps, the rafters lit like day. Cause: light. Cheapest fix: lower ambient so only the lamp pools are bright.
5. **A bar with no use on it** (tell 3, `0 280 480 400`): one clean grain the whole length, no wear at the rail or top. Cause: material. Cheapest fix: darken and wear the bar top and foot-rail edge with grime and glass rings.

## c
- 1 Flat light: FAIL (`620 180 520 240`; `cut c_backwall.png`): the same even orange wall and bright rafters as a; no shadowed corners.
- 2 No atmosphere: FAIL (`620 180 520 240`; `cut c_backwall.png`): no smoke or haze in the lamplight; depth all crisp.
- 3 Too clean: FAIL (`0 100 260 420`; `cut c_leftdoor.png`): walls and floor uniform from end to end; no dirt at the skirting or round the door.
- 4 Too straight: FAIL (`620 180 520 240`; `cut c_backwall.png`): boards and rafters ruler-straight and evenly spaced.
- 5 Floating objects: FAIL (`330 400 180 100`; `cut a_stools.png`, same view): stools and chairs without contact shadow.
- 6 Repetition: FAIL (`900 240 260 120`; `cut c_sconces.png`): identical sconces repeated on every wall.
- 7 Empty: FAIL (`620 180 520 240`; `cut c_backwall.png`): two tables and a barn wall; the barman the only life.
- 8 Scale tells: FAIL (`620 0 660 240`; `cut c_backwall.png`): the barn roof dwarfs the bar and people.
- 9 Edges of the world: PASS (`620 60 520 200`): interior.
- 10 Stiff people: N/A
- **Verdict: cheap indie**
1. **Empty barn of a room** (tell 7, `620 180 520 240`): the same bare hall; the barman walking out helps a little. Cause: dressing. Cheapest fix: fill the back half with people and furniture or close it down with a balcony.
2. **Flat even orange** (tell 1, `620 180 520 240`): the light has no shape. Cause: light. Cheapest fix: kill the ambient fill.
3. **No smoke in the air** (tell 2, `620 180 520 240`): a saloon with no haze. Cause: light. Cheapest fix: distance haze and lamp glow.
4. **Repeated sconces** (tell 6, `900 240 260 120`): one fixture copied round the walls. Cause: dressing. Cheapest fix: vary fixtures and hang pictures between them.
5. **Props sitting on the floor** (tell 5, `330 400 180 100`): no contact darkness under stools and chairs. Cause: light. Cheapest fix: AO/contact shadows. (In its favour: the working girl's hair, corset and the subtitle read cared-for, `380 250 340 470`, `cut c_woman.png`.)

## d
- 1 Flat light: PASS (`260 200 220 240`): clear high sun, long hard shadows from people and ruts; you know where the light comes from.
- 2 No atmosphere: PASS (`560 100 360 200`): the mesas are hazed and softened against the near street.
- 3 Too clean: FAIL (`1120 140 160 200`; `cut d_jailside.png`): the jail's side wall is a flat blue-grey patch with no boards, stains or weathering.
- 4 Too straight: PASS (`0 0 1280 330`): the fronts lean and sag a little, posts out of true, the street curves.
- 5 Floating objects: FAIL (`820 440 460 200`; `cut d_rocks.png`): the road stones are shiny blue-grey lumps sitting on the dirt, not bedded in it; no dust round them.
- 6 Repetition: FAIL (`820 440 460 200`; `cut d_rocks.png`): the same rounded stone scattered evenly over the whole street, all the same blue.
- 7 Empty: PASS (`0 200 1280 200`): people talking, horses tied, a wagon down the street.
- 8 Scale tells: FAIL (`820 440 460 200`; `cut d_rocks.png`): from the low camera the stones read as boulders the size of hats.
- 9 Edges of the world: FAIL (`560 270 220 60`; `cut d_streetend.png`): the street ends in a bright blank plain with nothing past the last buildings.
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **Blue pebbles strewn like confetti** (tell 6, `820 440 460 200`): identical cool-grey stones evenly spread, glossy and sitting on top of the ground; the worst thing in the frame. Cause: dressing. Cheapest fix: colour them the dirt's tan, bed them half into the ground and cluster them along the ruts and edges.
2. **A blank side wall on the jail** (tell 3, `1120 140 160 200`): a flat blue panel next to a carefully weathered front. Cause: material. Cheapest fix: give the side the same board wood as the front.
3. **The street runs out into nothing** (tell 9, `560 270 220 60`): beyond the last building a flat white plain. Cause: geometry. Cheapest fix: close the vista with a building, corral or trees at the street's end.
4. **Stone scale from low down** (tell 8, `820 440 460 200`): the stones look like boulders. Cause: dressing. Cheapest fix: shrink most of them to gravel and keep a few larger.
5. **People in a slack stand** (tell 3/7, `260 200 220 240`; `cut d_couple.png`): the man's arms hang straight like a mannequin while she talks with a hand out; it reads posed, not talking. Cause: people. Cheapest fix: a conversational idle for the listener (hand on hip, weight shifted).

## e
- 1 Flat light: PASS (`0 0 1280 720`): golden low sun, long shadows down the ruts, warm rim on the fronts; the light tells the time of day.
- 2 No atmosphere: PASS (`640 240 640 200`; `cut e_farstreet.png`): dust and sun rays down the street, the canyon hazed.
- 3 Too clean: PASS (`0 0 420 340`; `cut e_porch.png`): the fronts are worn, boards patched, the steer skull and wanted poster dress the porch.
- 4 Too straight: PASS (`0 0 660 440`): the buildings sag and lean; the street curves.
- 5 Floating objects: PASS (`560 480 420 240`; `cut e_rocks.png`): the stones here take the dirt's colour and sit in shadow; the trough and horses ground with shadows.
- 6 Repetition: PASS (`640 240 640 200`): fronts differ; horses vary in pose.
- 7 Empty: PASS (`0 220 420 340`; `cut e_porch.png`): a man on the porch, horses tied, figures and a wagon down the street.
- 8 Scale tells: FAIL (`760 440 330 280`; `cut e_hand.png`): the player's hand is oversized, smooth pink, the fingers floating apart from the gun and the grip streaked.
- 9 Edges of the world: PASS (`900 360 200 60`; `cut e_streetend.png`): the street opens onto a bright flat plain, but the haze and the canyon behind make it read as distance.
- 10 Stiff people: N/A
- **Verdict: good indie**
1. **The rubber hand** (tell 8, `760 440 330 280`): in a frame this pretty, the player's own hand is the cheapest thing in it: smooth unpainted pink, detached fingers, a stretched grip. Cause: geometry. Cheapest fix: re-pose the grip so the fingers wrap the stock, paint the hand in the world's painted style.
2. **The man on the porch stands like a mannequin** (tell 8/people, `0 220 420 340`; `cut e_porch.png`): arms hanging straight down, square to camera, lit by the lamp right on his hat. Cause: people. Cheapest fix: a lean on the post or arms folded.
3. **Horses' plastic hide** (`0 340 420 380`; `cut e_porch.png`): hard flat-shaded facets and a uniform sheen on the horses next to the painted wood. Cause: material. Cheapest fix: paint the coat with muscle shading and dust low on the legs.
4. **Street end opens on blank plain** (`900 360 200 60`; `cut e_streetend.png`): the haze rescues it, but there's no building or tree closing the view. Cause: geometry. Cheapest fix: a silhouette (water tower, barn) at the end.
5. **Pale grey side wall and lettering slightly crisp** (`420 150 230 140`): the sign lettering is clean stencil on otherwise weathered boards. Cause: material. Cheapest fix: break up the lettering with fade and chips.

## f
- 1 Flat light: PASS (`0 0 483 272`; `cut f_frame1.png`): warm low sun, porch interior lamp-lit and darker than the street.
- 2 No atmosphere: PASS (`0 40 300 120`): the mesa softened and pinked by distance.
- 3 Too clean: PASS (`200 0 283 230`): weathered boards, patched siding, skull and posters.
- 4 Too straight: PASS (`140 0 343 230`): posts and rails slightly out of true.
- 5 Floating objects: PASS (`140 150 340 120`): the horses' hooves sit on the ground with shadow.
- 6 Repetition: PASS (`140 90 220 150`): two horses of a different colouring and pose.
- 7 Empty: PASS (`140 80 343 160`): horses, a rider, a man on the porch bench, men coming and going.
- 8 Scale tells: PASS (`140 90 343 160`): horses, people, porch read the right sizes.
- 9 Edges of the world: FAIL (`0 60 180 60`; `cut f_plain.png`): left of the mesa the land is a flat empty plain to a ruler-straight horizon with a few dots of bush.
- 10 Stiff people: FAIL (`140 90 220 150`; `cut f_rider.png`; `380 90 100 90`, `cut f_seated.png`): across eight frames the rider on the left horse and the man on the bench do not move at all; people pop in and out at the porch door between frames rather than walking.
- **Verdict: good indie**
1. **Frozen people** (tell 10, `140 90 220 150`): the mounted man and the seated man hold one pose through the whole strip; only the right horse shifts its head and a leg. Cause: people. Cheapest fix: breathing, head turns and a weight shift on every idle person, out of step with each other.
2. **Horses' faceted, glossy coats** (`140 90 343 160`; `cut f_frame1.png`): plastic-orange low-poly shading against the painted wood. Cause: material. Cheapest fix: paint the coats with soft muscle shading and dust.
3. **The empty plain** (tell 9, `0 60 180 60`): a flat strip to the horizon with a few dots. Cause: geometry. Cheapest fix: rolling ground, scrub and a distant ridge on that side.
4. **People appearing at the door** (tell 10, `330 60 150 120`; `cut f_frame3.png`): figures appear between frames by the porch post, reading as pop-in rather than arriving. Cause: people. Cheapest fix: have them walk out of the doorway visibly.
5. **The seated man barely reads** (`380 90 100 90`; `cut f_seated.png`): a dark lump behind the rail in shadow, no pose to say what he's doing. Cause: people. Cheapest fix: a lamp near him and a readable action (whittling, hat over eyes).

## Ranking
From least to most cheap-looking: e, f, d, c, a, b
