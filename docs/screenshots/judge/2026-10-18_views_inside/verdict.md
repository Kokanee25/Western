# Art judge, 2026-10-18_views_inside

## a
- Shapes: FAIL (the player's hand and gun, bottom centre: stacked toy blocks, not a hand; the room, bar, chairs and rafters are credible)
- Painted surface: FAIL (the side walls: smooth varnished red stripes with dotted seams; the floor's knots are scattered dark spots, not painted grain)
- Light: FAIL (the whole room: evenly bright, pale ceiling lit like day, no deep shadows; the wall sconces don't make pools of warm light against cool dark)
- People: FAIL (the hand: coarse orange blocks; the barman is a tiny dark smudge)
- One hand: FAIL (the blocky hand and camouflage-squared gun beside the smooth photo-like floor and walls)
- **Verdict: FAIL**
1. **Flat, high-key light** (`0 0 1280 220`): the ceiling and floor are lit evenly and pale, so the room reads as a lit barn by day; the authority is dark amber with deep, readable shadows and light pooling under each lamp. Cause: light. Fix: cut the ambient/fill to a dim cool level and let the sconces and chandeliers carry the room, with falloff into dark corners and rafters.
2. **Toy-block hand and gun** (`720 420 320 300`): fingers are big orange cuboids and the gun is random camouflage squares; the authority's hand is a painted hand with knuckles, warm skin and a dark cuff. Cause: shape. Fix: replace the viewmodel hand with a modelled hand painted in the man's style (planes of the knuckles, a sleeve).
3. **Varnished red walls** (`0 120 260 400`): smooth glossy red stripes with a dotted seam, like plastic panelling; the authority's walls are weathered boards painted in warm brown patches. Cause: paint. Fix: repaint the wall boards brown and worn in angular strokes, less red and less sheen.

## b
- Shapes: FAIL (the player's hand, bottom centre: toy blocks; the bar, stools and roof are credible)
- Painted surface: FAIL (the bar front: stretched photographic grain with black slot-like knots)
- Light: FAIL (the room: even and bright, ceiling pale, no deep darks; the far wall lamps do nothing)
- People: FAIL (the barman: smooth, flat, his face a dark blur; the hand blocky)
- One hand: FAIL (blocky hand, smooth barman and photo-grain bar in one frame)
- **Verdict: FAIL**
1. **Flat bright room** (`0 0 1280 280`): the pitched ceiling is a pale, evenly lit plane and nothing falls into shadow; the authority's room is lamp-lit amber with deep darks. Cause: light. Fix: drop the ambient and sky light inside; give each lamp a warm falloff and let the roof go dark.
2. **Bar front grain** (`0 380 520 340`): a photo-like grain stretched along the bar with black slot knots repeating; the authority's bar is broad warm painted planks. Cause: paint. Fix: repaint the bar front as wide planks with painted patches, no repeating dark knots.
3. **Barman and hand** (`60 340 260 280`): the barman is smooth flat colour with a dark muddy face, nothing like the authority's painted barman; the player's hand (`760 430 320 290`) is orange blocks. Cause: paint. Fix: paint the barman's face and clothes in planes like the authority, and a real painted hand.

## c
- Shapes: FAIL (the player's hand, bottom centre: blocks; the room, stairs and bar read)
- Painted surface: FAIL (the bar top: smeared stretched grain with dark streaks)
- Light: FAIL (the room: bright and flat, pale ceiling; only the blue door hints at night)
- People: FAIL (the barman: dark mottled face, smooth white sleeve, cut off at the shelves)
- One hand: FAIL (blocky hand, smeared bar, smooth barman)
- **Verdict: FAIL**
1. **Bar top smeared** (`860 340 420 380`): the grain is stretched and smeared into streaks like a low-res photo pulled along the top; the authority's wood is painted in angular patches that follow each board. Cause: paint. Fix: map the bar top so its texture isn't stretched, and paint it as boards with broad worn patches.
2. **Flat bright light** (`0 0 1280 400`): the ceiling and floor are lit evenly like day, so the moonlit door and lamps have nothing to glow against; the authority is dark amber with readable shadow. Cause: light. Fix: lower the interior ambient and let lamps pool warm light.
3. **Barman and hand** (`1060 280 200 200`): the barman's face is a dark mottled smear and his sleeve a smooth white shape; the player's hand (`740 420 300 300`) is orange blocks. Cause: paint. Fix: give the barman a painted face (planes, warm skin, moustache) and the hand a real model.

## d
- Shapes: PASS (the seated man, the men behind him, table, lamp and bottle are credible masses with good silhouettes)
- Painted surface: FAIL (the near man's face and coat: random mottled squares, camouflage, not strokes following the form)
- Light: PASS (warm lamp key on the table and faces, cool blue moonlight through the door, darks readable)
- People: FAIL (the near man's face is coarse squares without planes; the men behind are smooth flat colour with jagged red vest edges)
- One hand: FAIL (the coarse-squared man beside smooth background men and a smooth, streaked table)
- **Verdict: FAIL**
1. **Coarse squares on the near man** (`380 120 300 300`): his face, hat and coat are big mottled squares that don't follow the planes of the face or the folds; the authority's man is painted in angular patches that follow the cheekbones, brow and coat folds. Cause: paint. Fix: paint his face and coat at a finer texel size with strokes following form; keep only a little square.
2. **Smooth background men** (`640 80 280 420`): the standing men are flat smooth colour, the red vest has a ragged, torn edge into the white sleeve; the authority's background men are painted with folds and lit edges. Cause: paint. Fix: paint the background men's clothes in folds and clean up the vest's edge where it meets the shirt.
3. **Streaked table top** (`720 400 560 320`): the table is stretched, streaky grain like a smeared photo; the authority's table is painted boards with warm lamp highlights and worn edges. Cause: paint. Fix: unstretch the table top's mapping and repaint it as boards with broad painted patches.

## e
- Shapes: PASS (the near man, the card players, the standing men and the stairs read as credible forms)
- Painted surface: FAIL (the near man's face and hat: noisy coarse squares)
- Light: PASS (warm lamp on the left wall and faces, blue moonlit door behind, darks readable)
- People: FAIL (the near man's face is noisy squares, not planes; the card players and the red-vest man are smooth flat colour)
- One hand: FAIL (the noisy-squared near man against smooth background men and walls)
- **Verdict: FAIL**
1. **Noisy face** (`440 120 420 340`): close up, the face, moustache and hat are random coarse squares, the eyes stuck on; the authority's face is modelled in a few broad warm planes with a painted moustache. Cause: paint. Fix: repaint his face in planes at a finer texel size, so squares follow cheek, brow and nose.
2. **Red vest torn edge and smooth sleeves** (`1040 60 240 520`): the vest's edge is ragged and the white sleeves are smooth flat white with no folds; the authority's clothes are painted in folds. Cause: shape. Fix: give the vest a clean edge on its own mesh and paint the sleeves with folds and shading.
3. **Flat card players** (`0 280 420 440`): their faces and clothes are smooth, unshaded colour, small and doll-like beside the near man; the authority's players are painted, lit figures. Cause: paint. Fix: paint the background men with the same strokes as the near man, at matched detail.

## f
- Shapes: PASS (the man, bar, chairs and table are credible; the man stands stiff but sound)
- Painted surface: FAIL (the side walls: varnished red stripes; the floor: scattered dark knot spots)
- Light: FAIL (the room: bright and even, pale ceiling, no deep shadows)
- People: PASS (the standing man: face in planes, warm skin, painted moustache and hair, coat painted in folds, lit)
- One hand: FAIL (the man's squared paint against the smooth, photo-like room)
- **Verdict: FAIL**
1. **Flat bright room** (`0 0 1280 220`): the ceiling and floor are lit like day; the authority's room is dark amber with lamp pools and readable shadow. Cause: light. Fix: lower the interior ambient and let the sconces and chandeliers carry the light.
2. **Man and room don't match** (`560 260 160 360`): the man is painted in squares and warm patches, but the room around him is smooth, varnished and bright; the authority paints both in the same strokes. Cause: paint. Fix: repaint the walls and floor in the same angular, slightly square patches as the man.
3. **Varnished red walls** (`0 120 260 400`): glossy red stripes with dotted seams, like plastic panelling. Cause: paint. Fix: repaint the walls as weathered brown boards with painted wear, less red and less sheen.

## g
- Shapes: FAIL (the player's hand: blocks; the back wall is studs and gaps, the room thin and bare)
- Painted surface: FAIL (the grey walls: photographic weathered planks; the floor: photo grain with dark knots)
- Light: FAIL (the room: flat grey daylight, no warm key, no lamp, nothing in shadow)
- People: FAIL (the man behind the bar: dark squared blob with no face; the hand blocky)
- One hand: FAIL (photo-like grey walls, orange floor, blocky hand and squared man)
- **Verdict: FAIL**
1. **No light to speak of** (`220 200 560 220`): the room is lit flat grey from everywhere, no warm key and no cool fill, so nothing reads; the authority has a named warm source and deep shadows. Cause: light. Fix: light it from the door and windows (warm low sun in a shaft) and let the room's corners go dark.
2. **Light leaking through the floor** (`820 440 460 100`): thin bright lines run across the floorboards, seams showing through; the authority's floor is solid. Cause: shape. Fix: close the gaps between floorboards (or put a dark backing under them).
3. **Faceless barman** (`900 260 220 120`): the man is a dark, coarse-squared blob, his face unreadable against the pale wall; the authority's faces are painted planes in warm light. Cause: paint. Fix: paint his face and clothes like the authority's man, and light him.

## h
- Shapes: FAIL (the player's hand: blocks; the back wall a grid of studs with light leaking through)
- Painted surface: FAIL (the side walls: photographic grey planks; the windows: flat brown cards)
- Light: PASS (warm lamp on the bar as key, cool blue-grey on the back wall, darks readable)
- People: FAIL (the barman: dark mottled, no face; the hand blocky)
- One hand: FAIL (photo planks, flat brown windows, blocky hand)
- **Verdict: FAIL**
1. **Light leaking through the back wall** (`220 0 600 380`): bright dashes between every board and stud make the wall look like a lit grid; the authority's walls are solid and dark. Cause: shape. Fix: seal the wall's board gaps (a backing layer behind the boards).
2. **Flat brown windows** (`260 240 260 200`): the windows are opaque brown rectangles with no glass, frame or night beyond; the authority's windows show blue night and reflections. Cause: paint. Fix: give the windows panes with a cool painted night behind them and a frame.
3. **Faceless barman** (`880 260 240 180`): a dark mottled shape with no face, lit only from behind by the lamp; the authority's men are lit faces in warm light. Cause: paint. Fix: paint his face and let the bar lamp light his front.

## i
- Shapes: FAIL (the player's hand: blocks; the mirrors behind the bar are flat beige cards)
- Painted surface: FAIL (the bar front: stretched photographic grain with black slot knots)
- Light: FAIL (the room: flat greyish daylight, lamps unlit, no warm key, no deep darks)
- People: FAIL (the men at the bar: coarse mottled squares with orange skin patches showing through their boots and clothes)
- One hand: FAIL (mottled men, photo-grain bar, flat beige mirrors, blocky hand)
- **Verdict: FAIL**
1. **Mottled men with skin showing through** (`420 260 260 260`): the men at the bar are camouflage squares, and orange patches show through at boots and hems; the authority's men are painted in folds and lit. Cause: paint. Fix: paint their clothes in folds and fix where skin pokes through the garments.
2. **Flat, unlit room** (`0 0 1280 720`): the room is lit in flat grey-brown with no lamp lit and no shadow; the authority is lit warm by lamps with deep, readable darks. Cause: light. Fix: light the lamps and drop the ambient so they carry the room.
3. **Bar front grain and flat mirrors** (`120 360 420 260`): the bar front is stretched photo grain with black knot slots, and the mirrors behind (`120 120 420 260`) are flat beige cards. Cause: paint. Fix: repaint the bar front as broad planks, and give the mirrors a painted reflection of the warm room.
