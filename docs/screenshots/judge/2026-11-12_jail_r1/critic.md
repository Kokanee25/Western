# The jail: the blind critic, round 1, 2026-11-12

I looked at the eight pair images (target painting left, game render right) and cut crops of the
front facade, the corner, the yard, the lane, the roof, the office's right wall, the cell
corridor's far end and the cell's window. I judged the form only. The exclusions hide a fair
amount. In the target the stone carries form as well as colour: dressed quoins at the corners,
raised window surrounds with lintels and sills, a moulded cornice and a coping on every parapet
and yard wall. A flat placeholder stone can't show whether those exist as geometry. Inside, the
whitewashed plaster is what makes the target's office and cells read bright, so part of the
render's darkness may come from the material and not from the openings. With the bunks and
furniture left out, the cells' chain-hung bunk shelves are missing, and those are part of how the
cage reads. Leaving out signs hides the sign panel the stepped parapet frames. The grey
neighbours hide whether the jail's scale and spacing on the street are right. The render's sky
and sun time also differ from every target, so exact light patches can't be compared.

## Grades (the building's form)

| Pair | Grade | Why |
|---|---|---|
| front | **CLOSE** | The same one-storey stone box with a centre door, a barred window each side and a raised platform with a centre step. But the top edge is flat where the target has a stepped parapet (raised end piers and a raised centre block over a cornice), the door has no transom, and the platform is planks with one step instead of a stone stoop with steps at both ends. The yard wall with its plank gate isn't on the right. |
| corner | **DIFFERENT** | The target's office block is taller and has a cornice. The cell wing steps down behind it, with small high windows, and the yard wall with its gate comes after that. The render is one box of even height with small windows and an extra doorway in the side wall, and its windows are much smaller than the target's two tall barred ones. |
| yard | **DIFFERENT** | The target looks down an enclosed yard: the cell wing's flank with small high windows on the left, the office's rear wall ahead with a door on steps and a barred window, and a plank gate in the far wall. The render shows a long free-standing box seen from its corner, with tiny slits, and the yard walls are far off and low, so there's no enclosed yard. |
| lane | **DIFFERENT** | In the target the yard wall is about head height and has a plank gate, and the cell wing's end wall rises well above it with a small barred window. The office's stepped parapet shows behind. In the render the yard wall is so tall and long that it hides almost all of the building, and it has no gate. |
| office | **DIFFERENT** | Beamed ceiling and plank floor match. But the target's room is shallow and has two tall multi-pane sash windows in the right-hand wall that flood it with sun, plus two doors in the back wall (one opening to the cells). The render's room is long and deep, with one small barred window at the far end and a doorway in the left wall. Its right-hand windows barely show, so the room is dark. |
| cells | **CLOSE** | The corridor's parts match: a row of strap-iron cages, a stone wall, a joist ceiling and a flagstone floor. But the sides are mirrored (cages on the left, not the right), and the outer wall has no row of high barred windows, only a slit at the far end. The corridor is dim and blue where the target is lit by windows and a lantern. |
| cage | **CLOSE** | The lattice cage on two sides, the stone back wall and the joists all match. The window is a tall thin slit where the target has a small, square, barred window set high, and the sun patch it should throw on the wall is missing. |
| roof | **DIFFERENT** | There's no roof to stand on: a dark wall fills the lower half at or above eye height. There's no deck of boards, no stovepipe, no hatch and no waist-high parapet with coping, and no raised parapet block at the corner. |

Totals: 0 SAME, 3 CLOSE, 5 DIFFERENT.

## The five biggest differences a viewer would notice

1. **The roof view has no roof** (roof, crop `910 330 900 176`): from the roof position, a viewer
   sees a solid dark wall at eye height and the town above it. The target shows a board deck, a
   stovepipe, a hatch and a waist-high parapet with flat coping. To match, the camera needs to
   stand on a walkable deck behind a parapet about 0.9 to 1 m high, with coping, a stovepipe and
   a hatch frame.
2. **The office is dark and the wrong shape** (office, crop `1100 40 710 420`): the target's
   office is a shallow room that two tall sash windows in the right-hand wall fill with sun. It
   has a plank door and an open door to the cells in the back wall. The render is a long, deep,
   dim room with one small barred window at the far end. To match: a shallower office, two tall
   glazed multi-pane sash windows on the street side (glass, not bars), and both doors in the
   back wall.
3. **The skyline is flat and the masses don't step** (front, crop `1150 150 420 100`; corner,
   crop `1160 140 430 200`): the target's facade ends in a stepped parapet, with raised corner
   piers and a raised centre block over a cornice. The cell wing is clearly lower than the
   office block. The render is one even-height box with a straight top edge. To match: the
   stepped parapet and cornice on the front, and the cell wing's roof dropped below the office's.
4. **The yard walls are the wrong height and the yard isn't enclosed** (lane, crop
   `945 260 800 160`; yard, crop `1120 140 520 230`): from the rear lane, the yard wall is so
   high and long that it hides the cell wing's end wall and its small barred window, and there's
   no plank gate. From the east, the cell wing stands alone with low walls far away, not as one
   side of a walled yard. To match: yard walls about 2 m high with a coping and a plank gate in
   the rear wall. The yard should be closed between the cell wing, the office's rear wall (a
   door on steps and a barred window) and the far wall.
5. **The cell corridor has no windows and no light** (cells, crop `1410 0 400 506`): in the
   target, a row of small high barred windows along the outer wall throws daylight down the
   corridor, with a lantern overhead. The render's outer wall is blank apart from one slit at the
   far end, so the corridor is dim and cold. It is also mirrored, with the cages on the left. To
   match: three or four small, square, high barred windows along the outer wall, letting in sun,
   and in the cells square barred windows instead of tall slits.
